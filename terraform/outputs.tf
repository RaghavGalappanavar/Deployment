output "service_name" {
  description = "Name of the ContractService"
  value       = local.service_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.app.id
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "s3_bucket_name" {
  description = "S3 bucket name for contract storage"
  value       = aws_s3_bucket.contracts.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.contracts.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.contract_service.repository_url
  sensitive   = true
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app.arn
}

output "service_security_group_id" {
  description = "Security group ID for the contract service"
  value       = aws_security_group.contract_service.id
}

# ALB outputs removed - using shared ALB from core infrastructure

output "database_security_group_id" {
  description = "Security group ID for the database"
  value       = aws_security_group.database.id
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.app_task_role.arn
}

# Additional outputs for CI/CD and monitoring
output "listener_rule_arn" {
  description = "ARN of the ALB listener rule"
  value       = aws_lb_listener_rule.app.arn
}

output "db_password_ssm_parameter" {
  description = "SSM parameter name for database password"
  value       = aws_ssm_parameter.db_password.name
  sensitive   = true
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.contract_service.name
}

output "ecr_user_access_key_id" {
  description = "Access Key ID for ECR user"
  value       = aws_iam_access_key.ecr_user_key.id
  sensitive   = true
}

output "ecr_user_secret_access_key" {
  description = "Secret Access Key for ECR user"
  value       = aws_iam_access_key.ecr_user_key.secret
  sensitive   = true
}

output "service_endpoint" {
  description = "Service endpoint path"
  value       = "/api/contract"
}

output "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers being used"
  value       = local.kafka_bootstrap_servers
  sensitive   = true
}

# Deployment commands
output "ecr_push_commands" {
  description = "Commands to build and push the Docker image to ECR"
  value       = <<EOF
# Login to ECR
aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.contract_service.repository_url}

# Build the Docker image
docker build -t ${aws_ecr_repository.contract_service.repository_url}:${var.ecr_image_tag} .

# Push the Docker image to ECR
docker push ${aws_ecr_repository.contract_service.repository_url}:${var.ecr_image_tag}
EOF
  sensitive   = true
}

output "update_service_command" {
  description = "Command to update the ECS service"
  value       = "aws ecs update-service --cluster ${local.ecs_cluster_arn} --service ${aws_ecs_service.app.name} --force-new-deployment --region ${var.aws_region}"
  sensitive   = true
}
