# ECS Task Role for Contract Service
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-${local.service_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach S3 access policy to task role
resource "aws_iam_role_policy_attachment" "ecs_task_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# Attach SSM access policy for reading parameters
resource "aws_iam_role_policy_attachment" "ecs_task_ssm" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# Security group for Contract Service
resource "aws_security_group" "contract_service" {
  name_prefix = "${var.project_name}-${var.environment}-${local.service_name}-"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  # Allow inbound traffic from ALB
  ingress {
    from_port       = 8085
    to_port         = 8085
    protocol        = "tcp"
    security_groups = [data.aws_ssm_parameter.ecs_security_group_id.value]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-${local.service_name}-sg"
  })
}
