# Account we're deploying into. Used to build least-privilege ARNs
# (Bedrock model, ECR repo, log groups) below.
data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}