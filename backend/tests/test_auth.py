import pytest
from rest_framework.test import APIClient
from django.contrib.auth.models import User


@pytest.mark.django_db
def test_user_registration():
    client = APIClient()
    payload = {
        "email": "tester@example.com",
        "password": "SecurePassword123!",
        "first_name": "Test",
        "last_name": "User"
    }
    response = client.post('/api/v1/auth/register/', payload, format='json')
    assert response.status_code == 201
    assert response.data['success'] is True
    assert 'tokens' in response.data['data']
    assert response.data['data']['user']['email'] == 'tester@example.com'


@pytest.mark.django_db
def test_user_login():
    User.objects.create_user(username='login@example.com', email='login@example.com', password='Password123!')
    client = APIClient()
    payload = {
        "username": "login@example.com",
        "password": "Password123!"
    }
    response = client.post('/api/v1/auth/login/', payload, format='json')
    assert response.status_code == 200
    assert 'access' in response.data
    assert 'refresh' in response.data
