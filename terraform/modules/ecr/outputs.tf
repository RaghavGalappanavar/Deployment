# ECR Module Outputs

output "repository_urls" {
  description = "URLs of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.repository_url }
}

output "repository_arns" {
  description = "ARNs of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.arn }
}

output "registry_id" {
  description = "Registry ID where the repositories were created"
  value       = values(aws_ecr_repository.repositories)[0].registry_id
}
