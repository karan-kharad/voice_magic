from rest_framework.test import APITestCase


class SubscriptionsTestCase(APITestCase):
    def test_subscription_plans_feasibility_gate(self):
        response = self.client.get('/api/v1/subscriptions/plans/')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertEqual(response.data['data']['commercial_status'], 'development_preview')
        self.assertTrue(response.data['data']['feasibility_gate_active'])

        # Ensure paid plan is not purchasable
        plans = response.data['data']['plans']
        pro_plan = next(p for p in plans if p['id'] == 'tier_pro_monthly')
        self.assertFalse(pro_plan['is_purchasable'])
