import uuid
from django.db import models
from django.contrib.auth.models import User


class Subscription(models.Model):
    TIER_CHOICES = [
        ('free', 'Community Free'),
        ('pro_monthly', 'Voice Changer Pro Monthly'),
        ('pro_annual', 'Voice Changer Pro Annual'),
    ]

    STATUS_CHOICES = [
        ('active', 'Active'),
        ('grace_period', 'Grace Period'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='subscriptions')
    tier = models.CharField(max_length=30, choices=TIER_CHOICES, default='free')
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='active')
    starts_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    original_order_id = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.email} - {self.tier} ({self.status})"
