// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI centraliser les endpoints ?
//
// Si l'URL backend change (ex: migration de serveur, changement de version API),
// on modifie UN SEUL fichier au lieu de rechercher dans tout le code.
// C'est le principe DRY (Don't Repeat Yourself) appliqué aux constantes réseau.
//
// ─────────────────────────────────────────────────────────────────────────────
// CORRECTIONS SEMAINE 5 (backend réel reçu) :
//
// Plusieurs chemins ci-dessous ne correspondaient PAS au routing réel du
// backend Django (wallan/urls.py + urls.py de chaque app) et ont été corrigés :
//   - `profile`      : '/auth/profile/'        → '/auth/me/'        (UserProfileView)
//   - `tokenRefresh` : '/auth/token/refresh/'   → '/auth/refresh/'   (accounts/urls.py)
//   - `biometrics`   : '/biometric-data/'       → '/biometrics/...'  (chemins par patient_id)
// Ajouts : by_patient sur les alertes, alert-notifications, patient-relatives.
// ─────────────────────────────────────────────────────────────────────────────

/// Définition de toutes les URLs et constantes réseau du projet Wallan.
class ApiEndpoints {
  // ── URL de base ─────────────────────────────────────────────────────────────
  // 10.0.2.2 = adresse spéciale de l'émulateur Android qui pointe vers localhost de l'hôte.
  // Pour un vrai appareil physique sur le même réseau Wi-Fi, utiliser l'IP locale du PC.
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Émulateur Android
  static const String webBaseUrl = 'http://localhost:8000/api'; // Web / Desktop

  // ── Timeouts ────────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ── Auth Endpoints (accounts/urls.py) ─────────────────────────────────────────
  // POST /api/auth/login/     → SimpleJWT TokenObtainPairView, reçoit {email, password}
  //                              retourne UNIQUEMENT {access, refresh} (pas de "user" imbriqué)
  static const String login = '/auth/login/';

  // POST /api/auth/register/  → reçoit {email, password, role} → 201 Created
  // NOTE : RegisterSerializer n'accepte QUE ces 3 champs (pas de name/phone malgré
  // un ancien commentaire ici) — signalé à Hadjiratou/Mamadou Samba (hors périmètre Alpha).
  static const String register = '/auth/register/';

  // POST /api/auth/refresh/   → reçoit {refresh} → retourne {access}
  static const String tokenRefresh = '/auth/refresh/';

  // GET  /api/auth/me/        → retourne {id, email, role, profile:{phone,photo,language}}
  static const String profile = '/auth/me/';

  // POST /api/auth/logout/    → reçoit {refresh}, invalide le refresh token côté serveur
  static const String logout = '/auth/logout/';

  // ── Dashboard Admin Endpoint ─────────────────────────────────────────────────
  // ⚠️ Non implémenté côté backend à ce jour (aucune app "statistics" ou vue
  // "dashboard" trouvée dans le code reçu). Conservé ici pour Mamadou Samba,
  // hors périmètre Alpha (Alertes/Notifications/Stats).
  static const String adminDashboard = '/admin/dashboard/';

  // ── Patients Endpoints (patients/urls.py, DefaultRouter) ────────────────────
  // GET  /api/patients/       → liste TOUS les patients (non filtrée par rôle
  //                              malgré le Plan de Travail — PatientViewSet.queryset
  //                              = Patient.objects.all())
  static const String patients = '/patients/';
  static String patientDetail(String id) => '/patients/$id/';

  // GET  /api/patient-relatives/ → liste TOUS les liens patient↔proche (non filtrée
  //                                 par utilisateur connecté). Utilisé pour retrouver
  //                                 le patient suivi par le Proche connecté, en
  //                                 croisant avec /auth/me/ côté client.
  static const String patientRelatives = '/patient-relatives/';

  // ── Alerts Endpoints (alerts/urls.py, DefaultRouter) ─────────────────────────
  // GET  /api/alerts/                    → liste (AlertListSerializer allégé,
  //                                          SANS status/threshold_value/patient id)
  static const String alerts = '/alerts/';
  // GET  /api/alerts/{id}/               → détail (AlertSerializer complet)
  static String alertDetail(String id) => '/alerts/$id/';
  // GET  /api/alerts/by_patient/?patient_id=X → alertes d'un patient (AlertSerializer
  //                                              COMPLET, car self.action != 'list')
  static const String alertsByPatient = '/alerts/by_patient/';
  // POST /api/alerts/{id}/resolve/       → marque une alerte comme résolue
  static String resolveAlert(String id) => '/alerts/$id/resolve/';

  // ── Notifications Endpoints (alerts/urls.py — PAS d'app "notifications" dédiée) ──
  // GET  /api/alert-notifications/       → historique réel des notifications
  //                                          (AlertNotificationLog), non filtré par
  //                                          destinataire côté serveur.
  static const String alertNotifications = '/alert-notifications/';

  // ── Devices Endpoint ──────────────────────────────────────────────────────────
  static const String devices = '/devices/';

  // ── Biometrics Endpoints (biometric_data/urls.py, monté sur api/biometrics/) ────
  // GET  /api/biometrics/{patient_id}/          → 10 dernières mesures
  static String biometricsLatest(String patientId) => '/biometrics/$patientId/';
  // GET  /api/biometrics/{patient_id}/history/  → historique complet (graphiques),
  //                                                 accepte ?limit=&date_from=&date_to=
  static String biometricsHistory(String patientId) => '/biometrics/$patientId/history/';
}
