# 📅 Planning de Travail — Projet WALLAN
## Équipe : 5 Développeurs | Période : 29 Juin – 09 Octobre 2026

---

## 🗓️ SPRINT 1 — Initialisation (29 juin – 12 juil)

### Objectif
Mettre en place les bases du projet : architecture, GitHub, outils, maquettes.

| Tâche | Responsable | Deadline |
|-------|------------|----------|
| Réunion de lancement officiel (Google Meet) | Tous | 29 juin |
| Création dépôt GitHub + branches + règles | Mamadou Samba | 01 juil |
| Structure backend Django initialisée | Mamadou Samba | 03 juil |
| Structure frontend Flutter initialisée | Hadjiratou | 03 juil |
| Schéma de base de données (ERD) | Hadjiratou | 03 juil |
| Maquettes UX/UI — Écrans Auth & Admin | Hadjiratou | 05 juil |
| Maquettes UX/UI — Espaces Patient & Médecin | Fatima | 05 juil |
| Maquettes UX/UI — Alertes & Bracelet | Alpha + Hady | 05 juil |
| Réunion #1 — Validation architecture | Tous | 06 juil |
| Commande composants hardware | Pôle Hardware | 07 juil |
| **LIVRABLE : Architecture validée + GitHub opérationnel** | Mamadou Samba | 12 juil |

---

## 🗓️ SPRINT 2 — Backend : Auth & Patients (13 – 26 juil)

### Objectif
Développer les modules fondamentaux du backend.

| Tâche | Responsable | Deadline |
|-------|------------|----------|
| Module `accounts/` — Modèles User, Role, Profile | Mamadou Samba | 17 juil |
| Module `accounts/` — API JWT register/login/logout | Mamadou Samba | 19 juil |
| Module `patients/` — Modèles Patient, MedicalHistory | Fatima | 17 juil |
| Module `patients/` — API CRUD patients | Fatima | 19 juil |
| Module `care_management/` — Modèles DoctorProfile, RelativeProfile | Fatima | 21 juil |
| Module `devices/` — Modèles Device, DeviceStatus | Hady | 19 juil |
| Migrations PostgreSQL initiales | Hadjiratou | 19 juil |
| Seeds de données de test | Hadjiratou | 21 juil |
| Réunion #2 — Démo API Auth + Patients | Tous | 22 juil |
| Tests Postman — Auth endpoints | Hadjiratou | 24 juil |
| **LIVRABLE : API Auth + Patients fonctionnelle** | — | 26 juil |

---

## 🗓️ SPRINT 3 — Backend : Devices & Biometrics + Frontend Base (27 juil – 09 août)

### Objectif
Compléter le backend et démarrer le frontend.

| Tâche | Responsable | Deadline |
|-------|------------|----------|
| Module `devices/` — API register, association, état | Hady | 31 juil |
| Module `biometric_data/` — Modèles + API réception | Hady | 02 août |
| Module `care_management/` — API recommandations | Fatima | 31 juil |
| Frontend : Navigation de base + thème global | Hadjiratou | 31 juil |
| Frontend : `modules/auth/` — LoginScreen | Hadjiratou | 02 août |
| Frontend : `modules/auth/` — RegisterScreen | Hadjiratou | 04 août |
| Frontend : `modules/patient/` — PatientDashboard base | Fatima | 04 août |
| Frontend : `modules/device/` — DeviceConnection | Hady | 04 août |
| Réunion #3 — Démo backend complet + app navigation | Tous | 05 août |
| **LIVRABLE : Backend complet + App Flutter structurée** | — | 09 août |

---

## 🗓️ SPRINT 4 — Alertes, Notifs, Stats + Frontend Avancé (10 – 23 août)

### Objectif
Développer les modules critiques d'alertes et compléter les écrans frontend.

| Tâche | Responsable | Deadline |
|-------|------------|----------|
| Module `alerts/` — Modèles + API alertes/urgences | Alpha | 14 août |
| Module `notifications/` — SMS Africa's Talking | Alpha | 16 août |
| Module `notifications/` — Push Firebase | Alpha | 18 août |
| Module `statistics/` — API statistiques + rapports | Alpha | 20 août |
| Module `administration/` — Dashboard admin | Mamadou Samba | 16 août |
| Frontend : `modules/doctor/` — DoctorDashboard | Fatima | 16 août |
| Frontend : `modules/biometrics/` — Graphiques temps réel | Hady | 16 août |
| Frontend : `modules/alerts/` — AlertScreen + SosScreen | Alpha | 18 août |
| Frontend : `modules/relative/` — RelativeDashboard | Alpha | 20 août |
| Frontend : `modules/admin/` — AdminDashboard | Hadjiratou | 18 août |
| Réunion #4 — Démo alertes + notifications | Tous | 19 août |
| **LIVRABLE : Système d'alertes fonctionnel** | — | 23 août |

---

## 🗓️ SPRINT 5 — Intégration Bluetooth & Tests Internes (24 août – 06 sept)

### Objectif
Intégrer la communication bracelet ↔ app et tester l'ensemble du système.

| Tâche | Responsable | Deadline |
|-------|------------|----------|
| Intégration Bluetooth bracelet ↔ smartphone | Hady | 28 août |
| Test envoi SMS via Africa's Talking | Alpha | 28 août |
| Frontend : `modules/notifications/` — NotificationsScreen | Alpha | 28 août |
| Frontend : `modules/statistics/` — StatisticsDashboard | Alpha | 30 août |
| Frontend : intégration API backend complète | Tous | 30 août |
| Tests fonctionnels complets (chaque module) | Hadjiratou | 01 sept |
| Corrections bugs identifiés | Tous | 03 sept |
| Réunion #5 — Rapport de tests internes | Tous | 02 sept |
| Documentation technique (docstrings + README modules) | Tous | 04 sept |
| **LIVRABLE : Prototype stable V2 + rapport de tests** | — | 06 sept |

---

## 🗓️ SPRINT 6 — Tests Terrain (07 – 20 sept)

### Objectif
Tester avec des utilisateurs réels et corriger les retours.

| Tâche | Responsable | Deadline |
|-------|------------|----------|
| Tests terrain avec utilisateurs (patients, familles) | Tous | 10 sept |
| Analyse des retours terrain | Mamadou Samba | 11 sept |
| Amélioration UX/UI selon retours | Hadjiratou + Fatima | 15 sept |
| Correction précision alertes | Alpha + Hady | 15 sept |
| Optimisation autonomie batterie bracelet | Hady | 17 sept |
| Réunion #6 — Décision go/no-go prototype final | Tous | 16 sept |
| **LIVRABLE : Prototype V3 + rapport terrain** | — | 20 sept |

---

## 🗓️ SPRINT 7 — Validation Finale & Démo (21 sept – 09 oct)

### Objectif
Valider, documenter et préparer la démonstration finale.

| Tâche | Responsable | Deadline |
|-------|------------|----------|
| Tests de validation finale (fonctionnels + autonomie) | Tous | 25 sept |
| Réunion #7 — Validation officielle | Tous | 25 sept |
| Rédaction rapport final | Hadjiratou | 30 sept |
| Documentation technique complète | Tous | 30 sept |
| Préparation slides de présentation | Mamadou Samba | 02 oct |
| Répétition démo | Tous | 06 oct |
| **🎯 LIVRABLE FINAL : Prototype + Documentation + Démo** | Tous | 09 oct |

---

## 📊 Résumé des Livrables

| Sprint | Date | Livrable |
|--------|------|----------|
| Sprint 1 | 12 juil | Architecture + GitHub initialisé |
| Sprint 2 | 26 juil | API Auth + Patients fonctionnelle |
| Sprint 3 | 09 août | Backend complet + App Flutter structurée |
| Sprint 4 | 23 août | Système d'alertes fonctionnel |
| Sprint 5 | 06 sept | Prototype stable V2 |
| Sprint 6 | 20 sept | Prototype V3 amélioré |
| Sprint 7 | 09 oct  | 🎯 PROTOTYPE FINAL |
