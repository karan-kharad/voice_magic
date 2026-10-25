import pytest
from rest_framework.test import APIClient


@pytest.mark.django_db
def test_subscription_plans_feasibility_gate():
    client = APIClient()
    response = client.get('/api/v1/subscriptions/plans/')
    assert response.status_code == 200
    assert response.data['success'] is True
    assert response.data['data']['commercial_status'] == 'development_preview'
    assert response.data['data']['feasibility_gate_active'] is True

    # Ensure paid plan is not purchasable
    plans = response.data['data']['plans']
    pro_plan = next(p for p in plans if p['id'] == 'tier_pro_monthly')
    assert pro_plan['is_purchasable'] is False
