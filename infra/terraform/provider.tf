provider "aws" {
  region = var.aws_region

  # Credentials come from the environment: AWS_PROFILE locally (e.g. chatbot),
  # or the OIDC-assumed role in GitHub Actions.
  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      CreatedBy = "Vakul.Jain"
    }
  }
}
