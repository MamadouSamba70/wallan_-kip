import uuid
from django.db import models
from devices.models import Device


class BiometricReading(models.Model):
    """
    Stocke une mesure biométrique envoyée par le bracelet ESP32.
    Supporte le mode hors-ligne : les mesures prises sans connexion
    sont stockées localement puis synchronisées plus tard (is_synced_offline=True).

    CORRECTION SEMAINE 3 : FK patient pointe vers patients.Patient
    (et non plus vers User) pour accéder directement aux seuils d'alerte du patient.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Patient dont proviennent les données — accès direct aux seuils via patient.threshold_*
    patient = models.ForeignKey(
        'patients.Patient',
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

    # Données brutes de l'accéléromètre stockées en JSON
    movement_data = models.JSONField(null=True, blank=True)

    # Date et heure de la mesure réelle sur le bracelet (pas forcément l'heure d'envoi)
    recorded_at = models.DateTimeField()

    # Date et heure de réception par le serveur
    synced_at = models.DateTimeField(auto_now_add=True)

    # True si la donnée a été envoyée après une coupure réseau
    is_synced_offline = models.BooleanField(default=False)

    class Meta:
        db_table = 'biometric_readings'
        verbose_name = 'Mesure biométrique'
        verbose_name_plural = 'Mesures biométriques'
        ordering = ['-recorded_at']

    def __str__(self):
        return f"Mesure {self.patient} — {self.recorded_at} | FC:{self.heart_rate} T:{self.temperature} SpO2:{self.spo2}"


class LocationLog(models.Model):
    """
    Enregistre la position GPS du patient au moment d'une mesure.
    Utilisé par les proches pour localiser le patient en cas d'urgence.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Patient concerné — même logique, FK vers patients.Patient
    patient = models.ForeignKey(
        'patients.Patient',
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