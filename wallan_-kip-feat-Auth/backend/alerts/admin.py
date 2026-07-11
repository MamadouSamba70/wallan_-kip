from django.contrib import admin
from .models import Alert, AlertNotificationLog

@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):
    list_display = ['patient', 'alert_type', 'severity', 'status', 'created_at']
    list_filter = ['alert_type', 'severity', 'status', 'created_at']
    search_fields = ['patient__full_name', 'patient__user__email']
    readonly_fields = ['id', 'created_at', 'resolved_at']
    fieldsets = (
        ('Information d\'Alerte', {
            'fields': ('id', 'patient', 'alert_type', 'severity', 'value_detected', 'threshold_value')
        }),
        ('Statut', {
            'fields': ('status', 'created_at', 'resolved_at')
        }),
    )


@admin.register(AlertNotificationLog)
class AlertNotificationLogAdmin(admin.ModelAdmin):
    list_display = ['alert', 'recipient', 'channel', 'status', 'sent_at']
    list_filter = ['channel', 'status', 'sent_at']
    search_fields = ['alert__id', 'recipient__email']
    readonly_fields = ['id', 'sent_at', 'delivered_at']
    fieldsets = (
        ('Information', {
            'fields': ('id', 'alert', 'recipient', 'channel', 'status')
        }),
        ('Timestamps', {
            'fields': ('sent_at', 'delivered_at')
        }),
    )
