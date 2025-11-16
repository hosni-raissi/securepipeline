#!/bin/bash

# Local testing script for security scans
# Run security tools locally before pushing to GitLab

set -e

echo "=================================================="
echo "Running Local Security Checks"
echo "=================================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Function to print section headers
print_section() {
    echo ""
    echo "=================================================="
    echo "$1"
    echo "=================================================="
}

# Function to check command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 not found. Please install it first.${NC}"
        return 1
    fi
    return 0
}

# 1. Python Linting
print_section "1. Running Python Linting (flake8)"
if check_command flake8; then
    flake8 app/ --max-line-length=120 --exclude=venv,__pycache__ || echo -e "${YELLOW}⚠️  Linting warnings found${NC}"
fi

# 2. Security Linting with Bandit
print_section "2. Running Bandit (Python Security Linter)"
if check_command bandit; then
    bandit -r app/ -ll || echo -e "${YELLOW}⚠️  Security issues found${NC}"
fi

# 3. Dependency Check with Safety
print_section "3. Checking Dependencies (Safety)"
if check_command safety; then
    safety check --file app/requirements.txt || echo -e "${YELLOW}⚠️  Vulnerable dependencies found${NC}"
fi

# 4. Unit Tests
print_section "4. Running Unit Tests"
if check_command pytest; then
    cd app
    pytest tests/ --cov=. --cov-report=term --cov-report=html || echo -e "${RED}❌ Tests failed${NC}"
    cd ..
fi

# 5. Docker Build
print_section "5. Building Docker Image"
if check_command docker; then
    docker build -f docker/Dockerfile -t securepipeline:test . || echo -e "${RED}❌ Docker build failed${NC}"
fi

# 6. Trivy Scan
print_section "6. Running Trivy Container Scan"
if check_command trivy; then
    echo "Scanning filesystem..."
    trivy fs --severity HIGH,CRITICAL app/ || echo -e "${YELLOW}⚠️  Vulnerabilities found${NC}"
    
    echo ""
    echo "Scanning Docker image..."
    trivy image --severity HIGH,CRITICAL securepipeline:test || echo -e "${YELLOW}⚠️  Image vulnerabilities found${NC}"
fi

# 7. OPA Policy Test
print_section "7. Testing OPA Policies"
if check_command opa; then
    opa test security/opa/policies/ -v || echo -e "${YELLOW}⚠️  Policy tests failed${NC}"
    
    # Test with baseline data
    echo ""
    echo "Testing with baseline data..."
    opa eval -d security/opa/policies/security.rego \
             -i security/opa/data/baseline.json \
             "data.security.allow" --format pretty
fi

# 8. Secrets Scan (if gitleaks is available)
print_section "8. Scanning for Secrets"
if check_command gitleaks; then
    gitleaks detect --source . --verbose || echo -e "${YELLOW}⚠️  Potential secrets found${NC}"
else
    echo -e "${YELLOW}⚠️  gitleaks not installed, skipping secrets scan${NC}"
fi

# Summary
print_section "Local Security Check Summary"
echo -e "${GREEN}✅ All local security checks completed${NC}"
echo ""
echo "Next steps:"
echo "  1. Review any warnings or failures above"
echo "  2. Fix security issues before committing"
echo "  3. Commit and push to trigger full GitLab CI/CD pipeline"
echo ""
echo "To run individual checks:"
echo "  - Linting:       flake8 app/"
echo "  - Security:      bandit -r app/"
echo "  - Dependencies:  safety check"
echo "  - Tests:         pytest app/tests/"
echo "  - Trivy:         trivy fs app/"
echo "  - OPA:           opa test security/opa/policies/"
echo ""
