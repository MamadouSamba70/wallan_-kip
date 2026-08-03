# 🏥 Plan de Travail & Cahier Technique — Projet WALLAN
## Backend Django REST Framework & Frontend Flutter

---

## 📋 Table des Matières
1. [Présentation du projet](#1-présentation-du-projet)
   - 1.1 [Les trois profils utilisateurs](#11-les-trois-profils-utilisateurs)
   - 1.2 [Stack technique](#12-stack-technique)
   - 1.3 [Organisation de l'équipe](#13-organisation-de-léquipe)
2. [Association du bracelet à un compte patient](#2-association-du-bracelet-à-un-compte-patient)
   - 2.1 [Principe de fonctionnement](#21-principe-de-fonctionnement)
3. [Schéma complet de la base de données](#3-schéma-complet-de-la-base-de-données)
   - 3.1 [Module accounts (Hadjiratou)](#31-module-accounts-hadjiratou)
   - 3.2 [Module patients (Fatima)](#32-module-patients-fatima)
   - 3.3 [Module devices (Hady)](#33-module-devices-hady)
   - 3.4 [Module biometric_data (Hady)](#34-module-biometric_data-hady)
   - 3.5 [Module alerts (Fatima)](#35-module-alerts-fatima)
4. [Planning détaillé — semaine par semaine](#4-planning-détaillé--semaine-par-semaine)
5. [Cahier technique — liste complète des endpoints API](#5-cahier-technique--liste-complète-des-endpoints-api)
6. [Risques et points de vigilance](#6-risques-et-points-de-vigilance)
7. [Conclusion](#7-conclusion)

---

## 1. Présentation du projet
**Wallan** est un bracelet intelligent de surveillance médicale destiné aux patients atteints de rhumatisme en Guinée. Le système collecte en continu des données vitales via un bracelet connecté (température, fréquence cardiaque, saturation en oxygène, mouvements), les transmet à une application mobile, et alerte automatiquement le patient ainsi que ses proches en cas de situation critique — y compris sans connexion internet grâce à l'envoi de SMS.

### 1.1 Les trois profils utilisateurs
*   **Patient** : Suit ses propres constantes vitales et reçoit les alertes le concernant.
*   **Proche** : Surveille l'état de santé d'un patient à distance et reçoit les alertes en cas d'urgence.
*   **Administrateur** : Supervise l'ensemble du système, les patients, les appareils et les alertes.

### 1.2 Stack technique
| Couche | Technologie | Rôle |
| :--- | :--- | :--- |
| **Backend** | Django + Django REST Framework | API REST, logique métier |
| **Frontend** | Flutter (Dart) | Application mobile Android / iOS |
| **Base de données** | PostgreSQL | Stockage des données |
| **Stockage local** | SQLite | Fonctionnement hors connexion |
| **Authentification** | JWT | Sécurité des sessions |
| **SMS** | Africa's Talking API | Alertes sans connexion internet |
| **Notifications push** | Firebase Cloud Messaging | Alertes en temps réel |
| **Communication bracelet** | Bluetooth Low Energy (BLE) | Bracelet ↔ smartphone |
| **Versioning** | Git / GitHub | Gestion du code source |

### 1.3 Organisation de l'équipe
| Nom | Pôle | Responsabilité principale |
| :--- | :--- | :--- |
| **Mamadou Hady Diallo** | Backend | Modèles Devices et données biométriques |
| **Fatima Abdul Sow** | Backend | Modèles Patients et système d'alertes |
| **Hadjiratou Diallo** | Backend | Authentification, tests et documentation API |
| **Mamadou Samba Diallo** | Frontend | Écrans Authentification et Administration |
| **Alpha Oumar Bah** | Frontend | Écrans Alertes, Notifications, Statistiques et Proche |

> [!NOTE]
> **Note sur l'organisation :**
> L'équipe est volontairement scindée en deux pôles spécialisés (3 développeurs backend, 2 développeurs frontend) plutôt qu'une répartition mixte où chacun ferait à la fois du Django et du Flutter. Cette organisation permet à chaque membre de se concentrer sur la technologie qu'il maîtrise le mieux et de monter en compétence plus rapidement. Le backend documente ses contrats d'API en amont pour que le frontend puisse travailler avec des données simulées sans attendre que les endpoints réels soient terminés.

---

## 2. Association du bracelet à un compte patient
Chaque bracelet Wallan possède un identifiant matériel unique, comparable à un numéro de carte SIM. Cet identifiant est utilisé pour lier de façon sécurisée un bracelet physique à un seul compte patient à la fois.

### 2.1 Principe de fonctionnement
1.  Chaque ESP32 possède une adresse MAC Bluetooth unique de fabrication, utilisée comme identifiant matériel (`hardware_id`).
2.  Cet identifiant est enregistré dans la table `Device` de la base de données avec un statut « non assigné » (`unassigned`).
3.  Un administrateur (ou le patient via un QR code collé sur le bracelet) associe le bracelet à un compte patient précis.
4.  Cette association crée un lien permanent entre le `device_id` et le `patient_id` dans la base de données.
5.  À chaque connexion Bluetooth, l'application vérifie que l'identifiant matériel du bracelet correspond bien au patient connecté avant d'accepter ses données.

> [!IMPORTANT]
> **Pourquoi c'est important :**
> Ce mécanisme empêche qu'un bracelet égaré, volé ou mal configuré n'envoie des données dans le mauvais dossier patient. Un bracelet ne peut être assigné qu'à un seul patient actif à la fois ; la table `DeviceAssignment` conserve l'historique complet des associations passées.

---

## 3. Schéma complet de la base de données
Cette section liste l'intégralité des tables PostgreSQL du projet Wallan, organisées par module. Chaque développeur backend doit s'y référer pour créer ses modèles Django avec les champs exacts.

### 3.1 Module accounts — Hadjiratou

#### Table : `User`
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **email** | VARCHAR(255) UNIQUE | Email de connexion |
| **password_hash** | VARCHAR(255) | Mot de passe haché |
| **role** | ENUM | `patient` / `proche` / `admin` |
| **is_active** | BOOLEAN | Compte actif ou désactivé |
| **date_joined** | TIMESTAMP | Date de création du compte |
| **last_login** | TIMESTAMP | Dernière connexion |

#### Table : `Profile`
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **user_id** | UUID (FK → User) | Utilisateur associé |
| **phone** | VARCHAR(20) | Numéro de téléphone |
| **photo** | VARCHAR(255) | URL de la photo de profil |
| **language** | VARCHAR(5) | Langue préférée (`fr` par défaut) |

### 3.2 Module patients — Fatima

#### Table : `Patient`
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **user_id** | UUID (FK → User) | Compte utilisateur lié |
| **full_name** | VARCHAR(255) | Nom complet |
| **birth_date** | DATE | Date de naissance |
| **condition** | VARCHAR(50) | Pathologie (rhumatisme) |
| **threshold_heart_rate** | INTEGER | Seuil d'alerte rythme cardiaque |
| **threshold_temperature** | DECIMAL(4,1) | Seuil d'alerte température |
| **threshold_spo2** | INTEGER | Seuil d'alerte SpO2 |
| **created_at** | TIMESTAMP | Date de création du dossier |

#### Table : `MedicalHistory`
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **patient_id** | UUID (FK → Patient) | Patient concerné |
| **description** | TEXT | Description de l'antécédent |
| **diagnosed_date** | DATE | Date de diagnostic |

#### Table : `PatientRelative` (lien patient ↔ proche)
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **patient_id** | UUID (FK → Patient) | Patient suivi |
| **relative_user_id** | UUID (FK → User) | Compte du proche |
| **relationship** | VARCHAR(50) | Lien de parenté |
| **is_primary_contact** | BOOLEAN | Contact d'urgence prioritaire |

### 3.3 Module devices — Hady

#### Table : `Device`
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **hardware_id** | VARCHAR(50) UNIQUE | Identifiant matériel ESP32 (adresse MAC) |
| **model** | VARCHAR(50) | Modèle du bracelet |
| **firmware_version** | VARCHAR(20) | Version du firmware embarqué |
| **status** | ENUM | `unassigned` / `active` / `inactive` |
| **registered_at** | TIMESTAMP | Date d'enregistrement |

#### Table : `DeviceAssignment` (historique des associations)
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **device_id** | UUID (FK → Device) | Bracelet concerné |
| **patient_id** | UUID (FK → Patient) | Patient assigné |
| **assigned_at** | TIMESTAMP | Date d'association |
| **unassigned_at** | TIMESTAMP | Date de fin d'association (null si actif) |
| **is_current** | BOOLEAN | Association active actuellement |

#### Table : `DeviceStatus`
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **device_id** | UUID (FK → Device) | Bracelet concerné |
| **battery_level** | INTEGER | Niveau de batterie en % |
| **is_connected** | BOOLEAN | Connecté actuellement en Bluetooth |
| **last_sync** | TIMESTAMP | Dernière synchronisation |

### 3.4 Module biometric_data — Hady

#### Table : `BiometricReading`
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **patient_id** | UUID (FK → Patient) | Patient concerné |
| **device_id** | UUID (FK → Device) | Bracelet source |
| **heart_rate** | INTEGER | Rythme cardiaque (bpm) |
| **temperature** | DECIMAL(4,1) | Température corporelle (°C) |
| **spo2** | INTEGER | Saturation en oxygène (%) |
| **movement_data** | JSON | Données accéléromètre brutes |
| **recorded_at** | TIMESTAMP | Date de mesure réelle (sur le bracelet) |
| **synced_at** | TIMESTAMP | Date de synchronisation avec le serveur |
| **is_synced_offline** | BOOLEAN | Donnée envoyée après une coupure réseau |

#### Table : `LocationLog`
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **patient_id** | UUID (FK → Patient) | Patient concerné |
| **latitude** | DECIMAL(9,6) | Latitude GPS |
| **longitude** | DECIMAL(9,6) | Longitude GPS |
| **recorded_at** | TIMESTAMP | Date de localisation |

### 3.5 Module alerts — Fatima

#### Table : `Alert`
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **patient_id** | UUID (FK → Patient) | Patient concerné |
| **type** | ENUM | `heart_rate` / `temperature` / `spo2` / `movement` |
| **severity** | ENUM | `warning` / `critical` |
| **value_detected** | DECIMAL(6,2) | Valeur mesurée ayant déclenché l'alerte |
| **threshold_value** | DECIMAL(6,2) | Seuil dépassé |
| **status** | ENUM | `active` / `resolved` / `false_alarm` |
| **created_at** | TIMESTAMP | Date de déclenchement |
| **resolved_at** | TIMESTAMP | Date de résolution |

#### Table : `AlertNotificationLog`
| Champ | Type | Description |
| :--- | :--- | :--- |
| **id** | UUID (PK) | Identifiant unique |
| **alert_id** | UUID (FK → Alert) | Alerte concernée |
| **recipient_user_id** | UUID (FK → User) | Destinataire de la notification |
| **channel** | ENUM | `sms` / `push` |
| **status** | ENUM | `sent` / `failed` / `delivered` |
| **sent_at** | TIMESTAMP | Date d'envoi |

---

## 4. Planning détaillé — semaine par semaine
Le projet est organisé sur 8 semaines (2 mois), avec une réunion de suivi deux fois par semaine (mardi et vendredi). Chaque membre de l'équipe livre quelque chose de concret chaque semaine, qu'il s'agisse du backend ou du frontend.

> [!TIP]
> **Principe directeur :**
> Le frontend travaille toujours avec des données simulées en avance sur le backend réel. Dès qu'un module backend expose son contrat d'API (la structure exacte des données échangées), le frontend peut commencer à construire ses écrans sans attendre que l'implémentation complète soit terminée.

### 🗓️ Semaine 1 (06 juil – 12 juil 2026) : Initialisation et architecture
**Objectif :** Poser les fondations du projet, créer les structures de code et valider le schéma de base de données en équipe.
*   **Hadjiratou** : Initialisation Django + modèle User et Profile. *Livrable :* Migrations PostgreSQL appliquées pour `accounts/`.
*   **Fatima** : Modèles Patient, MedicalHistory, PatientRelative. *Livrable :* Migrations PostgreSQL appliquées pour `patients/`.
*   **Hady** : Modèles Device, DeviceAssignment, BiometricReading. *Livrable :* Migrations PostgreSQL appliquées pour `devices/` et `biometric_data/`.
*   **Mamadou Samba** : Initialisation Flutter + thème global + navigation. *Livrable :* Projet Flutter structuré avec `go_router` et le thème Wallan.
*   **Alpha** : Maquettes des écrans Alertes et Dashboard Proche. *Livrable :* Maquettes validées en réunion.
*   *Réunions :*
    - Réunion 1 (mardi) : Présentation du plan de travail, validation du schéma de base de données.
    - Réunion 2 (vendredi) : Démonstration des migrations Django de chacun, validation collective.

### 🗓️ Semaine 2 (13 juil – 19 juil 2026) : Authentification et CRUD de base
**Objectif :** Avoir une API d'authentification fonctionnelle et les opérations de base sur les patients et les bracelets.
*   **Hadjiratou** : API JWT complète. *Livrable :* Endpoints `register` / `login` / `logout` / `me` fonctionnels et testés.
*   **Fatima** : API CRUD patients. *Livrable :* Endpoints `GET/POST /api/patients/` et `GET/PUT/DELETE /api/patients/{id}/` fonctionnels.
*   **Hady** : API d'enregistrement et association des bracelets. *Livrable :* Endpoints `register` et `associate` fonctionnels (logique `hardware_id`).
*   **Mamadou Samba** : Écran `LoginScreen` + `RegisterScreen` Flutter. *Livrable :* Écrans connectés à des données simulées, navigation fonctionnelle.
*   **Alpha** : Structure `AlertScreen` + `SosScreen`. *Livrable :* Écrans avec données simulées, bouton SOS visuel fonctionnel.
*   *Réunions :*
    - Réunion 1 (mardi) : Démonstration de l'API Auth en cours, ajustements.
    - Réunion 2 (vendredi) : Démonstration complète Auth + Patients + Devices via Postman.
*   *Point technique :* `POST /api/devices/{id}/associate/` reçoit `patient_id` et `hardware_id`. Le backend vérifie que le `hardware_id` correspond bien au device enregistré, crée une ligne dans `DeviceAssignment` avec `is_current=true`, et met à jour le statut du Device à `active`.

### 🗓️ Semaine 3 (20 juil – 26 juil 2026) : Données biométriques et alertes
**Objectif :** Permettre la réception des données vitales et la détection automatique des situations critiques.
*   **Hadjiratou** : Support de synchronisation hors-ligne (API). *Livrable :* Endpoint de synchronisation par lot acceptant des mesures horodatées avec `is_synced_offline=true`.
*   **Fatima** : Modèle `Alert` + API de détection. *Livrable :* Endpoints `GET /api/alerts/` et `POST /api/alerts/create/` avec comparaison aux seuils du patient.
*   **Hady** : API de réception des données biométriques. *Livrable :* Endpoint `POST /api/biometrics/` recevant `heart_rate`, `temperature`, `spo2`, `movement_data`.
*   **Mamadou Samba** : Écran `AdminDashboard` (structure). *Livrable :* Vue d'ensemble avec données simulées.
*   **Alpha** : `RelativeDashboard` + `NotificationsScreen`. *Livrable :* Écrans proche avec données simulées.
*   *Réunions :*
    - Réunion 1 (mardi) : Test du flux complet (mesures → alertes).
    - Réunion 2 (vendredi) : Démonstration des écrans Admin et Proche.

### 🗓️ Semaine 4 (27 juil – 02 août 2026) : Notifications et tests
**Objectif :** Faire sortir les alertes vers l'extérieur (SMS, push) et fiabiliser le système.
*   **Hadjiratou** : Tests Postman complets + documentation API. *Livrable :* Collection Postman couvrant tous les endpoints Auth, Patients, Devices.
*   **Fatima** : Intégration SMS Africa's Talking + Push Firebase. *Livrable :* Endpoint d'envoi SMS testé avec un vrai message.
*   **Hady** : Historique biométrique + préparation WebSocket. *Livrable :* Endpoint d'historique + recherche technique Django Channels.
*   **Mamadou Samba** : Intégration API réelle dans Auth + Admin Flutter. *Livrable :* Connexion Dio fonctionnelle remplaçant les données simulées.
*   **Alpha** : Statistics Dashboard Flutter. *Livrable :* Écran avec graphiques `fl_chart` sur données simulées.
*   *Réunions :*
    - Réunion 1 (mardi) : Test d'envoi SMS réel via Africa's Talking.
    - Réunion 2 (vendredi) : Bilan de mi-projet et démos.
*   *Livrable mi-projet :* Backend fonctionnel assemblé et frontend connecté aux premières APIs réelles.

### 🗓️ Semaine 5 (03 août – 09 août 2026) : Intégration complète Flutter / Django
**Objectif :** Connecter tous les écrans Flutter restants aux APIs réelles du backend.
*   **Hadjiratou** : Support technique intégration + corrections API. *Livrable :* Résolution des bugs signalés par le frontend sous 48h.
*   **Fatima** : Finalisation API recommandations et historique patient. *Livrable :* Endpoint d'historique patient complet.
*   **Hady** : Intégration Bluetooth BLE (connexion simulateur). *Livrable :* Service Flutter connecté à un bracelet simulé.
*   **Mamadou Samba** : Connexion complète Admin Dashboard à l'API. *Livrable :* Données réelles affichées sur le Dashboard Admin.
*   **Alpha** : Connexion Alertes + Notifications + Stats à l'API. *Livrable :* Connexion complète aux endpoints réels.
*   *Réunions :*
    - Réunion 1 (mardi) : Point sur les blocages d'intégration.
    - Réunion 2 (vendredi) : Démo de l'app mobile connectée.

### 🗓️ Semaine 6 (10 août – 16 août 2026) : Mode hors-ligne et stabilisation
**Objectif :** Implémenter le stockage local SQLite et fiabiliser l'ensemble du système.
*   **Hadjiratou** : Tests fonctionnels complets de tous les modules. *Livrable :* Rapport de bugs détaillé avec niveaux de priorité.
*   **Fatima** : Gestion des cas limites des alertes. *Livrable :* Logique de déduplication des alertes en doublon.
*   **Hady** : Stockage local SQLite côté Flutter. *Livrable :* Sauvegarde locale des mesures en cas de déconnexion et synchronisation automatique au retour du réseau.
*   **Mamadou Samba** : Corrections UI/UX selon retours. *Livrable :* Interface Admin et Auth polie.
*   **Alpha** : Corrections UI/UX selon retours. *Livrable :* Interface Alertes, Notifications et Proche finalisée.
*   *Réunions :*
    - Réunion 1 (mardi) : Démo du mode hors-ligne et synchronisation.
    - Réunion 2 (vendredi) : Revue et planification des corrections de bugs.

### 🗓️ Semaine 7 (17 août – 23 août 2026) : Tests terrain et corrections
**Objectif :** Tester l'application avec des utilisateurs réels (patients et familles) et corriger les problèmes remontés.
*   **Tous** : Tests terrain avec patients et familles volontaires. *Livrable :* Synthèse documentée des retours d'utilisation.
*   **Hadjiratou** : Correction des bugs critiques identifiés. *Livrable :* Application stabilisée, exempte de crashs bloquants.
*   **Fatima** : Ajustement des seuils d'alerte selon retours réels. *Livrable :* Étalonnage précis des seuils d'alerte.
*   **Hady** : Optimisation de la synchronisation hors-ligne. *Livrable :* Transfert de données fiable même après une coupure prolongée.
*   **Mamadou Samba + Alpha** : Améliorations UX selon retours. *Livrable :* Ergonomie de l'interface ajustée.
*   *Réunions :*
    - Réunion 1 (mardi) : Lancement officiel et répartition des tests terrain.
    - Réunion 2 (vendredi) : Compilation des retours et décision go/no-go.

### 🗓️ Semaine 8 (24 août – 30 août 2026) : Finalisation, documentation et démonstration
**Objectif :** Livrer une version logicielle stable et documentée. Préparer la phase hardware.
*   **Hadjiratou** : Documentation technique complète. *Livrable :* Documentation backend finalisée.
*   **Fatima** : Documentation des modèles et de la logique d'alertes. *Livrable :* Schéma ERD commenté.
*   **Hady** : Documentation du protocole Bluetooth et plan hardware. *Livrable :* Cahier technique d'intégration hardware (ESP32).
*   **Mamadou Samba** : Préparation des slides de présentation finale. *Livrable :* Support de présentation de fin de projet.
*   **Alpha** : Répétition de la démonstration finale. *Livrable :* Scénario de démonstration validé.
*   **Tous** : Démonstration finale du prototype logiciel complet. *Livrable :* Démonstration et validation finale du logiciel.
*   *Réunions :*
    - Réunion 1 (mardi) : Répétition générale.
    - Réunion 2 (vendredi) : Démo de clôture.

> [!TIP]
> **Après la semaine 8 — Phase Hardware :**
> Une fois le logiciel validé, l'équipe attaquera la phase d'assemblage physique du bracelet (ESP32, capteurs MAX30102, MLX90614, MPU-6050, module SIM800L) et l'écriture du firmware embarqué, sous la direction de Mamadou Hady Diallo.

---

## 5. Cahier technique — liste complète des endpoints API

### 5.1 Authentification (`accounts/`)
| Méthode | Endpoint | Description |
| :--- | :--- | :--- |
| **POST** | `/api/auth/register/` | Inscription d'un nouvel utilisateur |
| **POST** | `/api/auth/login/` | Connexion, retourne l'access_token et le refresh_token |
| **POST** | `/api/auth/logout/` | Déconnexion (invalidation du token) |
| **POST** | `/api/auth/refresh/` | Renouvellement de l'access_token |
| **GET** | `/api/auth/me/` | Récupération du profil de l'utilisateur connecté |
| **PUT** | `/api/profile/update/` | Mise à jour du profil |

### 5.2 Patients (`patients/`)
| Méthode | Endpoint | Description |
| :--- | :--- | :--- |
| **GET** | `/api/patients/` | Liste des patients (filtrée par rôle) |
| **POST** | `/api/patients/` | Création d'un dossier patient |
| **GET** | `/api/patients/{id}/` | Détail d'un patient |
| **PUT** | `/api/patients/{id}/` | Mise à jour d'un dossier patient |
| **DELETE** | `/api/patients/{id}/` | Suppression d'un dossier patient |
| **GET** | `/api/patients/{id}/history/` | Historique médical complet |

### 5.3 Bracelets connectés (`devices/`)
| Méthode | Endpoint | Description |
| :--- | :--- | :--- |
| **POST** | `/api/devices/register/` | Enregistrement d'un nouveau bracelet (`hardware_id`) |
| **GET** | `/api/devices/` | Liste de tous les bracelets |
| **POST** | `/api/devices/{id}/associate/` | Association d'un bracelet à un patient |
| **GET** | `/api/devices/{id}/status/` | État actuel du bracelet |

### 5.4 Données biométriques (`biometric_data/`)
| Méthode | Endpoint | Description |
| :--- | :--- | :--- |
| **POST** | `/api/biometrics/` | Transmission d'une mesure en temps réel |
| **POST** | `/api/biometrics/sync/` | Synchronisation d'un lot de mesures hors-ligne |
| **GET** | `/api/biometrics/{patient_id}/` | Dernières constantes reçues pour un patient |
| **GET** | `/api/biometrics/{patient_id}/history/` | Historique complet des mesures (pour graphes) |

### 5.5 Alertes et urgences (`alerts/`)
| Méthode | Endpoint | Description |
| :--- | :--- | :--- |
| **GET** | `/api/alerts/` | Liste des alertes |
| **POST** | `/api/alerts/create/` | Déclenchement d'une alerte |
| **POST** | `/api/alerts/emergency/` | Signalement SOS d'urgence |
| **PUT** | `/api/alerts/{id}/resolve/` | Résolution d'une alerte |

### 5.6 Notifications (`notifications/`)
| Méthode | Endpoint | Description |
| :--- | :--- | :--- |
| **POST** | `/api/notifications/sms/` | Envoi d'un SMS via l'API Africa's Talking |
| **POST** | `/api/notifications/push/` | Envoi d'un push via Firebase Cloud Messaging |
| **GET** | `/api/notifications/` | Historique des notifications expédiées |

### 5.7 Statistiques (`statistics/`)
| Méthode | Endpoint | Description |
| :--- | :--- | :--- |
| **GET** | `/api/statistics/reports/` | Rapports et tendances médicales d'un patient |
| **GET** | `/api/admin/dashboard/` | Métriques d'activité pour les administrateurs |

---

## 6. Risques et points de vigilance
| Risque | Niveau | Mesures d'atténuation |
| :--- | :--- | :--- |
| **Retard d'intégration** (frontend bloqué par le backend) | **Moyen** | Contrats d'API signés et mockés dès la première semaine. |
| **Pertes de données** lors des phases hors-ligne | **Élevé** | SQLite local obligatoire avec contrôle d'intégrité lors de la synchronisation. |
| **Fatigue d'alerte** (fausses alertes en série) | **Moyen** | Système de déduplication temporelle des alertes et réglage des seuils par patient. |
| **Insuffisance des tests terrain** | **Élevé** | Semaine 7 intégralement allouée à la récolte de feedback utilisateur en situation réelle. |
| **Conflit d'adresse unique de bracelet** | **Faible** | Utilisation stricte de l'adresse MAC Bluetooth (`hardware_id`). |

---

## 7. Conclusion
Ce plan de travail structure de manière optimale les 8 semaines de développement logiciel du projet **Wallan**. L'approche ciblant une séparation nette des rôles techniques — backend pour Hady, Fatima et Hadjiratou, frontend pour Mamadou Samba et Alpha — permet de maximiser la concentration de chacun et d'accélérer l'avancement. 

À l'issue de cette phase logicielle, la mise en place du firmware et des capteurs physiques viendra compléter le prototype pour en faire une solution opérationnelle de surveillance médicale.
