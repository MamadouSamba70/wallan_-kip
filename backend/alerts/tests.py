# ==============================================================================
# TESTS DES NOTIFICATIONS ET DES SERVICES SMS/PUSH (Semaine 4 - Fatima Abdul Sow)
# ==============================================================================

from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from patients.models import Patient, PatientRelative
from accounts.models import Profile
from alerts.models import Alert, AlertNotificationLog
from alerts.services import AfricasTalkingSMSService, FirebasePushService

User = get_user_model()


class NotificationServicesTestCase(TestCase):
    """
    [SEMAINE 4 - FATIMA ABDUL SOW]
    Classe de tests unitaires pour valider les services de notifications (SMS & Push).
    """

    def setUp(self):
        # Création du client d'API REST
        self.client = APIClient()

        # Création d'un utilisateur médecin / admin pour les requêtes authentifiées
        self.doctor_user = User.objects.create_user(
            email='fatima@wallan.health',
            password='password123',
            role='admin'
        )
        self.client.force_authenticate(user=self.doctor_user)

        # Création d'un utilisateur patient et son profil
        self.patient_user = User.objects.create_user(
            email='modou@wallan.health',
            password='password123',
            role='patient'
        )
        Profile.objects.create(user=self.patient_user, phone='+221772223344')

        # Création de la fiche Patient associée selon le vrai schéma de patients/models.py
        self.patient = Patient.objects.create(
            user=self.patient_user,
            full_name="Modou Ndiaye",
            birth_date="1985-05-15",
            condition="rheumatism",
            threshold_heart_rate=100,
            threshold_temperature=38.5,
            threshold_spo2=90
        )

        # Création d'un utilisateur Proche et son profil
        self.relative_user = User.objects.create_user(
            email='aminata@wallan.health',
            password='password123',
            role='proche'
        )
        Profile.objects.create(user=self.relative_user, phone='+221773334455')

        # Association du proche au patient
        self.relative = PatientRelative.objects.create(
            patient=self.patient,
            relative_user=self.relative_user,
            relationship="spouse",
            is_primary_contact=True
        )

    def test_africastalking_sms_service_simulation(self):
        """
        Teste le fonctionnement du service SMS Africa's Talking (mode simulation/dev).
        """
        sms_service = AfricasTalkingSMSService()
        result = sms_service.send_sms('+221770000000', 'Test SMS Fatima Semaine 4')

        self.assertEqual(result['status'], 'sent')
        self.assertIn('mode', result)

    def test_firebase_push_service_simulation(self):
        """
        Teste le fonctionnement du service Firebase Push Notification (mode simulation/dev).
        """
        push_service = FirebasePushService()
        result = push_service.send_push_notification('fake_token_123', 'Alerte Test', 'Contenu du test')

        self.assertEqual(result['status'], 'sent')
        self.assertIn('mode', result)

    def test_endpoint_test_sms(self):
        """
        Teste le livrable principal de la Semaine 4 : POST /api/alerts/test_sms/
        """
        payload = {
            'phone_number': '+221774445566',
            'message': 'SMS de test du livrable semaine 4'
        }
        response = self.client.post('/api/alerts/test_sms/', payload, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['result']['status'], 'sent')

    def test_alert_creation_triggers_notifications(self):
        """
        Vérifie que la création d'une alerte déclenche automatiquement l'enregistrement
        des notifications SMS pour le patient et son proche dans AlertNotificationLog.
        """
        alert_payload = {
            'patient': str(self.patient.id),
            'alert_type': 'heart_rate',
            'severity': 'critical',
            'value_detected': 145.0,
            'threshold_value': 120.0,
            'status': 'active'
        }

        response = self.client.post('/api/alerts/', alert_payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        alert_id = response.data['id']
        logs = AlertNotificationLog.objects.filter(alert_id=alert_id)

        # Au moins 2 SMS doivent être enregistrés (1 pour le patient, 1 pour le proche)
        self.assertGreaterEqual(logs.count(), 2)


class AlertDeduplicationWeek6TestCase(TestCase):
    """
    [SEMAINE 6 - FATIMA ABDUL SOW - LIVRABLE SEMAINE 6]
    Tests unitaires pour la déduplication des alertes et la gestion des cas limites.
    """

    def setUp(self):
        from devices.models import Device
        from django.utils import timezone

        self.client = APIClient()
        self.user = User.objects.create_user(
            email='fatima_semaine6@wallan.health',
            password='password123',
            role='admin'
        )
        self.client.force_authenticate(user=self.user)

        self.patient_user = User.objects.create_user(
            email='patient_sem6@wallan.health',
            password='password123',
            role='patient'
        )
        Profile.objects.create(user=self.patient_user, phone='+221778889900')

        self.patient = Patient.objects.create(
            user=self.patient_user,
            full_name="Awa Ndiaye",
            birth_date="1990-01-01",
            condition="hypertension",
            threshold_heart_rate=100,
            threshold_temperature=38.0,
            threshold_spo2=92
        )

        # Création d'un bracelet connecté pour les tests biométriques
        self.device = Device.objects.create(
            hardware_id="AA:BB:CC:DD:EE:66",
            model="Wallan-v1",
            firmware_version="1.0.0",
            status="active"
        )

    def test_alert_deduplication_prevents_duplicate_active_alerts(self):
        """
        [SEMAINE 6 - FATIMA ABDUL SOW]
        Vérifie que la réception successive de deux mesures anormales rapprochées
        ne crée pas deux alertes actives distinctes en base de données (anti-spam).
        """
        from biometric_data.views import detect_and_create_alerts
        from biometric_data.models import BiometricReading
        from django.utils import timezone

        now = timezone.now()

        # Premières mesures anormales
        reading1 = BiometricReading.objects.create(
            patient=self.patient,
            device=self.device,
            heart_rate=130,
            temperature=37.0,
            spo2=98,
            recorded_at=now
        )
        alerts1 = detect_and_create_alerts(reading1, self.patient)
        self.assertEqual(len(alerts1), 1)
        self.assertEqual(Alert.objects.filter(patient=self.patient, alert_type='heart_rate').count(), 1)

        # Seconde mesure anormale dans la fenêtre de temporisation (ex: 1 min après)
        reading2 = BiometricReading.objects.create(
            patient=self.patient,
            device=self.device,
            heart_rate=135,
            temperature=37.0,
            spo2=98,
            recorded_at=now
        )
        alerts2 = detect_and_create_alerts(reading2, self.patient)
        
        # Aucun nouvel objet alerte ne doit être retourné en tant que nouvellement créé
        self.assertEqual(len(alerts2), 0)

        # Le nombre total d'alertes en base doit rester à 1
        self.assertEqual(Alert.objects.filter(patient=self.patient, alert_type='heart_rate').count(), 1)

        # La valeur détectée dans l'alerte existante a été mise à jour à 135
        alert = Alert.objects.get(patient=self.patient, alert_type='heart_rate')
        self.assertEqual(float(alert.value_detected), 135.0)

    def test_batch_sync_offline_deduplicates_alerts(self):
        """
        [SEMAINE 6 - FATIMA ABDUL SOW]
        Vérifie la déduplication lors de la synchronisation en masse (Batch Sync)
        de plusieurs mesures enregistrées hors-ligne.
        """
        payload_sync = [
            {
                'patient': str(self.patient.id),
                'device': str(self.device.id),
                'heart_rate': 125,
                'temperature': 37.0,
                'spo2': 98,
                'recorded_at': '2026-08-11T10:00:00Z'
            },
            {
                'patient': str(self.patient.id),
                'device': str(self.device.id),
                'heart_rate': 128,
                'temperature': 37.0,
                'spo2': 98,
                'recorded_at': '2026-08-11T10:05:00Z'
            },
            {
                'patient': str(self.patient.id),
                'device': str(self.device.id),
                'heart_rate': 132,
                'temperature': 37.0,
                'spo2': 98,
                'recorded_at': '2026-08-11T10:10:00Z'
            }
        ]

        response = self.client.post('/api/biometrics/sync/', payload_sync, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['saved_count'], 3)

        # Même si 3 mesures dépassaient le seuil, une seule alerte globale a été créée
        self.assertEqual(Alert.objects.filter(patient=self.patient, alert_type='heart_rate').count(), 1)
        self.assertEqual(response.data['alerts_created'], 1)


