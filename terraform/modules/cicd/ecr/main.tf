variable "repo_name" {
  description = "Repository name"
}

locals {
  repo_policy_json = <<EOF
  {
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keeponlyoneuntaggedimage,expireallothers",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
    }
  EOF
}

resource "aws_ecr_repository" "my_repo" {
  name = var.repo_name
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "repo_lifecycle_policy" {
  repository = aws_ecr_repository.my_repo.name
  policy     = local.repo_policy_json
}

output "repo-arn" {
  value = aws_ecr_repository.my_repo.arn
}