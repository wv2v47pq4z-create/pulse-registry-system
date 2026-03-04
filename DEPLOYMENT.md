# SR-HYBRID Blue/Green Deployment Guide

## Overview

This repository includes a complete blue/green deployment setup for Kubernetes with automated CI/CD via GitHub Actions.

## Architecture

### Blue/Green Deployment Pattern

The deployment uses two identical production environments:
- **Blue** deployment (`sr-hybrid-blue`)
- **Green** deployment (`sr-hybrid-green`)

At any time, only one environment (blue or green) receives live traffic via the Service selector. During deployment:
1. The inactive environment is updated with the new image
2. Health checks validate the new deployment
3. If healthy, traffic is switched to the new environment
4. If unhealthy, the deployment is automatically rolled back

### Components

```
.github/workflows/deploy.yml    - CI/CD workflow for build and deployment
docker/Dockerfile               - Multi-stage container build
k8s/
├── namespace.yaml              - sr-hybrid namespace
├── storage-pvc.yaml            - Persistent storage (10Gi)
├── sr-hybrid-service.yaml      - Service with blue/green selector
├── sr-hybrid-blue-deployment.yaml   - Blue environment (2 replicas)
├── sr-hybrid-green-deployment.yaml  - Green environment (2 replicas)
├── prometheus-configmap.yaml   - Monitoring configuration
├── prometheus-deployment.yaml  - Prometheus server
├── prometheus-service.yaml     - Prometheus access
├── grafana-deployment.yaml     - Visualization dashboard
└── grafana-service.yaml        - Grafana access
```

## Prerequisites

### Required GitHub Secrets

Configure these secrets in your GitHub repository settings:

1. **DOCKER_REGISTRY** - Your Docker registry URL (e.g., `ghcr.io/owner`)
2. **DOCKER_USERNAME** - Registry username
3. **DOCKER_PASSWORD** - Registry password/token
4. **KUBE_CONFIG_B64** - Base64-encoded kubeconfig file

To create KUBE_CONFIG_B64:
```bash
cat ~/.kube/config | base64 -w 0
```

### Optional Secrets

5. **SLACK_WEBHOOK_URL** - For deployment notifications (optional)

## Deployment Workflow

### Automatic Deployment

The workflow automatically triggers on:
- Push to `main` branch
- Version tags (e.g., `v1.0.0`)

### Workflow Steps

1. **Build & Push**
   - Builds Docker image from `docker/Dockerfile`
   - Tags with SHA, branch name, and semver
   - Pushes to configured registry
   - Uses GitHub Actions cache for faster builds

2. **Blue/Green Deploy**
   - Detects currently active color (blue/green)
   - Updates inactive environment with new image
   - Waits for Kubernetes rollout to complete
   - Performs health checks with exponential backoff
   - Switches traffic if healthy, rolls back if not

3. **Monitoring & Logging**
   - Captures deployment state
   - Collects pod logs from both environments
   - Uploads artifacts (14-day retention)
   - Sends Slack notification (if configured)

## Application Requirements

Your application must:

1. **Expose port 8080** - The deployment expects the application to listen on port 8080

2. **Implement /health endpoint** - Health checks are performed on `http://localhost:8080/health`
   - Should return HTTP 200 when healthy
   - Should respond within 3 seconds
   - Example Node.js implementation:
   ```javascript
   app.get('/health', (req, res) => {
     res.status(200).json({ status: 'healthy' });
   });
   ```

3. **Include package.json** - For dependency installation (if Node.js based)

4. **Have index.js entry point** - Or modify Dockerfile CMD to match your entry point

## Local Development

### Build Docker Image

```bash
docker build -f docker/Dockerfile -t sr-hybrid:local .
```

### Test Locally

```bash
docker run -p 8080:8080 sr-hybrid:local
curl http://localhost:8080/health
```

### Validate Kubernetes Manifests

```bash
# Dry run to check syntax
kubectl apply --dry-run=client -f k8s/

# Validate with actual cluster (no changes)
kubectl apply --dry-run=server -f k8s/
```

## Monitoring

### Prometheus

Access Prometheus at the service endpoint in your cluster:
```bash
kubectl port-forward -n sr-hybrid svc/prometheus 9090:9090
```

Then open http://localhost:9090

### Grafana

Access Grafana:
```bash
kubectl port-forward -n sr-hybrid svc/grafana 3000:3000
```

Default credentials:
- Username: `admin`
- Password: `admin`

Add Prometheus data source:
- URL: `http://prometheus:9090`

## Troubleshooting

### View Deployment Status

```bash
# Check current active color
kubectl get svc sr-hybrid -n sr-hybrid -o jsonpath='{.spec.selector.version}'

# View all deployments
kubectl get deployments -n sr-hybrid

# Check pod status
kubectl get pods -n sr-hybrid -l app=sr-hybrid
```

### View Logs

```bash
# Blue deployment
kubectl logs -n sr-hybrid -l app=sr-hybrid,version=blue --tail=100

# Green deployment
kubectl logs -n sr-hybrid -l app=sr-hybrid,version=green --tail=100
```

### Manual Rollback

If needed, manually switch back to the previous color:

```bash
# Switch to blue
kubectl patch svc sr-hybrid -n sr-hybrid \
  -p '{"spec":{"selector":{"version":"blue"}}}'

# Switch to green
kubectl patch svc sr-hybrid -n sr-hybrid \
  -p '{"spec":{"selector":{"version":"green"}}}'
```

### Check Health Endpoint

```bash
# From within cluster
kubectl exec -n sr-hybrid <pod-name> -- curl http://localhost:8080/health

# Port forward and test locally
kubectl port-forward -n sr-hybrid <pod-name> 8080:8080
curl http://localhost:8080/health
```

## Customization

### Adjust Resources

Edit resource limits in deployment files:
- `k8s/sr-hybrid-blue-deployment.yaml`
- `k8s/sr-hybrid-green-deployment.yaml`

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Change Replica Count

```yaml
spec:
  replicas: 2  # Adjust as needed
```

### Modify Health Check Settings

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30  # Adjust based on startup time
  periodSeconds: 10
```

## Security Considerations

1. **Non-root Container** - Dockerfile uses a non-root user (uid 1001)
2. **Secret Management** - Use Kubernetes secrets for sensitive data
3. **Network Policies** - Consider adding network policies to restrict traffic
4. **Image Scanning** - Enable vulnerability scanning in your registry
5. **RBAC** - Ensure kubeconfig has minimal required permissions

## Production Checklist

Before deploying to production:

- [ ] Configure all required GitHub secrets
- [ ] Test health endpoint responds correctly
- [ ] Verify resource limits are appropriate
- [ ] Set up monitoring alerts
- [ ] Configure backup strategy for persistent data
- [ ] Review and adjust retention policies
- [ ] Test rollback procedure
- [ ] Document incident response process
- [ ] Configure log aggregation
- [ ] Set up SSL/TLS termination (if needed)

## References

- [Kubernetes Blue/Green Deployments](https://kubernetes.io/blog/2018/04/30/zero-downtime-deployment-kubernetes-jenkins/)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [GitHub Actions Workflows](https://docs.github.com/en/actions/using-workflows)
- [Prometheus Monitoring](https://prometheus.io/docs/introduction/overview/)
