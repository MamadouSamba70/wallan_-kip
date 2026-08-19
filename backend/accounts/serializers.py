from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Profile

# On récupère notre modèle User personnalisé
User = get_user_model()

# 1. Sérialiseur pour lire les données du Profil
class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = Profile
        fields = ['phone', 'photo', 'language']

# 2. Sérialiseur pour lire les données de l'Utilisateur
class UserSerializer(serializers.ModelSerializer):
    # On imbrique le ProfileSerializer pour avoir les infos du profil avec l'utilisateur
    profile = ProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'role', 'profile']

# 3. Sérialiseur spécifique pour l'Inscription (Register)
class RegisterSerializer(serializers.ModelSerializer):
    # write_only=True garantit que le mot de passe ne sera jamais renvoyé lors de la lecture
    password = serializers.CharField(write_only=True, min_length=8)
    
    class Meta:
        model = User
        fields = ['email', 'password', 'role']

    def create(self, validated_data):
        # On utilise notre UserManager pour créer l'utilisateur proprement (hachage du mot de passe)
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            role=validated_data.get('role', 'patient')
        )
        # On crée automatiquement un profil vide lié à ce nouvel utilisateur
        Profile.objects.create(user=user)
        
        return user


# 4. Sérialiseur de connexion personnalisé (Custom SimpleJWT)
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        user = self.user
        
        # Récupération du nom du patient si c'est un patient, sinon l'email
        full_name = user.email
        if hasattr(user, 'patient_profile') and user.patient_profile:
            full_name = user.patient_profile.full_name

        phone = ''
        if hasattr(user, 'profile') and user.profile:
            phone = user.profile.phone

        data['user'] = {
            'id': str(user.id),
            'email': user.email,
            'name': full_name,
            'role': user.role,
            'phone': phone,
        }
        return data

