import uuid
from django.db import models
from django.contrib.auth.models import User


class UserProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    preferred_preset = models.CharField(max_length=50, default='normal')
    audio_settings = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Profile of {self.user.email}"


class CustomPreset(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='custom_presets')
    name = models.CharField(max_length=100)
    pitch_semitones = models.FloatField(default=0.0)
    echo_delay_ms = models.IntegerField(default=0)
    robot_freq_hz = models.FloatField(default=0.0)
    is_favorite = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.profile.user.email})"
