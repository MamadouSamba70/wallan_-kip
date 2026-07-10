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

    # Identifiant unique généré automatiquement
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Adresse MAC Bluetooth de l'ESP32 — unique par bracelet physique
    hardware_id = models.CharField(max_length=50, unique=True)

    # Modèle du bracelet (ex: Wallan-v1)
    model = models.CharField(max_length=50)

    # Version du firmware embarqué sur l'ESP32
    firmware_version = models.CharField(max_length=20)

    # Statut actuel du bracelet
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='unassigned')

    # Date d'enregistrement du bracelet dans le système
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
    Les anciennes associations sont conservées pour l'audit.
    """

    # Identifiant unique généré automatiquement
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Bracelet concerné par cette association
    device = models.ForeignKey(
        Device,
        on_delete=models.CASCADE,
        related_name='assignments'
    )

    # Patient auquel le bracelet est assigné
    # On utilise settings.AUTH_USER_MODEL pour pointer vers notre modèle User custom (accounts.User)
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='device_assignments'
    )

    # Date à laquelle le bracelet a été assigné au patient
    assigned_at = models.DateTimeField(auto_now_add=True)

    # Date de fin d'association — null si l'association est encore active
    unassigned_at = models.DateTimeField(null=True, blank=True)

    # True si c'est l'association en cours, False si c'est un historique
    is_current = models.BooleanField(default=True)

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

    # Identifiant unique généré automatiquement
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Bracelet concerné — OneToOne car un bracelet a un seul état en temps réel
    device = models.OneToOneField(
        Device,
        on_delete=models.CASCADE,
        related_name='device_status'
    )

    # Niveau de batterie en pourcentage (0 à 100)
    battery_level = models.IntegerField()

    # True si le bracelet est actuellement connecté en Bluetooth
    is_connected = models.BooleanField(default=False)

    # Date et heure de la dernière synchronisation avec le serveur
    last_sync = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'device_status'
        verbose_name = 'État du bracelet'
        verbose_name_plural = 'États des bracelets'

    def __str__(self):
        return f"Status {self.device} - Batterie: {self.battery_level}%"