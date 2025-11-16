"""
Vulnerable Flask Application for DevSecOps Pipeline Testing
This application intentionally contains security vulnerabilities for testing purposes.
DO NOT use in production!
"""

from flask import Flask, request, render_template_string, redirect, session
import sqlite3
import os
import pickle
import subprocess

app = Flask(__name__)
app.secret_key = "hardcoded-secret-key-123"                 

# Simulated user database (in-memory for demo)
users_db = {
    "admin": {"password": "admin123", "role": "admin"},
    "user": {"password": "user123", "role": "user"}
}

@app.route('/')
def index():
    return render_template_string("""
    <!DOCTYPE html>
    <html>
    <head>
        <title>SecurePipeline Demo App</title>
        <style>
            body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
            h1 { color: #333; }
            .endpoint { background: #f4f4f4; padding: 10px; margin: 10px 0; border-left: 4px solid #007bff; }
            .warning { background: #fff3cd; border-left-color: #ffc107; padding: 15px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <h1>🔒 SecurePipeline - DevSecOps Demo Application</h1>
        <div class="warning">
            <strong>⚠️ Warning:</strong> This application contains intentional security vulnerabilities for testing purposes.
            DO NOT deploy to production!
        </div>
        
        <h2>Available Endpoints:</h2>
        <div class="endpoint">
            <strong>GET /</strong> - This page
        </div>
        <div class="endpoint">
            <strong>POST /login</strong> - Login endpoint (vulnerable to SQL injection)
        </div>
        <div class="endpoint">
            <strong>GET /search?q=term</strong> - Search endpoint (vulnerable to XSS)
        </div>
        <div class="endpoint">
            <strong>POST /upload</strong> - File upload (vulnerable to arbitrary file upload)
        </div>
        <div class="endpoint">
            <strong>GET /admin</strong> - Admin panel (vulnerable to broken access control)
        </div>
        <div class="endpoint">
            <strong>POST /execute</strong> - Command execution (vulnerable to command injection)
        </div>
        <div class="endpoint">
            <strong>GET /health</strong> - Health check endpoint
        </div>
        
        <h2>OWASP Top 10 Vulnerabilities Included:</h2>
        <ul>
            <li>A01: Broken Access Control</li>
            <li>A02: Cryptographic Failures</li>
            <li>A03: Injection (SQL, Command, XSS)</li>
            <li>A05: Security Misconfiguration</li>
            <li>A07: Identification and Authentication Failures</li>
            <li>A08: Software and Data Integrity Failures</li>
            <li>A09: Security Logging and Monitoring Failures</li>
        </ul>
    </body>
    </html>
    """)

# A03: SQL Injection Vulnerability
@app.route('/login', methods=['POST'])
def login():
    username = request.form.get('username', '')
    password = request.form.get('password', '')
    
    # VULNERABLE: SQL Injection
    conn = sqlite3.connect(':memory:')
    cursor = conn.cursor()
    
    # Create table
    cursor.execute('''CREATE TABLE IF NOT EXISTS users 
                     (username TEXT, password TEXT, role TEXT)''')
    cursor.execute("INSERT INTO users VALUES ('admin', 'admin123', 'admin')")
    cursor.execute("INSERT INTO users VALUES ('user', 'user123', 'user')")
    
    # Vulnerable query - direct string concatenation
    query = f"SELECT * FROM users WHERE username='{username}' AND password='{password}'"
    
    try:
        result = cursor.execute(query).fetchone()
        conn.close()
        
        if result:
            session['username'] = result[0]
            session['role'] = result[2]
            return {"status": "success", "message": "Logged in successfully", "role": result[2]}
        else:
            return {"status": "error", "message": "Invalid credentials"}, 401
    except Exception as e:
        return {"status": "error", "message": str(e)}, 500

# A03: Cross-Site Scripting (XSS) Vulnerability
@app.route('/search')
def search():
    query = request.args.get('q', '')
    
    # VULNERABLE: Reflected XSS
    return render_template_string(f"""
    <!DOCTYPE html>
    <html>
    <head><title>Search Results</title></head>
    <body>
        <h1>Search Results</h1>
        <p>You searched for: {query}</p>
        <p>No results found.</p>
    </body>
    </html>
    """)

# A01: Broken Access Control
@app.route('/admin')
def admin():
    # VULNERABLE: No authentication check
    # Should verify session['role'] == 'admin'
    return render_template_string("""
    <!DOCTYPE html>
    <html>
    <head><title>Admin Panel</title></head>
    <body>
        <h1>🔐 Admin Panel</h1>
        <p>This page should be restricted to administrators only!</p>
        <ul>
            <li>View all users</li>
            <li>Delete user accounts</li>
            <li>Access sensitive data</li>
        </ul>
    </body>
    </html>
    """)

# A03: Command Injection Vulnerability
@app.route('/execute', methods=['POST'])
def execute_command():
    command = request.json.get('command', '')
    
    # VULNERABLE: Command Injection
    try:
        result = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        return {"status": "success", "output": result.decode('utf-8')}
    except Exception as e:
        return {"status": "error", "message": str(e)}, 500

# A08: Insecure Deserialization
@app.route('/deserialize', methods=['POST'])
def deserialize():
    data = request.data
    
    # VULNERABLE: Unsafe deserialization
    try:
        obj = pickle.loads(data)
        return {"status": "success", "data": str(obj)}
    except Exception as e:
        return {"status": "error", "message": str(e)}, 500

# A05: Security Misconfiguration - Debug mode enabled
@app.route('/debug')
def debug():
    # VULNERABLE: Exposing debug information
    return {
        "environment": dict(os.environ),
        "secret_key": app.secret_key,
        "debug": app.debug
    }

# Health check endpoint (secure)
@app.route('/health')
def health():
    return {"status": "healthy", "version": "1.0.0"}

# A09: Security Logging and Monitoring Failures
# No logging implemented for security events

if __name__ == '__main__':
    # VULNERABLE: Running in debug mode, binding to all interfaces
    app.run(host='0.0.0.0', port=5000, debug=True)
