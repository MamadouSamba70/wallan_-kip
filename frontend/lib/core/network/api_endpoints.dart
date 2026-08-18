// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI centraliser les endpoints ?
//
// Si l'URL backend change (ex: migration de serveur, changement de version API),
// on modifie UN SEUL fichier au lieu de rechercher dans tout le code.
// C'est le principe DRY (Don't Repeat Yourself) appliqué aux constantes réseau.
// ─────────────────────────────────────────────────────────────────────────────

/// Définition de toutes les URLs et constantes réseau du projet Wallan.
class ApiEndpoints {
  // ── URL de base ─────────────────────────────────────────────────────────────
  // 10.0.2.2 = adresse spéciale de l'émulateur Android qui pointe vers localhost de l'hôte.
  // Pour un vrai appareil physique sur le même réseau Wi-Fi, utiliser l'IP locale du PC.
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Émulateur Android
  static const String webBaseUrl = 'http://localhost:8000/api'; // Web / Desktop

  // ── Timeouts ────────────────────────────────────────────────────────────────
  // 15 secondes : suffisant pour une API Django locale ou sur réseau local.
  // Augmenter à 30s pour des serveurs distants ou connexions mobiles lentes.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ── Auth Endpoints ───────────────────────────────────────────────────────────
  // POST /api/auth/login/     → reçoit {email, password} → retourne {access, refresh, user}
  static const String login = '/auth/login/';

  // POST /api/auth/register/  → reçoit {name, email, phone, password, role} → 201 Created
  static const String register = '/auth/register/';

  // POST /api/auth/token/refresh/ → reçoit {refresh} → retourne {access}
  static const String tokenRefresh = '/auth/token/refresh/';

  // GET  /api/auth/profile/   → retourne le profil de l'utilisateur connecté
  static const String profile = '/auth/profile/';

  // POST /api/auth/logout/    → invalide le refresh token côté serveur
  static const String logout = '/auth/logout/';

  // ── Dashboard Admin Endpoint ─────────────────────────────────────────────────
  // GET /api/admin/dashboard/ → retourne les statistiques globales du système
  static const String adminDashboard = '/admin/dashboard/';

  // ── Patients Endpoints ───────────────────────────────────────────────────────
  // GET  /api/patients/       → liste tous les patients
  static const String patients = '/patients/';
  // GET  /api/patients/{id}/  → détail d'un patient
  static String patientDetail(String id) => '/patients/$id/';

  // ── Alerts Endpoints ─────────────────────────────────────────────────────────
  // GET  /api/alerts/         → liste toutes les alertes
  static const String alerts = '/alerts/';
  // GET  /api/alerts/{id}/    → détail d'une alerte
  static String alertDetail(String id) => '/alerts/$id/';
  // POST /api/alerts/{id}/resolve/ → marquer une alerte comme résolue
  static String resolveAlert(String id) => '/alerts/$id/resolve/';

  // ── Devices & Biometrics Endpoints ───────────────────────────────────────────
  // GET  /api/devices/        → liste tous les bracelets/capteurs
  static const String devices = '/devices/';
  // GET  /api/biometric-data/ → liste les données biométriques
  static const String biometrics = '/biometric-data/';

  static const String biometricsReceive = '/biometrics/';
static const String biometricsSync = '/biometrics/sync/';
static String biometricsLatest(String patientId) => '/biometrics/$patientId/';
static String biometricsHistory(String patientId) => '/biometrics/$patientId/history/';
}
