from rest_framework import serializers
from .models import Alert, AlertNotificationLog
from accounts.models import User
from patients.models import Patient

class AlertSerializer(serializers.ModelSerializer):
    """Sérializer pour les alertes."""
    patient_name = serializers.CharField(source='patient.full_name', read_only=True)
    patient_email = serializers.EmailField(source='patient.user.email', read_only=True)
    alert_type_display = serializers.CharField(source='get_alert_type_display', read_only=True)
    severity_display = serializers.CharField(source='get_severity_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Alert
        fields = [
            'id', 'patient', 'patient_name', 'patient_email',
            'alert_type', 'alert_type_display',
            'severity', 'severity_display',
            'value_detected', 'threshold_value',
            'status', 'status_display',
            'created_at', 'resolved_at'
        ]
        read_only_fields = ['id', 'created_at', 'resolved_at']


class AlertListSerializer(serializers.ModelSerializer):
    """Sérializer simplifié pour la liste des alertes."""
    patient_name = serializers.CharField(source='patient.full_name', read_only=True)
    alert_type_display = serializers.CharField(source='get_alert_type_display', read_only=True)
    severity_display = serializers.CharField(source='get_severity_display', read_only=True)
    
    class Meta:
        model = Alert
        fields = [
            'id', 'patient_name',
            'alert_type', 'alert_type_display',
            'severity', 'severity_display',
            'value_detected', 'created_at'
        ]


class AlertNotificationLogSerializer(serializers.ModelSerializer):
    """Sérializer pour les logs de notification."""
    alert_id = serializers.UUIDField(source='alert.id', read_only=True)
    recipient_email = serializers.EmailField(source='recipient.email', read_only=True)
    channel_display = serializers.CharField(source='get_channel_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = AlertNotificationLog
        fields = [
            'id', 'alert', 'alert_id',
            'recipient', 'recipient_email',
            'channel', 'channel_display',
            'status', 'status_display',
            'sent_at', 'delivered_at'
        ]
        read_only_fields = ['id', 'sent_at']
