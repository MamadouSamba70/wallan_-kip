import uuid
from django.db import models
from accounts.models import User
from patients.models import Patient

class Alert(models.Model):
    """
    Représente une alerte générée quand les seuils vitaux d'un patient sont dépassés.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='alerts')
    
    # Type d'alerte
    ALERT_TYPE_CHOICES = [
        ('heart_rate', 'Rythme Cardiaque'),
        ('temperature', 'Température'),
        ('spo2', 'SpO2'),
        ('movement', 'Mouvement'),
    ]
    alert_type = models.CharField(max_length=20, choices=ALERT_TYPE_CHOICES)
    
    # Sévérité
    SEVERITY_CHOICES = [
        ('warning', 'Avertissement'),
        ('critical', 'Critique'),
    ]
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES)
    
    # Valeurs mesurées
    value_detected = models.DecimalField(max_digits=6, decimal_places=2, help_text="Valeur mesurée ayant déclenché l'alerte")
    threshold_value = models.DecimalField(max_digits=6, decimal_places=2, help_text="Seuil dépassé")
    
    # Statut de l'alerte
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('resolved', 'Résolue'),
        ('false_alarm', 'Fausse Alerte'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'alerts'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['patient', '-created_at']),
            models.Index(fields=['status']),
        ]

    def __str__(self):
        return f"Alerte {self.get_alert_type_display()} - {self.patient.full_name} ({self.get_severity_display()})"


class AlertNotificationLog(models.Model):
    """
    Journal des notifications envoyées pour une alerte (SMS, Push, etc.)
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    alert = models.ForeignKey(Alert, on_delete=models.CASCADE, related_name='notifications')
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='alert_notifications')
    
    # Canal de notification
    CHANNEL_CHOICES = [
        ('sms', 'SMS'),
        ('push', 'Push Notification'),
        ('email', 'Email'),
    ]
    channel = models.CharField(max_length=20, choices=CHANNEL_CHOICES)
    
    # Statut d'envoi
    STATUS_CHOICES = [
        ('sent', 'Envoyée'),
        ('failed', 'Échouée'),
        ('delivered', 'Livrée'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='sent')
    
    sent_at = models.DateTimeField(auto_now_add=True)
    delivered_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'alert_notification_logs'
        ordering = ['-sent_at']
        indexes = [
            models.Index(fields=['alert', 'channel']),
            models.Index(fields=['recipient', 'status']),
        ]

    def __str__(self):
        return f"Notification {self.get_channel_display()} pour alerte {self.alert.id} - {self.get_status_display()}"
