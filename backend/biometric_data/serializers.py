from rest_framework import serializers
from .models import BiometricReading
from devices.models import Device

# 1. Sérialiseur standard pour lire ou enregistrer une seule mesure
class BiometricReadingSerializer(serializers.ModelSerializer):
    class Meta:
        model = BiometricReading
        fields = [
            'id', 'patient', 'device', 'heart_rate', 'temperature', 
            'spo2', 'movement_data', 'recorded_at', 'synced_at', 'is_synced_offline'
        ]
        read_only_fields = ['id', 'synced_at']


# 2. Sérialiseur spécifique pour la synchronisation par lot (Offline Sync)
class BiometricSyncSerializer(serializers.ModelSerializer):
    class Meta:
        model = BiometricReading
        # On ne met pas 'patient' ni 'is_synced_offline' car ils seront injectés automatiquement par le serveur
        fields = [
            'device', 'heart_rate', 'temperature', 
            'spo2', 'movement_data', 'recorded_at'
        ]

    def create(self, validated_data):
        # On force le flag à True car cette donnée provient d'une synchro hors-ligne
        validated_data['is_synced_offline'] = True
        return super().create(validated_data)
