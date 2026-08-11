from django.test import TestCase
from django.utils import timezone
from datetime import date
from rest_framework.test import APIClient
from rest_framework import status
from accounts.models import User
from patients.models import Patient, MedicalHistory, PatientRelative
from devices.models import Device
from biometric_data.models import BiometricReading
from alerts.models import Alert

class PatientSemaine5Tests(TestCase):
    """
    [SEMAINE 5 - FATIMA ABDUL SOW]
    Tests unitaires pour l'historique complet et les recommandations de santé.
    """

    def setUp(self):
        self.client = APIClient()

        # Création de l'utilisateur patient
        self.user = User.objects.create_user(
            email='fatima_test@wallan.health',
            password='Password123!',
            role='patient'
        )
        self.client.force_authenticate(user=self.user)

        # Création du profil patient
        self.patient = Patient.objects.create(
            user=self.user,
            full_name='Fatima Sow Test',
            birth_date=date(1990, 5, 15),
            condition='rheumatism',
            threshold_heart_rate=100,
            threshold_temperature=38.0,
            threshold_spo2=92
        )

        # Antécédent médical
        self.history = MedicalHistory.objects.create(
            patient=self.patient,
            description='Diagnostic initial de rhumatisme',
            diagnosed_date=date(2023, 1, 10)
        )

        # Device et mesures biométriques
        self.device = Device.objects.create(
            hardware_id='AA:BB:CC:DD:EE:FF',
            model='Wallan-v1',
            firmware_version='1.0.0',
            status='active'
        )

        self.reading = BiometricReading.objects.create(
            patient=self.patient,
            device=self.device,
            heart_rate=115,  # Dépasse le seuil de 100 bpm
            temperature=38.5, # Dépasse 38.0 °C
            spo2=90,         # En dessous du seuil de 92%
            recorded_at=timezone.now()
        )

    def test_full_history_endpoint(self):
        """Vérifie la réponse de /api/patients/{id}/full-history/"""
        url = f'/api/patients/{self.patient.id}/full-history/'
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['full_name'], 'Fatima Sow Test')
        self.assertIn('medical_history', response.data)
        self.assertIn('biometric_readings', response.data)
        self.assertIn('alerts', response.data)
        self.assertIn('recommendations', response.data)
        self.assertGreaterEqual(len(response.data['biometric_readings']), 1)

    def test_recommendations_endpoint(self):
        """Vérifie la réponse de /api/patients/{id}/recommendations/ et les alertes générées"""
        url = f'/api/patients/{self.patient.id}/recommendations/'
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['patient_name'], 'Fatima Sow Test')
        recommendations = response.data['recommendations']

        # Vérification qu'on détecte la fréquence cardiaque élevée, la fièvre et SpO2 faible
        categories = [r['category'] for r in recommendations]
        self.assertIn('vital_sign', categories)
        self.assertIn('condition', categories)

        titles = [r['title'] for r in recommendations]
        self.assertTrue(any('Rythme cardiaque' in t for t in titles))
        self.assertTrue(any('Température' in t for t in titles))
        self.assertTrue(any('Saturation' in t for t in titles))
