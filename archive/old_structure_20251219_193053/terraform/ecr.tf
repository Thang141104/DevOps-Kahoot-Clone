# ================================
# AWS ECR Repositories for Images
# ================================

locals {
  ecr_repositories = [
    "gateway",
    "auth",
    "user",
    "quiz",
    "game",
    "analytics",
    "frontend"
  ]
}

# Create ECR repositories for each service
resource "aws_ecr_repository" "kahoot_services" {
  for_each = toset(local.ecr_repositories)
  
  name                 = "${var.project_name}-${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true  # Auto scan for vulnerabilities
  }

  encryption_configuration {
    encryption_type = "AES256"  # Free tier encryption
  }

  tags = {
    Name        = "${var.project_name}-${each.key}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Lifecycle policy to keep only last 10 images (save storage costs)
resource "aws_ecr_lifecycle_policy" "kahoot_lifecycle" {
  for_each   = aws_ecr_repository.kahoot_services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policy - Allow pull from EC2 instances
resource "aws_ecr_repository_policy" "kahoot_pull_policy" {
  for_each   = aws_ecr_repository.kahoot_services
  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPullFromEC2"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-jenkins-role",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-k8s-node-role"
          ]
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# ================================
# Outputs
# ================================

output "ecr_repositories" {
  description = "ECR repository URLs"
  value = {
    for k, v in aws_ecr_repository.kahoot_services : k => v.repository_url
  }
}

output "ecr_registry_url" {
  description = "ECR registry URL"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  sensitive   = true
}
