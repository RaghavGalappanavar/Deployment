# MB OTR Helm Charts

This directory contains **simplified** Helm charts for deploying the MB OTR (On-The-Road) microservices application to Kubernetes.

## Architecture Overview

The MB OTR application consists of 6 microservices:

1. **DealService** (Port 8080) - Deal management and processing
2. **MockService** (Port 8084) - Mock data and external service simulation
3. **PurchaseRequestService** (Port 8082) - Purchase request processing
4. **ContractService** (Port 8085) - Contract generation and management
5. **OrderPlacementService** (Port 8086) - Order processing and placement
6. **Frontend** (Port 80) - React-based user interface

## Chart Structure

```
helm/
├── mb-otr/                    # Main umbrella chart
│   ├── Chart.yaml
│   ├── values.yaml            # Simple default values
│   ├── templates/             # Main chart templates (minimal)
│   └── charts/                # Subcharts (simplified)
│       ├── dealservice/       # Only deployment.yaml + service.yaml
│       ├── mockservice/       # Only deployment.yaml + service.yaml
│       ├── purchaserequestservice/
│       ├── contractservice/
│       ├── orderplacementservice/
│       └── frontend/
└── README.md                  # This file
```

## Prerequisites

- Kubernetes cluster (v1.20+)
- Helm 3.8+
- kubectl configured to access your cluster
- Container registry access for Docker images

### Required Dependencies

The chart automatically installs these dependencies:
- PostgreSQL (Bitnami chart)
- Apache Kafka with Zookeeper (Bitnami chart)

## Quick Start

### 1. Add Required Helm Repositories

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Simple Installation

```bash
# Install with default values
helm install mb-otr ./mb-otr

# Or with custom namespace
kubectl create namespace mb-otr
helm install mb-otr ./mb-otr -n mb-otr
```

## Configuration

### Simple Configuration

The charts use minimal configuration with sensible defaults:

#### Service Configuration
```yaml
dealservice:
  enabled: true
  # Uses default values from subchart
```

#### Infrastructure Configuration
```yaml
postgresql:
  enabled: true
  auth:
    postgresPassword: "password"
    database: "dealservice"

kafka:
  enabled: true
```

### Customizing Values

Each service subchart has its own simple `values.yaml` with basic configuration:
- Image repository and tag
- Service port configuration
- Basic environment variables (database URL, Kafka servers, etc.)

## Deployment Commands

### Install/Upgrade
```bash
# Install new deployment
helm install mb-otr ./mb-otr

# Upgrade existing deployment
helm upgrade mb-otr ./mb-otr

# Install/upgrade with custom values
helm upgrade --install mb-otr ./mb-otr --set dealservice.image.tag=v2.0.0
```

### Management Commands
```bash
# Check deployment status
helm status mb-otr

# List all releases
helm list

# Get deployment values
helm get values mb-otr

# Uninstall
helm uninstall mb-otr
```

## Monitoring and Troubleshooting

### Accessing Services

#### Development Environment
```bash
# Port forward to access services locally
kubectl port-forward svc/mb-otr-frontend 8080:80
kubectl port-forward svc/mb-otr-dealservice 8081:8080
kubectl port-forward svc/mb-otr-kafka-ui 8082:8080
kubectl port-forward svc/mb-otr-pgadmin 8083:80
```

#### Check Pod Status
```bash
# Get all pods
kubectl get pods

# Describe specific pod
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name> -f

# Execute into pod
kubectl exec -it <pod-name> -- /bin/bash
```

### Common Issues

1. **ImagePullBackOff**: Ensure Docker images are built and pushed to registry
2. **CrashLoopBackOff**: Check application logs and health check endpoints
3. **Service Connection Issues**: Verify service discovery and network policies

### Health Checks

All services include health check endpoints:
- DealService: `http://dealservice:8080/deal/actuator/health`
- PurchaseRequestService: `http://purchaserequestservice:8082/api/purchase-request/actuator/health`
- ContractService: `http://contractservice:8085/api/contract/actuator/health`
- OrderPlacementService: `http://orderplacementservice:8086/api/order/actuator/health`
- Frontend: `http://frontend:80/health`

## Security Considerations

- All containers run as non-root user (UID 1001)
- Security contexts configured with minimal privileges
- Secrets used for sensitive data (database passwords)
- Network policies can be enabled for service isolation

## Scaling

### Manual Scaling
```bash
# Scale specific service
kubectl scale deployment mb-otr-dealservice --replicas=3

# Scale using Helm values
helm upgrade mb-otr ./mb-otr --set dealservice.replicaCount=3
```

### Auto Scaling
HPA (Horizontal Pod Autoscaler) is configured for production:
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

## Backup and Recovery

### Database Backup
```bash
# PostgreSQL backup
kubectl exec -it mb-otr-postgresql-0 -- pg_dump -U postgres dealservice > backup.sql
```

### Persistent Volume Backup
Ensure your storage class supports snapshots for automated backups.

## Contributing

1. Test changes in development environment first
2. Update documentation for any configuration changes
3. Follow semantic versioning for chart versions
4. Test upgrade scenarios before releasing

## Support

For issues and questions:
- Check logs using kubectl commands above
- Review Kubernetes events: `kubectl get events --sort-by=.metadata.creationTimestamp`
- Contact the MB OTR development team
