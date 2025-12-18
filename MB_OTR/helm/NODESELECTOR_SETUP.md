# Node Selector Configuration for Infrastructure Components

## Overview

This document describes the node selector configuration that has been applied to the Kafka and PostgreSQL infrastructure components in the MB OTR Helm chart.

## Changes Made

### PostgreSQL Configuration
Added `nodeSelector` configuration to the PostgreSQL primary instance:

```yaml
postgresql:
  primary:
    nodeSelector:
      role: mbotr
```

This ensures that the PostgreSQL primary database pod will be scheduled only on nodes labeled with `role=mbotr`.

### Kafka Configuration
Added `nodeSelector` configuration to all Kafka components:

```yaml
kafka:
  broker:
    nodeSelector:
      role: mbotr
  controller:
    nodeSelector:
      role: mbotr
  zookeeper:
    nodeSelector:
      role: mbotr
```

This ensures that:
- Kafka broker pods are scheduled on nodes with `role=mbotr`
- Kafka controller pods are scheduled on nodes with `role=mbotr`
- Zookeeper pods are scheduled on nodes with `role=mbotr`

## Consistency with Application Services

All application services already had the `nodeSelector: role: mbotr` configuration:
- dealservice
- mockservice
- purchaserequestservice
- contractservice
- orderplacementservice
- frontend

Now the infrastructure components (PostgreSQL and Kafka) are also configured to use the same node selector, ensuring all components of the MB OTR application are scheduled on the designated nodes.

## Node Requirements

To deploy this application, ensure your Kubernetes cluster has nodes labeled with:
```bash
kubectl label nodes <node-name> role=mbotr
```

## Verification

After deployment, you can verify that pods are scheduled on the correct nodes:

```bash
# Check all MB OTR pods and their node assignments
kubectl get pods -o wide -l "app.kubernetes.io/instance=mb-otr"

# Check node labels
kubectl get nodes --show-labels | grep role=mbotr
```

## Files Modified

- `MB_OTR/helm/mb-otr/values.yaml`: Added nodeSelector configurations for PostgreSQL and Kafka

## Dependencies

This configuration uses the Bitnami Helm charts for:
- PostgreSQL (version 12.12.10)
- Kafka (version 25.3.5)

The nodeSelector configurations follow the standard Bitnami chart structure for these components.
