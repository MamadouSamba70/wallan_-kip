# 📦 Répartition des Modules — Projet WALLAN
## Équipe de 5 Développeurs

---

## 👤 DEV 1 — Mamadou Samba Diallo (Chef de Projet)

### Backend
| Module | Application Django | Responsabilités |
|--------|-------------------|-----------------|
| Module 1 | `accounts/` | Inscription, Connexion, JWT, Rôles, Profil, Permissions |
| Module 9 | `administration/` | Dashboard admin, Logs, Audit, Sauvegarde |

### Base de données (coordination)
- Conception du schéma global PostgreSQL
- Mise en place des migrations initiales
- Configuration Redis + Celery

### DevOps / Infrastructure
- Mise en place GitHub (branches, règles, CI/CD)
- Configuration du serveur (Render / Railway)
- Variables d'environnement et `.env`

### Endpoints API à livrer
```
POST /api/auth/register/
POST /api/auth/login/
POST /api/auth/logout/
POST /api/auth/refresh/
GET  /api/profile/
PUT  /api/profile/update/
GET  /api/admin/dashboard/
GET  /api/admin/logs/
GET  /api/admin/users/
```

---

## 👤 DEV 2 — Fatima Abdul Sow

### Backend
| Module | Application Django | Responsabilités |
|--------|-------------------|-----------------|
| Module 2 | `patients/` | Dossiers patients, antécédents, maladies, traitements |
| Module 3 | `care_management/` | Relations médecin-patient, proche-patient, recommandations |

### Frontend
| Module | Dossier Flutter | Écrans |
|--------|----------------|--------|
| Espace Patient | `modules/patient/` | PatientDashboard, VitalSigns, MedicalHistory, EmergencyContacts, BraceletSettings |
| Espace Médecin | `modules/doctor/` | DoctorDashboard, PatientsList, PatientDetails, Recommendation, Reports |

### Endpoints API à livrer
```
GET    /api/patients/
POST   /api/patients/
PUT    /api/patients/{id}/
DELETE /api/patients/{id}/
GET    /api/doctors/
GET    /api/relatives/
POST   /api/recommendations/
```

---

## 👤 DEV 3 — Mamadou Hady Diallo

### Backend
| Module | Application Django | Responsabilités |
|--------|-------------------|-----------------|
| Module 4 | `devices/` | Enregistrement bracelet, association, état, synchronisation |
| Module 5 | `biometric_data/` | Réception mesures, historisation, consultation |

### Frontend
| Module | Dossier Flutter | Écrans |
|--------|----------------|--------|
| Gestion Bracelet | `modules/device/` | DeviceConnection, DeviceStatus, Pairing |
| Données Biométriques | `modules/biometrics/` | BiometricDashboard, History, Statistics |

### Endpoints API à livrer
```
POST /api/devices/register/
GET  /api/devices/
PUT  /api/devices/{id}/
POST /api/biometrics/
GET  /api/biometrics/history/
```

---

## 👤 DEV 4 — Alpha Oumar Bah

### Backend
| Module | Application Django | Responsabilités |
|--------|-------------------|-----------------|
| Module 6 | `alerts/` | Détection crises, alertes, escalade, historique |
| Module 7 | `notifications/` | SMS (Africa's Talking), Push Firebase, Emails |
| Module 8 | `statistics/` | Rapports PDF, graphiques, tendances médicales |

### Frontend
| Module | Dossier Flutter | Écrans |
|--------|----------------|--------|
| Alertes | `modules/alerts/` | AlertScreen, EmergencyScreen, SosScreen |
| Notifications | `modules/notifications/` | NotificationsScreen |
| Statistiques | `modules/statistics/` | StatisticsDashboard, ReportsScreen |
| Espace Proche | `modules/relative/` | RelativeDashboard, AlertsScreen, PatientLocation, AlertHistory |

### Endpoints API à livrer
```
GET  /api/alerts/
POST /api/alerts/create/
GET  /api/emergencies/
GET  /api/notifications/
GET  /api/statistics/
GET  /api/reports/
```

---

## 👤 DEV 5 — Hadjiratou Diallo

### Frontend
| Module | Dossier Flutter | Écrans |
|--------|----------------|--------|
| Authentification | `modules/auth/` | LoginScreen, RegisterScreen, ForgotPassword, ProfileScreen |
| Administration | `modules/admin/` | AdminDashboard, UsersManagement, DevicesManagement, LogsScreen |

### Base de données
- Scripts SQL de création des tables
- Scripts de seeds (données de test)
- Optimisation des index PostgreSQL
- Documentation du schéma ERD

### Tests & QA
- Tests des endpoints API (Postman)
- Tests unitaires Flutter
- Rapport de tests

---

## 📊 Tableau Récapitulatif

| Développeur | Backend | Frontend | Modules |
|-------------|---------|----------|---------|
| Mamadou Samba Diallo | accounts + administration | — | Auth API, Admin API, DevOps |
| Fatima Abdul Sow | patients + care_management | patient + doctor | Dossiers médicaux, Relations soins |
| Mamadou Hady Diallo | devices + biometric_data | device + biometrics | Bracelet, Capteurs IoT |
| Alpha Oumar Bah | alerts + notifications + statistics | alerts + notifications + statistics + relative | Urgences, Communication, Rapports |
| Hadjiratou Diallo | — | auth + admin | UI Auth, UI Admin, Base de données |
