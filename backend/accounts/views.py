from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer, UserSerializer

User = get_user_model()

# 1. Vue pour l'inscription (Register)
class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    # AllowAny = Tout le monde peut accéder à cette route (pas besoin d'être connecté pour s'inscrire)
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer

# 2. Vue pour récupérer le profil de l'utilisateur connecté (Me)
class UserProfileView(generics.RetrieveAPIView):
    # IsAuthenticated = Il faut fournir un token JWT valide pour y accéder
    permission_classes = (IsAuthenticated,)
    serializer_class = UserSerializer

    def get_object(self):
        # Au lieu de chercher par ID dans l'URL, on retourne l'utilisateur lié au token envoyé
        return self.request.user

# 3. Vue pour la déconnexion (Logout)
class LogoutView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        try:
            # On récupère le refresh_token envoyé par le client
            refresh_token = request.data["refresh"]
            token = RefreshToken(refresh_token)
            # On le place sur "liste noire" pour qu'il ne puisse plus jamais servir
            token.blacklist()
            return Response({"message": "Déconnexion réussie"}, status=status.HTTP_205_RESET_CONTENT)
        except Exception as e:
            return Response({"error": "Token invalide ou déjà expiré"}, status=status.HTTP_400_BAD_REQUEST)
