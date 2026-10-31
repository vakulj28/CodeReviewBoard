# =============================================================================
# CI/CD IAM roles (GitHub Actions via OIDC, keyless)
# =============================================================================
# Three roles, all trusting the account's EXISTING GitHub OIDC provider:
#   - ci-plan   : read-only; assumed on PRs + pushes to main (terraform plan)
#   - ci-apply  : write; assumed ONLY from the gated prod environment (apply/destroy)
#   - ci-deploy : push the container image to ECR; assumed on pushes to main
#
# ORG OIDC QUIRK (same as Project 1): this org rewrites the OIDC `sub` claim to
# embed numeric owner/repo IDs, so a standard `repo:owner/repo:...` sub never
# matches. We pin the clean `repository`/`actor`/`environment` claims with
# StringEquals and wildcard the sub's id portion with StringLike.

# ---- Trust: plan role (PRs + main) ------------------------------------------
data "aws_iam_policy_document" "plan_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository"
      values   = [var.github_repo]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:actor"
      values   = [var.github_actor]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:*:pull_request",
        "repo:*:ref:refs/heads/main",
      ]
    }
  }
}

# ---- Trust: apply role (gated prod environment only) ------------------------
data "aws_iam_policy_document" "apply_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository"
      values   = [var.github_repo]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:actor"
      values   = [var.github_actor]
    }
    # Gated by the protected environment; match the clean `environment` claim.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:environment"
      values   = [var.github_environment]
    }
    # AWS requires a sub (or job_workflow_ref) condition not scoped to all.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:*:environment:${var.github_environment}"]
    }
  }
}

# ---- Trust: deploy role (pushes to main) -----------------------------------
data "aws_iam_policy_document" "deploy_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository"
      values   = [var.github_repo]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:actor"
      values   = [var.github_actor]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:*:ref:refs/heads/main"]
    }
  }
}

# ---- Permissions: apply role (least-privilege for THIS stack) ---------------
# Broad-ish at the service level because IaC creates resources whose ARNs aren't
# all known ahead of time, but every statement is scoped to this project's
# resources. The real guardrail is the environment approval gate on the trust.
data "aws_iam_policy_document" "apply" {
  statement {
    sid       = "STS"
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  # Terraform state in the shared bucket — our key prefix only.
  statement {
    sid       = "S3StateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }
  statement {
    sid       = "S3StateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/code-review-board/*"]
  }

  # Read the reused OIDC provider (for the data source lookup).
  statement {
    sid       = "IAMOIDCProviderRead"
    effect    = "Allow"
    actions   = ["iam:GetOpenIDConnectProvider"]
    resources = ["arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"]
  }

  # This project's IAM roles (runtime-exec + the three CI roles).
  statement {
    sid    = "IAMRoles"
    effect = "Allow"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy", "iam:TagRole", "iam:UntagRole", "iam:ListRoleTags",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy", "iam:ListRolePolicies",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.project}-*"]
  }

  # Pass the runtime execution role to the AgentCore service only.
  statement {
    sid       = "PassRuntimeRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.project}-runtime-exec"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["bedrock-agentcore.amazonaws.com"]
    }
  }

  # The ECR repository itself (create/manage — NOT image push; that's ci-deploy).
  statement {
    sid    = "ECRRepo"
    effect = "Allow"
    actions = [
      "ecr:CreateRepository", "ecr:DeleteRepository", "ecr:DescribeRepositories",
      "ecr:PutLifecyclePolicy", "ecr:GetLifecyclePolicy", "ecr:DeleteLifecyclePolicy",
      "ecr:PutImageScanningConfiguration", "ecr:PutImageTagMutability",
      "ecr:GetRepositoryPolicy",
      "ecr:TagResource", "ecr:UntagResource", "ecr:ListTagsForResource",
    ]
    resources = ["arn:aws:ecr:${var.aws_region}:${local.account_id}:repository/${var.project}"]
  }

  # The AgentCore Runtime. Scoped to this account+region. (The first real apply
  # in Phase 8 may surface a couple more bedrock-agentcore actions to add here —
  # same iterative tightening we did on Project 1.)
  statement {
    sid    = "AgentCoreRuntime"
    effect = "Allow"
    actions = [
      "bedrock-agentcore:CreateAgentRuntime", "bedrock-agentcore:UpdateAgentRuntime",
      "bedrock-agentcore:DeleteAgentRuntime", "bedrock-agentcore:GetAgentRuntime",
      "bedrock-agentcore:ListAgentRuntimes",
      "bedrock-agentcore:TagResource", "bedrock-agentcore:UntagResource",
      "bedrock-agentcore:ListTagsForResource",
    ]
    resources = ["arn:aws:bedrock-agentcore:${var.aws_region}:${local.account_id}:*"]
  }
}

# ---- Permissions: deploy role (push the image to ECR) ----------------------
data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "ECRAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # Can't be resource-scoped.
  }
  statement {
    sid    = "ECRPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = ["arn:aws:ecr:${var.aws_region}:${local.account_id}:repository/${var.project}"]
  }
}

# ---- The roles --------------------------------------------------------------
resource "aws_iam_role" "ci_plan" {
  name               = "${var.project}-ci-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_trust.json
}

resource "aws_iam_role_policy_attachment" "ci_plan_readonly" {
  role       = aws_iam_role.ci_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role" "ci_apply" {
  name               = "${var.project}-ci-apply"
  assume_role_policy = data.aws_iam_policy_document.apply_trust.json
}

resource "aws_iam_role_policy" "ci_apply" {
  name   = "${var.project}-ci-apply"
  role   = aws_iam_role.ci_apply.id
  policy = data.aws_iam_policy_document.apply.json
}

resource "aws_iam_role" "ci_deploy" {
  name               = "${var.project}-ci-deploy"
  assume_role_policy = data.aws_iam_policy_document.deploy_trust.json
}

resource "aws_iam_role_policy" "ci_deploy" {
  name   = "${var.project}-ci-deploy"
  role   = aws_iam_role.ci_deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}
