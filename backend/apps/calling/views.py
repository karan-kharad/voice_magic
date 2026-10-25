import uuid
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from django.shortcuts import get_object_or_404
from .models import CallRoom, SignalingMessage
from .serializers import CallRoomSerializer, SignalingMessageSerializer

DEFAULT_ICE_SERVERS = [
    {"urls": "stun:stun.l.google.com:19302"},
    {"urls": "stun:stun1.l.google.com:19302"},
    {"urls": "stun:stun2.l.google.com:19302"},
    {"urls": "stun:stun3.l.google.com:19302"},
    {"urls": "stun:stun4.l.google.com:19302"},
]


class IceServersView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({
            "success": True,
            "data": {
                "ice_servers": DEFAULT_ICE_SERVERS,
                "protocol": "WebRTC-VoIP-v1",
                "audio_codecs": ["opus/48000/2", "ISAC/16000"],
            }
        })


class CreateCallRoomView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        host_id = request.data.get('host_id') or f"caller_{uuid.uuid4().hex[:8]}"
        preset = request.data.get('preset') or 'normal'

        room = CallRoom.objects.create(
            host_id=host_id,
            active_preset=preset,
            status='waiting'
        )

        return Response({
            "success": True,
            "data": {
                "room": CallRoomSerializer(room).data,
                "role": "host",
                "ice_servers": DEFAULT_ICE_SERVERS,
            }
        }, status=status.HTTP_201_CREATED)


class JoinCallRoomView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, room_code):
        room = get_object_or_404(CallRoom, room_code__iexact=room_code.strip())

        if room.status == 'ended':
            return Response({
                "success": False,
                "error": "This call has already ended."
            }, status=status.HTTP_400_BAD_REQUEST)

        peer_id = request.data.get('peer_id') or f"peer_{uuid.uuid4().hex[:8]}"
        room.peer_id = peer_id
        room.status = 'connected'
        room.save(update_fields=['peer_id', 'status', 'updated_at'])

        return Response({
            "success": True,
            "data": {
                "room": CallRoomSerializer(room).data,
                "role": "peer",
                "ice_servers": DEFAULT_ICE_SERVERS,
            }
        })


class SendSignalView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, room_code):
        room = get_object_or_404(CallRoom, room_code__iexact=room_code.strip())

        sender_type = request.data.get('sender_type')
        signal_type = request.data.get('signal_type')
        payload = request.data.get('payload', {})

        if sender_type not in ['host', 'peer']:
            return Response({
                "success": False,
                "error": "sender_type must be 'host' or 'peer'"
            }, status=status.HTTP_400_BAD_REQUEST)

        if not signal_type:
            return Response({
                "success": False,
                "error": "signal_type is required"
            }, status=status.HTTP_400_BAD_REQUEST)

        # Handle special signal types
        if signal_type == 'hangup':
            room.status = 'ended'
            room.save(update_fields=['status', 'updated_at'])
        elif signal_type == 'preset_update':
            new_preset = payload.get('preset')
            if new_preset:
                room.active_preset = new_preset
                room.save(update_fields=['active_preset', 'updated_at'])

        signal = SignalingMessage.objects.create(
            room=room,
            sender_type=sender_type,
            signal_type=signal_type,
            payload=payload,
        )

        return Response({
            "success": True,
            "data": {
                "signal_id": signal.id,
                "room_status": room.status,
            }
        }, status=status.HTTP_201_CREATED)


class PollSignalsView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, room_code):
        room = get_object_or_404(CallRoom, room_code__iexact=room_code.strip())

        # The poller wants signals sent by the OTHER participant
        poller_role = request.query_params.get('role', 'host')
        target_sender = 'peer' if poller_role == 'host' else 'host'

        last_id = request.query_params.get('last_id')
        queryset = room.signals.filter(sender_type=target_sender)

        if last_id:
            try:
                queryset = queryset.filter(id__gt=int(last_id))
            except ValueError:
                pass

        signals = queryset.all()

        return Response({
            "success": True,
            "data": {
                "room_status": room.status,
                "active_preset": room.active_preset,
                "signals": SignalingMessageSerializer(signals, many=True).data
            }
        })


class EndCallView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, room_code):
        room = get_object_or_404(CallRoom, room_code__iexact=room_code.strip())
        role = request.data.get('role', 'host')

        room.status = 'ended'
        room.save(update_fields=['status', 'updated_at'])

        SignalingMessage.objects.create(
            room=room,
            sender_type=role,
            signal_type='hangup',
            payload={"reason": "User ended the call"}
        )

        return Response({
            "success": True,
            "data": {
                "room_code": room.room_code,
                "status": "ended",
            }
        })
