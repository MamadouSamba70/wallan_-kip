import uuid
from django.db import models
from django.conf import settings
from devices.models import Device


class BiometricReading(models.Model):
    """
    Stocke une mesure biométrique envoyée par le bracelet.
    Supporte le mode hors-ligne : les mesures prises sans connexion
    sont stockées localement puis synchronisées plus tard (is_synced_offline=True).
    """

    # Identifiant unique généré automatiquement
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Patient dont proviennent les données
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='biometric_readings'
    )

    # Bracelet qui a effectué la mesure
    device = models.ForeignKey(
        Device,
        on_delete=models.CASCADE,
        related_name='biometric_readings'
    )

    # Fréquence cardiaque en battements par minute (bpm)
    heart_rate = models.IntegerField()

    # Température corporelle en degrés Celsius
    temperature = models.DecimalField(max_digits=4, decimal_places=1)

    # Saturation en oxygène en pourcentage (SpO2)
    spo2 = models.IntegerField()

    # Données brutes de l'accéléromètre (mouvements du patient) stockées en JSON
    movement_data = models.JSONField(null=True, blank=True)

    # Date et heure de la mesure réelle sur le bracelet (pas forcément l'heure d'envoi)
    recorded_at = models.DateTimeField()

    # Date et heure de réception par le serveur
    synced_at = models.DateTimeField(auto_now_add=True)

    # True si la donnée a été envoyée après une coupure réseau (synchronisation différée)
    is_synced_offline = models.BooleanField(default=False)

    class Meta:
        db_table = 'biometric_readings'
        verbose_name = 'Mesure biométrique'
        verbose_name_plural = 'Mesures biométriques'
        # Tri par défaut : les mesures les plus récentes en premier
        ordering = ['-recorded_at']

    def __str__(self):
        return f"Mesure {self.patient} — {self.recorded_at} | FC:{self.heart_rate} T:{self.temperature} SpO2:{self.spo2}"


class LocationLog(models.Model):
    """
    Enregistre la position GPS du patient au moment d'une mesure.
    Utilisé par les proches pour localiser le patient en cas d'urgence.
    """

    # Identifiant unique généré automatiquement
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Patient concerné par cette position
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='location_logs'
    )

    # Coordonnée GPS latitude (ex: 9.537500)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)

    # Coordonnée GPS longitude (ex: -13.677300)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)

    # Date et heure de la localisation
    recorded_at = models.DateTimeField()

    class Meta:
        db_table = 'location_logs'
        verbose_name = 'Position GPS'
        verbose_name_plural = 'Positions GPS'
        ordering = ['-recorded_at']

    def __str__(self):
        return f"Position {self.patient} — {self.recorded_at} ({self.latitude}, {self.longitude})"