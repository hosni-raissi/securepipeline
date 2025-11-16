package compliance

# Compliance Policy for SecurePipeline
# Enforces organizational security and compliance requirements

import future.keywords.if
import future.keywords.in

# Default compliance status
default compliant = false

# Overall compliance check
compliant if {
    docker_compliance
    code_compliance
    deployment_compliance
}

# Docker/Container Compliance
docker_compliance if {
    runs_as_non_root
    no_privileged_containers
    minimal_base_image
    security_scanning_enabled
}

# Check if container runs as non-root
runs_as_non_root if {
    input.docker.user != "root"
    input.docker.user != "0"
}

violation[msg] if {
    not runs_as_non_root
    msg := "Container must not run as root user"
}

# Check for privileged containers
no_privileged_containers if {
    input.docker.privileged == false
}

violation[msg] if {
    not no_privileged_containers
    msg := "Privileged containers are not allowed"
}

# Verify minimal base image
minimal_base_image if {
    approved_images := ["alpine", "distroless", "scratch", "slim"]
    some approved in approved_images
    contains(lower(input.docker.base_image), approved)
}

violation[msg] if {
    not minimal_base_image
    msg := "Must use minimal base image (alpine, distroless, slim)"
}

# Security scanning enabled
security_scanning_enabled if {
    input.security.trivy_scan == true
}

violation[msg] if {
    not security_scanning_enabled
    msg := "Container security scanning must be enabled"
}

# Code Compliance
code_compliance if {
    code_coverage_acceptable
    no_code_smells_critical
    technical_debt_acceptable
}

# Code coverage threshold
code_coverage_acceptable if {
    input.sonarqube.coverage >= 80
}

violation[msg] if {
    not code_coverage_acceptable
    coverage := input.sonarqube.coverage
    msg := sprintf("Code coverage %d%% below required 80%%", [coverage])
}

# Critical code smells
no_code_smells_critical if {
    input.sonarqube.code_smells_critical == 0
}

violation[msg] if {
    not no_code_smells_critical
    msg := "Critical code smells detected"
}

# Technical debt
technical_debt_acceptable if {
    input.sonarqube.technical_debt_days <= 5
}

violation[msg] if {
    not technical_debt_acceptable
    debt := input.sonarqube.technical_debt_days
    msg := sprintf("Technical debt %d days exceeds limit of 5 days", [debt])
}

# Deployment Compliance
deployment_compliance if {
    environment_approved
    change_management_approved
    rollback_plan_exists
}

# Environment approval
environment_approved if {
    input.deployment.environment in ["development", "staging", "production"]
    environment_requirements_met
}

environment_requirements_met if {
    input.deployment.environment == "production"
    all_gates_passed
}

environment_requirements_met if {
    input.deployment.environment != "production"
}

all_gates_passed if {
    input.gates.sast_passed == true
    input.gates.dast_passed == true
    input.gates.container_scan_passed == true
}

violation[msg] if {
    not environment_approved
    msg := "Environment not approved or requirements not met"
}

# Change management
change_management_approved if {
    input.deployment.environment == "production"
    input.deployment.change_ticket != ""
    input.deployment.approver != ""
}

change_management_approved if {
    input.deployment.environment != "production"
}

violation[msg] if {
    not change_management_approved
    msg := "Production deployment requires change ticket and approver"
}

# Rollback plan
rollback_plan_exists if {
    input.deployment.rollback_plan == true
}

violation[msg] if {
    not rollback_plan_exists
    msg := "Deployment rollback plan required"
}

# Network security compliance
network_security if {
    no_public_ips
    firewall_enabled
    encrypted_traffic
}

no_public_ips if {
    count(input.network.public_ips) == 0
}

firewall_enabled if {
    input.network.firewall == true
}

encrypted_traffic if {
    input.network.tls_enabled == true
    input.network.tls_version >= 1.2
}

violation[msg] if {
    not network_security
    msg := "Network security requirements not met"
}

# Data protection compliance
data_protection if {
    encryption_at_rest
    encryption_in_transit
    no_sensitive_data_in_logs
}

encryption_at_rest if {
    input.data.encryption_at_rest == true
}

encryption_in_transit if {
    input.data.encryption_in_transit == true
}

no_sensitive_data_in_logs if {
    input.data.sensitive_in_logs == false
}

violation[msg] if {
    not data_protection
    msg := "Data protection requirements not met"
}

# Compliance score
compliance_score := score if {
    checks := [
        docker_compliance,
        code_compliance,
        deployment_compliance,
        network_security,
        data_protection
    ]
    passed := count([c | c := checks[_]; c == true])
    total := count(checks)
    score := (passed / total) * 100
}

# Minimum compliance score
minimum_compliance_score := 100

compliance_score_met if {
    compliance_score >= minimum_compliance_score
}

violation[msg] if {
    not compliance_score_met
    msg := sprintf("Compliance score %d%% below required %d%%", [compliance_score, minimum_compliance_score])
}
