from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny


class CompatibilityCheckView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        android_sdk = int(request.query_params.get('android_sdk', 35))
        device_model = request.query_params.get('device_model', 'Unknown Device')

        is_supported_sdk = android_sdk >= 26
        low_latency_ready = android_sdk >= 30

        return Response({
            "success": True,
            "data": {
                "device_model": device_model,
                "android_sdk": android_sdk,
                "supported": is_supported_sdk,
                "capabilities": {
                    "oboe_low_latency": low_latency_ready,
                    "native_dsp_engine": True,
                    "whatsapp_voice_note_share": True,
                    "in_app_voip_calls": True,
                    "whatsapp_live_call_injection": False
                },
                "disclaimer": (
                    "WhatsApp live-call voice modification is isolated by Android security boundaries. "
                    "Studio effects are available for Voice Notes and In-App Calling."
                ),
                "recommended_buffer_size": 192 if low_latency_ready else 512
            }
        })
