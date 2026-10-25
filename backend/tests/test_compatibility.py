import pytest
from rest_framework.test import APIClient


@pytest.mark.django_db
def test_compatibility_check():
    client = APIClient()
    response = client.get('/api/v1/compatibility/check/?android_sdk=35&device_model=Pixel9Pro')
    assert response.status_code == 200
    assert response.data['success'] is True
    assert response.data['data']['capabilities']['whatsapp_live_call_injection'] is False
    assert response.data['data']['capabilities']['whatsapp_voice_note_share'] is True
