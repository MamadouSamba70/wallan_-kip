from django.urls import path
from .views import (
    BiometricReceiveView,
    BiometricSyncView,
    BiometricLatestView,
    BiometricHistoryView,
)

urlpatterns = [
    # Réception d'une mesure en temps réel
    path('', BiometricReceiveView.as_view(), name='biometric-receive'),

    # Synchronisation d'un lot de mesures hors-ligne
    path('sync/', BiometricSyncView.as_view(), name='biometric-sync'),

    # Dernières mesures d'un patient
    path('<uuid:patient_id>/', BiometricLatestView.as_view(), name='biometric-latest'),

    # Historique complet d'un patient (pour les graphiques)
    path('<uuid:patient_id>/history/', BiometricHistoryView.as_view(), name='biometric-history'),
]