from rest_framework import serializers
from .models import Device, DeviceAssignment, DeviceStatus


class DeviceSerializer(serializers.ModelSerializer):
    """
    Sérialiseur complet d'un bracelet.
    Utilisé pour les réponses GET et dans les autres sérialiseurs.
    """

    class Meta:
        model = Device
        fields = ['id', 'hardware_id', 'model', 'firmware_version', 'status', 'registered_at']
        read_only_fields = ['id', 'registered_at', 'status']


class DeviceRegisterSerializer(serializers.ModelSerializer):
    """
    Sérialiseur pour l'enregistrement d'un nouveau bracelet.
    Endpoint : POST /api/devices/register/
    """

    class Meta:
        model = Device
        fields = ['hardware_id', 'model', 'firmware_version']

    def validate_hardware_id(self, value):
        """
        Vérifie que le hardware_id n'est pas déjà enregistré dans le système.
        Chaque bracelet physique (ESP32) est unique par adresse MAC.
        """
        if Device.objects.filter(hardware_id=value).exists():
            raise serializers.ValidationError(
                "Un bracelet avec cet identifiant matériel est déjà enregistré."
            )
        return value


class DeviceAssociateSerializer(serializers.Serializer):
    """
    Sérialiseur pour l'association d'un bracelet à un patient.
    Endpoint : POST /api/devices/{id}/associate/

    On demande les deux champs pour double vérification de sécurité :
    - patient_id : l'UUID du patient dans la base de données
    - hardware_id : l'adresse MAC du bracelet (confirmée par l'app Flutter via Bluetooth)
    """

    patient_id = serializers.UUIDField(
        help_text="UUID du patient auquel associer le bracelet"
    )
    hardware_id = serializers.CharField(
        max_length=50,
        help_text="Adresse MAC du bracelet (confirmée via Bluetooth)"
    )


class DeviceStatusSerializer(serializers.ModelSerializer):
    """
    Sérialiseur pour l'état en temps réel d'un bracelet.
    Endpoint : GET /api/devices/{id}/status/
    """

    # Afficher les infos du bracelet dans la réponse
    device = DeviceSerializer(read_only=True)

    class Meta:
        model = DeviceStatus
        fields = ['id', 'device', 'battery_level', 'is_connected', 'last_sync']