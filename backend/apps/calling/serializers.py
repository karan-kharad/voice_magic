from rest_framework import serializers
from .models import CallRoom, SignalingMessage


class CallRoomSerializer(serializers.ModelSerializer):
    class Meta:
        model = CallRoom
        fields = [
            'id',
            'room_code',
            'status',
            'host_id',
            'peer_id',
            'active_preset',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'room_code', 'created_at', 'updated_at']


class SignalingMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = SignalingMessage
        fields = [
            'id',
            'sender_type',
            'signal_type',
            'payload',
            'created_at',
            'delivered',
        ]
        read_only_fields = ['id', 'created_at']
