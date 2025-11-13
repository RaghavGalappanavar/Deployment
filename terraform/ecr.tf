# ECR Repository for Contract Service
resource "aws_ecr_repository" "contract_service" {
  name                 = "${var.project_name}-${var.environment}-${var.service_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-${var.service_name}"
  })
}

# ECR Lifecycle Policy to manage image retention
resource "aws_ecr_lifecycle_policy" "contract_service" {
  repository = aws_ecr_repository.contract_service.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod", "release", "v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 development images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev", "staging", "latest", "main"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Store ECR repository URL in SSM Parameter Store for reference
resource "aws_ssm_parameter" "ecr_repository_url" {
  name  = "/${var.project_name}/${var.environment}/${var.service_name}/ecr_repository_url"
  type  = "String"
  value = aws_ecr_repository.contract_service.repository_url

  tags = local.common_tags
}

# Create an IAM user for CI/CD to push images to ECR
resource "aws_iam_user" "ecr_user" {
  name = "${var.project_name}-${var.environment}-${var.service_name}-ecr-user"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-${var.service_name}-ecr-user"
  })
}

# IAM Policy for ECR access
resource "aws_iam_policy" "ecr_policy" {
  name        = "${var.project_name}-${var.environment}-${var.service_name}-ecr-policy"
  description = "Policy for pushing images to ${var.service_name} ECR repository"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken"
        ]
        Resource = [
          aws_ecr_repository.contract_service.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach ECR policy to the IAM user
resource "aws_iam_user_policy_attachment" "ecr_user_policy" {
  user       = aws_iam_user.ecr_user.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

# Create access key for the IAM user
# Note: In a real-world scenario, you might want to create this outside of Terraform
# or use AWS Secrets Manager to store the credentials
resource "aws_iam_access_key" "ecr_user_key" {
  user = aws_iam_user.ecr_user.name
}

# Store ECR credentials in SSM Parameter Store (encrypted)
resource "aws_ssm_parameter" "ecr_access_key_id" {
  name  = "/${var.project_name}/${var.environment}/${var.service_name}/ecr_access_key_id"
  type  = "SecureString"
  value = aws_iam_access_key.ecr_user_key.id

  tags = local.common_tags
}

resource "aws_ssm_parameter" "ecr_secret_access_key" {
  name  = "/${var.project_name}/${var.environment}/${var.service_name}/ecr_secret_access_key"
  type  = "SecureString"
  value = aws_iam_access_key.ecr_user_key.secret

  tags = local.common_tags
}
