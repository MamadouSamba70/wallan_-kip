import json
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

from .models import BiometricReading, LocationLog
from .serializers import (
    BiometricReadingSerializer,
    BiometricReadingCreateSerializer,
    BiometricSyncSerializer,
)
from patients.models import Patient
from alerts.models import Alert


def detect_and_create_alerts(reading, patient):
    """
    Comparaison automatique des valeurs reçues aux seuils du patient.
    Crée une alerte si un seuil est dépassé.
    Sévérité : warning (écart < 20%) ou critical (écart >= 20%).
    """

    def calculate_severity(value, threshold):
        ecart = abs(value - threshold) / threshold * 100
        return 'critical' if ecart >= 20 else 'warning'

    alerts_crees = []

    # Vérification fréquence cardiaque
    if reading.heart_rate > patient.threshold_heart_rate:
        alert = Alert.objects.create(
            patient=patient,
            alert_type='heart_rate',
            severity=calculate_severity(reading.heart_rate, patient.threshold_heart_rate),
            value_detected=reading.heart_rate,
            threshold_value=patient.threshold_heart_rate,
            status='active'
        )
        alerts_crees.append(alert)

    # Vérification température
    if float(reading.temperature) > float(patient.threshold_temperature):
        alert = Alert.objects.create(
            patient=patient,
            alert_type='temperature',
            severity=calculate_severity(float(reading.temperature), float(patient.threshold_temperature)),
            value_detected=reading.temperature,
            threshold_value=patient.threshold_temperature,
            status='active'
        )
        alerts_crees.append(alert)

    # Vérification SpO2 (alerte si INFÉRIEUR au seuil)
    if reading.spo2 < patient.threshold_spo2:
        alert = Alert.objects.create(
            patient=patient,
            alert_type='spo2',
            severity=calculate_severity(reading.spo2, patient.threshold_spo2),
            value_detected=reading.spo2,
            threshold_value=patient.threshold_spo2,
            status='active'
        )
        alerts_crees.append(alert)

    return alerts_crees


class BiometricReceiveView(APIView):
    """
    POST /api/biometrics/
    Reçoit une mesure biométrique en temps réel.
    Après enregistrement :
    1. Détection automatique des alertes
    2. Diffusion via WebSocket à tous les clients connectés (Flutter temps réel)
    """

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = BiometricReadingCreateSerializer(data=request.data)

        if serializer.is_valid():
            reading = serializer.save(is_synced_offline=False)
            patient = reading.patient

            # Détection automatique des alertes
            alerts = detect_and_create_alerts(reading, patient)

            # Diffusion WebSocket en temps réel vers Flutter
            # Tous les clients connectés au groupe biometric_{patient_id} reçoivent la mesure
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f'biometric_{patient.id}',
                {
                    'type': 'biometric_update',
                    'data': BiometricReadingSerializer(reading).data
                }
            )

            response_data = {
                'message': 'Mesure enregistrée et diffusée en temps réel.',
                'reading': BiometricReadingSerializer(reading).data,
                'alerts_created': len(alerts),
            }

            if alerts:
                response_data['alert_types'] = [a.alert_type for a in alerts]

            return Response(response_data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class BiometricSyncView(APIView):
    """
    POST /api/biometrics/sync/
    Reçoit un lot de mesures hors-ligne synchronisées.
    Limite : 500 mesures par lot.
    """

    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not isinstance(request.data, list):
            return Response(
                {'error': 'Le body doit être une liste de mesures.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(request.data) == 0:
            return Response(
                {'error': 'La liste de mesures est vide.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(request.data) > 500:
            return Response(
                {'error': 'Maximum 500 mesures par synchronisation.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        saved = []
        errors = []
        total_alerts = 0

        for i, item in enumerate(request.data):
            serializer = BiometricSyncSerializer(data=item)
            if serializer.is_valid():
                reading = serializer.save(is_synced_offline=True)
                saved.append(reading)
                alerts = detect_and_create_alerts(reading, reading.patient)
                total_alerts += len(alerts)
            else:
                errors.append({'index': i, 'errors': serializer.errors})

        return Response(
            {
                'message': f'{len(saved)} mesures synchronisées avec succès.',
                'saved_count': len(saved),
                'error_count': len(errors),
                'alerts_created': total_alerts,
                'errors': errors if errors else None,
            },
            status=status.HTTP_201_CREATED
        )


class BiometricLatestView(APIView):
    """
    GET /api/biometrics/{patient_id}/
    Retourne les 10 dernières mesures d'un patient.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id):
        patient = get_object_or_404(Patient, pk=patient_id)
        readings = BiometricReading.objects.filter(
            patient=patient
        ).order_by('-recorded_at')[:10]

        serializer = BiometricReadingSerializer(readings, many=True)
        return Response({
            'patient_id': str(patient_id),
            'count': len(serializer.data),
            'readings': serializer.data
        })


class BiometricHistoryView(APIView):
    """
    GET /api/biometrics/{patient_id}/history/
    Retourne l'historique des mesures d'un patient pour les graphiques Flutter.

    Paramètres optionnels :
    - limit      : nombre de mesures (défaut 100, max 1000)
    - date_from  : date de début au format YYYY-MM-DD
    - date_to    : date de fin au format YYYY-MM-DD

    Exemples :
    GET /api/biometrics/{id}/history/?limit=50
    GET /api/biometrics/{id}/history/?date_from=2026-07-01&date_to=2026-07-25
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id):
        patient = get_object_or_404(Patient, pk=patient_id)

        queryset = BiometricReading.objects.filter(
            patient=patient
        ).order_by('-recorded_at')

        # Filtre par date de début
        date_from = request.query_params.get('date_from')
        if date_from:
            queryset = queryset.filter(recorded_at__date__gte=date_from)

        # Filtre par date de fin
        date_to = request.query_params.get('date_to')
        if date_to:
            queryset = queryset.filter(recorded_at__date__lte=date_to)

        # Limite (défaut 100, max 1000)
        limit = int(request.query_params.get('limit', 100))
        limit = min(limit, 1000)

        readings = queryset[:limit]
        serializer = BiometricReadingSerializer(readings, many=True)

        return Response({
            'patient_id': str(patient_id),
            'total': len(serializer.data),
            'limit': limit,
            'date_from': date_from,
            'date_to': date_to,
            'readings': serializer.data
        })
