from rest_framework.test import APITestCase


class CompatibilityTestCase(APITestCase):
    def test_compatibility_check(self):
        response = self.client.get('/api/v1/compatibility/check/?android_sdk=35&device_model=Pixel9Pro')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertFalse(response.data['data']['capabilities']['whatsapp_live_call_injection'])
        self.assertTrue(response.data['data']['capabilities']['whatsapp_voice_note_share'])
