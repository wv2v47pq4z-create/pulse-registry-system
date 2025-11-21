# SR-HYBRID System Troubleshooting Guide

This guide provides structured troubleshooting steps organized by system layer.

## Table of Contents

1. [CI Failures](#ci-failures)
2. [Docker Build Failures](#docker-build-failures)
3. [Kubernetes Deploy Failures](#kubernetes-deploy-failures)
4. [Health Check Failures](#health-check-failures)
5. [Metrics/Monitoring Issues](#metricsmonitoring-issues)
6. [Application Errors](#application-errors)

---

## CI Failures

### Test Failures

**Symptoms:**
- Tests fail in CI but pass locally
- Coverage below threshold

**Checklist:**
- [ ] Check if tests are using correct Python version (3.11)
- [ ] Verify all dependencies are in `requirements-dev.txt`
- [ ] Check for timing-dependent tests
- [ ] Review test logs in GitHub Actions artifacts

**Commands:**
```bash
# Run tests locally with same configuration as CI
pytest tests/ -v --cov=src --cov-report=term --cov-fail-under=80

# Check Python version
python --version

# Verify dependencies
pip list
```

**Common Issues:**
- **Environment differences**: Install exact versions from requirements
- **Missing test data**: Ensure test fixtures are committed
- **Race conditions**: Use proper synchronization in tests

### Lint Failures

**Symptoms:**
- Ruff or mypy errors in CI

**Checklist:**
- [ ] Run linters locally before pushing
- [ ] Check if `.ruff.toml` or `mypy.ini` is configured
- [ ] Verify Python version compatibility

**Commands:**
```bash
# Run ruff
ruff check src/ tests/

# Run mypy
mypy src/ --ignore-missing-imports

# Auto-fix ruff issues
ruff check src/ tests/ --fix
```

---

## Docker Build Failures

### Image Build Fails

**Symptoms:**
- Docker build fails in CI or locally
- "No such file or directory" errors

**Checklist:**
- [ ] Verify `Dockerfile` syntax
- [ ] Check that all referenced files exist
- [ ] Ensure `.dockerignore` isn't excluding needed files
- [ ] Verify base image is accessible

**Commands:**
```bash
# Build with verbose output
docker build -f docker/Dockerfile -t sr-hybrid:test . --progress=plain

# Check what files are being sent to build context
docker build -f docker/Dockerfile -t sr-hybrid:test . --no-cache 2>&1 | grep "COPY"

# Verify .dockerignore
cat .dockerignore
```

**Common Issues:**
- **Missing requirements.txt**: Ensure file exists and is not in `.dockerignore`
- **Wrong COPY paths**: Verify paths in Dockerfile match repo structure
- **Base image unavailable**: Try pulling base image manually

### Image Too Large

**Symptoms:**
- Build succeeds but image is very large
- Slow push/pull times

**Solutions:**
```bash
# Check image size
docker images sr-hybrid

# Use multi-stage builds (already done in Dockerfile)
# Remove unnecessary files

# Analyze layers
docker history sr-hybrid:latest

# Use dive tool for detailed analysis
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest sr-hybrid:latest
```

---

## Kubernetes Deploy Failures

### Deployment Not Starting

**Symptoms:**
- Pods stuck in `Pending` state
- No pods created

**Checklist:**
- [ ] Check if namespace exists
- [ ] Verify resource quotas
- [ ] Check node capacity
- [ ] Verify image exists and is accessible

**Commands:**
```bash
# Check deployment status
kubectl get deployment sr-hybrid-blue -n sr-hybrid
kubectl describe deployment sr-hybrid-blue -n sr-hybrid

# Check pods
kubectl get pods -n sr-hybrid
kubectl describe pod <pod-name> -n sr-hybrid

# Check events
kubectl get events -n sr-hybrid --sort-by='.lastTimestamp'

# Check node resources
kubectl top nodes
kubectl describe nodes
```

**Common Issues:**
- **Insufficient resources**: Scale down or add nodes
- **Image pull errors**: Verify image exists and credentials are correct
- **PVC not bound**: Check storage class and PVC status

### Image Pull Errors

**Symptoms:**
- Pods show `ImagePullBackOff` or `ErrImagePull`

**Checklist:**
- [ ] Verify image exists in registry
- [ ] Check image name and tag are correct
- [ ] Verify registry credentials
- [ ] Check network connectivity to registry

**Commands:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n sr-hybrid

# Verify image exists
docker pull <image-name>

# Check image pull secrets
kubectl get secrets -n sr-hybrid
kubectl describe secret <secret-name> -n sr-hybrid

# Recreate image pull secret if needed
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password> \
  --namespace=sr-hybrid
```

### PVC Not Bound

**Symptoms:**
- Pods stuck in `Pending` with PVC binding issues

**Checklist:**
- [ ] Verify storage class exists
- [ ] Check PVC status
- [ ] Verify sufficient storage on nodes

**Commands:**
```bash
# Check PVC status
kubectl get pvc -n sr-hybrid
kubectl describe pvc sr-hybrid-data-pvc -n sr-hybrid

# Check storage class
kubectl get storageclass
kubectl describe storageclass standard

# Check PV
kubectl get pv

# Delete and recreate PVC if needed
kubectl delete pvc sr-hybrid-data-pvc -n sr-hybrid
kubectl apply -f k8s/storage-pvc.yaml
```

---

## Health Check Failures

### Readiness Probe Failing

**Symptoms:**
- Pods not becoming ready
- Service not routing traffic to pods

**Checklist:**
- [ ] Verify `/health` endpoint is accessible
- [ ] Check application logs for errors
- [ ] Verify port 8080 is correct
- [ ] Check if application started successfully

**Commands:**
```bash
# Check pod status
kubectl get pods -n sr-hybrid -o wide

# Check pod logs
kubectl logs <pod-name> -n sr-hybrid

# Exec into pod and test endpoint
kubectl exec -it <pod-name> -n sr-hybrid -- sh
# Inside pod:
python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/health').read())"

# Check endpoint from another pod
kubectl run curl-test --rm -i --restart=Never --image=curlimages/curl:latest -- \
  curl -v http://<pod-ip>:8080/health
```

**Common Issues:**
- **Application not started**: Check logs for startup errors
- **Wrong port**: Verify port in deployment and application
- **Slow startup**: Increase `initialDelaySeconds` in probe

### Liveness Probe Failing

**Symptoms:**
- Pods constantly restarting
- CrashLoopBackOff

**Checklist:**
- [ ] Check application logs before restart
- [ ] Verify liveness probe settings
- [ ] Check for application hangs

**Commands:**
```bash
# Get pod restart count
kubectl get pods -n sr-hybrid

# Get logs from previous container
kubectl logs <pod-name> -n sr-hybrid --previous

# Check probe configuration
kubectl describe pod <pod-name> -n sr-hybrid | grep -A 10 "Liveness"

# Increase failure threshold temporarily
kubectl patch deployment sr-hybrid-blue -n sr-hybrid -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"sr-hybrid","livenessProbe":{"failureThreshold":5}}]}}}}'
```

---

## Metrics/Monitoring Issues

### Prometheus Not Scraping

**Symptoms:**
- Metrics not appearing in Prometheus
- Targets showing as down

**Checklist:**
- [ ] Verify `/metrics` endpoint is accessible
- [ ] Check Prometheus configuration
- [ ] Verify service discovery

**Commands:**
```bash
# Check Prometheus targets
kubectl port-forward -n sr-hybrid svc/prometheus 9090:9090
# Open http://localhost:9090/targets

# Test metrics endpoint
kubectl run curl-test --rm -i --restart=Never --image=curlimages/curl:latest -- \
  curl http://sr-hybrid:8080/metrics

# Check Prometheus logs
kubectl logs -n sr-hybrid deployment/prometheus

# Verify ConfigMap
kubectl get configmap prometheus-config -n sr-hybrid -o yaml
```

### Grafana Dashboard Empty

**Symptoms:**
- Grafana shows no data
- Dashboard panels empty

**Checklist:**
- [ ] Verify Prometheus data source is configured
- [ ] Check if Prometheus is collecting metrics
- [ ] Verify metric names in queries

**Commands:**
```bash
# Access Grafana
kubectl port-forward -n sr-hybrid svc/grafana 3000:3000
# Open http://localhost:3000 (admin/admin)

# Check Grafana logs
kubectl logs -n sr-hybrid deployment/grafana

# Verify data source in Grafana:
# Configuration → Data Sources → Prometheus
# Test connection
```

**Solutions:**
1. Add Prometheus data source manually:
   - URL: `http://prometheus:9090`
   - Access: Server (default)
   - Save & Test

2. Import dashboard:
   - Dashboard → Import
   - Upload `monitoring/grafana-dashboard.json`

---

## Application Errors

### Import Errors

**Symptoms:**
- `ModuleNotFoundError` in logs

**Checklist:**
- [ ] Verify all dependencies in `requirements.txt`
- [ ] Check Python path
- [ ] Verify module structure

**Commands:**
```bash
# Check installed packages
pip list

# Verify module can be imported
python -c "import src.sr_graph"

# Check PYTHONPATH
echo $PYTHONPATH
```

### Port Already in Use

**Symptoms:**
- Application fails to start with "Address already in use" error

**Solutions:**
```bash
# Find process using port 8080
lsof -i :8080
# or
netstat -tulpn | grep 8080

# Kill process
kill -9 <PID>

# Or use different port
export SR_PORT=8081
python -m src.sr_graph
```

### High Memory Usage

**Symptoms:**
- Pods being OOMKilled
- High memory usage in metrics

**Checklist:**
- [ ] Check resource limits
- [ ] Review application logs
- [ ] Check for memory leaks

**Commands:**
```bash
# Check pod resource usage
kubectl top pods -n sr-hybrid

# Get detailed pod info
kubectl describe pod <pod-name> -n sr-hybrid

# Check container limits
kubectl get pod <pod-name> -n sr-hybrid -o yaml | grep -A 5 "resources:"

# Increase memory limit
kubectl patch deployment sr-hybrid-blue -n sr-hybrid -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"sr-hybrid","resources":{"limits":{"memory":"2Gi"}}}]}}}}'
```

### Recursion Limit Errors

**Symptoms:**
- `RecursionLimitError` in logs
- Application crashes during complex operations

**Solutions:**
```bash
# Check recursion depth in metrics
kubectl port-forward -n sr-hybrid svc/prometheus 9090:9090
# Query: sr_hybrid_recursion_depth

# Increase max recursion depth via environment variable
kubectl set env deployment/sr-hybrid-blue -n sr-hybrid SR_MAX_RECURSION_DEPTH=200

# Or edit deployment
kubectl edit deployment sr-hybrid-blue -n sr-hybrid
# Add to env:
#   - name: SR_MAX_RECURSION_DEPTH
#     value: "200"
```

---

## Emergency Procedures

### Immediate Rollback

```bash
# Switch service to stable version
kubectl patch service sr-hybrid -n sr-hybrid -p \
  '{"spec":{"selector":{"version":"blue"}}}'  # or "green"

# Rollback deployment
kubectl rollout undo deployment/sr-hybrid-<version> -n sr-hybrid
```

### Scale Down Failing Deployment

```bash
# Scale to 0
kubectl scale deployment sr-hybrid-<version> -n sr-hybrid --replicas=0

# Scale back up after fix
kubectl scale deployment sr-hybrid-<version> -n sr-hybrid --replicas=2
```

### Collect Diagnostic Info

```bash
#!/bin/bash
# Save to diagnose.sh
mkdir -p diagnostics
kubectl get all -n sr-hybrid > diagnostics/all-resources.txt
kubectl describe deployment -n sr-hybrid > diagnostics/deployments.txt
kubectl logs -n sr-hybrid -l app=sr-hybrid --tail=500 > diagnostics/logs.txt
kubectl get events -n sr-hybrid --sort-by='.lastTimestamp' > diagnostics/events.txt
kubectl top pods -n sr-hybrid > diagnostics/resource-usage.txt
```

---

## Getting Help

If issues persist:

1. **Collect diagnostics** using script above
2. **Check logs** from all relevant components
3. **Review recent changes** in git history
4. **Check GitHub Actions** artifacts for build/deploy logs
5. **Consult documentation** at docs/

For urgent issues, follow the emergency rollback procedures first.
