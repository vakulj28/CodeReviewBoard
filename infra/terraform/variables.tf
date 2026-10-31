variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "project" {
  type    = string
  default = "code-review-board"
}

variable "state_bucket_name" {
  description = "Existing S3 bucket that holds Terraform state (reused from Project 1)"
  type        = string
}

variable "github_repo" {
  description = "owner/name of the GitHub repo CI runs from"
  type        = string
  default     = "vakulj28/CodeReviewBoard"
}

variable "github_actor" {
  description = "GitHub user allowed to assume the CI roles"
  type        = string
  default     = "vakulj28"
}

variable "github_environment" {
  description = "GitHub Environment the apply/deploy roles will trust (created later)"
  type        = string
  default     = "code-review-board-prod"
}

variable "model_id" {
  description = "Bedrock inference profile the agent invokes"
  type        = string
  default     = "eu.amazon.nova-lite-v1:0"
}
