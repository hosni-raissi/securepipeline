"""
Unit tests for the vulnerable Flask application
"""

import pytest
from app.main import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index(client):
    """Test the index page loads"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'SecurePipeline' in response.data

def test_health_check(client):
    """Test health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'
    assert 'version' in data

def test_login_valid_credentials(client):
    """Test login with valid credentials"""
    response = client.post('/login', data={
        'username': 'admin',
        'password': 'admin123'
    })
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'success'

def test_login_invalid_credentials(client):
    """Test login with invalid credentials"""
    response = client.post('/login', data={
        'username': 'admin',
        'password': 'wrongpassword'
    })
    assert response.status_code == 401
    data = response.get_json()
    assert data['status'] == 'error'

def test_search_endpoint(client):
    """Test search functionality"""
    response = client.get('/search?q=test')
    assert response.status_code == 200
    assert b'Search Results' in response.data

def test_admin_endpoint(client):
    """Test admin panel access"""
    response = client.get('/admin')
    assert response.status_code == 200
    assert b'Admin Panel' in response.data

def test_debug_endpoint(client):
    """Test debug endpoint"""
    response = client.get('/debug')
    assert response.status_code == 200
    data = response.get_json()
    assert 'secret_key' in data
