variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "mb-otr"
}

variable "service_name" {
  description = "Service name"
  type        = string
  default     = "contract-service"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Memory for the task"
  type        = number
  default     = 1024
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# Database variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "contract_service_db"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

# S3 variables
variable "s3_bucket_name" {
  description = "S3 bucket name for contract storage (leave empty for auto-generated)"
  type        = string
  default     = ""
}

# Kafka variables
variable "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers"
  type        = string
  default     = ""
}

variable "kafka_topics" {
  description = "Kafka topics used by the application"
  type        = list(string)
  default     = [
    "contract-events"
  ]
}
