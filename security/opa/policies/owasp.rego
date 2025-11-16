package owasp

# OWASP Top 10 2021 Compliance Policy
# This policy checks for OWASP Top 10 vulnerabilities

import future.keywords.if
import future.keywords.in

# OWASP Top 10 categories
owasp_categories := {
    "A01": "Broken Access Control",
    "A02": "Cryptographic Failures",
    "A03": "Injection",
    "A04": "Insecure Design",
    "A05": "Security Misconfiguration",
    "A06": "Vulnerable and Outdated Components",
    "A07": "Identification and Authentication Failures",
    "A08": "Software and Data Integrity Failures",
    "A09": "Security Logging and Monitoring Failures",
    "A10": "Server-Side Request Forgery (SSRF)"
}

# Default compliance status
default compliant = false

# Check overall OWASP compliance
compliant if {
    no_a01_broken_access_control
    no_a02_cryptographic_failures
    no_a03_injection
    no_a04_insecure_design
    no_a05_security_misconfiguration
    no_a06_vulnerable_components
    no_a07_auth_failures
    no_a08_integrity_failures
    no_a09_logging_failures
    no_a10_ssrf
}

# A01: Broken Access Control
no_a01_broken_access_control if {
    not has_vulnerability("access-control")
    not has_vulnerability("authorization")
    not has_vulnerability("privilege-escalation")
}

violation[msg] if {
    not no_a01_broken_access_control
    msg := "A01: Broken Access Control vulnerabilities detected"
}

# A02: Cryptographic Failures
no_a02_cryptographic_failures if {
    not has_vulnerability("weak-crypto")
    not has_vulnerability("insecure-hash")
    not has_vulnerability("hardcoded-secret")
    not has_vulnerability("plaintext-storage")
}

violation[msg] if {
    not no_a02_cryptographic_failures
    msg := "A02: Cryptographic Failures detected"
}

# A03: Injection
no_a03_injection if {
    not has_vulnerability("sql-injection")
    not has_vulnerability("command-injection")
    not has_vulnerability("xss")
    not has_vulnerability("ldap-injection")
    not has_vulnerability("xpath-injection")
}

violation[msg] if {
    not no_a03_injection
    msg := "A03: Injection vulnerabilities detected"
}

# A04: Insecure Design
no_a04_insecure_design if {
    has_threat_modeling
    has_secure_design_patterns
    not has_vulnerability("insecure-design")
}

violation[msg] if {
    not no_a04_insecure_design
    msg := "A04: Insecure Design patterns detected"
}

# A05: Security Misconfiguration
no_a05_security_misconfiguration if {
    not has_vulnerability("debug-enabled")
    not has_vulnerability("default-credentials")
    not has_vulnerability("unnecessary-features")
    not has_vulnerability("missing-security-headers")
    security_headers_present
}

violation[msg] if {
    not no_a05_security_misconfiguration
    msg := "A05: Security Misconfiguration detected"
}

# A06: Vulnerable and Outdated Components
no_a06_vulnerable_components if {
    no_outdated_dependencies
    no_vulnerable_dependencies
}

no_outdated_dependencies if {
    count([dep | dep := input.dependencies[_]; dep.outdated == true]) == 0
}

no_vulnerable_dependencies if {
    count([dep | dep := input.dependencies[_]; dep.vulnerabilities > 0]) == 0
}

violation[msg] if {
    not no_a06_vulnerable_components
    msg := "A06: Vulnerable and Outdated Components detected"
}

# A07: Identification and Authentication Failures
no_a07_auth_failures if {
    not has_vulnerability("weak-password")
    not has_vulnerability("session-fixation")
    not has_vulnerability("broken-auth")
    not has_vulnerability("credential-stuffing")
    has_mfa_enabled
}

violation[msg] if {
    not no_a07_auth_failures
    msg := "A07: Identification and Authentication Failures detected"
}

# A08: Software and Data Integrity Failures
no_a08_integrity_failures if {
    not has_vulnerability("insecure-deserialization")
    not has_vulnerability("unsigned-code")
    has_integrity_checks
}

violation[msg] if {
    not no_a08_integrity_failures
    msg := "A08: Software and Data Integrity Failures detected"
}

# A09: Security Logging and Monitoring Failures
no_a09_logging_failures if {
    has_security_logging
    has_monitoring
    not has_vulnerability("insufficient-logging")
}

violation[msg] if {
    not no_a09_logging_failures
    msg := "A09: Security Logging and Monitoring Failures detected"
}

# A10: Server-Side Request Forgery
no_a10_ssrf if {
    not has_vulnerability("ssrf")
    has_url_validation
}

violation[msg] if {
    not no_a10_ssrf
    msg := "A10: Server-Side Request Forgery (SSRF) vulnerabilities detected"
}

# Helper functions
has_vulnerability(vuln_type) if {
    some vuln in input.vulnerabilities
    vuln.type == vuln_type
}

security_headers_present if {
    required_headers := ["X-Frame-Options", "X-Content-Type-Options", "Content-Security-Policy"]
    count([h | h := required_headers[_]; h in input.headers]) == count(required_headers)
}

has_threat_modeling if {
    input.security_practices.threat_modeling == true
}

has_secure_design_patterns if {
    input.security_practices.secure_design == true
}

has_mfa_enabled if {
    input.authentication.mfa_enabled == true
}

has_integrity_checks if {
    input.integrity.checksums_verified == true
}

has_security_logging if {
    input.logging.security_events == true
}

has_monitoring if {
    input.monitoring.enabled == true
}

has_url_validation if {
    input.security_practices.url_validation == true
}

# Compliance score
owasp_compliance_score := score if {
    passed := count([cat | cat := owasp_categories[_]; category_passed(cat)])
    total := count(owasp_categories)
    score := (passed / total) * 100
}

category_passed(category) if {
    category == "A01"
    no_a01_broken_access_control
}

category_passed(category) if {
    category == "A02"
    no_a02_cryptographic_failures
}

category_passed(category) if {
    category == "A03"
    no_a03_injection
}

# Additional categories follow same pattern...
