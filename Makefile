.PHONY: help setup start stop clean test security-check build deploy-local

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo '$(BLUE)SecurePipeline - DevSecOps Project$(NC)'
	@echo ''
	@echo '$(GREEN)Available commands:$(NC)'
	@echo ''
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ''

setup: ## Initial project setup
	@echo '$(GREEN)Setting up SecurePipeline...$(NC)'
	@chmod +x scripts/*.sh
	@bash scripts/setup.sh

start: ## Start all services with Docker Compose
	@echo '$(GREEN)Starting services...$(NC)'
	@cd docker && docker-compose up -d
	@echo '$(GREEN)Services started successfully!$(NC)'
	@echo ''
	@echo 'Services available at:'
	@echo '  - Application:  http://localhost:5000'
	@echo '  - SonarQube:    http://localhost:9000'
	@echo '  - OWASP ZAP:    http://localhost:8080'
	@echo '  - OPA:          http://localhost:8181'

stop: ## Stop all services
	@echo '$(YELLOW)Stopping services...$(NC)'
	@cd docker && docker-compose down
	@echo '$(GREEN)Services stopped.$(NC)'

logs: ## View logs from all services
	@cd docker && docker-compose logs -f

status: ## Show status of all services
	@cd docker && docker-compose ps

restart: stop start ## Restart all services

clean: ## Clean up containers, images, and artifacts
	@echo '$(YELLOW)Cleaning up...$(NC)'
	@cd docker && docker-compose down -v --remove-orphans
	@rm -rf zap-reports/ trivy-reports/ sonar-reports/ ci-artifacts/
	@rm -rf htmlcov/ .coverage coverage.xml
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo '$(GREEN)Cleanup completed.$(NC)'

install-deps: ## Install Python dependencies
	@echo '$(GREEN)Installing Python dependencies...$(NC)'
	@pip install -r app/requirements.txt
	@pip install pytest pytest-cov pytest-flask bandit safety flake8 pylint

test: ## Run unit tests
	@echo '$(GREEN)Running unit tests...$(NC)'
	@cd app && pytest tests/ --cov=. --cov-report=term --cov-report=html

test-verbose: ## Run unit tests with verbose output
	@echo '$(GREEN)Running unit tests (verbose)...$(NC)'
	@cd app && pytest tests/ -v --cov=. --cov-report=term --cov-report=html

coverage: test ## Generate coverage report and open in browser
	@echo '$(GREEN)Opening coverage report...$(NC)'
	@xdg-open htmlcov/index.html 2>/dev/null || open htmlcov/index.html 2>/dev/null || echo 'Please open htmlcov/index.html manually'

security-check: ## Run local security checks
	@echo '$(GREEN)Running security checks...$(NC)'
	@bash scripts/local-security-check.sh

lint: ## Run code linting
	@echo '$(GREEN)Running linters...$(NC)'
	@flake8 app/ --max-line-length=120 --exclude=venv,__pycache__
	@pylint app/*.py --disable=C0111,C0103

bandit: ## Run Bandit security linter
	@echo '$(GREEN)Running Bandit security linter...$(NC)'
	@bandit -r app/ -ll

safety: ## Check dependencies for vulnerabilities
	@echo '$(GREEN)Checking dependencies...$(NC)'
	@safety check --file app/requirements.txt

build: ## Build Docker image
	@echo '$(GREEN)Building Docker image...$(NC)'
	@docker build -f docker/Dockerfile -t securepipeline:latest .
	@echo '$(GREEN)Image built successfully: securepipeline:latest$(NC)'

build-no-cache: ## Build Docker image without cache
	@echo '$(GREEN)Building Docker image (no cache)...$(NC)'
	@docker build --no-cache -f docker/Dockerfile -t securepipeline:latest .

run-app: ## Run the application locally (without Docker)
	@echo '$(GREEN)Starting Flask application...$(NC)'
	@cd app && python main.py

run-docker: build ## Run the application in Docker
	@echo '$(GREEN)Running application in Docker...$(NC)'
	@docker run -d --name securepipeline-app -p 5000:5000 securepipeline:latest
	@echo '$(GREEN)Application running at http://localhost:5000$(NC)'

stop-docker: ## Stop the Docker container
	@docker stop securepipeline-app 2>/dev/null || true
	@docker rm securepipeline-app 2>/dev/null || true

trivy-scan: build ## Scan Docker image with Trivy
	@echo '$(GREEN)Scanning image with Trivy...$(NC)'
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy:latest image --severity HIGH,CRITICAL securepipeline:latest

trivy-fs: ## Scan filesystem with Trivy
	@echo '$(GREEN)Scanning filesystem with Trivy...$(NC)'
	@docker run --rm -v $(PWD):/app aquasec/trivy:latest fs --severity HIGH,CRITICAL /app/app

opa-test: ## Test OPA policies
	@echo '$(GREEN)Testing OPA policies...$(NC)'
	@docker run --rm -v $(PWD)/security/opa/policies:/policies \
		openpolicyagent/opa:latest test /policies -v

opa-eval: ## Evaluate OPA policies with baseline data
	@echo '$(GREEN)Evaluating OPA policies...$(NC)'
	@docker run --rm \
		-v $(PWD)/security/opa/policies:/policies \
		-v $(PWD)/security/opa/data:/data \
		openpolicyagent/opa:latest eval \
		-d /policies/security.rego \
		-i /data/baseline.json \
		"data.security.allow" --format pretty

sonar-scan: ## Run SonarQube scan locally
	@echo '$(GREEN)Running SonarQube scan...$(NC)'
	@docker run --rm \
		-e SONAR_HOST_URL=http://localhost:9000 \
		-e SONAR_TOKEN=${SONAR_TOKEN} \
		-v $(PWD):/usr/src \
		sonarsource/sonar-scanner-cli

deploy-local: build ## Deploy application locally with all security services
	@echo '$(GREEN)Deploying complete stack locally...$(NC)'
	@cd docker && docker-compose up -d
	@echo ''
	@echo '$(GREEN)Deployment complete!$(NC)'
	@echo ''
	@echo 'Access services at:'
	@echo '  - Application:  http://localhost:5000'
	@echo '  - SonarQube:    http://localhost:9000 (admin/admin)'
	@echo '  - OWASP ZAP:    http://localhost:8080'
	@echo '  - OPA:          http://localhost:8181'

validate-pipeline: ## Validate GitLab CI pipeline syntax
	@echo '$(GREEN)Validating GitLab CI pipeline...$(NC)'
	@command -v gitlab-ci-lint >/dev/null 2>&1 || { echo "$(RED)gitlab-ci-lint not installed$(NC)"; exit 1; }
	@gitlab-ci-lint .gitlab-ci.yml

docs: ## Generate documentation
	@echo '$(GREEN)Documentation available:$(NC)'
	@echo '  - README.md'
	@echo '  - docs/ARCHITECTURE.md'
	@echo '  - docs/GITLAB_VARIABLES.md'
	@echo '  - SECURITY.md'

git-hooks: ## Install git hooks
	@echo '$(GREEN)Installing git hooks...$(NC)'
	@echo '#!/bin/bash' > .git/hooks/pre-commit
	@echo 'make security-check' >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo '$(GREEN)Pre-commit hook installed.$(NC)'

init: setup install-deps git-hooks ## Complete project initialization
	@echo ''
	@echo '$(GREEN)✅ Project initialized successfully!$(NC)'
	@echo ''
	@echo 'Next steps:'
	@echo '  1. make start          # Start all services'
	@echo '  2. make test           # Run tests'
	@echo '  3. make security-check # Run security scans'
	@echo ''
