from django.urls import path
from .views import BiometricSyncView

urlpatterns = [
    #  Route de synchronisation différée
    path('sync/', BiometricSyncView.as_view(), name='biometrics_sync'),
]
