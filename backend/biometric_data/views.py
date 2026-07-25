from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404

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
    Fonction utilitaire appelée après chaque réception de mesure.
    Compare les valeurs reçues aux seuils personnalisés du patient
    et crée automatiquement des alertes si un seuil est dépassé.

    Règle de sévérité :
    - warning  : valeur dépasse le seuil de moins de 20%
    - critical : valeur dépasse le seuil de 20% ou plus
    """

    def calculate_severity(value, threshold):
        """Calcule la sévérité selon l'écart au seuil."""
        ecart = abs(value - threshold) / threshold * 100
        return 'critical' if ecart >= 20 else 'warning'

    alerts_crees = []

    # Vérification de la fréquence cardiaque
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

    # Vérification de la température
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

    # Vérification de la saturation en oxygène (SpO2)
    # SpO2 déclenche une alerte quand la valeur est INFÉRIEURE au seuil
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

    Reçoit une mesure biométrique en temps réel depuis le bracelet ESP32.
    Après enregistrement, déclenche automatiquement la détection d'alertes
    en comparant les valeurs aux seuils personnalisés du patient.

    Body attendu :
    {
        "patient": "uuid-du-patient",
        "device": "uuid-du-device",
        "heart_rate": 95,
        "temperature": 37.5,
        "spo2": 98,
        "movement_data": {"x": 0.1, "y": 0.2, "z": 9.8},
        "recorded_at": "2026-07-18T10:30:00Z"
    }
    """

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = BiometricReadingCreateSerializer(data=request.data)

        if serializer.is_valid():
            # Enregistrer la mesure avec is_synced_offline=False (mesure temps réel)
            reading = serializer.save(is_synced_offline=False)

            # Récupérer le patient pour accéder à ses seuils d'alerte
            patient = reading.patient

            # Détecter automatiquement les anomalies et créer les alertes
            alerts = detect_and_create_alerts(reading, patient)

            response_data = {
                'message': 'Mesure enregistrée avec succès.',
                'reading': BiometricReadingSerializer(reading).data,
                'alerts_created': len(alerts),
            }

            # Informer l'appelant si des alertes ont été générées
            if alerts:
                response_data['alert_types'] = [a.alert_type for a in alerts]

            return Response(response_data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class BiometricSyncView(APIView):
    """
    POST /api/biometrics/sync/

    Reçoit un lot de mesures hors-ligne synchronisées.
    Utilisé quand le bracelet n'avait pas de connexion et envoie
    toutes ses mesures stockées localement d'un coup.

    Body attendu (liste de mesures) :
    [
        {
            "patient": "uuid",
            "device": "uuid",
            "heart_rate": 90,
            "temperature": 37.2,
            "spo2": 97,
            "recorded_at": "2026-07-18T08:00:00Z"
        },
        ...
    ]
    """

    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Le body doit être une liste de mesures
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

        # Limite de sécurité : max 500 mesures par synchronisation
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
                # Forcer is_synced_offline=True pour toutes les mesures du lot
                reading = serializer.save(is_synced_offline=True)
                saved.append(reading)

                # Détecter les alertes pour chaque mesure synchronisée
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
    Utilisé par Flutter pour afficher les paramètres vitaux en temps réel.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id):
        # Vérifier que le patient existe
        patient = get_object_or_404(Patient, pk=patient_id)

        # Récupérer les 10 dernières mesures
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

    Retourne l'historique complet des mesures d'un patient.
    Utilisé par Flutter pour générer les graphiques médicaux (FL Chart).

    Paramètres optionnels :
    - limit : nombre de mesures à retourner (défaut : 100)
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id):
        # Vérifier que le patient existe
        patient = get_object_or_404(Patient, pk=patient_id)

        # Paramètre limit optionnel (défaut 100, max 1000)
        limit = int(request.query_params.get('limit', 100))
        limit = min(limit, 1000)

        readings = BiometricReading.objects.filter(
            patient=patient
        ).order_by('-recorded_at')[:limit]

        serializer = BiometricReadingSerializer(readings, many=True)
        return Response({
            'patient_id': str(patient_id),
            'total': len(serializer.data),
            'limit': limit,
            'readings': serializer.data
        })
