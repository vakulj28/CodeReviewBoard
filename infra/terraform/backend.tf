terraform {
  backend "s3" {
    bucket       = "bedrock-chatbot-tfstate"
    key          = "code-review-board/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
