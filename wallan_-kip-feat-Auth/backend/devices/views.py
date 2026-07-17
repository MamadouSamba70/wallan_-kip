from rest_framework.views import APIView
from rest_framework.generics import ListAPIView, RetrieveAPIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.utils import timezone

from .models import Device, DeviceAssignment, DeviceStatus
from .serializers import (
    DeviceSerializer,
    DeviceRegisterSerializer,
    DeviceAssociateSerializer,
    DeviceStatusSerializer,
)
from patients.models import Patient


class DeviceRegisterView(APIView):
    """
    POST /api/devices/register/

    Enregistre un nouveau bracelet ESP32 dans le système.
    Le bracelet est créé avec le statut 'unassigned' (pas encore associé à un patient).
    Un DeviceStatus vide est automatiquement créé pour ce bracelet.

    Body attendu :
    {
        "hardware_id": "AA:BB:CC:DD:EE:FF",
        "model": "Wallan-v1",
        "firmware_version": "1.0.0"
    }
    """

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = DeviceRegisterSerializer(data=request.data)

        if serializer.is_valid():
            # Créer le bracelet avec statut 'unassigned' par défaut
            device = serializer.save(status='unassigned')

            # Créer automatiquement un DeviceStatus vide pour ce bracelet
            # Chaque bracelet doit avoir un état dès son enregistrement
            DeviceStatus.objects.create(
                device=device,
                battery_level=0,
                is_connected=False,
                last_sync=None
            )

            return Response(
                {
                    'message': 'Bracelet enregistré avec succès.',
                    'device': DeviceSerializer(device).data
                },
                status=status.HTTP_201_CREATED
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DeviceAssociateView(APIView):
    """
    POST /api/devices/{id}/associate/

    Associe un bracelet existant à un patient.

    Logique complète :
    1. Vérifier que le bracelet existe (via l'ID dans l'URL)
    2. Vérifier que le hardware_id envoyé correspond bien à ce bracelet (sécurité)
    3. Vérifier que le patient existe
    4. Clôturer l'ancienne association active du patient (s'il en avait une)
    5. Clôturer l'ancienne association active du bracelet (s'il était déjà assigné)
    6. Créer la nouvelle association avec is_current=True
    7. Mettre le statut du bracelet à 'active'

    Body attendu :
    {
        "patient_id": "uuid-du-patient",
        "hardware_id": "AA:BB:CC:DD:EE:FF"
    }
    """

    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        # Étape 1 : Récupérer le bracelet par son UUID (dans l'URL)
        device = get_object_or_404(Device, pk=pk)

        # Valider le body de la requête
        serializer = DeviceAssociateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        patient_id = serializer.validated_data['patient_id']
        hardware_id = serializer.validated_data['hardware_id']

        # Étape 2 : Vérifier que le hardware_id correspond bien au bracelet
        # Sécurité : évite qu'on associe accidentellement le mauvais bracelet
        if device.hardware_id != hardware_id:
            return Response(
                {'error': 'Le hardware_id ne correspond pas à ce bracelet.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Étape 3 : Vérifier que le patient existe
        patient = get_object_or_404(Patient, pk=patient_id)

        # Étape 4 : Clôturer l'ancienne association active du patient
        # Un patient ne peut avoir qu'un seul bracelet actif à la fois
        DeviceAssignment.objects.filter(
            patient=patient,
            is_current=True
        ).update(
            is_current=False,
            unassigned_at=timezone.now()
        )

        # Étape 5 : Clôturer l'ancienne association active du bracelet
        # Un bracelet ne peut être assigné qu'à un seul patient à la fois
        DeviceAssignment.objects.filter(
            device=device,
            is_current=True
        ).update(
            is_current=False,
            unassigned_at=timezone.now()
        )

        # Étape 6 : Créer la nouvelle association
        assignment = DeviceAssignment.objects.create(
            device=device,
            patient=patient,
            is_current=True
        )

        # Étape 7 : Mettre à jour le statut du bracelet
        device.status = 'active'
        device.save()

        return Response(
            {
                'message': f'Bracelet associé avec succès au patient {patient.full_name}.',
                'device': DeviceSerializer(device).data,
                'assignment_id': str(assignment.id),
                'assigned_at': assignment.assigned_at
            },
            status=status.HTTP_200_OK
        )


class DeviceListView(ListAPIView):
    """
    GET /api/devices/
    Retourne la liste de tous les bracelets enregistrés dans le système.
    Triés du plus récent au plus ancien.
    """

    permission_classes = [IsAuthenticated]
    serializer_class = DeviceSerializer
    queryset = Device.objects.all().order_by('-registered_at')


class DeviceStatusView(RetrieveAPIView):
    """
    GET /api/devices/{id}/status/
    Retourne l'état en temps réel d'un bracelet :
    niveau de batterie, connexion Bluetooth, dernière synchronisation.
    """

    permission_classes = [IsAuthenticated]
    serializer_class = DeviceStatusSerializer

    def get_object(self):
        # Récupérer d'abord le bracelet, puis son statut associé
        device = get_object_or_404(Device, pk=self.kwargs['pk'])
        return get_object_or_404(DeviceStatus, device=device)