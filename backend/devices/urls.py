from django.urls import path
from .views import (
    DeviceRegisterView,
    DeviceAssociateView,
    DeviceListView,
    DeviceStatusView,
)

urlpatterns = [
    # Enregistrement d'un nouveau bracelet
    path('register/', DeviceRegisterView.as_view(), name='device-register'),

    # Liste de tous les bracelets
    path('', DeviceListView.as_view(), name='device-list'),

    # Association d'un bracelet à un patient
    path('<uuid:pk>/associate/', DeviceAssociateView.as_view(), name='device-associate'),

    # État en temps réel d'un bracelet
    path('<uuid:pk>/status/', DeviceStatusView.as_view(), name='device-status'),
]