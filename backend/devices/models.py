import uuid
from django.db import models
from django.conf import settings


class Device(models.Model):
    """
    Représente un bracelet connecté ESP32.
    Chaque bracelet a un identifiant matériel unique (adresse MAC Bluetooth).
    """

    STATUS_CHOICES = [
        ('unassigned', 'Non assigné'),  # Bracelet enregistré mais pas encore attribué
        ('active', 'Actif'),            # Bracelet actuellement assigné à un patient
        ('inactive', 'Inactif'),        # Bracelet désactivé ou hors service
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    hardware_id = models.CharField(max_length=50, unique=True)  # Adresse MAC Bluetooth de l'ESP32
    model = models.CharField(max_length=50)                      # Modèle du bracelet (ex: Wallan-v1)
    firmware_version = models.CharField(max_length=20)           # Version du firmware embarqué
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='unassigned')
    registered_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'devices'
        verbose_name = 'Bracelet'
        verbose_name_plural = 'Bracelets'

    def __str__(self):
        return f"{self.model} ({self.hardware_id})"


class DeviceAssignment(models.Model):
    """
    Historique complet des associations bracelet ↔ patient.
    Un bracelet ne peut avoir qu'une seule association active (is_current=True) à la fois.
    Les anciennes associations sont conservées pour l'historique.

    CORRECTION SEMAINE 2 : FK pointe vers patients.Patient (et non plus vers User)
    conformément au schéma de la base de données du cahier technique.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Bracelet concerné par cette association
    device = models.ForeignKey(
        Device,
        on_delete=models.CASCADE,
        related_name='assignments'
    )

    # Patient auquel le bracelet est assigné
    # On utilise une string 'patients.Patient' pour éviter les imports circulaires
    patient = models.ForeignKey(
        'patients.Patient',
        on_delete=models.CASCADE,
        related_name='device_assignments'
    )

    assigned_at = models.DateTimeField(auto_now_add=True)      # Date de début de l'association
    unassigned_at = models.DateTimeField(null=True, blank=True) # Date de fin (null si encore actif)
    is_current = models.BooleanField(default=True)              # True = association en cours

    class Meta:
        db_table = 'device_assignments'
        verbose_name = 'Association bracelet-patient'
        verbose_name_plural = 'Associations bracelet-patient'

    def __str__(self):
        return f"{self.device} → {self.patient} (actif: {self.is_current})"


class DeviceStatus(models.Model):
    """
    État en temps réel d'un bracelet.
    Mis à jour à chaque synchronisation Bluetooth avec le smartphone.
    Relation OneToOne : un bracelet a exactement un état à la fois.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # OneToOne car un bracelet a un seul état en temps réel
    device = models.OneToOneField(
        Device,
        on_delete=models.CASCADE,
        related_name='device_status'
    )

    battery_level = models.IntegerField()               # Niveau batterie en % (0 à 100)
    is_connected = models.BooleanField(default=False)   # True si connecté en Bluetooth
    last_sync = models.DateTimeField(null=True, blank=True)  # Dernière synchronisation serveur

    class Meta:
        db_table = 'device_status'
        verbose_name = 'État du bracelet'
        verbose_name_plural = 'États des bracelets'

    def __str__(self):
        return f"Status {self.device} - Batterie: {self.battery_level}%"