import json
from channels.generic.websocket import AsyncWebsocketConsumer


class BiometricConsumer(AsyncWebsocketConsumer):
    """
    WebSocket Consumer pour la diffusion des données biométriques en temps réel.

    Fonctionnement :
    - Flutter se connecte via ws://serveur/ws/biometrics/{patient_id}/
    - Dès qu'une nouvelle mesure est reçue via POST /api/biometrics/,
      elle est automatiquement diffusée à tous les clients connectés
      qui écoutent ce patient (médecin, proche, patient lui-même).

    Groupe de diffusion : biometric_{patient_id}
    → Toute mesure envoyée à ce groupe est reçue par tous les connectés.
    """

    async def connect(self):
        """
        Appelé quand un client Flutter ouvre une connexion WebSocket.
        On l'ajoute au groupe correspondant à son patient.
        """
        # Récupérer l'UUID du patient depuis l'URL WebSocket
        self.patient_id = self.scope['url_route']['kwargs']['patient_id']
        self.group_name = f'biometric_{self.patient_id}'

        # Rejoindre le groupe de diffusion du patient
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )

        # Accepter la connexion WebSocket
        await self.accept()

    async def disconnect(self, close_code):
        """
        Appelé quand le client Flutter ferme la connexion.
        On le retire du groupe de diffusion.
        """
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        """
        Appelé si le client envoie un message via WebSocket.
        Non utilisé pour l'instant — les données viennent du bracelet via l'API REST.
        """
        pass

    async def biometric_update(self, event):
        """
        Appelé automatiquement quand une nouvelle mesure est diffusée au groupe.
        Envoie les données au client Flutter connecté.
        """
        await self.send(text_data=json.dumps(event['data']))