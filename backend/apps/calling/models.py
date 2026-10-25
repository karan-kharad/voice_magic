import secrets
import string
from django.db import models


def generate_room_code():
    chars = string.ascii_uppercase + string.digits
    # Generate 6-char code like "VOX-842"
    part1 = ''.join(secrets.choice(string.ascii_uppercase) for _ in range(3))
    part2 = ''.join(secrets.choice(string.digits) for _ in range(3))
    return f"{part1}-{part2}"


class CallRoom(models.Model):
    STATUS_CHOICES = (
        ('waiting', 'Waiting for Peer'),
        ('ringing', 'Ringing'),
        ('connected', 'Connected'),
        ('ended', 'Ended'),
    )

    room_code = models.CharField(max_length=16, unique=True, db_index=True, default=generate_room_code)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='waiting')
    host_id = models.CharField(max_length=100)
    peer_id = models.CharField(max_length=100, blank=True, null=True)
    active_preset = models.CharField(max_length=50, default='normal')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Room {self.room_code} ({self.status})"


class SignalingMessage(models.Model):
    SENDER_CHOICES = (
        ('host', 'Host Caller'),
        ('peer', 'Remote Peer'),
    )

    SIGNAL_TYPES = (
        ('offer', 'SDP Offer'),
        ('answer', 'SDP Answer'),
        ('candidate', 'ICE Candidate'),
        ('hangup', 'Call Hangup'),
        ('preset_update', 'DSP Preset Update'),
    )

    room = models.ForeignKey(CallRoom, related_name='signals', on_delete=models.CASCADE)
    sender_type = models.CharField(max_length=10, choices=SENDER_CHOICES)
    signal_type = models.CharField(max_length=30, choices=SIGNAL_TYPES)
    payload = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)
    delivered = models.BooleanField(default=False)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Signal {self.signal_type} from {self.sender_type} in {self.room.room_code}"
