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
