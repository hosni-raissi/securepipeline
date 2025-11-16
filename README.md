# SecurePipeline - DevSecOps Shift-Left Pipeline

## 🎯 Overview

A comprehensive DevSecOps pipeline implementing security-first practices with automated security gates and compliance checks. This pipeline blocks deployment automatically if OWASP Top 10 vulnerabilities or policy violations are detected.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitLab CI/CD Pipeline                        │
├─────────────────────────────────────────────────────────────────┤
│  Build → SAST → DAST → Container Scan → Policy Check → Deploy  │
└─────────────────────────────────────────────────────────────────┘

Stage 1: BUILD
├── Build application
└── Run unit tests

Stage 2: SAST (Static Application Security Testing)
├── SonarQube Scanner
├── Code quality analysis
├── Security hotspot detection
└── Quality Gate enforcement

Stage 3: DAST (Dynamic Application Security Testing)
├── Deploy test environment
├── OWASP ZAP baseline scan
├── OWASP ZAP full scan
└── Vulnerability reporting

Stage 4: CONTAINER SCANNING
├── Trivy filesystem scan
├── Trivy image scan
├── CVE detection
└── Severity-based blocking

Stage 5: POLICY AS CODE
├── OPA policy evaluation
├── OWASP Top 10 compliance
├── Security baseline checks
└── Deployment approval

Stage 6: DEPLOY
└── Conditional deployment (only if all gates pass)
```

## 🛠️ Technologies

- **GitLab CI/CD**: Orchestration platform
- **SonarQube**: Static code analysis (SAST)
- **OWASP ZAP**: Dynamic security testing (DAST)
- **Trivy**: Container vulnerability scanning
- **OPA (Open Policy Agent)**: Policy-as-code enforcement
- **Docker**: Containerization
- **Python/Flask**: Demo application

## 📁 Project Structure

```
SecurePipeline/
├── app/
│   ├── main.py                 # Flask application
│   ├── requirements.txt        # Python dependencies
│   └── tests/                  # Unit tests
├── docker/
│   ├── Dockerfile              # Application container
│   └── docker-compose.yml      # Multi-service setup
├── security/
│   ├── sonarqube/
│   │   ├── sonar-project.properties
│   │   └── quality-gate.json
│   ├── zap/
│   │   ├── zap-baseline.conf
│   │   ├── zap-full-scan.conf
│   │   └── rules.tsv
│   ├── trivy/
│   │   └── trivy.yaml
│   └── opa/
│       ├── policies/
│       │   ├── security.rego
│       │   ├── owasp.rego
│       │   └── compliance.rego
│       └── data/
│           └── baseline.json
├── .gitlab-ci.yml              # CI/CD pipeline
├── .gitignore
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- GitLab instance (self-hosted or GitLab.com)
- SonarQube server (or SonarCloud)
- Docker and Docker Compose
- GitLab Runner with Docker executor

### Setup

1. **Clone the repository**
```bash
git clone <your-repo-url>
cd SecurePipeline
```

2. **Configure GitLab CI/CD Variables**

Navigate to Settings > CI/CD > Variables and add:

| Variable | Description | Required |
|----------|-------------|----------|
| `SONAR_HOST_URL` | SonarQube server URL | Yes |
| `SONAR_TOKEN` | SonarQube authentication token | Yes |
| `DOCKER_REGISTRY` | Container registry URL | Yes |
| `DOCKER_REGISTRY_USER` | Registry username | Yes |
| `DOCKER_REGISTRY_PASSWORD` | Registry password | Yes |
| `DEPLOY_TOKEN` | Deployment authentication | Optional |

3. **Run locally with Docker Compose**
```bash
docker-compose up -d
```

4. **Access services**
- Application: http://localhost:5000
- SonarQube: http://localhost:9000
- OWASP ZAP: http://localhost:8080

## 🔒 Security Features

### SAST (SonarQube)
- **Code quality analysis**: Detects bugs, code smells, and vulnerabilities
- **Security hotspots**: Identifies security-sensitive code
- **Quality gates**: Automatic blocking on quality/security failures
- **Coverage tracking**: Enforces minimum code coverage (80%)

### DAST (OWASP ZAP)
- **Baseline scan**: Quick security check for common issues
- **Full scan**: Comprehensive active scanning for vulnerabilities
- **OWASP Top 10 detection**: Specifically targets critical web vulnerabilities
- **API scanning**: Tests REST endpoints

### Container Security (Trivy)
- **Filesystem scanning**: Checks dependencies and packages
- **Image scanning**: Analyzes Docker images for CVEs
- **Severity filtering**: Blocks on HIGH/CRITICAL vulnerabilities
- **SBOM generation**: Creates software bill of materials

### Policy as Code (OPA)
- **Security policies**: Enforces security best practices
- **OWASP compliance**: Validates against OWASP Top 10
- **Custom rules**: Organization-specific policies
- **Automated decisions**: Blocks non-compliant deployments

## 🔐 OWASP Top 10 Coverage

| # | Vulnerability | Detection Method | Blocking |
|---|---------------|------------------|----------|
| A01 | Broken Access Control | ZAP + OPA | ✅ |
| A02 | Cryptographic Failures | SonarQube + ZAP | ✅ |
| A03 | Injection | SonarQube + ZAP | ✅ |
| A04 | Insecure Design | SonarQube + OPA | ✅ |
| A05 | Security Misconfiguration | ZAP + Trivy + OPA | ✅ |
| A06 | Vulnerable Components | Trivy + SonarQube | ✅ |
| A07 | Authentication Failures | ZAP + SonarQube | ✅ |
| A08 | Software/Data Integrity | Trivy + OPA | ✅ |
| A09 | Security Logging Failures | SonarQube + OPA | ✅ |
| A10 | SSRF | ZAP + SonarQube | ✅ |

## 📊 Pipeline Stages

### 1. Build & Test
```yaml
- Compile application
- Run unit tests
- Generate test coverage
```

### 2. SAST Analysis
```yaml
- SonarQube scan
- Quality gate check
- Fail on: Coverage < 80%, Security issues
```

### 3. DAST Testing
```yaml
- Deploy to test environment
- ZAP baseline scan
- ZAP full scan (if baseline passes)
- Fail on: High/Critical vulnerabilities
```

### 4. Container Scanning
```yaml
- Trivy filesystem scan
- Build Docker image
- Trivy image scan
- Fail on: HIGH/CRITICAL CVEs
```

### 5. Policy Validation
```yaml
- OPA policy evaluation
- OWASP Top 10 compliance
- Security baseline checks
- Fail on: Policy violations
```

### 6. Deployment
```yaml
- Deploy only if all gates pass
- Automatic rollback on failure
```

## 🧪 Testing the Pipeline

### Test with vulnerabilities
```bash
# The demo app includes intentional vulnerabilities
git push origin main
# Watch the pipeline fail at security gates
```

### Test with fixes
```bash
# Apply security patches
./scripts/apply-security-fixes.sh
git push origin secure-branch
# Watch the pipeline succeed
```

## 📈 Metrics & Reporting

- **SonarQube Dashboard**: Code quality and security trends
- **ZAP Reports**: HTML/JSON vulnerability reports
- **Trivy Reports**: JSON/SARIF format for CVE tracking
- **OPA Decisions**: Policy evaluation logs
- **GitLab Security Dashboard**: Unified security view

## 🔧 Configuration

### Customizing Security Policies

Edit `security/opa/policies/security.rego` to modify security rules:

```rego
package security

# Customize severity thresholds
max_high_vulnerabilities = 0
max_medium_vulnerabilities = 5
```

### Adjusting Quality Gates

Edit `security/sonarqube/quality-gate.json` to change thresholds:

```json
{
  "coverage": 80,
  "duplications": 3,
  "security_rating": "A"
}
```

## 🐛 Troubleshooting

### Pipeline fails at SonarQube stage
- Check `SONAR_HOST_URL` and `SONAR_TOKEN` variables
- Verify SonarQube server is accessible
- Review SonarQube logs

### ZAP scan timeout
- Increase `ZAP_TIMEOUT` variable
- Use baseline scan for faster feedback
- Check application is properly deployed

### Trivy scanning errors
- Update Trivy database: `trivy image --download-db-only`
- Check internet connectivity for CVE database
- Verify Docker daemon is running

### OPA policy failures
- Review policy evaluation logs
- Test policies locally: `opa eval -d policies/ -i input.json`
- Validate Rego syntax

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure all security gates pass
5. Submit a pull request

## 📝 License

MIT License - See LICENSE file for details

## 📚 Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [OPA Documentation](https://www.openpolicyagent.org/docs/)

## 👥 Authors

SecurePipeline DevSecOps Team

## 🔄 Version

1.0.0 - Initial Release (November 2025)
# securepipeline
