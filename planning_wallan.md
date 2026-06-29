# 🏥 Plan de Travail — Projet WALLAN
### Bracelet Intelligent de Surveillance Médicale

---

## 👥 Équipe & Répartition des Modules

| # | Développeur | Backend | Frontend | Base de Données |
|---|-------------|---------|----------|-----------------|
| 1 | **Mamadou Samba Diallo** *(Chef de projet)* | `accounts/` + `administration/` | — | Schéma global + Config Redis/Celery |
| 2 | **Fatima Abdul Sow** | `patients/` + `care_management/` | `modules/patient/` + `modules/doctor/` | Tables patients, médecins, proches |
| 3 | **Mamadou Hady Diallo** | `devices/` + `biometric_data/` | `modules/device/` + `modules/biometrics/` | Tables bracelets, mesures biométriques |
| 4 | **Alpha Oumar Bah** | `alerts/` + `notifications/` + `statistics/` | `modules/alerts/` + `modules/notifications/` + `modules/statistics/` + `modules/relative/` | Tables alertes, notifications, statistiques |
| 5 | **Hadjiratou Diallo** | — | `modules/auth/` + `modules/admin/` | Scripts SQL + Seeds + Index + Tests QA |

---

## 📋 Détail des Tâches par Développeur

### 👤 DEV 1 — Mamadou Samba Diallo

#### Backend : `accounts/` + `administration/`
- ✅ Modèles : `User`, `Role`, `Profile`
- ✅ API JWT : register, login, logout, refresh
- ✅ Gestion des rôles et permissions
- ✅ Module administration : Dashboard, Logs, Audit, Backup
- ✅ Mise en place GitHub (branches, règles de collaboration)
- ✅ Configuration serveur (Render/Railway), variables `.env`

#### Endpoints à livrer
```
POST /api/auth/register/         → Inscription
POST /api/auth/login/            → Connexion (JWT)
POST /api/auth/logout/           → Déconnexion
POST /api/auth/refresh/          → Renouvellement token
POST /api/auth/password-reset/   → Reset mot de passe
GET  /api/profile/               → Consulter profil
PUT  /api/profile/update/        → Modifier profil
GET  /api/admin/dashboard/       → Tableau de bord admin
GET  /api/admin/logs/            → Logs système
GET  /api/admin/audit/           → Journal d'audit
```

---

### 👤 DEV 2 — Fatima Abdul Sow

#### Backend : `patients/` + `care_management/`
- ✅ Modèles : `Patient`, `MedicalHistory`, `Disease`, `Treatment`
- ✅ Modèles : `DoctorProfile`, `RelativeProfile`, `DoctorPatient`, `PatientRelative`, `Recommendation`
- ✅ API CRUD patients et dossiers médicaux
- ✅ API affectations médecin-patient et proche-patient

#### Frontend : `modules/patient/` + `modules/doctor/`
- ✅ `PatientDashboardScreen` — tableau de bord personnel
- ✅ `VitalSignsScreen` — paramètres vitaux
- ✅ `MedicalHistoryScreen` — antécédents médicaux
- ✅ `EmergencyContactsScreen` — contacts d'urgence
- ✅ `DoctorDashboardScreen` — tableau de bord médecin
- ✅ `PatientsListScreen` — liste des patients suivis
- ✅ `PatientDetailsScreen` + `RecommendationScreen`

#### Endpoints à livrer
```
GET/POST /api/patients/          → Liste / Créer
GET/PUT/DELETE /api/patients/{id}/ → CRUD patient
GET /api/patients/{id}/history/  → Historique médical
GET /api/doctors/                → Liste médecins
POST /api/recommendations/       → Créer recommandation
GET /api/relatives/              → Liste proches
```

---

### 👤 DEV 3 — Mamadou Hady Diallo

#### Backend : `devices/` + `biometric_data/`
- ✅ Modèles : `Device`, `DeviceStatus`
- ✅ Modèles : `BiometricData`, `HeartRate`, `Temperature`, `Location`
- ✅ API enregistrement bracelet, association, état
- ✅ API réception des mesures ESP32 → API
- ✅ Logique de détection d'anomalies (seuils)

#### Frontend : `modules/device/` + `modules/biometrics/`
- ✅ `DeviceConnectionScreen` — connexion Bluetooth
- ✅ `DeviceStatusScreen` — état batterie, signal
- ✅ `PairingScreen` — association bracelet ↔ patient
- ✅ `BiometricDashboardScreen` — mesures temps réel
- ✅ `HistoryScreen` — historique des mesures
- ✅ Widgets : `HeartRateWidget`, `TemperatureWidget`, `OxygenWidget`, `ChartWidget`

#### Endpoints à livrer
```
POST /api/devices/register/      → Enregistrer bracelet
GET  /api/devices/               → Liste bracelets
POST /api/devices/{id}/assign/   → Associer bracelet-patient
GET  /api/devices/{id}/status/   → État du bracelet
POST /api/biometrics/            → Recevoir mesures (ESP32)
GET  /api/biometrics/history/    → Historique mesures
GET  /api/biometrics/anomalies/  → Anomalies détectées
```

---

### 👤 DEV 4 — Alpha Oumar Bah

#### Backend : `alerts/` + `notifications/` + `statistics/`
- ✅ Modèles : `Alert`, `Emergency`, `Crisis`
- ✅ Modèles : `Notification`, `SmsLog`, `PushNotification`
- ✅ Modèles : `Statistic`, `Report`
- ✅ Intégration Africa's Talking (SMS)
- ✅ Intégration Firebase Cloud Messaging (Push)
- ✅ Génération de rapports PDF (ReportLab)
- ✅ Tâches Celery pour envoi asynchrone

#### Frontend : `modules/alerts/` + `modules/notifications/` + `modules/statistics/` + `modules/relative/`
- ✅ `AlertScreen`, `EmergencyScreen`, `SosScreen`
- ✅ `NotificationsScreen` — historique notifications
- ✅ `StatisticsDashboardScreen`, `ReportsScreen`
- ✅ `RelativeDashboardScreen`, `PatientLocationScreen`
- ✅ Widgets : `SosButton`, `AlertCard`, `LocationMap`

#### Endpoints à livrer
```
GET  /api/alerts/                → Liste alertes
POST /api/alerts/create/         → Créer alerte
PUT  /api/alerts/{id}/resolve/   → Résoudre alerte
GET  /api/emergencies/           → Urgences actives
GET  /api/notifications/         → Notifications reçues
GET  /api/statistics/            → Statistiques patient
POST /api/reports/generate/      → Générer rapport PDF
```

---

### 👤 DEV 5 — Hadjiratou Diallo

#### Frontend : `modules/auth/` + `modules/admin/`
- ✅ `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`, `ProfileScreen`
- ✅ `AdminDashboardScreen`, `UsersManagementScreen`
- ✅ `DevicesManagementScreen`, `LogsScreen`
- ✅ Thème global (couleurs, typographie, composants réutilisables)
- ✅ Configuration Go Router (navigation + garde d'authentification)

#### Base de Données
- ✅ Scripts SQL de création de toutes les tables
- ✅ Index de performance PostgreSQL
- ✅ Scripts de seeds (données de test)
- ✅ Schéma ERD documenté
- ✅ Tables de configuration des seuils d'alerte

#### Tests & QA
- ✅ Tests Postman de tous les endpoints
- ✅ Tests unitaires Flutter
- ✅ Rapport de tests par sprint

---

## 📅 Planning par Sprint

| Sprint | Dates | Objectif | Livrable |
|--------|-------|----------|----------|
| **Sprint 1** | 29 juin – 12 juil | Initialisation, GitHub, maquettes | Architecture + GitHub opérationnel |
| **Sprint 2** | 13 juil – 26 juil | Backend Auth + Patients | API Auth + Patients fonctionnelle |
| **Sprint 3** | 27 juil – 09 août | Backend Devices + App Flutter base | Backend complet + App Flutter structurée |
| **Sprint 4** | 10 août – 23 août | Alertes + Notifications + Frontend avancé | Système d'alertes fonctionnel |
| **Sprint 5** | 24 août – 06 sept | Intégration Bluetooth + Tests internes | Prototype stable V2 |
| **Sprint 6** | 07 sept – 20 sept | Tests terrain + corrections | Prototype V3 amélioré |
| **Sprint 7** | 21 sept – 09 oct  | Validation finale + Démo | 🎯 **PROTOTYPE FINAL** |

---

## 📁 Fichiers Créés dans `S:\wallan\`

```
wallan/
├── README.md                    ← Présentation générale du projet
├── CONTRIBUTING.md              ← Règles de collaboration GitHub
├── .gitignore                   ← Fichiers ignorés par Git
├── .env.example                 ← Template variables d'environnement
└── docs/
    ├── repartition_modules.md   ← Répartition détaillée par développeur
    ├── planning.md              ← Planning complet par sprint
    ├── conception_backend.md    ← Modèles Django + API endpoints
    ├── conception_frontend.md   ← Écrans + Widgets Flutter
    └── conception_bdd.md        ← Scripts SQL PostgreSQL complets
```

---

## 🚀 Prochaines Étapes

1. **Créer le dépôt GitHub** `wallan` (organisation ou compte personnel)
2. **Initialiser le projet Django** : `django-admin startproject config backend/`
3. **Initialiser le projet Flutter** : `flutter create frontend`
4. **Créer les branches** pour chaque développeur
5. **Partager le `.env.example`** → chaque dev crée son `.env` local
6. **Réunion de lancement** via Google Meet pour valider l'architecture

> 💡 **Conseil** : Commencez par le Sprint 1 immédiatement — mettez en place GitHub et la structure du projet avant de coder.
