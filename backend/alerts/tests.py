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
