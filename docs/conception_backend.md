# 🗄️ Cahier de Conception Backend — Projet WALLAN

## Technologies
- **Framework** : Django REST Framework
- **Langage** : Python 3.11+
- **Base de données** : PostgreSQL 15
- **Authentification** : JWT (djangorestframework-simplejwt)
- **Notifications** : Firebase Cloud Messaging
- **Tâches asynchrones** : Redis + Celery
- **Documentation API** : drf-spectacular (OpenAPI/Swagger)

---

## Structure Générale

```
backend/
├── accounts/          # Module 1 — Auth & Utilisateurs
├── patients/          # Module 2 — Gestion Patients
├── care_management/   # Module 3 — Médecins & Proches
├── devices/           # Module 4 — Bracelets Connectés
├── biometric_data/    # Module 5 — Données Biométriques
├── alerts/            # Module 6 — Alertes & Urgences
├── notifications/     # Module 7 — Notifications
├── statistics/        # Module 8 — Statistiques & Rapports
├── administration/    # Module 9 — Administration
├── api/               # Routeur API principal
├── config/            # Configuration Django
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── manage.py
```

---

## MODULE 1 — Authentification et Utilisateurs

**Dossier** : `accounts/`  
**Développeur** : Mamadou Samba Diallo

### Modèles

```python
# accounts/models.py

class Role(models.Model):
    name = models.CharField(max_length=50)  # admin, patient, doctor, relative
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    username = models.CharField(max_length=150, unique=True)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    phone = models.CharField(max_length=20, blank=True)
    role = models.ForeignKey(Role, on_delete=models.SET_NULL, null=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    USERNAME_FIELD = 'email'

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    avatar = models.ImageField(upload_to='avatars/', blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    address = models.TextField(blank=True)
    city = models.CharField(max_length=100, blank=True)
    country = models.CharField(max_length=100, default='Guinée')
    fcm_token = models.TextField(blank=True)  # Pour notifications push
```

### Endpoints API

| Méthode | URL | Description |
|---------|-----|-------------|
| POST | `/api/auth/register/` | Inscription |
| POST | `/api/auth/login/` | Connexion (retourne JWT) |
| POST | `/api/auth/logout/` | Déconnexion |
| POST | `/api/auth/refresh/` | Renouvellement token |
| POST | `/api/auth/password-reset/` | Réinitialisation mot de passe |
| GET | `/api/profile/` | Consulter son profil |
| PUT | `/api/profile/update/` | Modifier son profil |

---

## MODULE 2 — Gestion des Patients

**Dossier** : `patients/`  
**Développeur** : Fatima Abdul Sow

### Modèles

```python
# patients/models.py

class Patient(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    blood_type = models.CharField(max_length=5, blank=True)
    weight = models.FloatField(null=True, blank=True)
    height = models.FloatField(null=True, blank=True)
    emergency_contact_name = models.CharField(max_length=200, blank=True)
    emergency_contact_phone = models.CharField(max_length=20, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

class Disease(models.Model):
    name = models.CharField(max_length=200)
    category = models.CharField(max_length=100)  # rhumatisme, épilepsie, etc.
    description = models.TextField(blank=True)
    icd_code = models.CharField(max_length=20, blank=True)

class MedicalHistory(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='medical_histories')
    disease = models.ForeignKey(Disease, on_delete=models.CASCADE)
    diagnosed_at = models.DateField()
    is_active = models.BooleanField(default=True)
    notes = models.TextField(blank=True)

class Treatment(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='treatments')
    medication_name = models.CharField(max_length=200)
    dosage = models.CharField(max_length=100)
    frequency = models.CharField(max_length=100)
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    prescribed_by = models.CharField(max_length=200, blank=True)
    is_active = models.BooleanField(default=True)
```

### Endpoints API

| Méthode | URL | Description |
|---------|-----|-------------|
| GET | `/api/patients/` | Liste des patients |
| POST | `/api/patients/` | Créer un dossier patient |
| GET | `/api/patients/{id}/` | Détails d'un patient |
| PUT | `/api/patients/{id}/` | Modifier un patient |
| DELETE | `/api/patients/{id}/` | Supprimer un patient |
| GET | `/api/patients/{id}/history/` | Historique médical |
| GET | `/api/patients/{id}/treatments/` | Traitements en cours |

---

## MODULE 3 — Gestion Médecins et Proches

**Dossier** : `care_management/`  
**Développeur** : Fatima Abdul Sow

### Modèles

```python
# care_management/models.py

class DoctorProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    specialty = models.CharField(max_length=200)
    license_number = models.CharField(max_length=100, unique=True)
    hospital = models.CharField(max_length=200, blank=True)
    years_experience = models.IntegerField(default=0)

class RelativeProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    relationship = models.CharField(max_length=100)  # père, mère, frère, etc.

class DoctorPatient(models.Model):
    doctor = models.ForeignKey(DoctorProfile, on_delete=models.CASCADE)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    assigned_at = models.DateTimeField(auto_now_add=True)
    is_primary = models.BooleanField(default=False)

class PatientRelative(models.Model):
    relative = models.ForeignKey(RelativeProfile, on_delete=models.CASCADE)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    assigned_at = models.DateTimeField(auto_now_add=True)
    can_receive_alerts = models.BooleanField(default=True)

class Recommendation(models.Model):
    doctor = models.ForeignKey(DoctorProfile, on_delete=models.CASCADE)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_urgent = models.BooleanField(default=False)
```

### Endpoints API

| Méthode | URL | Description |
|---------|-----|-------------|
| GET | `/api/doctors/` | Liste des médecins |
| GET | `/api/doctors/{id}/patients/` | Patients d'un médecin |
| POST | `/api/doctors/{id}/assign/` | Affecter un patient |
| GET | `/api/relatives/` | Liste des proches |
| POST | `/api/relatives/{id}/assign/` | Affecter un proche à un patient |
| GET | `/api/recommendations/` | Liste des recommandations |
| POST | `/api/recommendations/` | Créer une recommandation |

---

## MODULE 4 — Gestion des Bracelets Connectés

**Dossier** : `devices/`  
**Développeur** : Mamadou Hady Diallo

### Modèles

```python
# devices/models.py

class Device(models.Model):
    serial_number = models.CharField(max_length=100, unique=True)
    mac_address = models.CharField(max_length=17, unique=True)
    firmware_version = models.CharField(max_length=50, blank=True)
    model = models.CharField(max_length=100, default='Wallan-ESP32-v1')
    patient = models.OneToOneField(Patient, on_delete=models.SET_NULL, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    registered_at = models.DateTimeField(auto_now_add=True)
    last_sync = models.DateTimeField(null=True, blank=True)

class DeviceStatus(models.Model):
    device = models.ForeignKey(Device, on_delete=models.CASCADE, related_name='statuses')
    battery_level = models.IntegerField()  # 0-100 %
    signal_strength = models.IntegerField()  # dBm
    is_connected = models.BooleanField(default=False)
    connection_type = models.CharField(max_length=20)  # bluetooth, wifi
    recorded_at = models.DateTimeField(auto_now_add=True)
```

### Endpoints API

| Méthode | URL | Description |
|---------|-----|-------------|
| POST | `/api/devices/register/` | Enregistrer un bracelet |
| GET | `/api/devices/` | Liste des bracelets |
| GET | `/api/devices/{id}/` | Détails d'un bracelet |
| PUT | `/api/devices/{id}/` | Modifier un bracelet |
| POST | `/api/devices/{id}/assign/` | Associer bracelet ↔ patient |
| GET | `/api/devices/{id}/status/` | État du bracelet |

---

## MODULE 5 — Données Biométriques

**Dossier** : `biometric_data/`  
**Développeur** : Mamadou Hady Diallo

### Modèles

```python
# biometric_data/models.py

class BiometricData(models.Model):
    device = models.ForeignKey(Device, on_delete=models.CASCADE)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    recorded_at = models.DateTimeField()
    is_anomaly = models.BooleanField(default=False)

class HeartRate(models.Model):
    biometric = models.OneToOneField(BiometricData, on_delete=models.CASCADE)
    value_bpm = models.FloatField()          # Battements/minute
    spo2_percent = models.FloatField()       # Saturation O2 (%)
    # Seuils normaux : 60-100 bpm, SpO2 > 95%

class Temperature(models.Model):
    biometric = models.OneToOneField(BiometricData, on_delete=models.CASCADE)
    body_temp = models.FloatField()          # Température corporelle (°C)
    joint_temp = models.FloatField(null=True)# Température articulaire (°C) — clé rhumatisme
    # Seuils normaux : 36.1 – 37.2 °C

class Location(models.Model):
    biometric = models.OneToOneField(BiometricData, on_delete=models.CASCADE)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    accuracy = models.FloatField(null=True)
    address = models.TextField(blank=True)
```

### Endpoints API

| Méthode | URL | Description |
|---------|-----|-------------|
| POST | `/api/biometrics/` | Recevoir des mesures (bracelet → API) |
| GET | `/api/biometrics/history/` | Historique des mesures |
| GET | `/api/biometrics/latest/` | Dernières mesures d'un patient |
| GET | `/api/biometrics/anomalies/` | Anomalies détectées |

---

## MODULE 6 — Alertes et Urgences

**Dossier** : `alerts/`  
**Développeur** : Alpha Oumar Bah

### Modèles

```python
# alerts/models.py

class Alert(models.Model):
    SEVERITY_CHOICES = [('low', 'Faible'), ('medium', 'Moyen'), ('high', 'Élevé'), ('critical', 'Critique')]
    STATUS_CHOICES = [('active', 'Active'), ('acknowledged', 'Reconnue'), ('resolved', 'Résolue')]

    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    biometric_data = models.ForeignKey(BiometricData, on_delete=models.SET_NULL, null=True)
    alert_type = models.CharField(max_length=100)  # heart_rate, temperature, etc.
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

class Emergency(models.Model):
    alert = models.OneToOneField(Alert, on_delete=models.CASCADE)
    gps_location = models.TextField(blank=True)
    sms_sent = models.BooleanField(default=False)
    notified_relatives = models.ManyToManyField(RelativeProfile, blank=True)
    response_time_seconds = models.IntegerField(null=True)

class Crisis(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField(null=True, blank=True)
    crisis_type = models.CharField(max_length=100)   # rhumatisme, épilepsie, etc.
    severity = models.CharField(max_length=20)
    notes = models.TextField(blank=True)
```

### Endpoints API

| Méthode | URL | Description |
|---------|-----|-------------|
| GET | `/api/alerts/` | Liste des alertes |
| POST | `/api/alerts/create/` | Créer une alerte manuellement |
| GET | `/api/alerts/{id}/` | Détail d'une alerte |
| PUT | `/api/alerts/{id}/resolve/` | Résoudre une alerte |
| GET | `/api/emergencies/` | Liste des urgences |
| GET | `/api/crises/` | Historique des crises |

---

## MODULE 7 — Notifications

**Dossier** : `notifications/`  
**Développeur** : Alpha Oumar Bah

### Modèles

```python
# notifications/models.py

class Notification(models.Model):
    TYPE_CHOICES = [('push', 'Push'), ('sms', 'SMS'), ('email', 'Email')]
    STATUS_CHOICES = [('pending', 'En attente'), ('sent', 'Envoyé'), ('failed', 'Échoué')]

    recipient = models.ForeignKey(User, on_delete=models.CASCADE)
    alert = models.ForeignKey(Alert, on_delete=models.SET_NULL, null=True)
    notification_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    title = models.CharField(max_length=200)
    message = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

class SmsLog(models.Model):
    notification = models.OneToOneField(Notification, on_delete=models.CASCADE)
    phone_number = models.CharField(max_length=20)
    provider = models.CharField(max_length=50, default="Africa's Talking")
    message_id = models.CharField(max_length=100, blank=True)
    cost = models.DecimalField(max_digits=10, decimal_places=4, null=True)

class PushNotification(models.Model):
    notification = models.OneToOneField(Notification, on_delete=models.CASCADE)
    fcm_token = models.TextField()
    fcm_message_id = models.CharField(max_length=200, blank=True)
```

### Endpoints API

| Méthode | URL | Description |
|---------|-----|-------------|
| GET | `/api/notifications/` | Liste des notifications reçues |
| POST | `/api/notifications/send/` | Envoyer une notification |
| PUT | `/api/notifications/{id}/read/` | Marquer comme lue |

---

## MODULE 8 — Statistiques et Rapports

**Dossier** : `statistics/`  
**Développeur** : Alpha Oumar Bah

### Modèles

```python
# statistics/models.py

class Statistic(models.Model):
    PERIOD_CHOICES = [('daily', 'Quotidien'), ('weekly', 'Hebdomadaire'), ('monthly', 'Mensuel')]

    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    period = models.CharField(max_length=20, choices=PERIOD_CHOICES)
    period_start = models.DateField()
    period_end = models.DateField()
    avg_heart_rate = models.FloatField(null=True)
    avg_temperature = models.FloatField(null=True)
    avg_spo2 = models.FloatField(null=True)
    total_alerts = models.IntegerField(default=0)
    total_crises = models.IntegerField(default=0)
    generated_at = models.DateTimeField(auto_now_add=True)

class Report(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    generated_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    period_start = models.DateField()
    period_end = models.DateField()
    pdf_file = models.FileField(upload_to='reports/', blank=True)
    summary = models.TextField(blank=True)
    generated_at = models.DateTimeField(auto_now_add=True)
```

### Endpoints API

| Méthode | URL | Description |
|---------|-----|-------------|
| GET | `/api/statistics/` | Statistiques d'un patient |
| GET | `/api/statistics/global/` | Statistiques globales (admin) |
| GET | `/api/reports/` | Liste des rapports |
| POST | `/api/reports/generate/` | Générer un rapport PDF |
| GET | `/api/reports/{id}/download/` | Télécharger un rapport |

---

## MODULE 9 — Administration

**Dossier** : `administration/`  
**Développeur** : Mamadou Samba Diallo

### Modèles

```python
# administration/models.py

class AuditLog(models.Model):
    ACTION_CHOICES = [('create', 'Création'), ('update', 'Modification'), ('delete', 'Suppression'), ('login', 'Connexion')]

    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)
    resource = models.CharField(max_length=100)
    resource_id = models.CharField(max_length=50, blank=True)
    ip_address = models.GenericIPAddressField(null=True)
    details = models.JSONField(default=dict)
    timestamp = models.DateTimeField(auto_now_add=True)

class SystemLog(models.Model):
    LEVEL_CHOICES = [('info', 'Info'), ('warning', 'Avertissement'), ('error', 'Erreur'), ('critical', 'Critique')]

    level = models.CharField(max_length=20, choices=LEVEL_CHOICES)
    module = models.CharField(max_length=100)
    message = models.TextField()
    stack_trace = models.TextField(blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

class Backup(models.Model):
    filename = models.CharField(max_length=200)
    file_size = models.BigIntegerField()
    backup_type = models.CharField(max_length=50)  # full, incremental
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    is_successful = models.BooleanField(default=True)
```

### Endpoints API

| Méthode | URL | Description |
|---------|-----|-------------|
| GET | `/api/admin/dashboard/` | Tableau de bord admin |
| GET | `/api/admin/logs/` | Logs système |
| GET | `/api/admin/audit/` | Journal d'audit |
| POST | `/api/admin/backup/` | Déclencher une sauvegarde |
| GET | `/api/admin/users/` | Gestion des utilisateurs |

---

## Configuration Requise

```python
# requirements.txt
django==4.2.*
djangorestframework==3.15.*
djangorestframework-simplejwt==5.*
django-cors-headers==4.*
psycopg2-binary==2.9.*
redis==5.*
celery==5.*
firebase-admin==6.*
drf-spectacular==0.27.*
pillow==10.*
reportlab==4.*        # Génération PDF
africas-talking==1.*  # SMS
python-decouple==3.*  # Variables d'environnement
```
