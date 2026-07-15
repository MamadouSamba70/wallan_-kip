from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('patients.urls')),   # Routes des patients (Fatima)
    path('api/', include('alerts.urls')),     # Routes des alertes (Fatima)
    path('api/devices/', include('devices.urls')),  # Routes des bracelets (Hady)
]