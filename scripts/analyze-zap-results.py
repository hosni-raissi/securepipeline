#!/usr/bin/env python3
"""
Analyze OWASP ZAP scan results and fail the build if critical issues are found
"""

import json
import sys
from typing import Dict, List

# OWASP Top 10 Risk Levels
OWASP_RISK_LEVELS = {
    "3": "High",
    "2": "Medium",
    "1": "Low",
    "0": "Informational"
}

def analyze_zap_results(report_file: str) -> Dict:
    """Analyze ZAP JSON report"""
    
    with open(report_file, 'r') as f:
        data = json.load(f)
    
    site = data.get('site', [{}])[0]
    alerts = site.get('alerts', [])
    
    results = {
        "high": [],
        "medium": [],
        "low": [],
        "info": []
    }
    
    for alert in alerts:
        risk = alert.get('riskdesc', '').split()[0].lower()
        
        alert_info = {
            "name": alert.get('name'),
            "risk": alert.get('riskdesc'),
            "confidence": alert.get('confidence'),
            "cweid": alert.get('cweid'),
            "wascid": alert.get('wascid'),
            "description": alert.get('desc'),
            "solution": alert.get('solution'),
            "instances": len(alert.get('instances', []))
        }
        
        if risk == 'high':
            results['high'].append(alert_info)
        elif risk == 'medium':
            results['medium'].append(alert_info)
        elif risk == 'low':
            results['low'].append(alert_info)
        else:
            results['info'].append(alert_info)
    
    return results

def print_results(results: Dict):
    """Print formatted results"""
    
    print("\n" + "="*80)
    print("OWASP ZAP Security Scan Results")
    print("="*80 + "\n")
    
    # Summary
    print(f"🔴 High Risk Issues: {len(results['high'])}")
    print(f"🟡 Medium Risk Issues: {len(results['medium'])}")
    print(f"🟢 Low Risk Issues: {len(results['low'])}")
    print(f"ℹ️  Informational: {len(results['info'])}\n")
    
    # High Risk Details
    if results['high']:
        print("="*80)
        print("🔴 HIGH RISK VULNERABILITIES (CRITICAL)")
        print("="*80)
        for i, alert in enumerate(results['high'], 1):
            print(f"\n{i}. {alert['name']}")
            print(f"   Risk: {alert['risk']}")
            print(f"   Confidence: {alert['confidence']}")
            print(f"   CWE: {alert['cweid']}")
            print(f"   WASC: {alert['wascid']}")
            print(f"   Instances: {alert['instances']}")
            print(f"   Description: {alert['description'][:200]}...")
            print(f"   Solution: {alert['solution'][:200]}...")
    
    # Medium Risk Details
    if results['medium']:
        print("\n" + "="*80)
        print("🟡 MEDIUM RISK VULNERABILITIES")
        print("="*80)
        for i, alert in enumerate(results['medium'], 1):
            print(f"\n{i}. {alert['name']}")
            print(f"   Risk: {alert['risk']}")
            print(f"   CWE: {alert['cweid']}")
            print(f"   Instances: {alert['instances']}")

def check_thresholds(results: Dict, max_high: int = 0, max_medium: int = 5) -> bool:
    """Check if results exceed thresholds"""
    
    high_count = len(results['high'])
    medium_count = len(results['medium'])
    
    print("\n" + "="*80)
    print("THRESHOLD CHECK")
    print("="*80)
    print(f"High Risk Issues: {high_count} / {max_high} allowed")
    print(f"Medium Risk Issues: {medium_count} / {max_medium} allowed")
    
    if high_count > max_high:
        print(f"\n❌ FAILED: {high_count} high risk issues exceed threshold of {max_high}")
        return False
    
    if medium_count > max_medium:
        print(f"\n❌ FAILED: {medium_count} medium risk issues exceed threshold of {max_medium}")
        return False
    
    print("\n✅ PASSED: All thresholds met")
    return True

def main():
    if len(sys.argv) < 2:
        print("Usage: python analyze-zap-results.py <zap-report.json>")
        sys.exit(1)
    
    report_file = sys.argv[1]
    
    try:
        results = analyze_zap_results(report_file)
        print_results(results)
        
        # Check thresholds
        passed = check_thresholds(results, max_high=0, max_medium=5)
        
        if not passed:
            print("\n" + "="*80)
            print("❌ ZAP SCAN FAILED - DEPLOYMENT BLOCKED")
            print("="*80)
            sys.exit(1)
        else:
            print("\n" + "="*80)
            print("✅ ZAP SCAN PASSED - PROCEEDING WITH DEPLOYMENT")
            print("="*80)
            sys.exit(0)
            
    except FileNotFoundError:
        print(f"Error: Report file '{report_file}' not found")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in report file '{report_file}'")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
