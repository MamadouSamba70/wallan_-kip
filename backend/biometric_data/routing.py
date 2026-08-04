from django.urls import re_path
from . import consumers

# URLs WebSocket pour les données biométriques en temps réel
# Flutter se connecte via : ws://serveur/ws/biometrics/{patient_id}/
websocket_urlpatterns = [
    re_path(
        r'ws/biometrics/(?P<patient_id>[0-9a-f-]+)/$',
        consumers.BiometricConsumer.as_asgi()
    ),
]