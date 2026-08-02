from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PatientViewSet, MedicalHistoryViewSet, PatientRelativeViewSet

router = DefaultRouter()
router.register(r'patients', PatientViewSet, basename='patient')
router.register(r'medical-history', MedicalHistoryViewSet, basename='medical-history')
router.register(r'patient-relatives', PatientRelativeViewSet, basename='patient-relative')

urlpatterns = [
    path('', include(router.urls)),
]
