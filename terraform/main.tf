terraform {
  required_version = ">= 1.2.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Data sources to retrieve shared infrastructure values from SSM (from core infrastructure)
data "aws_ssm_parameter" "vpc_id" {
  name = "/core/${var.environment}/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/core/${var.environment}/private_subnets"
}

data "aws_ssm_parameter" "ecs_cluster_name" {
  name = "/core/${var.environment}/ecs_cluster_name"
}

data "aws_ssm_parameter" "ecs_task_execution_role_arn" {
  name = "/core/${var.environment}/ecs_task_execution_role_arn"
}

data "aws_ssm_parameter" "ecs_security_group_id" {
  name = "/core/${var.environment}/ecs_security_group_id"
}

# Optional SSM parameters - these may not exist in all environments
data "aws_ssm_parameter" "kafka_bootstrap_servers" {
  count = var.kafka_bootstrap_servers == "" ? 1 : 0
  name  = "/core/${var.environment}/kafka_bootstrap_brokers"
}

data "aws_ssm_parameter" "http_listener_arn" {
  name = "/core/${var.environment}/http_listener_arn"
}

# ECR repository URL will be provided by ecr.tf

locals {
  service_name = var.service_name

  # Use shared Kafka from core infrastructure or variable
  kafka_bootstrap_servers = var.kafka_bootstrap_servers != "" ? var.kafka_bootstrap_servers : (
    length(data.aws_ssm_parameter.kafka_bootstrap_servers) > 0 ?
    data.aws_ssm_parameter.kafka_bootstrap_servers[0].value :
    "localhost:9092"
  )

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Service     = local.service_name
    ManagedBy   = "terraform"
  }

  # Use shared infrastructure from core infrastructure (mockerservice)
  ecs_task_execution_role_arn = data.aws_ssm_parameter.ecs_task_execution_role_arn.value
  ecs_cluster_arn = data.aws_ssm_parameter.ecs_cluster_name.value
  ecs_security_group_id = data.aws_ssm_parameter.ecs_security_group_id.value
  private_subnet_ids = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
  vpc_id = data.aws_ssm_parameter.vpc_id.value

  # Use existing ALB listener ARN from core infrastructure
  http_listener_arn = data.aws_ssm_parameter.http_listener_arn.value

  ecr_repository_url = aws_ecr_repository.contract_service.repository_url
}


