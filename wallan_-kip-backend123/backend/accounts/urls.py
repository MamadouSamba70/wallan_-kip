from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import RegisterView, UserProfileView, LogoutView

urlpatterns = [
    # Inscription
    path('register/', RegisterView.as_view(), name='register'),
    
    # Connexion (Génère l'Access Token et le Refresh Token)
    path('login/', TokenObtainPairView.as_view(), name='login'),
    
    # Renouvellement du Token
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Profil de l'utilisateur connecté
    path('me/', UserProfileView.as_view(), name='me'),
    
    # Déconnexion (Invalide le Refresh Token)
    path('logout/', LogoutView.as_view(), name='logout'),
]
