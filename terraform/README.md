# Contract Service - Terraform Infrastructure

This Terraform configuration deploys a production-ready Contract Service on AWS using ECS Fargate with dedicated PostgreSQL database, S3 storage, and comprehensive monitoring.

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Application   │    │    Load Balancer │    │   ECS Fargate   │
│   Load Balancer │◄───┤    Target Group  │◄───┤   Service       │
│                 │    │                  │    │   (Port 8085)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                       ┌─────────────────┐              │
                       │   CloudWatch    │◄─────────────┘
                       │   Logs          │
                       └─────────────────┘
                                │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────▼──────┐    ┌──────────▼──────┐    ┌─────────▼────────┐
│  PostgreSQL  │    │   S3 Bucket     │    │   Kafka Topics   │
│  Database    │    │   (Contracts)   │    │   (Events)       │
│  (RDS)       │    │                 │    │                  │
└──────────────┘    └─────────────────┘    └──────────────────┘
```

## Infrastructure Components

### Compute & Networking
- **ECS Fargate Service**: Containerized application running on port 8085
- **Security Groups**: Network access control for service and database
- **VPC Integration**: Deployed in private subnets with shared infrastructure

### Data Storage
- **RDS PostgreSQL 15.4**: Dedicated database with encryption and automated backups
- **S3 Bucket**: Secure contract document storage with lifecycle policies
- **Parameter Store**: Secure storage for database credentials and configuration

### Monitoring & Logging
- **CloudWatch Logs**: Centralized application logging with 7-day retention
- **RDS Enhanced Monitoring**: Database performance metrics

### Security & Access
- **IAM Roles**: Least-privilege access for ECS tasks and RDS monitoring
- **Encryption**: At-rest encryption for database and S3 bucket
- **Private Networking**: Database accessible only from application security group

## Prerequisites

- **Terraform** >= 1.2.0
- **AWS CLI** configured with appropriate credentials
- **Shared Infrastructure**: VPC, ECS cluster, and load balancer must exist
- **ECR Repository**: Container image repository must be available

## Configuration

### Required SSM Parameters
The following parameters must exist in AWS Systems Manager Parameter Store:
```
/${project_name}/${environment}/vpc_id
/${project_name}/${environment}/private_subnet_ids
/${project_name}/${environment}/ecs_cluster_name
/${project_name}/${environment}/ecs_task_execution_role_arn
/${project_name}/${environment}/ecs_task_role_arn
/${project_name}/${environment}/ecs_security_group_id
/${project_name}/${environment}/database_security_group_id
/${project_name}/${environment}/${service_name}/target_group_arn
/${project_name}/${environment}/${service_name}/ecr_repository_url
```

### Key Variables
```hcl
# Core Configuration
aws_region    = "ap-south-1"
environment   = "dev"
project_name  = "mb-otr"
service_name  = "contract-service"

# Container Configuration
image_tag     = "latest"
cpu           = 512
memory        = 1024
desired_count = 1

# Database Configuration
db_instance_class     = "db.t3.micro"
db_allocated_storage  = 20
db_name              = "contract_service_db"
db_username          = "postgres"

# Kafka Configuration
kafka_bootstrap_servers = "your-kafka-servers"
kafka_topics           = ["contract-events"]
```

## Deployment

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Create Variables File
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Plan Deployment
```bash
terraform plan
```

### 4. Deploy Infrastructure
```bash
terraform apply
```

## Resources Created

### ECS Resources
- ECS Task Definition with container configuration
- ECS Service with load balancer integration
- CloudWatch Log Group for application logs

### Database Resources
- RDS PostgreSQL instance with encryption
- Database subnet group across AZs
- Database parameter group with logging
- Security group for database access

### Storage Resources
- S3 bucket with versioning and encryption
- Lifecycle policies (IA after 30 days, Glacier after 90 days)
- Public access blocking for security

### Security Resources
- ECS task IAM role with S3 access
- RDS monitoring IAM role
- Security groups for network isolation
- SSM parameter for database password

## Application Endpoints

- **Service API**: `/api/contracts`
- **Health Check**: `/actuator/health`
- **Port**: 8085

## Environment Variables

The application receives these environment variables:
- `SPRING_PROFILES_ACTIVE`: Environment profile
- `DATABASE_URL`: PostgreSQL connection string
- `DATABASE_USERNAME/PASSWORD`: Database credentials
- `S3_BUCKET_NAME`: Contract storage bucket
- `KAFKA_BOOTSTRAP_SERVERS`: Kafka connection
- `KAFKA_CONTRACT_TOPIC`: Event topic name

## Monitoring

- **Application Logs**: Available in CloudWatch Logs
- **Database Metrics**: Enhanced monitoring enabled
- **S3 Access**: CloudTrail integration available

## Security Features

- Database encryption at rest
- S3 bucket encryption (AES256)
- Private subnet deployment
- Security group isolation
- IAM least-privilege access
- Secrets stored in Parameter Store

## Cleanup

```bash
terraform destroy
```

**Note**: Database has deletion protection disabled for development. Enable for production use.
