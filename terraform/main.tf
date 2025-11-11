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

# Data sources to retrieve shared infrastructure values from SSM
data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project_name}/${var.environment}/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/${var.project_name}/${var.environment}/private_subnet_ids"
}

data "aws_ssm_parameter" "ecs_cluster_name" {
  name = "/${var.project_name}/${var.environment}/ecs_cluster_name"
}

data "aws_ssm_parameter" "ecs_task_execution_role_arn" {
  name = "/${var.project_name}/${var.environment}/ecs_task_execution_role_arn"
}

data "aws_ssm_parameter" "ecs_task_role_arn" {
  name = "/${var.project_name}/${var.environment}/ecs_task_role_arn"
}

data "aws_ssm_parameter" "ecs_security_group_id" {
  name = "/${var.project_name}/${var.environment}/ecs_security_group_id"
}

data "aws_ssm_parameter" "database_security_group_id" {
  name = "/${var.project_name}/${var.environment}/database_security_group_id"
}

data "aws_ssm_parameter" "target_group_arn" {
  name = "/${var.project_name}/${var.environment}/${var.service_name}/target_group_arn"
}

data "aws_ssm_parameter" "ecr_repository_url" {
  name = "/${var.project_name}/${var.environment}/${var.service_name}/ecr_repository_url"
}

data "aws_ssm_parameter" "kafka_bootstrap_servers" {
  name = "/${var.project_name}/${var.environment}/msk_bootstrap_brokers"
}

locals {
  service_name = var.service_name
  
  # Use shared Kafka from core infrastructure
  kafka_bootstrap_servers = var.kafka_bootstrap_servers != "" ? var.kafka_bootstrap_servers : data.aws_ssm_parameter.kafka_bootstrap_servers.value
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Service     = local.service_name
    ManagedBy   = "terraform"
  }
}
