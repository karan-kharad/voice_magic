from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from .models import UserProfile, CustomPreset
from .serializers import UserProfileSerializer, CustomPresetSerializer


class ProfileDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        serializer = UserProfileSerializer(profile)
        return Response({
            "success": True,
            "data": serializer.data
        })

    def put(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        preferred_preset = request.data.get('preferred_preset')
        audio_settings = request.data.get('audio_settings')

        if preferred_preset:
            profile.preferred_preset = preferred_preset
        if isinstance(audio_settings, dict):
            profile.audio_settings = audio_settings
        profile.save()

        return Response({
            "success": True,
            "data": UserProfileSerializer(profile).data,
            "message": "Preferences updated successfully."
        })


class CustomPresetListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        presets = profile.custom_presets.all()
        return Response({
            "success": True,
            "data": CustomPresetSerializer(presets, many=True).data
        })

    def post(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        serializer = CustomPresetSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(profile=profile)
            return Response({
                "success": True,
                "data": serializer.data,
                "message": "Custom preset saved."
            }, status=status.HTTP_201_CREATED)
        return Response({
            "success": False,
            "error": {"code": "VALIDATION_ERROR", "details": serializer.errors}
        }, status=status.HTTP_400_BAD_REQUEST)
