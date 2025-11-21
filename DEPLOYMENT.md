# SR-HYBRID System Deployment Guide

This guide covers deployment of the SR-HYBRID System using the blue/green deployment strategy on Kubernetes.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Local Development](#local-development)
4. [Docker Deployment](#docker-deployment)
5. [Kubernetes Deployment](#kubernetes-deployment)
6. [Blue/Green Deployment Strategy](#bluegreen-deployment-strategy)
7. [Monitoring](#monitoring)
8. [Rollback Procedures](#rollback-procedures)

## Prerequisites

### Required Tools

- **Python 3.11+** - Application runtime
- **Docker** - Container runtime
- **kubectl** - Kubernetes CLI
- **git** - Version control

### Required Secrets

For GitHub Actions CI/CD, configure the following secrets in your repository:

- `DOCKER_REGISTRY` - Docker registry URL
- `DOCKER_USERNAME` - Docker registry username
- `DOCKER_PASSWORD` - Docker registry password
- `KUBE_CONFIG_B64` - Base64-encoded Kubernetes config
- `SLACK_WEBHOOK_URL` - (Optional) Slack webhook for notifications

## Architecture Overview

The SR-HYBRID System consists of:

- **Application Server** - Python HTTP server (port 8080)
  - `/health` - Health check endpoint
  - `/metrics` - Prometheus metrics endpoint
  - `/status` - System status endpoint

- **Blue/Green Deployments** - Two identical environments
  - `sr-hybrid-blue` - Blue deployment
  - `sr-hybrid-green` - Green deployment

- **Service** - Load balancer switching between blue/green
  - Selector switches between `version: blue` and `version: green`

- **Monitoring Stack**
  - Prometheus - Metrics collection
  - Grafana - Visualization

## Local Development

### Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd pulse-registry-system
   ```

2. Run the setup script:
   ```bash
   ./scripts/setup.sh --dev
   ```

3. Configure environment:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

### Running Locally

Start the application:
```bash
./scripts/run.sh
```

Or manually:
```bash
source venv/bin/activate
python -m src.sr_graph
```

Access endpoints:
- Health: http://localhost:8080/health
- Metrics: http://localhost:8080/metrics
- Status: http://localhost:8080/status

### Running Tests

```bash
# Activate virtual environment
source venv/bin/activate

# Run all tests
pytest tests/

# Run with coverage
pytest tests/ --cov=src --cov-report=html

# Run specific test file
pytest tests/test_sr_state.py -v
```

## Docker Deployment

### Build Image

```bash
docker build -f docker/Dockerfile -t sr-hybrid:latest .
```

### Run Container

```bash
docker run -d \
  --name sr-hybrid \
  -p 8080:8080 \
  -e SR_LOG_LEVEL=INFO \
  sr-hybrid:latest
```

### Using Docker Compose

Start all services (app + monitoring):
```bash
docker-compose -f docker/docker-compose.yml up -d
```

Access services:
- Application: http://localhost:8080
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

Stop services:
```bash
docker-compose -f docker/docker-compose.yml down
```

## Kubernetes Deployment

### Initial Setup

1. Create namespace and resources:
   ```bash
   kubectl apply -f k8s/namespace.yaml
   kubectl apply -f k8s/storage-pvc.yaml
   ```

2. Create secrets:
   ```bash
   kubectl create secret generic sr-hybrid-secrets \
     --from-literal=ANTHROPIC_API_KEY=your-key \
     -n sr-hybrid
   ```

3. Deploy both blue and green:
   ```bash
   kubectl apply -f k8s/sr-hybrid-blue-deployment.yaml
   kubectl apply -f k8s/sr-hybrid-green-deployment.yaml
   kubectl apply -f k8s/sr-hybrid-service.yaml
   ```

4. Deploy monitoring:
   ```bash
   kubectl apply -f k8s/prometheus-configmap.yaml
   kubectl apply -f k8s/prometheus-deployment.yaml
   kubectl apply -f k8s/prometheus-service.yaml
   kubectl apply -f k8s/grafana-deployment.yaml
   kubectl apply -f k8s/grafana-service.yaml
   ```

### Using Kustomize

Deploy all resources at once:
```bash
kubectl apply -k k8s/
```

## Blue/Green Deployment Strategy

### How It Works

1. **Initial State**: Traffic goes to blue (or green)
2. **Deploy New Version**: Update the inactive environment
3. **Verify**: Health checks on new version
4. **Switch Traffic**: Update service selector
5. **Monitor**: Ensure new version is stable
6. **Rollback if Needed**: Switch back to previous version

### Manual Deployment

Use the deployment script:
```bash
# Deploy to blue
./scripts/deploy.sh blue your-registry/sr-hybrid:v1.2.3

# After verification, deploy to green
./scripts/deploy.sh green your-registry/sr-hybrid:v1.2.4
```

### GitHub Actions Deployment

Trigger workflow manually:
```bash
gh workflow run deploy.yml \
  -f environment=production \
  -f version=blue
```

Or through GitHub UI:
1. Go to Actions tab
2. Select "Deploy" workflow
3. Click "Run workflow"
4. Choose environment and version

### Deployment Process

The GitHub Actions workflow:

1. **Builds** Docker image (CI workflow)
2. **Pushes** to registry with SHA tag
3. **Updates** deployment with new image
4. **Waits** for rollout to complete
5. **Performs** health checks with exponential backoff
6. **Switches** service selector on success
7. **Rolls back** on failure
8. **Uploads** deployment logs
9. **Sends** Slack notification (if configured)

## Monitoring

### Prometheus Metrics

Available metrics:
- `sr_hybrid_total_messages` - Total messages processed
- `sr_hybrid_recursion_depth` - Current recursion depth
- `sr_hybrid_drift_score` - Current drift score
- `sr_hybrid_grounding_total` - Total grounding operations
- `sr_hybrid_agent_calls_total{agent_name}` - Agent calls by name
- `sr_hybrid_errors_total{error_type}` - Errors by type

### Access Monitoring

Port-forward to access locally:
```bash
# Prometheus
kubectl port-forward -n sr-hybrid svc/prometheus 9090:9090

# Grafana
kubectl port-forward -n sr-hybrid svc/grafana 3000:3000
```

Then open:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

### View Logs

```bash
# View logs for blue deployment
kubectl logs -n sr-hybrid -l app=sr-hybrid,version=blue --tail=100 -f

# View logs for green deployment
kubectl logs -n sr-hybrid -l app=sr-hybrid,version=green --tail=100 -f

# View logs for specific pod
kubectl logs -n sr-hybrid <pod-name> -f
```

## Rollback Procedures

### Quick Rollback

Switch service back to previous version:
```bash
# If currently on blue, switch to green
kubectl patch service sr-hybrid -n sr-hybrid -p \
  '{"spec":{"selector":{"version":"green"}}}'

# If currently on green, switch to blue
kubectl patch service sr-hybrid -n sr-hybrid -p \
  '{"spec":{"selector":{"version":"blue"}}}'
```

### Deployment Rollback

Rollback the deployment itself:
```bash
# Rollback blue deployment
kubectl rollout undo deployment/sr-hybrid-blue -n sr-hybrid

# Rollback green deployment
kubectl rollout undo deployment/sr-hybrid-green -n sr-hybrid

# Rollback to specific revision
kubectl rollout undo deployment/sr-hybrid-blue -n sr-hybrid --to-revision=2
```

### Check Rollout History

```bash
kubectl rollout history deployment/sr-hybrid-blue -n sr-hybrid
kubectl rollout history deployment/sr-hybrid-green -n sr-hybrid
```

### Emergency Procedures

1. **Immediate traffic switch**:
   ```bash
   kubectl patch service sr-hybrid -n sr-hybrid -p \
     '{"spec":{"selector":{"version":"<stable-version>"}}}'
   ```

2. **Scale down failing deployment**:
   ```bash
   kubectl scale deployment/sr-hybrid-<version> -n sr-hybrid --replicas=0
   ```

3. **Check pod status**:
   ```bash
   kubectl get pods -n sr-hybrid -l app=sr-hybrid
   kubectl describe pod <pod-name> -n sr-hybrid
   ```

4. **View events**:
   ```bash
   kubectl get events -n sr-hybrid --sort-by='.lastTimestamp'
   ```

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for detailed troubleshooting guides.

For AWS-specific deployment instructions, see [docs/aws-deployment.md](docs/aws-deployment.md).
