from django.urls import path
from .views import SubscriptionPlansView, EntitlementsView

urlpatterns = [
    path('plans/', SubscriptionPlansView.as_view(), name='subscription-plans'),
    path('entitlements/', EntitlementsView.as_view(), name='subscription-entitlements'),
]
