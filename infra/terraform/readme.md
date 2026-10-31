<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.18 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.71.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_bedrockagentcore_agent_runtime.board](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagentcore_agent_runtime) | resource |
| [aws_ecr_lifecycle_policy.board](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.board](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_iam_role.ci_apply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ci_deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ci_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ci_apply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ci_deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.runtime](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ci_plan_readonly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy_document.apply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.apply_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.deploy_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.plan_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.runtime_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.runtime_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | `"eu-west-1"` | no |
| <a name="input_deploy_runtime"></a> [deploy\_runtime](#input\_deploy\_runtime) | Create the AgentCore Runtime? false = ECR + roles only (bootstrap / runtime down); true = full stack (runtime up). | `bool` | `true` | no |
| <a name="input_github_actor"></a> [github\_actor](#input\_github\_actor) | GitHub user allowed to assume the CI roles | `string` | `"vakulj28"` | no |
| <a name="input_github_environment"></a> [github\_environment](#input\_github\_environment) | GitHub Environment the apply/deploy roles will trust (created later) | `string` | `"code-review-board-prod"` | no |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | owner/name of the GitHub repo CI runs from | `string` | `"vakulj28/CodeReviewBoard"` | no |
| <a name="input_model_id"></a> [model\_id](#input\_model\_id) | Bedrock inference profile the agent invokes | `string` | `"eu.amazon.nova-lite-v1:0"` | no |
| <a name="input_project"></a> [project](#input\_project) | n/a | `string` | `"code-review-board"` | no |
| <a name="input_state_bucket_name"></a> [state\_bucket\_name](#input\_state\_bucket\_name) | Existing S3 bucket that holds Terraform state (reused from Project 1) | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ci_apply_role_arn"></a> [ci\_apply\_role\_arn](#output\_ci\_apply\_role\_arn) | n/a |
| <a name="output_ci_deploy_role_arn"></a> [ci\_deploy\_role\_arn](#output\_ci\_deploy\_role\_arn) | n/a |
| <a name="output_ci_plan_role_arn"></a> [ci\_plan\_role\_arn](#output\_ci\_plan\_role\_arn) | Role ARNs feed the GitHub repo secrets; the ECR URL + runtime ARN are used by the deploy workflow and the Phase 8 invoke step. |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | n/a |
| <a name="output_runtime_arn"></a> [runtime\_arn](#output\_runtime\_arn) | n/a |
<!-- END_TF_DOCS -->