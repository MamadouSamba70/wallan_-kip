from django.contrib import admin
from .models import BiometricReading, LocationLog


@admin.register(BiometricReading)
class BiometricReadingAdmin(admin.ModelAdmin):
    """Interface admin pour les mesures biométriques."""
    list_display = ['patient', 'device', 'heart_rate', 'temperature', 'spo2', 'recorded_at', 'is_synced_offline']
    list_filter = ['is_synced_offline']
    search_fields = ['patient__full_name']
    ordering = ['-recorded_at']


@admin.register(LocationLog)
class LocationLogAdmin(admin.ModelAdmin):
    """Interface admin pour les positions GPS."""
    list_display = ['patient', 'latitude', 'longitude', 'recorded_at']
    ordering = ['-recorded_at']