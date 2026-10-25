from django.urls import path
from .views import SupportTicketCreateView

urlpatterns = [
    path('tickets/', SupportTicketCreateView.as_view(), name='support-ticket-create'),
]
