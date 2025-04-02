import json
import pytest
from app import app as flask_app

@pytest.fixture
def app():
    return flask_app

@pytest.fixture
def client(app):
    return app.test_client()

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'healthy'

def test_root_endpoint(client):
    response = client.get('/')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'message' in data

def test_tasks_endpoint(client):
    response = client.get('/tasks')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert isinstance(data, list)
    # Since we're returning sample data, we should have at least one task
    assert len(data) > 0
    if len(data) > 0:
        assert 'id' in data[0]
        assert 'title' in data[0]
        assert 'description' in data[0]
        assert 'status' in data[0]
