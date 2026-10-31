
locals {
  account_id = data.aws_caller_identity.current.account_id

  # AgentCore runtime names allow only letters, digits and underscores
  # (no hyphens), so the runtime itself can't reuse the "code-review-board" prefix.
  runtime_name = "code_review_board"
}