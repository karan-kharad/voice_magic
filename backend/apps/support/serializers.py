from rest_framework import serializers
from .models import SupportTicket


class SupportTicketSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupportTicket
        fields = ('id', 'subject', 'category', 'description', 'device_metadata', 'status', 'created_at')
        read_only_fields = ('id', 'status', 'created_at')
