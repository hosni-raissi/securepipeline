# SecurePipeline Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Developer Workflow                          │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                            Git Push                                  │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         GitLab CI/CD Trigger                         │
└─────────────────────────────────────────────────────────────────────┘
                                   │
        ┌──────────────────────────┴──────────────────────────┐
        ▼                          ▼                          ▼
┌───────────────┐         ┌───────────────┐         ┌───────────────┐
│  BUILD STAGE  │         │  TEST STAGE   │         │  SAST STAGE   │
│               │         │               │         │               │
│ • Compile     │──────▶  │ • Unit Tests  │──────▶  │ • SonarQube   │
│ • Validate    │         │ • Coverage    │         │ • Bandit      │
│               │         │ • Report      │         │ • Safety      │
└───────────────┘         └───────────────┘         └───────────────┘
                                                             │
        ┌────────────────────────────────────────────────────┘
        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         BUILD IMAGE STAGE                            │
│                                                                      │
│  • Docker build with security context                               │
│  • Multi-stage build for minimal footprint                          │
│  • Tag and push to registry                                         │
└─────────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          DAST STAGE                                  │
│                                                                      │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐         │
│  │ Deploy Test  │───▶│ ZAP Baseline │───▶│  ZAP Full    │         │
│  │ Environment  │    │    Scan      │    │   Scan       │         │
│  └──────────────┘    └──────────────┘    └──────────────┘         │
└─────────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     CONTAINER SCAN STAGE                             │
│                                                                      │
│  ┌──────────────┐                    ┌──────────────┐              │
│  │   Trivy FS   │                    │ Trivy Image  │              │
│  │     Scan     │                    │    Scan      │              │
│  └──────────────┘                    └──────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      POLICY CHECK STAGE                              │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ OPA Security │  │ OPA OWASP    │  │ OPA Compliance│            │
│  │   Policies   │  │   Top 10     │  │   Policies    │            │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│                                                                      │
│  ┌─────────────────────────────────────────────────┐               │
│  │        Security Gate Aggregation                │               │
│  │  ✅ All checks passed = Deploy approved        │               │
│  │  ❌ Any check failed = Deploy blocked          │               │
│  └─────────────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
        │
        ├──────────── PASS ─────────┐
        │                            ▼
        │                   ┌───────────────┐
        │                   │    DEPLOY     │
        │                   │   STAGING     │
        │                   └───────────────┘
        │                            │
        │                   ┌────────▼────────┐
        │                   │  Manual Approve │
        │                   └────────┬────────┘
        │                            ▼
        │                   ┌───────────────┐
        │                   │    DEPLOY     │
        │                   │  PRODUCTION   │
        │                   └───────────────┘
        │
        └──────────── FAIL ─────────┐
                                     ▼
                            ┌───────────────┐
                            │ BLOCK DEPLOY  │
                            │ Send Alert    │
                            └───────────────┘
```

## Security Gates Decision Flow

```
                    ┌─────────────────────┐
                    │   Scan Results      │
                    │   Aggregation       │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Quality Gate       │
                    │  Status: ?          │
                    └──────────┬──────────┘
                               │
            ┌──────────────────┼──────────────────┐
            ▼                  ▼                  ▼
    ┌──────────────┐   ┌──────────────┐  ┌──────────────┐
    │ Critical = 0?│   │  High = 0?   │  │ Medium <= 5? │
    └──────┬───────┘   └──────┬───────┘  └──────┬───────┘
           │                  │                  │
           └──────────┬───────┴──────────┬───────┘
                      │                  │
                 NO ──┤                  ├── YES
                      │                  │
                      ▼                  ▼
              ┌──────────────┐   ┌──────────────┐
              │ ❌ BLOCK      │   │ Coverage >80%│
              │ DEPLOYMENT    │   └──────┬───────┘
              └──────────────┘          │
                                   NO ──┤── YES
                                        │
                                        ▼
                                ┌──────────────┐
                                │Security Score│
                                │    >= 80?    │
                                └──────┬───────┘
                                       │
                                  NO ──┤── YES
                                       │
                                       ▼
                               ┌──────────────┐
                               │ ✅ APPROVE   │
                               │ DEPLOYMENT   │
                               └──────────────┘
```

## Component Interaction

```
┌─────────────────────────────────────────────────────────────────────┐
│                       GitLab Runner (Docker)                         │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                     Pipeline Jobs                           │    │
│  │                                                              │    │
│  │  Job 1: Build          Job 2: SAST         Job 3: DAST      │    │
│  │    │                      │                    │            │    │
│  │    ▼                      ▼                    ▼            │    │
│  │  Docker                SonarQube            OWASP ZAP       │    │
│  │  Container             API Call             Container       │    │
│  └────────────────────────────────────────────────────────────┘    │
│         │                      │                    │               │
└─────────┼──────────────────────┼────────────────────┼───────────────┘
          │                      │                    │
          ▼                      ▼                    ▼
  ┌──────────────┐      ┌──────────────┐     ┌──────────────┐
  │   Docker     │      │  SonarQube   │     │  Test App    │
  │   Registry   │      │   Server     │     │  Container   │
  └──────────────┘      └──────────────┘     └──────────────┘
          │                      │                    │
          │              ┌───────▼────────┐          │
          │              │  PostgreSQL    │          │
          │              │   Database     │          │
          │              └────────────────┘          │
          │                                          │
          ▼                                          ▼
  ┌──────────────┐                          ┌──────────────┐
  │    Trivy     │                          │  OWASP ZAP   │
  │  Scanning    │                          │   Scanner    │
  └──────────────┘                          └──────────────┘
          │                                          │
          └──────────────┬───────────────────────────┘
                         │
                         ▼
                 ┌──────────────┐
                 │     OPA      │
                 │ Policy Engine│
                 └──────────────┘
                         │
                         ▼
                 ┌──────────────┐
                 │  Deployment  │
                 │   Decision   │
                 └──────────────┘
```

## Technology Stack Details

### Application Layer
- **Language**: Python 3.11
- **Framework**: Flask 2.3.0
- **Container**: Docker (Alpine-based)

### Security Tools

#### SAST (Static Analysis)
- **SonarQube 10 Community**
  - Code quality analysis
  - Security vulnerability detection
  - Technical debt tracking
  - Code coverage enforcement

- **Bandit**
  - Python-specific security linter
  - Common security issue detection

- **Safety**
  - Dependency vulnerability checking
  - CVE database integration

#### DAST (Dynamic Analysis)
- **OWASP ZAP 2.12+**
  - Baseline scanning (passive)
  - Full scanning (active)
  - API security testing
  - OWASP Top 10 detection

#### Container Security
- **Trivy**
  - Filesystem scanning
  - Image scanning
  - CVE detection
  - SBOM generation
  - Severity-based filtering

#### Policy as Code
- **Open Policy Agent (OPA)**
  - Rego policy language
  - Security policy enforcement
  - OWASP Top 10 compliance
  - Custom compliance rules

### Infrastructure
- **CI/CD**: GitLab CI/CD
- **Container Runtime**: Docker 24+
- **Orchestration**: Docker Compose
- **Registry**: GitLab Container Registry

## Data Flow

```
Developer ──(git push)──▶ GitLab
                           │
                           ▼
                      GitLab Runner
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
    Source Code      Dependencies      Configuration
         │                 │                 │
         ▼                 ▼                 ▼
    SonarQube         Safety Check      OPA Policies
         │                 │                 │
         └─────────────────┼─────────────────┘
                           ▼
                    Security Reports
                           │
                           ▼
                    Aggregated Results
                           │
                           ▼
                     Policy Decision
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
         ✅ Deploy                  ❌ Block
```

## Security Metrics Collection

```
Each Pipeline Run Generates:

├── Code Quality Metrics
│   ├── Coverage percentage
│   ├── Code smells count
│   ├── Technical debt
│   └── Duplications

├── Security Metrics
│   ├── Vulnerability count by severity
│   ├── Security hotspots
│   ├── OWASP Top 10 compliance
│   └── Security score

├── Container Metrics
│   ├── CVE count by severity
│   ├── Outdated packages
│   ├── License compliance
│   └── Base image security

└── Policy Metrics
    ├── Policy violations
    ├── Compliance score
    ├── Deployment approvals
    └── Security gate status
```

## Deployment Environments

```
Development Branch
       │
       ├─── Auto Deploy ───▶ Dev Environment
       │                     (No manual approval)
       │
Develop Branch
       │
       ├─── Auto Deploy ───▶ Staging Environment
       │                     (If all gates pass)
       │
Main Branch
       │
       ├─── Manual Deploy ──▶ Production Environment
                              (Requires approval + all gates pass)
```
