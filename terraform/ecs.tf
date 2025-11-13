# Security group for Contract Service
resource "aws_security_group" "contract_service" {
  name_prefix = "${var.project_name}-${var.environment}-${local.service_name}-"
  vpc_id      = local.vpc_id

  # Allow inbound traffic from shared ECS security group
  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [local.ecs_security_group_id]
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

# Task definition for the contract service
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}-${local.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = local.ecs_task_execution_role_arn
  task_role_arn            = aws_iam_role.app_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-${var.environment}-${local.service_name}"
      image     = "${local.ecr_repository_url}:${var.ecr_image_tag}"
      essential = true
      
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = var.environment
        },
        {
          name  = "SERVER_PORT"
          value = tostring(var.app_port)
        },
        {
          name  = "DATABASE_URL"
          value = "jdbc:postgresql://${aws_db_instance.main.endpoint}/${var.db_name}"
        },
        {
          name  = "DATABASE_USERNAME"
          value = var.db_username
        },
        {
          name  = "S3_BUCKET_NAME"
          value = aws_s3_bucket.contracts.bucket
        },
        {
          name  = "S3_REGION"
          value = var.aws_region
        },
        {
          name  = "STORAGE_TYPE"
          value = "s3"
        },
        {
          name  = "KAFKA_BOOTSTRAP_SERVERS"
          value = local.kafka_bootstrap_servers
        },
        {
          name  = "KAFKA_CONTRACT_TOPIC"
          value = var.kafka_topics[0]
        }
      ]

      secrets = [
        {
          name      = "DATABASE_PASSWORD"
          valueFrom = aws_ssm_parameter.db_password.arn
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.project_name
        }
      }
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.app_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-${local.service_name}"
    Environment = var.environment
  }
}

# Service-specific task role with additional permissions
resource "aws_iam_role" "app_task_role" {
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

  tags = {
    Name        = "${var.project_name}-${var.environment}-${local.service_name}-task-role"
    Environment = var.environment
  }
}

# Service-specific policy for the task role
resource "aws_iam_policy" "app_task_policy" {
  name        = "${var.project_name}-${var.environment}-${local.service_name}-task-policy"
  description = "Policy for ${var.project_name} ${local.service_name} ECS task"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.app_logs.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.contracts.arn,
          "${aws_s3_bucket.contracts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          aws_ssm_parameter.db_password.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_task_policy" {
  role       = aws_iam_role.app_task_role.name
  policy_arn = aws_iam_policy.app_task_policy.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.project_name}-${var.environment}-${local.service_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-${local.service_name}"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "app" {
  name                               = "${var.project_name}-${var.environment}-${local.service_name}-service"
  cluster                            = local.ecs_cluster_arn
  task_definition                    = aws_ecs_task_definition.app.arn
  desired_count                      = var.app_count
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  health_check_grace_period_seconds  = 60
  
  network_configuration {
    security_groups  = [local.ecs_security_group_id, aws_security_group.contract_service.id]
    subnets          = local.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.project_name}-${var.environment}-${local.service_name}"
    container_port   = var.app_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [
    aws_db_instance.main
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}-${local.service_name}-service"
    Environment = var.environment
  }
}

# Target group for the ALB
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-${var.environment}-${local.service_name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    port                = "traffic-port"
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${local.service_name}-tg"
    Environment = var.environment
  }
}

# Listener rule for the shared ALB
resource "aws_lb_listener_rule" "app" {
  listener_arn = local.http_listener_arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = ["/api/contract/*"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-${local.service_name}-rule"
  })
}

# IAM policy to allow shared task execution role to access our SSM parameters
resource "aws_iam_policy" "task_execution_ssm_policy" {
  name        = "${var.project_name}-${var.environment}-${local.service_name}-execution-ssm-policy"
  description = "Policy to allow task execution role to access contract service SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = [
          aws_ssm_parameter.db_password.arn
        ]
      }
    ]
  })

  tags = local.common_tags
}

# Attach the policy to the shared task execution role
resource "aws_iam_role_policy_attachment" "task_execution_ssm_policy" {
  role       = split("/", local.ecs_task_execution_role_arn)[1]
  policy_arn = aws_iam_policy.task_execution_ssm_policy.arn
}
