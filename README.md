# 🏥 Projet WALLAN — Bracelet Intelligent de Surveillance Médicale

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.0-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter" />
  <img src="https://img.shields.io/badge/Django-REST-092E20?style=for-the-badge&logo=django" />
  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql" />
  <img src="https://img.shields.io/badge/Status-En_développement-orange?style=for-the-badge" />
</p>

---

## 📋 Description du Projet

**Wallan** est une plateforme intelligente de surveillance médicale destinée aux patients atteints de maladies chroniques (Phase 1 : Rhumatisme). Elle combine un **bracelet connecté ESP32** avec une **application mobile Flutter** et une **API REST Django** pour assurer la surveillance continue, la détection précoce des crises et l'alerte automatique des proches.

---

## 👥 Équipe de Développement

| Membre | Rôle Principal |
|--------|---------------|
| **Mamadou Samba Diallo** | Chef de projet / Backend Auth & Admin |
| **Fatima Abdul Sow** | Backend Patients & Care Management / Frontend Patient & Doctor |
| **Mamadou Hady Diallo** | Backend Devices & Biometrics / Frontend Device & Biometrics |
| **Alpha Oumar Bah** | Backend Alerts, Notifications & Statistics / Frontend Alerts, Notifications & Statistics |
| **Hadjiratou Diallo** | Frontend Auth, Admin & Relative / Base de données & DevOps |

---

## 🏗️ Architecture du Système

```
┌─────────────────────────────────────────────────────┐
│              COUCHE 1 : BRACELET (Edge)             │
│         ESP32 + Capteurs + Bluetooth/GSM            │
└──────────────────────┬──────────────────────────────┘
                       │ Bluetooth
┌──────────────────────▼──────────────────────────────┐
│           COUCHE 2 : APPLICATION MOBILE             │
│              Flutter (Android / iOS)                │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP REST / WebSocket
┌──────────────────────▼──────────────────────────────┐
│            COUCHE 3 : PLATEFORME CLOUD              │
│         Django REST Framework + PostgreSQL          │
│              Redis + Celery + Firebase              │
└─────────────────────────────────────────────────────┘
```

---

## 📁 Structure du Projet

```
wallan/
├── backend/                  # API Django REST Framework
│   ├── accounts/
│   ├── patients/
│   ├── care_management/
│   ├── devices/
│   ├── biometric_data/
│   ├── alerts/
│   ├── notifications/
│   ├── statistics/
│   ├── administration/
│   ├── api/
│   ├── config/
│   └── manage.py
│
├── frontend/                 # Application Mobile Flutter
│   └── lib/
│       ├── core/
│       ├── models/
│       ├── services/
│       ├── providers/
│       ├── modules/
│       │   ├── auth/
│       │   ├── patient/
│       │   ├── doctor/
│       │   ├── relative/
│       │   ├── device/
│       │   ├── biometrics/
│       │   ├── alerts/
│       │   ├── notifications/
│       │   ├── statistics/
│       │   └── admin/
│       ├── widgets/
│       ├── routes/
│       ├── themes/
│       ├── utils/
│       └── main.dart
│
├── database/                 # Scripts SQL & Migrations
│   ├── schema/
│   ├── migrations/
│   ├── seeds/
│   └── backups/
│
├── docs/                     # Documentation complète
│   ├── cahier_des_charges.md
│   ├── conception_backend.md
│   ├── conception_frontend.md
│   ├── repartition_modules.md
│   └── planning.md
│
├── .github/
│   └── workflows/            # CI/CD GitHub Actions
│
└── README.md
```

---

## 🚀 Technologies Utilisées

### Backend
| Technologie | Usage |
|-------------|-------|
| Django REST Framework | API REST principale |
| Python | Langage backend |
| PostgreSQL | Base de données principale |
| JWT (SimpleJWT) | Authentification |
| Firebase Cloud Messaging | Notifications Push |
| Redis + Celery | Cache et tâches asynchrones |

### Frontend
| Technologie | Usage |
|-------------|-------|
| Flutter / Dart | Application mobile cross-platform |
| Provider | Gestion d'état |
| Go Router | Navigation |
| Dio | Communication API |
| SQLite | Stockage local |
| FL Chart | Graphiques médicaux |
| Firebase Messaging | Notifications Push |

---

## 📅 Planning Global

| Phase | Période | Description |
|-------|---------|-------------|
| Phase 1 | 29 juin – 12 juil 2026 | Analyse, conception, initialisation |
| Phase 2 | 13 juil – 26 juil 2026 | Développement Hardware |
| Phase 3 | 27 juil – 09 août 2026 | Firmware + App mobile (base) |
| Phase 4 | 10 août – 23 août 2026 | Intégration système |
| Phase 5 | 24 août – 06 sept 2026 | Tests internes |
| Phase 6 | 07 sept – 20 sept 2026 | Tests terrain |
| Phase 7 | 21 sept – 09 oct 2026  | Validation finale + Démo |

---

## 🤝 Règles de Collaboration

1. **Branches** : Chaque développeur travaille sur sa branche `feature/nom-module`
2. **Commits** : Messages de commit en français, clairs et descriptifs
3. **Pull Requests** : Revue obligatoire par 1 autre membre avant merge
4. **Réunions** : 2 fois par semaine via Google Meet
5. **Communication** : Groupe WhatsApp dédié pour les échanges quotidiens

---

## ⚙️ Installation

```bash
# Cloner le projet
git clone https://github.com/[organisation]/wallan.git
cd wallan

# Backend
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver

# Frontend
cd frontend
flutter pub get
flutter run
```

---

## 📞 Contact

**Chef de projet** : Mamadou Barry  
**Département** : NTIC, UGANC  
**Contact** : 624 064 783  

---

*Projet Wallan — Version 2.0 — Juin 2026*
