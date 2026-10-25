from django.urls import path
from .views import ProfileDetailView, CustomPresetListView

urlpatterns = [
    path('', ProfileDetailView.as_view(), name='profile-detail'),
    path('presets/', CustomPresetListView.as_view(), name='profile-presets'),
]
