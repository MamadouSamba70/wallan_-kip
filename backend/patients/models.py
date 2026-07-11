import uuid
from django.db import models
from accounts.models import User

class Patient(models.Model):
    """
    Modèle représentant un patient avec ses données personnelles et ses seuils d'alerte.
    Un patient est lié à un compte utilisateur et peut avoir plusieurs proches.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='patient_profile')
    full_name = models.CharField(max_length=255, help_text="Nom complet du patient")
    birth_date = models.DateField()
    
    # Type de condition médicale (rhumatisme, etc.)
    CONDITION_CHOICES = [
        ('rheumatism', 'Rhumatisme'),
        ('other', 'Autre'),
    ]
    condition = models.CharField(max_length=50, choices=CONDITION_CHOICES, default='rheumatism')
    
    # Seuils d'alerte personnalisés pour ce patient
    threshold_heart_rate = models.IntegerField(help_text="Seuil d'alerte rythme cardiaque (bpm)")
    threshold_temperature = models.DecimalField(max_digits=4, decimal_places=1, help_text="Seuil température (°C)")
    threshold_spo2 = models.IntegerField(help_text="Seuil d'alerte SpO2 (%)")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'patients'
        verbose_name_plural = "Patients"

    def __str__(self):
        return f"{self.full_name} ({self.user.email})"


class MedicalHistory(models.Model):
    """
    Historique médical du patient : antécédents, diagnostic, interventions, etc.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='medical_history')
    description = models.TextField(help_text="Description de l'antécédent ou du diagnostic")
    diagnosed_date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'medical_history'
        verbose_name_plural = "Medical Histories"
        ordering = ['-diagnosed_date']

    def __str__(self):
        return f"Antécédent de {self.patient.full_name} - {self.diagnosed_date}"


class PatientRelative(models.Model):
    """
    Représente les proches d'un patient (famille, amis) qui reçoivent les alertes.
    Un proche peut être lié à plusieurs patients.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='relatives')
    relative_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='followed_patients')
    
    RELATIONSHIP_CHOICES = [
        ('parent', 'Parent'),
        ('child', 'Enfant'),
        ('spouse', 'Conjoint(e)'),
        ('sibling', 'Frère/Sœur'),
        ('friend', 'Ami(e)'),
        ('other', 'Autre'),
    ]
    relationship = models.CharField(max_length=50, choices=RELATIONSHIP_CHOICES, default='other')
    
    is_primary_contact = models.BooleanField(default=False, help_text="Contact d'urgence prioritaire")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'patient_relatives'
        unique_together = ('patient', 'relative_user')  # Un proche ne peut être assigné qu'une fois par patient
        verbose_name_plural = "Patient Relatives"

    def __str__(self):
        return f"{self.relative_user.email} - proche de {self.patient.full_name} ({self.get_relationship_display()})"
