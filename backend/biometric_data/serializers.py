from rest_framework import serializers
from .models import BiometricReading, LocationLog
from devices.models import Device


class BiometricReadingSerializer(serializers.ModelSerializer):
    """
    Sérialiseur complet pour une mesure biométrique.
    Utilisé pour les réponses GET (historique, dernières mesures).
    """

    class Meta:
        model = BiometricReading
        fields = [
            'id', 'patient', 'device', 'heart_rate', 'temperature',
            'spo2', 'movement_data', 'recorded_at', 'synced_at', 'is_synced_offline'
        ]
        read_only_fields = ['id', 'synced_at']


class BiometricReadingCreateSerializer(serializers.ModelSerializer):
    """
    Sérialiseur pour la réception d'une nouvelle mesure en temps réel.
    Endpoint : POST /api/biometrics/

    Le patient et le device sont fournis dans le body.
    recorded_at est obligatoire : c'est l'heure réelle de la mesure sur le bracelet.
    """

    class Meta:
        model = BiometricReading
        fields = [
            'patient', 'device', 'heart_rate', 'temperature',
            'spo2', 'movement_data', 'recorded_at'
        ]

    def validate(self, data):
        """
        Vérifie que les valeurs biométriques sont dans des plages réalistes.
        Évite d'enregistrer des données corrompues envoyées par un capteur défectueux.
        """
        if not (30 <= data['heart_rate'] <= 250):
            raise serializers.ValidationError(
                {'heart_rate': 'Fréquence cardiaque invalide (plage : 30–250 bpm).'}
            )
        if not (30.0 <= float(data['temperature']) <= 45.0):
            raise serializers.ValidationError(
                {'temperature': 'Température invalide (plage : 30–45 °C).'}
            )
        if not (50 <= data['spo2'] <= 100):
            raise serializers.ValidationError(
                {'spo2': 'SpO2 invalide (plage : 50–100 %).'}
            )
        return data


class BiometricSyncSerializer(serializers.ModelSerializer):
    """
    Sérialiseur pour la synchronisation d'une mesure hors-ligne.
    Endpoint : POST /api/biometrics/sync/

    Force is_synced_offline=True lors de la création.
    """

    class Meta:
        model = BiometricReading
        fields = [
            'patient', 'device', 'heart_rate', 'temperature',
            'spo2', 'movement_data', 'recorded_at'
        ]

    def validate(self, data):
        """Même validation que pour une mesure temps réel."""
        if not (30 <= data['heart_rate'] <= 250):
            raise serializers.ValidationError(
                {'heart_rate': 'Fréquence cardiaque invalide (plage : 30–250 bpm).'}
            )
        if not (30.0 <= float(data['temperature']) <= 45.0):
            raise serializers.ValidationError(
                {'temperature': 'Température invalide (plage : 30–45 °C).'}
            )
        if not (50 <= data['spo2'] <= 100):
            raise serializers.ValidationError(
                {'spo2': 'SpO2 invalide (plage : 50–100 %).'}
            )
        return data

    def create(self, validated_data):
        validated_data['is_synced_offline'] = True
        return super().create(validated_data)


class LocationLogSerializer(serializers.ModelSerializer):
    """
    Sérialiseur pour les positions GPS.
    """

    class Meta:
        model = LocationLog
        fields = ['id', 'patient', 'latitude', 'longitude', 'recorded_at']
        read_only_fields = ['id']
