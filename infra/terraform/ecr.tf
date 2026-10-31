# The registry that holds the agent's container image. CI (Phase 7) builds the
# ARM64 image and pushes it here; the Runtime pulls it from here.
resource "aws_ecr_repository" "board" {
  name = var.project

  # We push :latest repeatedly, so tags must be overwritable.
  image_tag_mutability = "MUTABLE"

  # Scan each pushed image for known CVEs.
  image_scanning_configuration {
    scan_on_push = true
  }

  # Let `terraform destroy` remove the repo even if it still holds images,
  # which is what makes "up/down on demand" a clean one-command teardown.
  force_delete = true
}

# Keep storage (and cost) tiny: retain only the few most recent images.
resource "aws_ecr_lifecycle_policy" "board" {
  repository = aws_ecr_repository.board.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the last 3 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 3
      }
      action = { type = "expire" }
    }]
  })
}
