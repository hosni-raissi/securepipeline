# GitLab CI/CD Variables Configuration Guide

## Required Variables

Configure these variables in GitLab: `Settings > CI/CD > Variables`

### SonarQube Configuration
- **SONAR_HOST_URL**: URL of your SonarQube server
  - Example: `https://sonarqube.example.com`
  - For local: `http://sonarqube:9000`
  - Type: Variable
  - Protected: Yes
  - Masked: No

- **SONAR_TOKEN**: SonarQube authentication token
  - Generate at: SonarQube > My Account > Security > Generate Token
  - Type: Variable
  - Protected: Yes
  - Masked: Yes

### Docker Registry Configuration
- **CI_REGISTRY**: Container registry URL
  - Example: `registry.gitlab.com/yourgroup/securepipeline`
  - GitLab Container Registry is used by default
  - Type: Variable
  - Protected: No
  - Masked: No

- **CI_REGISTRY_USER**: Registry username
  - For GitLab: use `$CI_REGISTRY_USER` (predefined)
  - Type: Variable
  - Protected: No
  - Masked: No

- **CI_REGISTRY_PASSWORD**: Registry password/token
  - For GitLab: use `$CI_REGISTRY_PASSWORD` (predefined)
  - Type: Variable
  - Protected: Yes
  - Masked: Yes

### Optional Variables

- **ZAP_TIMEOUT**: OWASP ZAP scan timeout in minutes
  - Default: `60`
  - Type: Variable
  - Protected: No
  - Masked: No

- **MIN_COVERAGE**: Minimum code coverage percentage
  - Default: `80`
  - Type: Variable
  - Protected: No
  - Masked: No

- **MAX_CRITICAL_VULNS**: Maximum allowed critical vulnerabilities
  - Default: `0`
  - Type: Variable
  - Protected: No
  - Masked: No

- **MAX_HIGH_VULNS**: Maximum allowed high severity vulnerabilities
  - Default: `0`
  - Type: Variable
  - Protected: No
  - Masked: No

- **MAX_MEDIUM_VULNS**: Maximum allowed medium severity vulnerabilities
  - Default: `5`
  - Type: Variable
  - Protected: No
  - Masked: No

## GitLab Runner Configuration

### Required Runner Tags
- `docker`: Runner with Docker executor

### Runner Configuration Example

```toml
[[runners]]
  name = "docker-runner"
  url = "https://gitlab.com/"
  token = "your-runner-token"
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = true
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock"]
    shm_size = 0
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
```

## SonarQube Setup

1. Access SonarQube at http://localhost:9000
2. Login with default credentials: `admin/admin`
3. Change the password
4. Create a new project:
   - Project key: `securepipeline`
   - Display name: `SecurePipeline DevSecOps`
5. Generate a token:
   - My Account > Security > Generate Token
   - Name: `gitlab-ci`
   - Copy the token
6. Add the token to GitLab CI/CD variables as `SONAR_TOKEN`

## Docker Registry Setup

### Using GitLab Container Registry

1. Enable Container Registry in your GitLab project:
   - Settings > General > Visibility > Container Registry: Enabled

2. The following variables are automatically available:
   - `$CI_REGISTRY`: Your project's registry URL
   - `$CI_REGISTRY_USER`: CI job user
   - `$CI_REGISTRY_PASSWORD`: CI job token

### Using External Registry (Docker Hub, AWS ECR, etc.)

1. Set `CI_REGISTRY` to your registry URL
2. Set `CI_REGISTRY_USER` to your username
3. Set `CI_REGISTRY_PASSWORD` to your password/token

## Verification

After configuring variables, verify them:

```bash
# In GitLab CI/CD pipeline, add a job to test:
test-variables:
  stage: .pre
  script:
    - echo "SONAR_HOST_URL is set: ${SONAR_HOST_URL:+yes}"
    - echo "SONAR_TOKEN is set: ${SONAR_TOKEN:+yes}"
    - echo "CI_REGISTRY is set: ${CI_REGISTRY:+yes}"
```

## Security Best Practices

1. **Never commit secrets** to the repository
2. **Use masked variables** for sensitive data
3. **Use protected variables** for production deployments
4. **Rotate tokens regularly** (every 90 days recommended)
5. **Limit variable scope** to specific branches/tags when possible
6. **Use GitLab environments** for environment-specific variables

## Troubleshooting

### SonarQube Connection Failed
- Verify `SONAR_HOST_URL` is accessible from GitLab Runner
- Check `SONAR_TOKEN` is valid and not expired
- Ensure SonarQube server is running

### Docker Registry Authentication Failed
- Verify registry credentials are correct
- Check registry URL format
- Ensure Runner has network access to registry

### Pipeline Variables Not Available
- Check variable names match exactly (case-sensitive)
- Verify variables are not set as "protected" if running on non-protected branch
- Ensure variables are not set as "environment-specific" when not needed
