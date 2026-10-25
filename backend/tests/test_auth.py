from rest_framework.test import APITestCase
from django.contrib.auth.models import User


class AuthTestCase(APITestCase):
    def test_user_registration(self):
        payload = {
            "email": "tester@example.com",
            "password": "SecurePassword123!",
            "first_name": "Test",
            "last_name": "User"
        }
        response = self.client.post('/api/v1/auth/register/', payload, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.data['success'])
        self.assertIn('tokens', response.data['data'])
        self.assertEqual(response.data['data']['user']['email'], 'tester@example.com')

    def test_user_login(self):
        User.objects.create_user(username='login@example.com', email='login@example.com', password='Password123!')
        payload = {
            "username": "login@example.com",
            "password": "Password123!"
        }
        response = self.client.post('/api/v1/auth/login/', payload, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
