from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import Alert, AlertNotificationLog
from .serializers import AlertSerializer, AlertListSerializer, AlertNotificationLogSerializer

class AlertViewSet(viewsets.ModelViewSet):
    """
    API CRUD pour les alertes.
    - GET /api/alerts/ : Liste des alertes
    - POST /api/alerts/ : Créer une nouvelle alerte
    - GET /api/alerts/{id}/ : Détails d'une alerte
    - PUT /api/alerts/{id}/ : Modifier une alerte
    - DELETE /api/alerts/{id}/ : Supprimer une alerte
    """
    queryset = Alert.objects.all()
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        """Utilise des sérializers différents selon l'action."""
        if self.action == 'list':
            return AlertListSerializer
        return AlertSerializer

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Récupère les alertes actives."""
        alerts = Alert.objects.filter(status='active')
        serializer = self.get_serializer(alerts, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_patient(self, request):
        """Récupère les alertes d'un patient spécifique."""
        patient_id = request.query_params.get('patient_id')
        if not patient_id:
            return Response(
                {'error': 'patient_id parameter required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        alerts = Alert.objects.filter(patient_id=patient_id)
        serializer = self.get_serializer(alerts, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Marque une alerte comme résolue."""
        alert = self.get_object()
        alert.status = 'resolved'
        alert.resolved_at = timezone.now()
        alert.save()
        serializer = self.get_serializer(alert)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def mark_false_alarm(self, request, pk=None):
        """Marque une alerte comme fausse alerte."""
        alert = self.get_object()
        alert.status = 'false_alarm'
        alert.resolved_at = timezone.now()
        alert.save()
        serializer = self.get_serializer(alert)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def notifications(self, request, pk=None):
        """Récupère toutes les notifications pour une alerte."""
        alert = self.get_object()
        notifications = alert.notifications.all()
        serializer = AlertNotificationLogSerializer(notifications, many=True)
        return Response(serializer.data)


class AlertNotificationLogViewSet(viewsets.ModelViewSet):
    """
    API CRUD pour les logs de notification d'alertes.
    """
    queryset = AlertNotificationLog.objects.all()
    serializer_class = AlertNotificationLogSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=True, methods=['post'])
    def mark_delivered(self, request, pk=None):
        """Marque une notification comme livrée."""
        notification = self.get_object()
        notification.status = 'delivered'
        notification.delivered_at = timezone.now()
        notification.save()
        serializer = self.get_serializer(notification)
        return Response(serializer.data)
