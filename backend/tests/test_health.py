import pytest
from rest_framework.test import APIClient


@pytest.mark.django_db
def test_health_check_endpoint():
    client = APIClient()
    response = client.get('/api/v1/health/')
    assert response.status_code == 200
    assert response.data['success'] is True
    assert 'database' in response.data['data']
    assert response.data['data']['version'] == '1.0.0'
