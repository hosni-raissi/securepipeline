#!/bin/bash

# Setup script for SecurePipeline DevSecOps project

set -e

echo "=================================================="
echo "SecurePipeline - DevSecOps Setup"
echo "=================================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting." >&2; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose is required but not installed. Aborting." >&2; exit 1; }

echo "✅ Docker installed"
echo "✅ Docker Compose installed"
echo ""

# Create necessary directories
echo "Creating directories..."
mkdir -p {zap-reports,trivy-reports,sonar-reports,ci-artifacts}
echo "✅ Directories created"
echo ""

# Start services with Docker Compose
echo "Starting services with Docker Compose..."
cd docker
docker-compose up -d

echo ""
echo "Waiting for services to be ready..."
sleep 30

# Check service status
echo ""
echo "Service Status:"
docker-compose ps

echo ""
echo "=================================================="
echo "✅ Setup Complete!"
echo "=================================================="
echo ""
echo "Services available at:"
echo "  - Application:  http://localhost:5000"
echo "  - SonarQube:    http://localhost:9000 (admin/admin)"
echo "  - OWASP ZAP:    http://localhost:8080"
echo "  - OPA:          http://localhost:8181"
echo ""
echo "Next steps:"
echo "  1. Configure SonarQube at http://localhost:9000"
echo "  2. Create a SonarQube token"
echo "  3. Add GitLab CI/CD variables:"
echo "     - SONAR_HOST_URL=http://sonarqube:9000"
echo "     - SONAR_TOKEN=<your-token>"
echo "     - DOCKER_REGISTRY=<your-registry>"
echo "     - DOCKER_REGISTRY_USER=<username>"
echo "     - DOCKER_REGISTRY_PASSWORD=<password>"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f [service-name]"
echo ""
echo "To stop services:"
echo "  docker-compose down"
echo ""
