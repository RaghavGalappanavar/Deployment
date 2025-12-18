# MB OTR Deployment Guide

## Quick Start

### 1. Prerequisites
- Kubernetes cluster (v1.20+)
- Helm 3.8+
- kubectl configured
- Docker images built and pushed to registry

### 2. Deploy Development Environment
```bash
cd MB_OTR/helm
./deploy.sh dev install
```

### 3. Deploy Production Environment
```bash
cd MB_OTR/helm
./deploy.sh prod install -n mb-otr-prod
```

## Services Overview

| Service | Port | Health Check | Description |
|---------|------|--------------|-------------|
| DealService | 8080 | `/deal/actuator/health` | Deal management |
| MockService | 8084 | `/actuator/health` | Mock data service |
| PurchaseRequestService | 8082 | `/api/purchase-request/actuator/health` | Purchase requests |
| ContractService | 8085 | `/api/contract/actuator/health` | Contract management |
| OrderPlacementService | 8086 | `/api/order/actuator/health` | Order processing |
| Frontend | 80 | `/health` | React UI |

## Infrastructure Components

- **PostgreSQL**: Primary database for all services
- **Apache Kafka**: Message broker for service communication
- **Kafka UI**: Web interface for Kafka management (dev only)
- **PgAdmin**: PostgreSQL administration tool (dev only)

## Environment Configurations

### Development (values-dev.yaml)
- Single replica per service
- Reduced resource limits
- Debug features enabled
- Monitoring tools included
- Local ingress configuration

### Production (values-prod.yaml)
- Multiple replicas with auto-scaling
- High resource limits
- Security hardened
- TLS enabled
- External monitoring integration

## Common Operations

### Check Deployment Status
```bash
./deploy.sh dev status
```

### View Logs
```bash
./deploy.sh dev logs
```

### Upgrade Deployment
```bash
./deploy.sh dev upgrade
```

### Scale Services
```bash
# Manual scaling
kubectl scale deployment mb-otr-dealservice --replicas=3

# Using Helm values
helm upgrade mb-otr ./mb-otr --set dealservice.replicaCount=3
```

### Access Services Locally
```bash
# Frontend
kubectl port-forward svc/mb-otr-frontend 8080:80

# Deal Service API
kubectl port-forward svc/mb-otr-dealservice 8081:8080

# Kafka UI (dev only)
kubectl port-forward svc/mb-otr-kafka-ui 8082:8080

# PgAdmin (dev only)
kubectl port-forward svc/mb-otr-pgadmin 8083:80
```

## Troubleshooting

### Common Issues

1. **ImagePullBackOff**
   - Ensure Docker images are built and pushed
   - Check image registry credentials
   - Verify image tags in values files

2. **CrashLoopBackOff**
   - Check application logs: `kubectl logs <pod-name>`
   - Verify health check endpoints
   - Check database connectivity

3. **Service Connection Issues**
   - Verify service discovery configuration
   - Check network policies
   - Ensure proper service naming

### Debug Commands
```bash
# Get pod details
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Execute into pod
kubectl exec -it <pod-name> -- /bin/bash

# Check service endpoints
kubectl get endpoints
```

## Security Notes

- All containers run as non-root user (UID 1001)
- Security contexts configured with minimal privileges
- Secrets used for sensitive data
- Network policies can be enabled for isolation

## Backup and Recovery

### Database Backup
```bash
kubectl exec -it mb-otr-postgresql-0 -- pg_dump -U postgres dealservice > backup.sql
```

### Configuration Backup
```bash
# Export current values
helm get values mb-otr > current-values.yaml
```

## Monitoring

### Health Checks
All services include comprehensive health checks with liveness and readiness probes.

### Metrics
Services expose metrics endpoints for Prometheus integration:
- Spring Boot services: `/actuator/metrics`
- Frontend: Custom metrics endpoint

### Logging
Centralized logging can be configured with:
- Fluentd/Fluent Bit for log collection
- Elasticsearch for log storage
- Kibana for log visualization

## Support

For issues and questions:
1. Check this deployment guide
2. Review service logs
3. Check Kubernetes events
4. Contact the development team

## Next Steps

After successful deployment:
1. Configure monitoring and alerting
2. Set up CI/CD pipelines
3. Configure backup strategies
4. Implement security scanning
5. Set up log aggregation
