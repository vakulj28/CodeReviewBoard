# --- The execution role the AgentCore Runtime assumes to run our agent --------
#
# Trust: only the AgentCore service may assume it, and only on behalf of THIS
# account + AgentCore resources in THIS region (the aws:SourceAccount / SourceArn
# conditions are the "confused deputy" guard).

data "aws_iam_policy_document" "runtime_trust" {
  statement {
    sid     = "AssumeRolePolicy"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock-agentcore:${var.aws_region}:${local.account_id}:*"]
    }
  }
}

# Permissions: adapted from AWS's reference AgentCore execution policy, but
# scoped to our one ECR repo and to Nova Lite only (not all of Bedrock).
data "aws_iam_policy_document" "runtime_permissions" {
  # Pull our image from ECR.
  statement {
    sid       = "ECRImageAccess"
    effect    = "Allow"
    actions   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    resources = [aws_ecr_repository.board.arn]
  }

  statement {
    sid       = "ECRTokenAccess"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # GetAuthorizationToken can't be resource-scoped.
  }

  # CloudWatch Logs for the runtime (log-group name carries a generated id,
  # hence the wildcards under the AgentCore-owned prefix).
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:DescribeLogStreams"]
    resources = ["arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:PutResourcePolicy"]
    resources = ["arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/bedrock-agentcore/runtimes/${local.runtime_name}-*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:*"] # Describe can't be scoped tighter.
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*:log-stream:*"]
  }

  # X-Ray traces (the agent's call chain). Not resource-scopable.
  statement {
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
    ]
    resources = ["*"]
  }

  # Custom metrics, restricted to the AgentCore namespace only.
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["bedrock-agentcore"]
    }
  }

  # Workload-identity token the runtime needs for itself. We omit
  # GetWorkloadAccessTokenForUserId (AWS's hardening advice) since we don't
  # issue per-user tokens.
  statement {
    sid    = "GetAgentAccessToken"
    effect = "Allow"
    actions = [
      "bedrock-agentcore:GetWorkloadAccessToken",
      "bedrock-agentcore:GetWorkloadAccessTokenForJWT",
    ]
    resources = [
      "arn:aws:bedrock-agentcore:${var.aws_region}:${local.account_id}:workload-identity-directory/default",
      "arn:aws:bedrock-agentcore:${var.aws_region}:${local.account_id}:workload-identity-directory/default/workload-identity/${local.runtime_name}-*",
    ]
  }

  # Invoke Nova Lite ONLY: the foundation model (any region, for cross-region
  # inference) plus the eu inference profile in our account.
  statement {
    sid    = "BedrockModelInvocation"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    resources = [
      "arn:aws:bedrock:*::foundation-model/amazon.nova-lite-v1:0",
      "arn:aws:bedrock:${var.aws_region}:${local.account_id}:inference-profile/${var.model_id}",
    ]
  }
}

resource "aws_iam_role" "runtime" {
  name               = "${var.project}-runtime-exec"
  assume_role_policy = data.aws_iam_policy_document.runtime_trust.json
}

resource "aws_iam_role_policy" "runtime" {
  name   = "${var.project}-runtime-exec"
  role   = aws_iam_role.runtime.id
  policy = data.aws_iam_policy_document.runtime_permissions.json
}
