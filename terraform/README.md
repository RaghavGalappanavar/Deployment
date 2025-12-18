# Microservices Infrastructure on AWS EKS

This Terraform configuration sets up a minimal AWS infrastructure for deploying microservices on Amazon EKS.

## Architecture

- **VPC**: Custom VPC with DNS support
- **Subnets**: 1 public subnet and 1 private subnet
- **EKS Cluster**: Managed Kubernetes cluster
- **Node Group**: EC2 instances for running workloads
- **ECR**: Container registries for microservices
- **NAT Gateway**: For private subnet internet access

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. kubectl installed (for cluster management)

## Quick Start

1. **Clone and navigate to terraform directory**:
   ```bash
   cd terraform
   ```

2. **Copy and customize variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your desired values
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

6. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --region us-west-2 --name microservices-cluster
   ```

7. **Build and push microservices**:
   ```bash
   ./scripts/build-and-push.sh
   ```

8. **Deploy microservices**:
   ```bash
   kubectl apply -f k8s-manifests/
   ```

## Microservices

The configuration creates ECR repositories for:
- contract-service
- deal-service  
- order-placement-service
- mock-service
- purchase-request-service

## Customization

- Modify `variables.tf` for different defaults
- Update `terraform.tfvars` for environment-specific values
- Adjust node group configuration for different instance types/sizes

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Service Access

Once deployed, your microservices will be accessible via Kubernetes services:

- **Contract Service**: `http://<ALB_DNS>/api/contract`
- **Deal Service**: `http://<ALB_DNS>/deal`
- **Order Placement Service**: `http://<ALB_DNS>/order-placement`
- **Mock Service**: `http://<ALB_DNS>/mock`
- **Purchase Request Service**: `http://<ALB_DNS>/purchase`

Get the ALB DNS name with: `terraform output load_balancer_dns`

## Estimated Costs

With default configuration (t3.medium instances):
- EKS Cluster: ~$73/month
- EC2 Instances: ~$60/month (2 x t3.medium)
- NAT Gateway: ~$45/month
- Application Load Balancer: ~$22/month
- Other resources: ~$10/month

**Total: ~$210/month**
