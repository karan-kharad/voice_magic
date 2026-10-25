from rest_framework.test import APITestCase


class HealthTestCase(APITestCase):
    def test_health_check_endpoint(self):
        response = self.client.get('/api/v1/health/')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertIn('database', response.data['data'])
        self.assertEqual(response.data['data']['version'], '1.0.0')
