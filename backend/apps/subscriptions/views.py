from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from .models import Subscription


class SubscriptionPlansView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        # Feasibility gate enforcement: paid plans are marked development_preview only
        return Response({
            "success": True,
            "data": {
                "commercial_status": "development_preview",
                "feasibility_gate_active": True,
                "feasibility_notice": (
                    "Commercial billing is locked until live recipient-side verification passes. "
                    "All core Voice Studio features are unlocked in Free / Development Preview mode."
                ),
                "plans": [
                    {
                        "id": "tier_free",
                        "name": "Community Tier",
                        "price_cents": 0,
                        "currency": "USD",
                        "billing_period": "lifetime",
                        "is_purchasable": True,
                        "features": [
                            "Normal, High Pitch, Low Pitch",
                            "Robot & Echo Effects",
                            "Live Input/Output Level Meters",
                            "Direct WhatsApp Voice Note Share"
                        ]
                    },
                    {
                        "id": "tier_pro_monthly",
                        "name": "Pro Monthly (Preview)",
                        "price_cents": 499,
                        "currency": "USD",
                        "billing_period": "monthly",
                        "is_purchasable": False,
                        "features": [
                            "Custom DSP Fine-Tuning",
                            "HD Opus Compression",
                            "Priority In-App VoIP Support"
                        ]
                    }
                ]
            }
        })


class EntitlementsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        subscription = Subscription.objects.filter(
            user=request.user,
            status='active'
        ).order_by('-created_at').first()

        tier = subscription.tier if subscription else 'free'

        return Response({
            "success": True,
            "data": {
                "user_id": str(request.user.id),
                "tier": tier,
                "is_active": True,
                "unlocked_features": [
                    "dsp_effects",
                    "whatsapp_voice_notes",
                    "diagnostics"
                ],
                "server_validated": True
            }
        })
