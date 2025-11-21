# SR-HYBRID System

Production-ready multi-agent system with blue/green Kubernetes deployment for Super Reality OS.

## Overview

The SR-HYBRID System is a sophisticated multi-agent platform featuring:

- **State Management** - Thread-safe state handling
- **Recursion Control** - Depth tracking and limiting
- **Grounding Engine** - Output stabilization and drift detection
- **Routing System** - Flexible message routing
- **Bridge** - Inter-component communication
- **Conflict Resolution** - Automatic conflict handling
- **Agent Management** - Dynamic agent registration and execution

## Features

✅ **Production Ready**
- Blue/green Kubernetes deployment strategy
- Comprehensive health checks and monitoring
- Prometheus metrics integration
- Grafana dashboards
- Docker containerization

✅ **Robust Architecture**
- Thread-safe components
- Recursion guards
- Error handling with custom exceptions
- Structured logging

✅ **Observability**
- `/health` - Health check endpoint
- `/metrics` - Prometheus metrics
- `/status` - System status
- Grafana dashboards for visualization

✅ **CI/CD**
- Automated testing with 80%+ coverage
- Linting (ruff) and type checking (mypy)
- Automated Docker builds
- Blue/green deployment workflow

## Quick Start

### Local Development

1. **Setup**:
   ```bash
   ./scripts/setup.sh --dev
   ```

2. **Configure**:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Run**:
   ```bash
   ./scripts/run.sh
   ```

4. **Access**:
   - Health: http://localhost:8080/health
   - Metrics: http://localhost:8080/metrics
   - Status: http://localhost:8080/status

### Docker

```bash
# Start with docker-compose
docker-compose -f docker/docker-compose.yml up -d

# Access services
# - Application: http://localhost:8080
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3000 (admin/admin)
```

### Kubernetes

```bash
# Deploy to Kubernetes
kubectl apply -k k8s/

# Or use deployment script
./scripts/deploy.sh blue your-registry/sr-hybrid:latest
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Load Balancer                        │
└───────────────────┬─────────────────────────────────────┘
                    │
        ┌───────────┴──────────┐
        │    Service (8080)     │
        │  Selector: blue/green │
        └───────────┬───────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼──────┐       ┌───────▼──────┐
│ Blue Deploy  │       │ Green Deploy │
│  (inactive)  │       │   (active)   │
└──────────────┘       └──────────────┘
```

### Blue/Green Deployment

1. Deploy to inactive environment (blue or green)
2. Run health checks
3. Switch service selector on success
4. Keep old version for quick rollback

## Project Structure

```
pulse-registry-system/
├── src/                      # Application source code
│   ├── sr_state.py          # State management
│   ├── sr_recursion.py      # Recursion control
│   ├── sr_grounding.py      # Grounding engine
│   ├── sr_routing.py        # Routing system
│   ├── sr_bridge.py         # Inter-component bridge
│   ├── sr_conflict.py       # Conflict resolution
│   ├── sr_errors.py         # Custom exceptions
│   ├── sr_agents.py         # Agent management
│   ├── sr_graph.py          # Main HTTP server
│   └── sr_logging.py        # Logging configuration
├── tests/                   # Test suite
├── docker/                  # Docker configuration
│   ├── Dockerfile           # Production image
│   ├── Dockerfile.dev       # Development image
│   └── docker-compose.yml   # Local stack
├── k8s/                     # Kubernetes manifests
│   ├── sr-hybrid-blue-deployment.yaml
│   ├── sr-hybrid-green-deployment.yaml
│   ├── sr-hybrid-service.yaml
│   └── ...
├── .github/workflows/       # CI/CD pipelines
│   ├── ci.yml              # Test, lint, build
│   └── deploy.yml          # Blue/green deployment
├── monitoring/              # Monitoring config
│   ├── prometheus.yml      # Prometheus configuration
│   └── grafana-dashboard.json
├── scripts/                 # Utility scripts
│   ├── setup.sh            # Initial setup
│   ├── run.sh              # Run application
│   └── deploy.sh           # Deployment script
└── docs/                    # Documentation
    ├── aws-deployment.md    # AWS EKS guide
    └── troubleshooting.md   # Troubleshooting guide
```

## Monitoring

### Prometheus Metrics

The system exposes the following metrics:

- `sr_hybrid_total_messages` - Total messages processed
- `sr_hybrid_recursion_depth` - Current recursion depth
- `sr_hybrid_drift_score` - Drift score between states
- `sr_hybrid_grounding_total` - Total grounding operations
- `sr_hybrid_agent_calls_total{agent_name}` - Agent calls by name
- `sr_hybrid_errors_total{error_type}` - Errors by type

### Grafana Dashboards

Pre-configured dashboards available in `monitoring/grafana-dashboard.json`:
- Message throughput
- Recursion depth tracking
- Drift score trends
- Grounding operations rate
- Agent performance
- Error tracking

## Testing

```bash
# Run all tests
pytest tests/

# Run with coverage
pytest tests/ --cov=src --cov-report=html

# Run specific test file
pytest tests/test_sr_state.py -v

# Run with verbose output
pytest tests/ -vv
```

Current coverage: **83%+**

## Deployment

### GitHub Actions

The system includes two workflows:

1. **CI Workflow** (`.github/workflows/ci.yml`)
   - Runs on push/PR
   - Tests, linting, type checking
   - Builds and pushes Docker images
   - 80% coverage requirement

2. **Deploy Workflow** (`.github/workflows/deploy.yml`)
   - Manual trigger
   - Blue/green deployment
   - Health checks with exponential backoff
   - Automatic rollback on failure
   - Deployment logs artifacts
   - Optional Slack notifications

### Manual Deployment

```bash
# Deploy to blue environment
./scripts/deploy.sh blue your-registry/sr-hybrid:v1.0.0

# After verification, deploy to green
./scripts/deploy.sh green your-registry/sr-hybrid:v1.1.0
```

### Rollback

```bash
# Quick rollback - switch service
kubectl patch service sr-hybrid -n sr-hybrid -p \
  '{"spec":{"selector":{"version":"blue"}}}'

# Full rollback - undo deployment
kubectl rollout undo deployment/sr-hybrid-green -n sr-hybrid
```

## Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SR_HOST` | `0.0.0.0` | Server bind host |
| `SR_PORT` | `8080` | Server port |
| `SR_LOG_LEVEL` | `INFO` | Logging level |
| `SR_LOG_DIR` | `/app/logs` | Log directory |
| `SR_LOG_FILE_ENABLED` | `false` | Enable file logging |
| `SR_MAX_RECURSION_DEPTH` | `100` | Max recursion depth |

## Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment guide
- **[docs/aws-deployment.md](docs/aws-deployment.md)** - AWS EKS deployment
- **[docs/troubleshooting.md](docs/troubleshooting.md)** - Troubleshooting guide

## Development

### Prerequisites

- Python 3.11+
- Docker
- kubectl (for K8s deployment)
- Git

### Setup Development Environment

```bash
# Clone and setup
git clone <repository-url>
cd pulse-registry-system
./scripts/setup.sh --dev

# Activate virtual environment
source venv/bin/activate

# Run tests
pytest tests/

# Run linting
ruff check src/ tests/
mypy src/
```

### Code Style

- **Linting**: ruff
- **Type Checking**: mypy
- **Testing**: pytest
- **Coverage**: 80% minimum

## Contributing

1. Create a feature branch
2. Make changes with tests
3. Ensure linting passes
4. Maintain 80%+ coverage
5. Submit PR

## Logging

Logs include:
- Timestamp
- Log level
- Component name
- Message

Configure via `SR_LOG_LEVEL`:
- `DEBUG` - Detailed debugging
- `INFO` - General information (default)
- `WARNING` - Warning messages
- `ERROR` - Error messages
- `CRITICAL` - Critical errors

## Security

- Non-root container user (UID 1000)
- Read-only root filesystem where possible
- Resource limits enforced
- Secrets stored in Kubernetes secrets
- Network policies for pod isolation

## License

See [LICENSE](LICENSE) file.

## Support

For issues and questions:
- Check [troubleshooting guide](docs/troubleshooting.md)
- Review [deployment documentation](DEPLOYMENT.md)
- Check GitHub Issues
- Review application logs

## Authors

Super Reality Studios - SR-HYBRID System Team
