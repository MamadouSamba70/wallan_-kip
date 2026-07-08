from django.contrib import admin
from .models import Patient, MedicalHistory, PatientRelative

@admin.register(Patient)
class PatientAdmin(admin.ModelAdmin):
    list_display = ['full_name', 'user', 'condition', 'created_at']
    list_filter = ['condition', 'created_at']
    search_fields = ['full_name', 'user__email']
    readonly_fields = ['id', 'created_at', 'updated_at']
    fieldsets = (
        ('Informations Personnelles', {
            'fields': ('id', 'user', 'full_name', 'birth_date', 'condition')
        }),
        ('Seuils d\'Alerte', {
            'fields': ('threshold_heart_rate', 'threshold_temperature', 'threshold_spo2')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(MedicalHistory)
class MedicalHistoryAdmin(admin.ModelAdmin):
    list_display = ['patient', 'diagnosed_date', 'created_at']
    list_filter = ['diagnosed_date', 'created_at']
    search_fields = ['patient__full_name', 'description']
    readonly_fields = ['id', 'created_at']
    fieldsets = (
        ('Information', {
            'fields': ('id', 'patient', 'description', 'diagnosed_date')
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )


@admin.register(PatientRelative)
class PatientRelativeAdmin(admin.ModelAdmin):
    list_display = ['relative_user', 'patient', 'relationship', 'is_primary_contact']
    list_filter = ['relationship', 'is_primary_contact', 'created_at']
    search_fields = ['patient__full_name', 'relative_user__email']
    readonly_fields = ['id', 'created_at']
    fieldsets = (
        ('Information', {
            'fields': ('id', 'patient', 'relative_user', 'relationship', 'is_primary_contact')
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )
