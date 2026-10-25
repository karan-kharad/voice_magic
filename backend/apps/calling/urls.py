from django.urls import path
from .views import (
    IceServersView,
    CreateCallRoomView,
    JoinCallRoomView,
    SendSignalView,
    PollSignalsView,
    EndCallView,
)

urlpatterns = [
    path('ice-servers/', IceServersView.as_view(), name='voip-ice-servers'),
    path('rooms/create/', CreateCallRoomView.as_view(), name='voip-room-create'),
    path('rooms/<str:room_code>/join/', JoinCallRoomView.as_view(), name='voip-room-join'),
    path('rooms/<str:room_code>/signal/', SendSignalView.as_view(), name='voip-room-signal'),
    path('rooms/<str:room_code>/poll/', PollSignalsView.as_view(), name='voip-room-poll'),
    path('rooms/<str:room_code>/end/', EndCallView.as_view(), name='voip-room-end'),
]
