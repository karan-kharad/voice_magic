from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny
from .serializers import SupportTicketSerializer


class SupportTicketCreateView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = SupportTicketSerializer(data=request.data)
        if serializer.is_valid():
            ticket = serializer.save(user=request.user if request.user.is_authenticated else None)
            return Response({
                "success": True,
                "data": SupportTicketSerializer(ticket).data,
                "message": "Support ticket created successfully."
            }, status=status.HTTP_201_CREATED)
        return Response({
            "success": False,
            "error": {"code": "VALIDATION_ERROR", "details": serializer.errors}
        }, status=status.HTTP_400_BAD_REQUEST)
