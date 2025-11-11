resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.environment}-${local.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = data.aws_ssm_parameter.ecs_task_execution_role_arn.value
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = local.service_name
      image = "${data.aws_ssm_parameter.ecr_repository_url.value}:${var.image_tag}"
      
      portMappings = [
        {
          containerPort = 8085
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
          value = "8085"
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
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.environment}-${local.service_name}"
  cluster         = data.aws_ssm_parameter.ecs_cluster_name.value
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [data.aws_ssm_parameter.ecs_security_group_id.value, aws_security_group.contract_service.id]
    subnets         = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
  }

  load_balancer {
    target_group_arn = data.aws_ssm_parameter.target_group_arn.value
    container_name   = local.service_name
    container_port   = 8085
  }

  depends_on = [aws_ecs_task_definition.main, aws_db_instance.main]

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.project_name}-${var.environment}-${local.service_name}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}
