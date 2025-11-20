# Makefile Deployment Guide

Complete guide for deploying the Autonomous Research Pipeline using Make.

## 🚀 Quick Start - Autonomous Deployment

The simplest way to deploy is using the **master prompt** for autonomous deployment:

```bash
make deploy-autonomous
```

This single command will:
1. ✅ Install all Python dependencies
2. ✅ Verify the setup and environment
3. ✅ Validate configuration (creates .env if missing)
4. ✅ Execute the pipeline
5. ✅ Save results to `deployment-results.json`

### First-Time Setup

If running for the first time, the autonomous deployment will create a `.env` file from the template and prompt you to configure it:

```bash
# First run - will stop and ask you to configure .env
make deploy-autonomous

# Edit the .env file with your API keys
nano .env  # or vim, code, etc.

# Run again after configuration
make deploy-autonomous
```

## 📋 Available Commands

### Setup & Installation

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make install` | Install Python dependencies from requirements.txt |
| `make setup` | Complete setup (install + create .env template) |
| `make verify` | Verify setup and check all requirements |
| `make status` | Show current deployment status and health |

### Deployment Options

| Command | Description |
|---------|-------------|
| `make deploy-autonomous` | 🚀 **Master Prompt** - Full autonomous deployment |
| `make deploy` | Deploy the pipeline (Python mode) |
| `make deploy-output` | Deploy and save results to results.json |
| `make deploy-docker` | Deploy using Docker Compose |
| `make quick-deploy` | Alias for deploy-autonomous |
| `make auto-deploy` | Alias for deploy-autonomous |
| `make run` | Alias for deploy |

### Docker Commands

| Command | Description |
|---------|-------------|
| `make docker-build` | Build Docker image |
| `make deploy-docker` | Deploy using Docker Compose |
| `make docker-logs` | Show Docker container logs |
| `make docker-stop` | Stop Docker containers |

### Development Commands

| Command | Description |
|---------|-------------|
| `make dev-setup` | Setup development environment |
| `make dev-test` | Run tests and linting |
| `make test` | Run integration tests |
| `make lint` | Check code style (requires pylint, flake8) |
| `make format` | Format code (requires black) |
| `make clean` | Clean up generated files and cache |

## 🎯 Common Use Cases

### 1. First-Time Deployment

```bash
# Step 1: Install dependencies
make install

# Step 2: Verify everything is set up correctly
make verify

# Step 3: Create and configure .env file
make setup
# Edit .env with your API keys

# Step 4: Deploy
make deploy-autonomous
```

### 2. Regular Deployment (After Initial Setup)

```bash
# Simple one-command deployment
make deploy-autonomous
```

or

```bash
make deploy
```

### 3. Docker Deployment

```bash
# Build the image
make docker-build

# Deploy with Docker Compose
make deploy-docker

# View logs
make docker-logs

# Stop when done
make docker-stop
```

### 4. Development Workflow

```bash
# Set up development environment
make dev-setup

# Make code changes...

# Test your changes
make dev-test

# Format code
make format

# Deploy to test
make deploy
```

### 5. Check Deployment Status

```bash
make status
```

Output example:
```
Deployment Status:

  ✓ Environment configured
  ✓ Python dependencies
  ✓ Previous deployment results available
  ⚠ Docker container not running
```

### 6. Clean Up

```bash
# Remove generated files and cache
make clean
```

## 🔧 Configuration

### Environment Variables

Before deployment, ensure your `.env` file contains:

```bash
# Airtable Configuration
AIRTABLE_API_KEY=your_airtable_api_key
AIRTABLE_BASE_ID=your_base_id
AIRTABLE_TABLE_NAME=Pulse Systems Research

# Claude API Configuration
CLAUDE_API_KEY=your_claude_api_key

# Data Source
ELICIT_DATA_URL=https://your-data-source.com/papers.json
```

### Validate Configuration

```bash
make validate-env
```

This will check that all required environment variables are set without running the full pipeline.

## 📊 Output & Results

### Standard Deployment

Results are displayed in the terminal with statistics:

```
Pipeline Execution Complete
--------------------------------------------------------------------------------
✅ Pipeline completed successfully

Statistics:
  Total papers processed: 50
  Successfully categorized: 45
  Skipped (duplicates): 3
  Failed: 2
```

### Deployment with JSON Output

```bash
make deploy-output
```

Creates `results.json` with detailed results:

```json
{
  "status": "completed",
  "statistics": {
    "total": 50,
    "success": 45,
    "skipped": 3,
    "failed": 2
  },
  "results": [...]
}
```

### Autonomous Deployment Output

```bash
make deploy-autonomous
```

Creates `deployment-results.json` and shows a summary:

```
════════════════════════════════════════════════════════════
  ✓ AUTONOMOUS DEPLOYMENT COMPLETE
════════════════════════════════════════════════════════════

Results saved to: deployment-results.json
Summary:
  Total: 50
  Success: 45
  Skipped: 3
  Failed: 2
```

## 🔍 Troubleshooting

### "make: command not found"

Install make:

**Ubuntu/Debian:**
```bash
sudo apt-get install make
```

**macOS:**
```bash
brew install make
```

**Windows:**
Use WSL (Windows Subsystem for Linux) or install via chocolatey:
```bash
choco install make
```

### "Environment validation failed"

Check your `.env` file:

```bash
# Show current configuration status
make status

# Validate specific environment variables
make validate-env
```

Ensure all required variables are set in `.env`.

### "Module not found" errors

Reinstall dependencies:

```bash
make clean
make install
make verify
```

### Docker deployment fails

Check Docker is running:

```bash
docker ps
```

Check `.env` file exists:

```bash
ls -la .env
```

View Docker logs:

```bash
make docker-logs
```

## 🎨 Customization

### Adding Custom Targets

Edit the `Makefile` and add your own targets:

```makefile
my-custom-target: ## My custom deployment
	@echo "Running custom deployment..."
	# Your commands here
```

### Changing Output Files

Modify the target in `Makefile`:

```makefile
deploy-output: validate-env
	python main.py --output my-custom-output.json
```

### Scheduled Deployments

Use cron with the Makefile:

```bash
# Edit crontab
crontab -e

# Add daily deployment at 2 AM
0 2 * * * cd /path/to/pulse-registry-system && make deploy-autonomous >> /var/log/pipeline.log 2>&1
```

## 📚 Integration with CI/CD

### GitHub Actions Example

```yaml
name: Deploy Pipeline

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Create .env file
        run: |
          echo "AIRTABLE_API_KEY=${{ secrets.AIRTABLE_API_KEY }}" >> .env
          echo "AIRTABLE_BASE_ID=${{ secrets.AIRTABLE_BASE_ID }}" >> .env
          echo "CLAUDE_API_KEY=${{ secrets.CLAUDE_API_KEY }}" >> .env
          echo "ELICIT_DATA_URL=${{ secrets.ELICIT_DATA_URL }}" >> .env
      
      - name: Deploy
        run: make deploy-autonomous
      
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: deployment-results
          path: deployment-results.json
```

### GitLab CI Example

```yaml
deploy-pipeline:
  stage: deploy
  script:
    - make deploy-autonomous
  artifacts:
    paths:
      - deployment-results.json
  only:
    - schedules
```

## 🚨 Best Practices

1. **Always run `make verify` before deployment** to catch issues early
2. **Use `make status` to check health** before and after deployment
3. **Review `deployment-results.json`** after each run to monitor success rates
4. **Run `make clean` periodically** to remove old cache and results
5. **Keep `.env` secure** - never commit it to version control
6. **Use `make deploy-autonomous`** for production deployments (most robust)
7. **Test with `make deploy-output`** in development to inspect results

## 📖 Additional Resources

- **PIPELINE_README.md** - Detailed implementation guide
- **MAKECOM_INTEGRATION.md** - No-code automation alternative
- **IMPLEMENTATION_SUMMARY.md** - Complete technical summary
- **verify_setup.py** - Standalone verification script

## 🤝 Support

If you encounter issues:

1. Run `make status` to check system health
2. Run `make verify` to identify problems
3. Check logs in terminal output
4. Review `deployment-results.json` for detailed error information
5. Consult PIPELINE_README.md troubleshooting section

## 🎯 Master Prompt Summary

The **master prompt for autonomous deployment** is:

```bash
make deploy-autonomous
```

This is the recommended way to deploy as it:
- ✅ Handles all dependencies automatically
- ✅ Validates configuration before running
- ✅ Provides detailed progress output
- ✅ Saves comprehensive results
- ✅ Shows summary statistics
- ✅ Returns appropriate exit codes for automation

---

**Quick Reference Card**

```bash
# First time
make deploy-autonomous  # Creates .env template
# Edit .env with your keys
make deploy-autonomous  # Runs full deployment

# Subsequent runs
make deploy-autonomous  # One command deployment

# Check status
make status

# View help
make help
```

---

**Version**: 1.0.0  
**Last Updated**: 2025-11-20
