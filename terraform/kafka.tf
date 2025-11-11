# Service-specific SSM parameters for Kafka
resource "aws_ssm_parameter" "service_kafka_bootstrap_servers" {
  name  = "/${var.project_name}/${var.environment}/${var.service_name}/kafka_bootstrap_servers"
  type  = "SecureString"
  value = local.kafka_bootstrap_servers

  tags = local.common_tags
}
