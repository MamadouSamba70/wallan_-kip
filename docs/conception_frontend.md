# 📱 Cahier de Conception Frontend — Projet WALLAN

## Technologies
- **Framework** : Flutter 3.x / Dart
- **Gestion d'état** : Provider
- **Navigation** : Go Router
- **HTTP Client** : Dio
- **Stockage local** : SQLite (sqflite)
- **Notifications Push** : Firebase Cloud Messaging
- **Graphiques** : FL Chart
- **Architecture** : MVVM

---

## Structure Générale

```
lib/
├── core/
│   ├── constants/         # Couleurs, tailles, chaînes
│   ├── errors/            # Gestion des exceptions
│   └── network/           # Client Dio, intercepteurs
│
├── models/                # Modèles de données (Patient, Alert, etc.)
├── services/              # Services API (AuthService, AlertService, etc.)
├── providers/             # Providers (état global)
│
├── modules/
│   ├── auth/              # Authentification
│   ├── patient/           # Espace Patient
│   ├── doctor/            # Espace Médecin
│   ├── relative/          # Espace Proche
│   ├── device/            # Gestion Bracelet
│   ├── biometrics/        # Données Biométriques
│   ├── alerts/            # Alertes & Urgences
│   ├── notifications/     # Notifications
│   ├── statistics/        # Statistiques
│   └── admin/             # Administration
│
├── widgets/               # Widgets réutilisables globaux
├── routes/                # Configuration Go Router
├── themes/                # Thème (couleurs, polices)
├── utils/                 # Utilitaires (formatage dates, etc.)
└── main.dart
```

---

## MODULE 1 — Authentification

**Dossier** : `modules/auth/`  
**Développeur** : Hadjiratou Diallo  
**Backend correspondant** : `accounts/`

### Écrans

| Écran | Fichier | Description |
|-------|---------|-------------|
| `LoginScreen` | `screens/login_screen.dart` | Formulaire connexion email/password |
| `RegisterScreen` | `screens/register_screen.dart` | Formulaire inscription avec sélection rôle |
| `ForgotPasswordScreen` | `screens/forgot_password_screen.dart` | Réinitialisation par email |
| `ProfileScreen` | `screens/profile_screen.dart` | Consultation et modification du profil |

### Widgets

| Widget | Fichier | Description |
|--------|---------|-------------|
| `LoginForm` | `widgets/login_form.dart` | Champs email/password + validation |
| `RegisterForm` | `widgets/register_form.dart` | Formulaire d'inscription complet |
| `ProfileCard` | `widgets/profile_card.dart` | Affichage résumé du profil |
| `RoleSelector` | `widgets/role_selector.dart` | Sélecteur de rôle à l'inscription |

### Service

```dart
// services/auth_service.dart
class AuthService {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(RegisterRequest request);
  Future<void> logout();
  Future<String> refreshToken();
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile(ProfileRequest request);
  Future<void> resetPassword(String email);
}
```

### Provider

```dart
// providers/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  String get userRole => _currentUser?.role ?? '';
}
```

---

## MODULE 2 — Espace Patient

**Dossier** : `modules/patient/`  
**Développeur** : Fatima Abdul Sow  
**Backend correspondant** : `patients/`

### Écrans

| Écran | Fichier | Description |
|-------|---------|-------------|
| `PatientDashboardScreen` | `screens/patient_dashboard.dart` | Vue principale patient : vitaux + alertes récentes |
| `VitalSignsScreen` | `screens/vital_signs_screen.dart` | Paramètres vitaux en temps réel |
| `MedicalHistoryScreen` | `screens/medical_history_screen.dart` | Antécédents médicaux + maladies + traitements |
| `EmergencyContactsScreen` | `screens/emergency_contacts_screen.dart` | Gestion des contacts d'urgence |
| `BraceletSettingsScreen` | `screens/bracelet_settings_screen.dart` | Configuration du bracelet + seuils d'alerte |

### Widgets

| Widget | Fichier | Description |
|--------|---------|-------------|
| `VitalCard` | `widgets/vital_card.dart` | Carte affichant une mesure vitale (FC, Temp, SpO2) |
| `EmergencyButton` | `widgets/emergency_button.dart` | Bouton SOS rouge, appui long |
| `PatientSummaryCard` | `widgets/patient_summary_card.dart` | Résumé dossier patient |
| `TreatmentTile` | `widgets/treatment_tile.dart` | Affichage d'un traitement médical |

---

## MODULE 3 — Espace Médecin

**Dossier** : `modules/doctor/`  
**Développeur** : Fatima Abdul Sow  
**Backend correspondant** : `care_management/`, `statistics/`

### Écrans

| Écran | Fichier | Description |
|-------|---------|-------------|
| `DoctorDashboardScreen` | `screens/doctor_dashboard.dart` | Vue principale médecin |
| `PatientsListScreen` | `screens/patients_list_screen.dart` | Liste des patients suivis |
| `PatientDetailsScreen` | `screens/patient_details_screen.dart` | Dossier complet d'un patient |
| `RecommendationScreen` | `screens/recommendation_screen.dart` | Saisie d'une recommandation médicale |
| `ReportsScreen` | `screens/reports_screen.dart` | Génération et consultation de rapports |

### Widgets

| Widget | Fichier | Description |
|--------|---------|-------------|
| `PatientCard` | `widgets/patient_card.dart` | Carte résumé d'un patient |
| `RecommendationForm` | `widgets/recommendation_form.dart` | Formulaire de recommandation |
| `MedicalChart` | `widgets/medical_chart.dart` | Graphique d'évolution des vitaux |

---

## MODULE 4 — Espace Proche

**Dossier** : `modules/relative/`  
**Développeur** : Alpha Oumar Bah  
**Backend correspondant** : `care_management/`, `alerts/`

### Écrans

| Écran | Fichier | Description |
|-------|---------|-------------|
| `RelativeDashboardScreen` | `screens/relative_dashboard.dart` | Vue principale proche avec état patient |
| `AlertsScreen` | `screens/alerts_screen.dart` | Alertes reçues en temps réel |
| `PatientLocationScreen` | `screens/patient_location_screen.dart` | Carte GPS localisation patient |
| `AlertHistoryScreen` | `screens/alert_history_screen.dart` | Historique des alertes passées |

### Widgets

| Widget | Fichier | Description |
|--------|---------|-------------|
| `AlertCard` | `widgets/alert_card.dart` | Carte d'alerte avec sévérité colorée |
| `LocationMap` | `widgets/location_map.dart` | Carte interactive (Google Maps ou OpenStreetMap) |
| `PatientStatusCard` | `widgets/patient_status_card.dart` | État actuel du patient surveillé |

---

## MODULE 5 — Gestion du Bracelet

**Dossier** : `modules/device/`  
**Développeur** : Mamadou Hady Diallo  
**Backend correspondant** : `devices/`

### Écrans

| Écran | Fichier | Description |
|-------|---------|-------------|
| `DeviceConnectionScreen` | `screens/device_connection.dart` | Connexion Bluetooth au bracelet |
| `DeviceStatusScreen` | `screens/device_status.dart` | État batterie, signal, firmware |
| `PairingScreen` | `screens/pairing_screen.dart` | Association bracelet ↔ patient |

### Widgets

| Widget | Fichier | Description |
|--------|---------|-------------|
| `BluetoothStatusWidget` | `widgets/bluetooth_status.dart` | Indicateur connexion Bluetooth |
| `DeviceCard` | `widgets/device_card.dart` | Carte d'un bracelet enregistré |
| `BatteryIndicator` | `widgets/battery_indicator.dart` | Jauge de batterie animée |

---

## MODULE 6 — Données Biométriques

**Dossier** : `modules/biometrics/`  
**Développeur** : Mamadou Hady Diallo  
**Backend correspondant** : `biometric_data/`

### Écrans

| Écran | Fichier | Description |
|-------|---------|-------------|
| `BiometricDashboardScreen` | `screens/biometric_dashboard.dart` | Mesures en temps réel |
| `HistoryScreen` | `screens/history_screen.dart` | Historique des mesures |
| `StatisticsScreen` | `screens/statistics_screen.dart` | Graphiques d'évolution |

### Widgets

| Widget | Fichier | Description |
|--------|---------|-------------|
| `HeartRateWidget` | `widgets/heart_rate_widget.dart` | Affichage FC avec animation |
| `TemperatureWidget` | `widgets/temperature_widget.dart` | Thermomètre animé |
| `OxygenWidget` | `widgets/oxygen_widget.dart` | Jauge SpO2 |
| `ChartWidget` | `widgets/chart_widget.dart` | Graphique linéaire FL Chart |

---

## MODULE 7 — Alertes et Urgences

**Dossier** : `modules/alerts/`  
**Développeur** : Alpha Oumar Bah  
**Backend correspondant** : `alerts/`

### Écrans

| Écran | Fichier | Description |
|-------|---------|-------------|
| `AlertScreen` | `screens/alert_screen.dart` | Liste des alertes actives |
| `EmergencyScreen` | `screens/emergency_screen.dart` | Écran urgence (fond rouge) |
| `SosScreen` | `screens/sos_screen.dart` | Activation SOS manuel |

### Widgets

| Widget | Fichier | Description |
|--------|---------|-------------|
| `AlertDialog` | `widgets/alert_dialog.dart` | Popup d'alerte critique |
| `EmergencyBanner` | `widgets/emergency_banner.dart` | Bandeau d'urgence |
| `SosButton` | `widgets/sos_button.dart` | Bouton SOS rouge, appui long 3 secondes |

---

## MODULE 8 — Notifications

**Dossier** : `modules/notifications/`  
**Développeur** : Alpha Oumar Bah  
**Backend correspondant** : `notifications/`

### Écrans

| Écran | Fichier | Description |
|-------|---------|-------------|
| `NotificationsScreen` | `screens/notifications_screen.dart` | Historique de toutes les notifications |

### Widgets

| Widget | Fichier | Description |
|--------|---------|-------------|
| `NotificationTile` | `widgets/notification_tile.dart` | Tuile de notification avec icône et heure |

---

## MODULE 9 — Statistiques

**Dossier** : `modules/statistics/`  
**Développeur** : Alpha Oumar Bah  
**Backend correspondant** : `statistics/`

### Écrans

| Écran | Fichier | Description |
|-------|---------|-------------|
| `StatisticsDashboardScreen` | `screens/statistics_dashboard.dart` | Graphiques récapitulatifs |
| `ReportsScreen` | `screens/reports_screen.dart` | Rapports PDF générés |

### Widgets

| Widget | Fichier | Description |
|--------|---------|-------------|
| `StatisticsCard` | `widgets/statistics_card.dart` | Carte d'indicateur (nombre alertes, moy FC) |
| `LineChartWidget` | `widgets/line_chart_widget.dart` | Graphique linéaire d'évolution |
| `PieChartWidget` | `widgets/pie_chart_widget.dart` | Graphique camembert répartition |

---

## MODULE 10 — Administration

**Dossier** : `modules/admin/`  
**Développeur** : Hadjiratou Diallo  
**Backend correspondant** : `administration/`

### Écrans

| Écran | Fichier | Description |
|-------|---------|-------------|
| `AdminDashboardScreen` | `screens/admin_dashboard.dart` | Tableau de bord global système |
| `UsersManagementScreen` | `screens/users_management.dart` | CRUD utilisateurs |
| `DevicesManagementScreen` | `screens/devices_management.dart` | Supervision des bracelets |
| `LogsScreen` | `screens/logs_screen.dart` | Consultation des logs système |

### Widgets

| Widget | Fichier | Description |
|--------|---------|-------------|
| `UserTable` | `widgets/user_table.dart` | Tableau de gestion des utilisateurs |
| `DashboardCard` | `widgets/dashboard_card.dart` | Carte statistique admin |
| `LogTable` | `widgets/log_table.dart` | Tableau des logs avec filtres |

---

## Thème et Design

```dart
// themes/app_theme.dart
class AppTheme {
  // Couleurs principales (Wallan)
  static const Color primaryBlue = Color(0xFF0D47A1);
  static const Color accentBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color alertRed = Color(0xFFD32F2F);
  static const Color successGreen = Color(0xFF388E3C);
  static const Color warningOrange = Color(0xFFF57C00);

  // Typographie
  static const String fontFamily = 'Inter';
}
```

---

## Navigation (Go Router)

```dart
// routes/app_router.dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/login',     builder: (ctx, state) => LoginScreen()),
    GoRoute(path: '/register',  builder: (ctx, state) => RegisterScreen()),
    GoRoute(path: '/patient',   builder: (ctx, state) => PatientDashboardScreen()),
    GoRoute(path: '/doctor',    builder: (ctx, state) => DoctorDashboardScreen()),
    GoRoute(path: '/relative',  builder: (ctx, state) => RelativeDashboardScreen()),
    GoRoute(path: '/admin',     builder: (ctx, state) => AdminDashboardScreen()),
    GoRoute(path: '/alerts',    builder: (ctx, state) => AlertScreen()),
    GoRoute(path: '/sos',       builder: (ctx, state) => SosScreen()),
    GoRoute(path: '/biometrics',builder: (ctx, state) => BiometricDashboardScreen()),
    GoRoute(path: '/device',    builder: (ctx, state) => DeviceConnectionScreen()),
    GoRoute(path: '/stats',     builder: (ctx, state) => StatisticsDashboardScreen()),
  ],
  redirect: (ctx, state) {
    final isLoggedIn = ctx.read<AuthProvider>().isAuthenticated;
    if (!isLoggedIn && state.matchedLocation != '/login') return '/login';
    return null;
  },
);
```

---

## Dépendances Flutter (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0
  go_router: ^13.0.0
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  firebase_core: ^2.27.0
  firebase_messaging: ^14.7.0
  fl_chart: ^0.66.0
  google_maps_flutter: ^2.5.0
  flutter_bluetooth_serial: ^0.4.0
  intl: ^0.18.0
  image_picker: ^1.0.0
  http: ^1.2.0
  shared_preferences: ^2.2.0
```
