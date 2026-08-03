from django.contrib import admin
from .models import Device, DeviceAssignment, DeviceStatus


@admin.register(Device)
class DeviceAdmin(admin.ModelAdmin):
    """Interface admin pour les bracelets connectés."""
    list_display = ['hardware_id', 'model', 'firmware_version', 'status', 'registered_at']
    list_filter = ['status']
    search_fields = ['hardware_id', 'model']
    ordering = ['-registered_at']


@admin.register(DeviceAssignment)
class DeviceAssignmentAdmin(admin.ModelAdmin):
    """Interface admin pour l'historique des associations bracelet-patient."""
    list_display = ['device', 'patient', 'assigned_at', 'unassigned_at', 'is_current']
    list_filter = ['is_current']
    ordering = ['-assigned_at']


@admin.register(DeviceStatus)
class DeviceStatusAdmin(admin.ModelAdmin):
    """Interface admin pour l'état en temps réel des bracelets."""
    list_display = ['device', 'battery_level', 'is_connected', 'last_sync']
    list_filter = ['is_connected']