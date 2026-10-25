import uuid
from django.db import models
from django.contrib.auth.models import User


class SupportTicket(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='support_tickets')
    subject = models.CharField(max_length=200)
    category = models.CharField(max_length=50, default='general')
    description = models.TextField()
    device_metadata = models.JSONField(default=dict, blank=True)
    status = models.CharField(max_length=30, default='open')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.subject} ({self.status})"
