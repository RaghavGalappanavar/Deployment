# RDS PostgreSQL for Contract Service

# DB Subnet Group
resource "aws_db_subnet_group" "contract_service" {
  name       = "${var.project_name}-${var.environment}-contract-db"
  subnet_ids = split(",", data.aws_ssm_parameter.private_subnet_ids.value)

  tags = {
    Name        = "${var.project_name}-${var.environment}-contract-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "contract_service" {
  identifier = "${var.project_name}-${var.environment}-contract-db"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.environment == "prod" ? "db.t3.small" : "db.t3.micro"

  db_name  = "contract_service_db"
  username = "postgres"
  password = random_password.contract_db_password.result

  allocated_storage = 20
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.contract_service.name
  vpc_security_group_ids = [data.aws_ssm_parameter.database_security_group_id.value]
  publicly_accessible    = false

  backup_retention_period = var.environment == "prod" ? 7 : 1
  skip_final_snapshot     = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-contract-db"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Database password
resource "random_password" "contract_db_password" {
  length  = 16
  special = true
}

# Store database credentials in SSM
resource "aws_ssm_parameter" "contract_db_endpoint" {
  name  = "/${var.project_name}/${var.environment}/contract-service/db_endpoint"
  type  = "String"
  value = aws_db_instance.contract_service.endpoint

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ssm_parameter" "contract_db_password" {
  name  = "/${var.project_name}/${var.environment}/contract-service/db_password"
  type  = "SecureString"
  value = random_password.contract_db_password.result

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
