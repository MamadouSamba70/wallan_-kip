from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from .models import Patient, MedicalHistory, PatientRelative
from .serializers import (
    PatientSerializer,
    PatientListSerializer,
    PatientDetailSerializer,
    MedicalHistorySerializer,
    PatientRelativeSerializer
)

class PatientViewSet(viewsets.ModelViewSet):
    """
    API CRUD pour les patients.
    - GET /api/patients/ : Liste des patients
    - POST /api/patients/ : Créer un nouveau patient
    - GET /api/patients/{id}/ : Détails d'un patient
    - PUT /api/patients/{id}/ : Modifier un patient
    - DELETE /api/patients/{id}/ : Supprimer un patient
    """
    queryset = Patient.objects.all()
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        """Utilise des sérializers différents selon l'action."""
        if self.action == 'retrieve':
            return PatientDetailSerializer
        elif self.action == 'list':
            return PatientListSerializer
        return PatientSerializer

    @action(detail=True, methods=['get'])
    def medical_history(self, request, pk=None):
        """Récupère l'historique médical d'un patient."""
        patient = self.get_object()
        history = patient.medical_history.all()
        serializer = MedicalHistorySerializer(history, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def relatives(self, request, pk=None):
        """Récupère les proches d'un patient."""
        patient = self.get_object()
        relatives = patient.relatives.all()
        serializer = PatientRelativeSerializer(relatives, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def add_relative(self, request, pk=None):
        """Ajoute un proche au patient."""
        patient = self.get_object()
        serializer = PatientRelativeSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(patient=patient)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class MedicalHistoryViewSet(viewsets.ModelViewSet):
    """
    API CRUD pour l'historique médical.
    """
    queryset = MedicalHistory.objects.all()
    serializer_class = MedicalHistorySerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        """Crée une nouvelle entrée d'historique."""
        serializer.save()


class PatientRelativeViewSet(viewsets.ModelViewSet):
    """
    API CRUD pour les proches d'un patient.
    """
    queryset = PatientRelative.objects.all()
    serializer_class = PatientRelativeSerializer
    permission_classes = [IsAuthenticated]
