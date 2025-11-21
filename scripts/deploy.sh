#!/bin/bash
# Deployment script for SR-HYBRID System

set -e

# Default values
VERSION=${1:-blue}
NAMESPACE="sr-hybrid"
IMAGE_TAG=${2:-latest}

if [ "$VERSION" != "blue" ] && [ "$VERSION" != "green" ]; then
    echo "Error: Version must be 'blue' or 'green'"
    echo "Usage: $0 <blue|green> [image-tag]"
    exit 1
fi

echo "=== SR-HYBRID Blue/Green Deployment ==="
echo "Version: $VERSION"
echo "Namespace: $NAMESPACE"
echo "Image Tag: $IMAGE_TAG"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found. Please install kubectl first."
    exit 1
fi

# Verify cluster connection
echo "Verifying cluster connection..."
kubectl cluster-info > /dev/null 2>&1 || {
    echo "Error: Cannot connect to Kubernetes cluster"
    exit 1
}

# Create namespace if it doesn't exist
echo "Ensuring namespace exists..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/storage-pvc.yaml

# Update deployment with new image
echo "Updating deployment sr-hybrid-${VERSION}..."
kubectl set image deployment/sr-hybrid-${VERSION} \
    sr-hybrid=${IMAGE_TAG} \
    -n $NAMESPACE

# Wait for rollout
echo "Waiting for rollout to complete..."
kubectl rollout status deployment/sr-hybrid-${VERSION} -n $NAMESPACE --timeout=5m

# Perform health checks
echo "Performing health checks..."
sleep 10

# Get pod IPs
POD_IPS=$(kubectl get pods -n $NAMESPACE -l app=sr-hybrid,version=${VERSION} \
    -o jsonpath='{.items[*].status.podIP}')

echo "Pod IPs: $POD_IPS"

# Check health of each pod
for ip in $POD_IPS; do
    echo "Checking health of pod at $ip..."
    # Use unique pod name to avoid conflicts
    POD_NAME="health-check-$(date +%s)-$$"
    kubectl run $POD_NAME --rm -i --restart=Never --image=curlimages/curl:latest -- \
        curl -sf http://${ip}:8080/health || {
        echo "Health check failed for pod at $ip"
        # Clean up if pod still exists
        kubectl delete pod $POD_NAME --ignore-not-found=true 2>/dev/null || true
        exit 1
    }
    echo "Pod at $ip is healthy"
done

# Ask for confirmation to switch traffic
echo ""
echo "All pods are healthy. Switch traffic to $VERSION? (yes/no)"
read -r CONFIRM

if [ "$CONFIRM" = "yes" ]; then
    echo "Switching traffic to $VERSION..."
    kubectl patch service sr-hybrid -n $NAMESPACE -p \
        '{"spec":{"selector":{"version":"'${VERSION}'"}}}'
    
    echo ""
    echo "=== Deployment Complete ==="
    echo "Service is now pointing to $VERSION"
    kubectl get service sr-hybrid -n $NAMESPACE -o wide
else
    echo "Traffic switch cancelled. Service still points to the previous version."
fi

echo ""
echo "To rollback, run:"
echo "  kubectl rollout undo deployment/sr-hybrid-${VERSION} -n $NAMESPACE"
