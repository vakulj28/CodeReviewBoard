# Role ARNs feed the GitHub repo secrets; the ECR URL + runtime ARN are used by
# the deploy workflow and the Phase 8 invoke step.
output "ci_plan_role_arn" {
  value = aws_iam_role.ci_plan.arn
}

output "ci_apply_role_arn" {
  value = aws_iam_role.ci_apply.arn
}

output "ci_deploy_role_arn" {
  value = aws_iam_role.ci_deploy.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.board.repository_url
}

output "runtime_arn" {
  # null when deploy_runtime = false (the runtime isn't created).
  value = one(aws_bedrockagentcore_agent_runtime.board[*].agent_runtime_arn)
}
