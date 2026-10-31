# Account + region we're deploying into. Used to build least-privilege ARNs
# (Bedrock model, ECR repo, log groups) in later phases.
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Reuse the GitHub Actions OIDC provider that Project 1 already created at the
# account level, rather than creating a second one. Looked up by its issuer URL.
# Its ARN feeds the CI role trust policies we add in Phase 7.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
