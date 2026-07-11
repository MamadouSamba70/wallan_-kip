from rest_framework import serializers
from .models import Patient, MedicalHistory, PatientRelative
from accounts.models import User

class PatientSerializer(serializers.ModelSerializer):
    """Sérializer complet pour les patients avec toutes les données."""
    user_email = serializers.EmailField(source='user.email', read_only=True)
    
    class Meta:
        model = Patient
        fields = [
            'id', 'user', 'user_email', 'full_name', 'birth_date',
            'condition', 'threshold_heart_rate', 'threshold_temperature',
            'threshold_spo2', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class PatientListSerializer(serializers.ModelSerializer):
    """Sérializer simplifié pour la liste des patients."""
    user_email = serializers.EmailField(source='user.email', read_only=True)
    
    class Meta:
        model = Patient
        fields = ['id', 'full_name', 'user_email', 'condition', 'created_at']


class MedicalHistorySerializer(serializers.ModelSerializer):
    """Sérializer pour l'historique médical."""
    patient_id = serializers.UUIDField(source='patient.id', read_only=True)
    patient_name = serializers.CharField(source='patient.full_name', read_only=True)
    
    class Meta:
        model = MedicalHistory
        fields = ['id', 'patient', 'patient_id', 'patient_name', 'description', 'diagnosed_date', 'created_at']
        read_only_fields = ['id', 'created_at']


class PatientRelativeSerializer(serializers.ModelSerializer):
    """Sérializer pour les proches d'un patient."""
    relative_email = serializers.EmailField(source='relative_user.email', read_only=True)
    patient_name = serializers.CharField(source='patient.full_name', read_only=True)
    
    class Meta:
        model = PatientRelative
        fields = ['id', 'patient', 'patient_name', 'relative_user', 'relative_email', 'relationship', 'is_primary_contact', 'created_at']
        read_only_fields = ['id', 'created_at']


class PatientDetailSerializer(serializers.ModelSerializer):
    """Sérializer détaillé incluant l'historique et les proches."""
    user_email = serializers.EmailField(source='user.email', read_only=True)
    medical_history = MedicalHistorySerializer(many=True, read_only=True)
    relatives = PatientRelativeSerializer(many=True, read_only=True)
    
    class Meta:
        model = Patient
        fields = [
            'id', 'user', 'user_email', 'full_name', 'birth_date',
            'condition', 'threshold_heart_rate', 'threshold_temperature',
            'threshold_spo2', 'created_at', 'updated_at',
            'medical_history', 'relatives'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
