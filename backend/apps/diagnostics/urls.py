from django.urls import path
from .views import CompatibilityCheckView

urlpatterns = [
    path('check/', CompatibilityCheckView.as_view(), name='compatibility-check'),
]
