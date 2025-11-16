package security

# Security Policy for SecurePipeline
# This policy enforces security best practices and blocks deployment on violations

import future.keywords.if
import future.keywords.in

# Default deny
default allow = false

# Allow deployment only if all security checks pass
allow if {
    no_critical_vulnerabilities
    no_high_vulnerabilities
    acceptable_medium_vulnerabilities
    no_security_hotspots
    quality_gate_passed
}

# Check for critical vulnerabilities
no_critical_vulnerabilities if {
    count([vuln | vuln := input.vulnerabilities[_]; vuln.severity == "CRITICAL"]) == 0
}

# Check for high vulnerabilities
no_high_vulnerabilities if {
    count([vuln | vuln := input.vulnerabilities[_]; vuln.severity == "HIGH"]) == 0
}

# Allow up to 5 medium vulnerabilities
acceptable_medium_vulnerabilities if {
    medium_count := count([vuln | vuln := input.vulnerabilities[_]; vuln.severity == "MEDIUM"])
    medium_count <= 5
}

# Check for security hotspots
no_security_hotspots if {
    count(input.security_hotspots) == 0
}

# Verify quality gate passed
quality_gate_passed if {
    input.quality_gate.status == "PASSED"
}

# Security score calculation (0-100)
security_score := score if {
    critical := count([vuln | vuln := input.vulnerabilities[_]; vuln.severity == "CRITICAL"])
    high := count([vuln | vuln := input.vulnerabilities[_]; vuln.severity == "HIGH"])
    medium := count([vuln | vuln := input.vulnerabilities[_]; vuln.severity == "MEDIUM"])
    low := count([vuln | vuln := input.vulnerabilities[_]; vuln.severity == "LOW"])
    
    # Weighted scoring
    deductions := (critical * 25) + (high * 10) + (medium * 3) + (low * 1)
    score := max([0, 100 - deductions])
}

# Minimum required score
minimum_score := 80

score_acceptable if {
    security_score >= minimum_score
}

# Block on failed security checks
violation[msg] if {
    not no_critical_vulnerabilities
    msg := "CRITICAL vulnerabilities detected - deployment blocked"
}

violation[msg] if {
    not no_high_vulnerabilities
    msg := "HIGH severity vulnerabilities detected - deployment blocked"
}

violation[msg] if {
    not acceptable_medium_vulnerabilities
    msg := "Too many MEDIUM severity vulnerabilities - deployment blocked"
}

violation[msg] if {
    not quality_gate_passed
    msg := "Quality gate failed - deployment blocked"
}

violation[msg] if {
    not score_acceptable
    msg := sprintf("Security score %d below minimum threshold %d - deployment blocked", [security_score, minimum_score])
}

# Secrets detection
secrets_detected if {
    count(input.secrets) > 0
}

violation[msg] if {
    secrets_detected
    msg := "Secrets detected in code - deployment blocked"
}

# License compliance
approved_licenses := [
    "MIT",
    "Apache-2.0",
    "BSD-3-Clause",
    "BSD-2-Clause",
    "ISC",
    "GPL-3.0"
]

unapproved_license if {
    some license in input.licenses
    not license in approved_licenses
}

violation[msg] if {
    unapproved_license
    msg := "Unapproved license detected - deployment blocked"
}
