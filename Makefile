.PHONY: help install verify setup deploy deploy-docker deploy-autonomous clean test lint format

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Autonomous Research Pipeline - Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Master Prompt for Autonomous Deployment:$(NC)"
	@echo "  make deploy-autonomous"

install: ## Install Python dependencies
	@echo "$(BLUE)Installing dependencies...$(NC)"
	pip install -r requirements.txt
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

verify: ## Verify setup and environment
	@echo "$(BLUE)Verifying setup...$(NC)"
	python verify_setup.py
	@echo "$(GREEN)✓ Verification complete$(NC)"

setup: install ## Complete setup (install + create .env from example)
	@echo "$(BLUE)Setting up environment...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(YELLOW)⚠ Created .env file from .env.example$(NC)"; \
		echo "$(YELLOW)⚠ Please edit .env with your API keys before deploying$(NC)"; \
	else \
		echo "$(GREEN)✓ .env file already exists$(NC)"; \
	fi
	@echo "$(GREEN)✓ Setup complete$(NC)"

validate-env: ## Validate environment variables are set
	@echo "$(BLUE)Validating environment variables...$(NC)"
	@python main.py --validate-only || (echo "$(RED)✗ Environment validation failed$(NC)" && exit 1)
	@echo "$(GREEN)✓ Environment validation passed$(NC)"

deploy: validate-env ## Deploy the pipeline (Python mode)
	@echo "$(BLUE)Deploying autonomous research pipeline...$(NC)"
	python main.py
	@echo "$(GREEN)✓ Pipeline execution complete$(NC)"

deploy-output: validate-env ## Deploy and save output to results.json
	@echo "$(BLUE)Deploying pipeline with JSON output...$(NC)"
	python main.py --output results.json
	@echo "$(GREEN)✓ Results saved to results.json$(NC)"

deploy-docker: ## Deploy using Docker Compose
	@echo "$(BLUE)Deploying with Docker...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(RED)✗ .env file not found$(NC)"; \
		echo "$(YELLOW)Run 'make setup' first$(NC)"; \
		exit 1; \
	fi
	docker-compose up -d
	@echo "$(GREEN)✓ Docker deployment started$(NC)"
	@echo "$(YELLOW)View logs with: docker-compose logs -f$(NC)"

deploy-autonomous: ## 🚀 Master Prompt - Autonomous deployment with all checks
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)  AUTONOMOUS DEPLOYMENT - Master Prompt Execution$(NC)"
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(BLUE)Step 1: Installing dependencies...$(NC)"
	@$(MAKE) install
	@echo ""
	@echo "$(BLUE)Step 2: Verifying setup...$(NC)"
	@$(MAKE) verify
	@echo ""
	@echo "$(BLUE)Step 3: Validating environment...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(RED)✗ .env file not found$(NC)"; \
		echo "$(YELLOW)Creating .env from template...$(NC)"; \
		cp .env.example .env; \
		echo "$(YELLOW)⚠ CRITICAL: You must edit .env with your API keys$(NC)"; \
		echo "$(YELLOW)⚠ Required variables:$(NC)"; \
		echo "  - AIRTABLE_API_KEY"; \
		echo "  - AIRTABLE_BASE_ID"; \
		echo "  - CLAUDE_API_KEY"; \
		echo "  - ELICIT_DATA_URL"; \
		echo "$(YELLOW)Run 'make deploy-autonomous' again after configuring .env$(NC)"; \
		exit 1; \
	fi
	@python main.py --validate-only || (echo "$(RED)✗ Environment validation failed$(NC)" && exit 1)
	@echo ""
	@echo "$(BLUE)Step 4: Executing pipeline...$(NC)"
	@python main.py --output deployment-results.json
	@echo ""
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)  ✓ AUTONOMOUS DEPLOYMENT COMPLETE$(NC)"
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Results saved to: deployment-results.json$(NC)"
	@if [ -f deployment-results.json ]; then \
		echo "$(BLUE)Summary:$(NC)"; \
		python -c "import json; r=json.load(open('deployment-results.json')); print(f\"  Total: {r.get('statistics',{}).get('total',0)}\"); print(f\"  Success: {r.get('statistics',{}).get('success',0)}\"); print(f\"  Skipped: {r.get('statistics',{}).get('skipped',0)}\"); print(f\"  Failed: {r.get('statistics',{}).get('failed',0)}\")"; \
	fi

docker-build: ## Build Docker image
	@echo "$(BLUE)Building Docker image...$(NC)"
	docker build -t research-pipeline .
	@echo "$(GREEN)✓ Docker image built$(NC)"

docker-logs: ## Show Docker container logs
	@echo "$(BLUE)Showing container logs...$(NC)"
	docker-compose logs -f

docker-stop: ## Stop Docker containers
	@echo "$(BLUE)Stopping Docker containers...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

clean: ## Clean up generated files and cache
	@echo "$(BLUE)Cleaning up...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type f -name "*.pyo" -delete 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -f deployment-results.json results.json 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

test: install ## Run integration tests
	@echo "$(BLUE)Running tests...$(NC)"
	python verify_setup.py
	@echo "$(GREEN)✓ Tests passed$(NC)"

lint: ## Check code style (requires pylint, flake8)
	@echo "$(BLUE)Linting code...$(NC)"
	@which pylint > /dev/null 2>&1 && pylint *.py || echo "$(YELLOW)pylint not installed, skipping$(NC)"
	@which flake8 > /dev/null 2>&1 && flake8 *.py --max-line-length=120 || echo "$(YELLOW)flake8 not installed, skipping$(NC)"

format: ## Format code (requires black)
	@echo "$(BLUE)Formatting code...$(NC)"
	@which black > /dev/null 2>&1 && black *.py || echo "$(YELLOW)black not installed, skipping$(NC)"
	@echo "$(GREEN)✓ Code formatted$(NC)"

status: ## Show deployment status and health
	@echo "$(BLUE)Deployment Status:$(NC)"
	@echo ""
	@if [ -f .env ]; then \
		echo "  $(GREEN)✓$(NC) Environment configured"; \
	else \
		echo "  $(RED)✗$(NC) Environment not configured"; \
	fi
	@python -c "import importlib.util; print('  $(GREEN)✓$(NC) Python dependencies' if all(importlib.util.find_spec(m) for m in ['requests', 'pyairtable', 'pydantic', 'dotenv']) else '  $(RED)✗$(NC) Python dependencies')"
	@if [ -f deployment-results.json ]; then \
		echo "  $(GREEN)✓$(NC) Previous deployment results available"; \
	else \
		echo "  $(YELLOW)⚠$(NC) No previous deployment results"; \
	fi
	@docker ps --filter name=autonomous-research-pipeline --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | grep -q autonomous && echo "  $(GREEN)✓$(NC) Docker container running" || echo "  $(YELLOW)⚠$(NC) Docker container not running"

# Quick deployment aliases
quick-deploy: deploy-autonomous ## Alias for deploy-autonomous
auto-deploy: deploy-autonomous ## Alias for deploy-autonomous
run: deploy ## Alias for deploy

# Development helpers
dev-setup: setup verify ## Setup for development
	@echo "$(GREEN)✓ Development environment ready$(NC)"

dev-test: test lint ## Run tests and linting
	@echo "$(GREEN)✓ Development checks passed$(NC)"
