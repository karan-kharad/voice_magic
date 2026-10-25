from rest_framework.test import APITestCase
from apps.calling.models import CallRoom, SignalingMessage


class CallingTestCase(APITestCase):
    def test_ice_servers_endpoint(self):
        response = self.client.get('/api/v1/calling/ice-servers/')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertGreater(len(response.data['data']['ice_servers']), 0)

    def test_create_and_join_call_room(self):
        # 1. Create Room as Host
        create_resp = self.client.post('/api/v1/calling/rooms/create/', {'preset': 'robot'}, format='json')
        self.assertEqual(create_resp.status_code, 201)
        self.assertTrue(create_resp.data['success'])
        room_code = create_resp.data['data']['room']['room_code']
        self.assertEqual(create_resp.data['data']['room']['status'], 'waiting')

        # 2. Join Room as Peer
        join_resp = self.client.post(f'/api/v1/calling/rooms/{room_code}/join/', {'peer_id': 'peer_123'}, format='json')
        self.assertEqual(join_resp.status_code, 200)
        self.assertEqual(join_resp.data['data']['room']['status'], 'connected')

        # 3. Host sends SDP offer
        signal_resp = self.client.post(
            f'/api/v1/calling/rooms/{room_code}/signal/',
            {
                'sender_type': 'host',
                'signal_type': 'offer',
                'payload': {'sdp': 'test_sdp_offer'}
            },
            format='json'
        )
        self.assertEqual(signal_resp.status_code, 201)

        # 4. Peer polls for host signal
        poll_resp = self.client.get(f'/api/v1/calling/rooms/{room_code}/poll/?role=peer')
        self.assertEqual(poll_resp.status_code, 200)
        signals = poll_resp.data['data']['signals']
        self.assertEqual(len(signals), 1)
        self.assertEqual(signals[0]['signal_type'], 'offer')

        # 5. End call
        end_resp = self.client.post(f'/api/v1/calling/rooms/{room_code}/end/', {'role': 'host'}, format='json')
        self.assertEqual(end_resp.status_code, 200)
        self.assertEqual(end_resp.data['data']['status'], 'ended')
