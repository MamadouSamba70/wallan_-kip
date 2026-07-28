"""
Configuration ASGI du projet Wallan.
Gère à la fois les requêtes HTTP classiques (DRF)
et les connexions WebSocket (Django Channels) pour le temps réel.
"""

import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
import biometric_data.routing

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'wallan.settings')

application = ProtocolTypeRouter({
    # Requêtes HTTP classiques (API REST DRF)
    'http': get_asgi_application(),

    # Connexions WebSocket (données biométriques temps réel)
    'websocket': AuthMiddlewareStack(
        URLRouter(
            biometric_data.routing.websocket_urlpatterns
        )
    ),
})