from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),

    # Authentification (Hadjiratou)
    path('api/auth/', include('accounts.urls')),

    # Patients et alertes (Fatima)
    path('api/', include('patients.urls')),
    path('api/', include('alerts.urls')),

    # Bracelets connectés (Hady - semaine 2)
    path('api/devices/', include('devices.urls')),

    # Données biométriques (Hady - semaine 3)
    path('api/biometrics/', include('biometric_data.urls')),
]
