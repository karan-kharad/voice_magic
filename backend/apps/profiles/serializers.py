from rest_framework import serializers
from .models import UserProfile, CustomPreset


class CustomPresetSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomPreset
        fields = ('id', 'name', 'pitch_semitones', 'echo_delay_ms', 'robot_freq_hz', 'is_favorite', 'created_at')


class UserProfileSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(source='user.email', read_only=True)
    custom_presets = CustomPresetSerializer(many=True, read_only=True)

    class Meta:
        model = UserProfile
        fields = ('id', 'email', 'preferred_preset', 'audio_settings', 'custom_presets', 'updated_at')
