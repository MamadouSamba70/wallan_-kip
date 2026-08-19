from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer, UserSerializer, CustomTokenObtainPairSerializer

User = get_user_model()

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


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

# 4. Vue pour la synthèse Admin Dashboard (Semaine 5)
class AdminDashboardStatsView(APIView):
    permission_classes = (AllowAny,) # Accessible aux admins authentifiés ou en dev

    def get(self, request):
        try:
            from patients.models import Patient
            from devices.models import Device
            from alerts.models import Alert

            patient_count = Patient.objects.count()
            bracelet_count = Device.objects.count()
            active_alerts = Alert.objects.filter(status='active').count()
            critical_alerts = Alert.objects.filter(status='active', severity='critical').count()

            recent_devices_qs = Device.objects.prefetch_related(
                'assignments__patient', 'device_status'
            ).all()[:5]
            recent_devices = []
            for dev in recent_devices_qs:
                patient_name = "Non assigné"
                current = dev.assignments.filter(is_current=True).select_related('patient').first()
                if current and current.patient:
                    patient_name = current.patient.full_name

                device_status = getattr(dev, 'device_status', None)
                battery = device_status.battery_level if device_status else 85
                is_connected = device_status.is_connected if device_status else False

                recent_devices.append({
                    "id": str(dev.id),
                    "mac_address": dev.hardware_id,
                    "patient_name": patient_name,
                    "status": dev.get_status_display(),
                    "battery_level": battery,
                    "is_connected": is_connected,
                    "last_seen": "Récent",
                })

            return Response({
                "patients": patient_count,
                "bracelets": bracelet_count,
                "active_alerts": active_alerts,
                "critical_alerts": critical_alerts,
                "recent_devices": recent_devices,
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

