#!/bin/bash

# MB OTR Simple Deployment Script
# Usage: ./deploy.sh [action] [options]

set -e

# Default values
ACTION="install"
NAMESPACE=""
RELEASE_NAME="mb-otr"
CHART_PATH="./mb-otr"
DRY_RUN=false
WAIT=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print usage
usage() {
    echo "Usage: $0 [action] [options]"
    echo ""
    echo "Actions:"
    echo "  install  - Install new deployment (default)"
    echo "  upgrade  - Upgrade existing deployment"
    echo "  delete   - Delete deployment"
    echo "  status   - Show deployment status"
    echo "  logs     - Show logs for all services"
    echo ""
    echo "Options:"
    echo "  -n, --namespace NAME    Kubernetes namespace"
    echo "  -r, --release NAME      Helm release name (default: mb-otr)"
    echo "  --dry-run              Perform dry run"
    echo "  --no-wait              Don't wait for deployment to complete"
    echo "  -h, --help             Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 install                    # Install with default settings"
    echo "  $0 upgrade -n mb-otr         # Upgrade in specific namespace"
    echo "  $0 delete                     # Delete deployment"
}

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we can connect to Kubernetes cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Add required Helm repositories
add_helm_repos() {
    print_status "Adding required Helm repositories..."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    print_success "Helm repositories updated"
}

# Create namespace if it doesn't exist
create_namespace() {
    if [ -n "$NAMESPACE" ]; then
        if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
            print_status "Creating namespace: $NAMESPACE"
            kubectl create namespace "$NAMESPACE"
            print_success "Namespace created: $NAMESPACE"
        else
            print_status "Namespace already exists: $NAMESPACE"
        fi
    fi
}

# Install deployment
install_deployment() {
    print_status "Installing MB OTR deployment..."

    local cmd="helm install $RELEASE_NAME $CHART_PATH"

    if [ -n "$NAMESPACE" ]; then
        cmd="$cmd -n $NAMESPACE"
    fi

    if [ "$DRY_RUN" = true ]; then
        cmd="$cmd --dry-run"
    fi

    if [ "$WAIT" = true ]; then
        cmd="$cmd --wait --timeout=10m"
    fi

    print_status "Executing: $cmd"
    eval $cmd

    if [ "$DRY_RUN" = false ]; then
        print_success "MB OTR deployment installed successfully"
        show_access_info
    fi
}

# Upgrade deployment
upgrade_deployment() {
    print_status "Upgrading MB OTR deployment..."

    local cmd="helm upgrade $RELEASE_NAME $CHART_PATH"

    if [ -n "$NAMESPACE" ]; then
        cmd="$cmd -n $NAMESPACE"
    fi

    if [ "$DRY_RUN" = true ]; then
        cmd="$cmd --dry-run"
    fi

    if [ "$WAIT" = true ]; then
        cmd="$cmd --wait --timeout=10m"
    fi

    print_status "Executing: $cmd"
    eval $cmd

    if [ "$DRY_RUN" = false ]; then
        print_success "MB OTR deployment upgraded successfully"
        show_access_info
    fi
}

# Delete deployment
delete_deployment() {
    print_status "Deleting MB OTR deployment..."

    local cmd="helm uninstall $RELEASE_NAME"

    if [ -n "$NAMESPACE" ]; then
        cmd="$cmd -n $NAMESPACE"
    fi

    print_status "Executing: $cmd"
    eval $cmd

    print_success "MB OTR deployment deleted successfully"
}

# Show deployment status
show_status() {
    print_status "Showing deployment status..."

    local cmd="helm status $RELEASE_NAME"

    if [ -n "$NAMESPACE" ]; then
        cmd="$cmd -n $NAMESPACE"
    fi

    eval $cmd

    print_status "Pod status:"
    if [ -n "$NAMESPACE" ]; then
        kubectl get pods -n "$NAMESPACE"
    else
        kubectl get pods
    fi
}

# Show logs for all services
show_logs() {
    print_status "Showing logs for all services..."

    local namespace_flag=""
    if [ -n "$NAMESPACE" ]; then
        namespace_flag="-n $NAMESPACE"
    fi

    # Get all pods with mb-otr label
    local pods=$(kubectl get pods $namespace_flag -l "app.kubernetes.io/instance=$RELEASE_NAME" -o jsonpath='{.items[*].metadata.name}')

    for pod in $pods; do
        print_status "Logs for $pod:"
        kubectl logs $namespace_flag "$pod" --tail=50
        echo "---"
    done
}

# Show access information
show_access_info() {
    print_status "Access Information:"
    echo ""
    echo "To access the services locally, use port forwarding:"
    echo ""

    local namespace_flag=""
    if [ -n "$NAMESPACE" ]; then
        namespace_flag="-n $NAMESPACE"
    fi

    echo "Frontend (React UI):"
    echo "  kubectl port-forward $namespace_flag svc/$RELEASE_NAME-frontend 8080:80"
    echo "  Then open: http://localhost:8080"
    echo ""

    echo "Deal Service API:"
    echo "  kubectl port-forward $namespace_flag svc/$RELEASE_NAME-dealservice 8081:8080"
    echo "  Health check: http://localhost:8081/deal/actuator/health"
    echo ""

    echo "Database and Kafka:"
    echo "  PostgreSQL: kubectl port-forward $namespace_flag svc/$RELEASE_NAME-postgresql 5432:5432"
    echo "  Kafka: kubectl port-forward $namespace_flag svc/$RELEASE_NAME-kafka 9092:9092"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        install|upgrade|delete|status|logs)
            ACTION="$1"
            shift
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-wait)
            WAIT=false
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Set default namespace if not specified
if [ -z "$NAMESPACE" ]; then
    NAMESPACE="default"
fi

# Main execution
print_status "MB OTR Simple Deployment Script"
print_status "Action: $ACTION"
print_status "Namespace: $NAMESPACE"
print_status "Release: $RELEASE_NAME"
echo ""

check_prerequisites

case $ACTION in
    install)
        add_helm_repos
        create_namespace
        install_deployment
        ;;
    upgrade)
        add_helm_repos
        upgrade_deployment
        ;;
    delete)
        delete_deployment
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    *)
        print_error "Unknown action: $ACTION"
        usage
        exit 1
        ;;
esac
