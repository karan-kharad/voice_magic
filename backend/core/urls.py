"""
URL configuration for WhatsApp Voice Changer backend.
"""
from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from django.db import connection
from django.utils import timezone


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """System health check endpoint verifying database connectivity."""
    db_status = "healthy"
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1;")
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    return Response({
        "success": True,
        "data": {
            "status": "healthy" if "unhealthy" not in db_status else "degraded",
            "database": db_status,
            "version": "1.0.0",
            "timestamp": timezone.now().isoformat()
        }
    })


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/health/', health_check, name='health-check'),
    path('api/v1/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/v1/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),

    # Modular Versioned APIs
    path('api/v1/auth/', include('apps.authentication.urls')),
    path('api/v1/profile/', include('apps.profiles.urls')),
    path('api/v1/subscriptions/', include('apps.subscriptions.urls')),
    path('api/v1/compatibility/', include('apps.diagnostics.urls')),
    path('api/v1/support/', include('apps.support.urls')),
]
