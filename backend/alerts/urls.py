from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AlertViewSet, AlertNotificationLogViewSet

router = DefaultRouter()
router.register(r'alerts', AlertViewSet, basename='alert')
router.register(r'alert-notifications', AlertNotificationLogViewSet, basename='alert-notification')

urlpatterns = [
    path('', include(router.urls)),
]
