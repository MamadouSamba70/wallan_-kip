/// Définition des endpoints et de la configuration de l'API backend Django
class ApiEndpoints {
  // Adresse IP de base du serveur backend Django (Configurable pour local/émulateur/réseau local)
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Par défaut pour émulateur Android
  static const String webBaseUrl = 'http://localhost:8000/api/v1'; // Pour test Web / Desktop

  // Timeouts HTTP
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Auth Endpoints
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String profile = '/auth/profile/';

  // Patients Endpoints
  static const String patients = '/patients/';
  static String patientDetail(String id) => '/patients/$id/';

  // Alerts Endpoints
  static const String alerts = '/alerts/';
  static String alertDetail(String id) => '/alerts/$id/';
  static String resolveAlert(String id) => '/alerts/$id/resolve/';

  // Devices & Biometrics Endpoints
  static const String devices = '/devices/';
  static const String biometrics = '/biometric-data/';
  static const String dashboardStats = '/admin/stats/';
}
