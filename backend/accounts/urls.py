from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import RegisterView, UserProfileView, LogoutView, CustomTokenObtainPairView

urlpatterns = [
    # Inscription
    path('register/', RegisterView.as_view(), name='register'),
    
    # Connexion (Génère l'Access Token, Refresh Token ET renvoie le profil User)
    path('login/', CustomTokenObtainPairView.as_view(), name='login'),

    
    # Renouvellement du Token
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Profil de l'utilisateur connecté
    path('me/', UserProfileView.as_view(), name='me'),
    
    # Déconnexion (Invalide le Refresh Token)
    path('logout/', LogoutView.as_view(), name='logout'),
]
