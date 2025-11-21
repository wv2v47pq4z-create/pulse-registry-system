# AWS EKS Deployment Guide

This guide covers deploying the SR-HYBRID System on Amazon Elastic Kubernetes Service (EKS).

## Prerequisites

- AWS CLI configured with appropriate credentials
- eksctl installed
- kubectl installed
- Docker installed
- AWS account with necessary permissions

## 1. Create EKS Cluster

### Using eksctl

```bash
# Create cluster
eksctl create cluster \
  --name sr-hybrid-cluster \
  --region us-west-2 \
  --nodegroup-name sr-hybrid-nodes \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 4 \
  --managed

# Verify cluster
kubectl get nodes
```

### Update kubeconfig

```bash
aws eks update-kubeconfig --region us-west-2 --name sr-hybrid-cluster
```

## 2. Set Up ECR (Elastic Container Registry)

### Create Repository

```bash
# Create ECR repository
aws ecr create-repository \
  --repository-name sr-hybrid \
  --region us-west-2

# Get repository URI
REPO_URI=$(aws ecr describe-repositories \
  --repository-names sr-hybrid \
  --region us-west-2 \
  --query 'repositories[0].repositoryUri' \
  --output text)

echo "Repository URI: $REPO_URI"
```

### Login to ECR

```bash
# Get login password and login
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin $REPO_URI
```

## 3. Build and Push Docker Image

```bash
# Build image
docker build -f docker/Dockerfile -t sr-hybrid:latest .

# Tag for ECR
docker tag sr-hybrid:latest $REPO_URI:latest
docker tag sr-hybrid:latest $REPO_URI:$(git rev-parse --short HEAD)

# Push to ECR
docker push $REPO_URI:latest
docker push $REPO_URI:$(git rev-parse --short HEAD)
```

## 4. Update Kubernetes Manifests

Update the image in deployment files:

```bash
# Set the ECR repository URI
REPO_URI="your-account-id.dkr.ecr.us-west-2.amazonaws.com/sr-hybrid"

# Update blue deployment
sed -i "s|your-registry/sr-hybrid:latest|$REPO_URI:latest|g" \
  k8s/sr-hybrid-blue-deployment.yaml

# Update green deployment
sed -i "s|your-registry/sr-hybrid:latest|$REPO_URI:latest|g" \
  k8s/sr-hybrid-green-deployment.yaml
```

## 5. Create Secrets

```bash
# Create Kubernetes secret for application
kubectl create secret generic sr-hybrid-secrets \
  --from-literal=ANTHROPIC_API_KEY=your-api-key \
  --from-literal=SR_LOG_LEVEL=INFO \
  -n sr-hybrid
```

## 6. Set Up Storage

### Create EBS Storage Class

```yaml
# storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
```

Apply:
```bash
kubectl apply -f storage-class.yaml
```

### Update PVC to use EBS

Update `k8s/storage-pvc.yaml`:
```yaml
storageClassName: ebs-sc  # Change from 'standard' to 'ebs-sc'
```

## 7. Deploy Application

### Deploy Namespace and Storage

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/storage-pvc.yaml
```

### Deploy Blue/Green

```bash
kubectl apply -f k8s/sr-hybrid-blue-deployment.yaml
kubectl apply -f k8s/sr-hybrid-green-deployment.yaml
kubectl apply -f k8s/sr-hybrid-service.yaml
```

### Verify Deployments

```bash
kubectl get deployments -n sr-hybrid
kubectl get pods -n sr-hybrid
kubectl get svc -n sr-hybrid
```

## 8. Set Up Load Balancer

### Create Application Load Balancer

```yaml
# alb-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sr-hybrid-ingress
  namespace: sr-hybrid
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /health
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: sr-hybrid
                port:
                  number: 8080
```

Install AWS Load Balancer Controller first:
```bash
# Add Helm repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=sr-hybrid-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

Apply ingress:
```bash
kubectl apply -f alb-ingress.yaml
```

Get Load Balancer URL:
```bash
kubectl get ingress sr-hybrid-ingress -n sr-hybrid
```

## 9. Deploy Monitoring

```bash
kubectl apply -f k8s/prometheus-configmap.yaml
kubectl apply -f k8s/prometheus-deployment.yaml
kubectl apply -f k8s/prometheus-service.yaml
kubectl apply -f k8s/grafana-deployment.yaml
kubectl apply -f k8s/grafana-service.yaml
```

### Access Monitoring

Port-forward or create LoadBalancer services:
```bash
# Port-forward Prometheus
kubectl port-forward -n sr-hybrid svc/prometheus 9090:9090

# Port-forward Grafana
kubectl port-forward -n sr-hybrid svc/grafana 3000:3000
```

## 10. Configure GitHub Actions

### Create IAM User for CI/CD

```bash
# Create IAM user
aws iam create-user --user-name github-actions-sr-hybrid

# Attach policies
aws iam attach-user-policy \
  --user-name github-actions-sr-hybrid \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

aws iam attach-user-policy \
  --user-name github-actions-sr-hybrid \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Create access key
aws iam create-access-key --user-name github-actions-sr-hybrid
```

### Configure GitHub Secrets

Add these secrets to your GitHub repository:

1. **DOCKER_REGISTRY**: Your ECR repository URI
2. **DOCKER_USERNAME**: `AWS`
3. **DOCKER_PASSWORD**: ECR login token (or use OIDC)
4. **KUBE_CONFIG_B64**: Base64-encoded kubeconfig

Get kubeconfig:
```bash
# Get current kubeconfig for EKS
aws eks update-kubeconfig --region us-west-2 --name sr-hybrid-cluster

# Encode as base64
cat ~/.kube/config | base64 -w 0
```

### Update CI/CD Workflow

Update `.github/workflows/ci.yml` and `.github/workflows/deploy.yml` to use ECR:

```yaml
- name: Log in to Amazon ECR
  uses: aws-actions/amazon-ecr-login@v2
  
- name: Build and push
  env:
    ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
    ECR_REPOSITORY: sr-hybrid
    IMAGE_TAG: ${{ github.sha }}
  run: |
    docker build -f docker/Dockerfile -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
```

## 11. Blue/Green Deployment on EKS

Use the deployment workflow:

```bash
# Trigger via GitHub Actions UI or
gh workflow run deploy.yml \
  -f environment=production \
  -f version=blue
```

Or use the deployment script:
```bash
./scripts/deploy.sh blue $REPO_URI:latest
```

## 12. Monitoring and Logging

### CloudWatch Integration

```bash
# Install Fluent Bit for log forwarding
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml
```

### View Logs in CloudWatch

```bash
aws logs tail /aws/eks/sr-hybrid-cluster/application --follow
```

## 13. Cost Optimization

### Use Spot Instances

```bash
eksctl create nodegroup \
  --cluster=sr-hybrid-cluster \
  --region=us-west-2 \
  --name=sr-hybrid-spot \
  --node-type=t3.medium \
  --nodes=2 \
  --spot
```

### Set Resource Limits

Ensure deployments have resource requests and limits set (already configured in manifests).

### Auto-scaling

```bash
# Install cluster autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

## 14. Security Best Practices

### Enable Secrets Encryption

```bash
eksctl utils enable-secrets-encryption \
  --cluster=sr-hybrid-cluster \
  --key-arn=arn:aws:kms:us-west-2:ACCOUNT_ID:key/KEY_ID
```

### Network Policies

Apply network policies to restrict pod-to-pod communication:

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sr-hybrid-network-policy
  namespace: sr-hybrid
spec:
  podSelector:
    matchLabels:
      app: sr-hybrid
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector: {}
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - podSelector: {}
```

## 15. Cleanup

### Delete Resources

```bash
# Delete Kubernetes resources
kubectl delete -k k8s/

# Delete cluster
eksctl delete cluster --name sr-hybrid-cluster --region us-west-2

# Delete ECR repository
aws ecr delete-repository --repository-name sr-hybrid --force
```

## Troubleshooting

### Pod Fails to Pull Image

```bash
# Verify ECR permissions
aws ecr get-login-password --region us-west-2

# Check image exists
aws ecr describe-images --repository-name sr-hybrid
```

### EBS Volume Fails to Mount

```bash
# Verify EBS CSI driver
kubectl get daemonset ebs-csi-node -n kube-system

# Check PVC status
kubectl get pvc -n sr-hybrid
kubectl describe pvc sr-hybrid-data-pvc -n sr-hybrid
```

### Load Balancer Not Created

```bash
# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify IAM permissions
aws iam get-role --role-name AWSLoadBalancerControllerRole
```

For more troubleshooting, see [troubleshooting.md](troubleshooting.md).
