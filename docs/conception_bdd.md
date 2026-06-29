# 🗄️ Conception Base de Données — Projet WALLAN
## Développeur responsable : Hadjiratou Diallo

---

## Schéma Entité-Relations (ERD)

```
┌──────────┐       ┌──────────┐       ┌──────────────┐
│   Role   │──1:N──│   User   │──1:1──│   Profile    │
└──────────┘       └────┬─────┘       └──────────────┘
                        │
           ┌────────────┼────────────┐
           │            │            │
      ┌────▼─────┐ ┌───▼──────┐ ┌───▼──────────┐
      │ Patient  │ │DoctorPrf │ │RelativePrf   │
      └────┬─────┘ └───┬──────┘ └───┬──────────┘
           │            │            │
           │    ┌───────┴──────┐    │
           │    │ DoctorPatient│    │
           │    └──────────────┘    │
           │    ┌───────────────────┤
           │    │  PatientRelative  │
           │    └───────────────────┘
           │
     ┌─────┴──────────────────────────────────────┐
     │                                             │
 ┌───▼────────┐  ┌──────────┐  ┌───────────────┐  │
 │MedicalHist │  │Treatment │  │    Device      │  │
 └────────────┘  └──────────┘  └───────┬───────┘  │
                                        │          │
                               ┌────────▼───────┐  │
                               │  DeviceStatus  │  │
                               └────────────────┘  │
                                                   │
                               ┌────────────────┐  │
                               │ BiometricData  │◄─┘
                               └───────┬────────┘
                                       │
                    ┌──────────────────┼──────────────┐
                    │                  │              │
              ┌─────▼────┐  ┌─────────▼──┐  ┌───────▼──┐
              │HeartRate │  │Temperature │  │ Location │
              └──────────┘  └────────────┘  └──────────┘
                                   │
                              ┌────▼─────┐
                              │  Alert   │
                              └────┬─────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
              ┌─────▼────┐  ┌─────▼───┐  ┌──────▼──────┐
              │Emergency │  │  Crisis │  │Notification │
              └──────────┘  └─────────┘  └─────────────┘
```

---

## Scripts SQL de Création

```sql
-- ============================================================
-- BASE DE DONNÉES WALLAN
-- PostgreSQL 15
-- ============================================================

-- Activation des extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";  -- Pour GPS

-- ============================================================
-- TABLE : roles
-- ============================================================
CREATE TABLE roles (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(50) UNIQUE NOT NULL,   -- admin, patient, doctor, relative
    description TEXT,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : users
-- ============================================================
CREATE TABLE users (
    id           SERIAL PRIMARY KEY,
    email        VARCHAR(255) UNIQUE NOT NULL,
    username     VARCHAR(150) UNIQUE NOT NULL,
    first_name   VARCHAR(100) NOT NULL,
    last_name    VARCHAR(100) NOT NULL,
    phone        VARCHAR(20),
    password     VARCHAR(255) NOT NULL,         -- Hash bcrypt
    role_id      INTEGER REFERENCES roles(id) ON DELETE SET NULL,
    is_active    BOOLEAN DEFAULT TRUE,
    is_staff     BOOLEAN DEFAULT FALSE,
    created_at   TIMESTAMP DEFAULT NOW(),
    updated_at   TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : profiles
-- ============================================================
CREATE TABLE profiles (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    avatar        VARCHAR(500),
    date_of_birth DATE,
    address       TEXT,
    city          VARCHAR(100),
    country       VARCHAR(100) DEFAULT 'Guinée',
    fcm_token     TEXT,                          -- Token Firebase pour push
    created_at    TIMESTAMP DEFAULT NOW(),
    updated_at    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : diseases
-- ============================================================
CREATE TABLE diseases (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    category    VARCHAR(100),                   -- rhumatisme, épilepsie, diabète
    description TEXT,
    icd_code    VARCHAR(20)                     -- Code CIM-10
);

-- ============================================================
-- TABLE : patients
-- ============================================================
CREATE TABLE patients (
    id                      SERIAL PRIMARY KEY,
    user_id                 INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    blood_type              VARCHAR(5),          -- A+, B-, O+, AB+, etc.
    weight                  DECIMAL(5,2),        -- kg
    height                  DECIMAL(5,2),        -- cm
    emergency_contact_name  VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : medical_histories
-- ============================================================
CREATE TABLE medical_histories (
    id            SERIAL PRIMARY KEY,
    patient_id    INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    disease_id    INTEGER REFERENCES diseases(id) ON DELETE CASCADE,
    diagnosed_at  DATE NOT NULL,
    is_active     BOOLEAN DEFAULT TRUE,
    notes         TEXT,
    created_at    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : treatments
-- ============================================================
CREATE TABLE treatments (
    id               SERIAL PRIMARY KEY,
    patient_id       INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    medication_name  VARCHAR(200) NOT NULL,
    dosage           VARCHAR(100),
    frequency        VARCHAR(100),
    start_date       DATE NOT NULL,
    end_date         DATE,
    prescribed_by    VARCHAR(200),
    is_active        BOOLEAN DEFAULT TRUE,
    created_at       TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : doctor_profiles
-- ============================================================
CREATE TABLE doctor_profiles (
    id                SERIAL PRIMARY KEY,
    user_id           INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    specialty         VARCHAR(200) NOT NULL,
    license_number    VARCHAR(100) UNIQUE NOT NULL,
    hospital          VARCHAR(200),
    years_experience  INTEGER DEFAULT 0,
    created_at        TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : relative_profiles
-- ============================================================
CREATE TABLE relative_profiles (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    relationship  VARCHAR(100),                  -- père, mère, épouse, etc.
    created_at    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : doctor_patients (relation M:N)
-- ============================================================
CREATE TABLE doctor_patients (
    id          SERIAL PRIMARY KEY,
    doctor_id   INTEGER REFERENCES doctor_profiles(id) ON DELETE CASCADE,
    patient_id  INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT NOW(),
    is_primary  BOOLEAN DEFAULT FALSE,
    UNIQUE(doctor_id, patient_id)
);

-- ============================================================
-- TABLE : patient_relatives (relation M:N)
-- ============================================================
CREATE TABLE patient_relatives (
    id                  SERIAL PRIMARY KEY,
    relative_id         INTEGER REFERENCES relative_profiles(id) ON DELETE CASCADE,
    patient_id          INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    assigned_at         TIMESTAMP DEFAULT NOW(),
    can_receive_alerts  BOOLEAN DEFAULT TRUE,
    UNIQUE(relative_id, patient_id)
);

-- ============================================================
-- TABLE : recommendations
-- ============================================================
CREATE TABLE recommendations (
    id          SERIAL PRIMARY KEY,
    doctor_id   INTEGER REFERENCES doctor_profiles(id) ON DELETE CASCADE,
    patient_id  INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    is_urgent   BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : devices (bracelets)
-- ============================================================
CREATE TABLE devices (
    id               SERIAL PRIMARY KEY,
    serial_number    VARCHAR(100) UNIQUE NOT NULL,
    mac_address      VARCHAR(17) UNIQUE NOT NULL,
    firmware_version VARCHAR(50),
    model            VARCHAR(100) DEFAULT 'Wallan-ESP32-v1',
    patient_id       INTEGER UNIQUE REFERENCES patients(id) ON DELETE SET NULL,
    is_active        BOOLEAN DEFAULT TRUE,
    registered_at    TIMESTAMP DEFAULT NOW(),
    last_sync        TIMESTAMP
);

-- ============================================================
-- TABLE : device_statuses
-- ============================================================
CREATE TABLE device_statuses (
    id               SERIAL PRIMARY KEY,
    device_id        INTEGER REFERENCES devices(id) ON DELETE CASCADE,
    battery_level    INTEGER CHECK (battery_level BETWEEN 0 AND 100),
    signal_strength  INTEGER,                    -- dBm
    is_connected     BOOLEAN DEFAULT FALSE,
    connection_type  VARCHAR(20),                -- bluetooth, wifi
    recorded_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : biometric_data
-- ============================================================
CREATE TABLE biometric_data (
    id           SERIAL PRIMARY KEY,
    device_id    INTEGER REFERENCES devices(id) ON DELETE CASCADE,
    patient_id   INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    recorded_at  TIMESTAMP NOT NULL,
    is_anomaly   BOOLEAN DEFAULT FALSE,
    created_at   TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : heart_rates
-- ============================================================
CREATE TABLE heart_rates (
    id            SERIAL PRIMARY KEY,
    biometric_id  INTEGER UNIQUE REFERENCES biometric_data(id) ON DELETE CASCADE,
    value_bpm     DECIMAL(6,2) NOT NULL,         -- Battements par minute
    spo2_percent  DECIMAL(5,2),                  -- Saturation oxygène (%)
    -- Seuils normaux : 60-100 bpm, SpO2 > 95%
    CONSTRAINT chk_heart_rate CHECK (value_bpm > 0 AND value_bpm < 300),
    CONSTRAINT chk_spo2 CHECK (spo2_percent BETWEEN 0 AND 100)
);

-- ============================================================
-- TABLE : temperatures
-- ============================================================
CREATE TABLE temperatures (
    id            SERIAL PRIMARY KEY,
    biometric_id  INTEGER UNIQUE REFERENCES biometric_data(id) ON DELETE CASCADE,
    body_temp     DECIMAL(5,2) NOT NULL,          -- Température corporelle °C
    joint_temp    DECIMAL(5,2),                   -- Température articulaire °C (rhumatisme)
    -- Seuils normaux : 36.1 – 37.2 °C
    CONSTRAINT chk_body_temp CHECK (body_temp BETWEEN 30 AND 45)
);

-- ============================================================
-- TABLE : locations
-- ============================================================
CREATE TABLE locations (
    id            SERIAL PRIMARY KEY,
    biometric_id  INTEGER UNIQUE REFERENCES biometric_data(id) ON DELETE CASCADE,
    latitude      DECIMAL(9,6) NOT NULL,
    longitude     DECIMAL(9,6) NOT NULL,
    accuracy      DECIMAL(8,2),                  -- Précision en mètres
    address       TEXT
);

-- ============================================================
-- TABLE : alerts
-- ============================================================
CREATE TABLE alerts (
    id                SERIAL PRIMARY KEY,
    patient_id        INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    biometric_data_id INTEGER REFERENCES biometric_data(id) ON DELETE SET NULL,
    alert_type        VARCHAR(100) NOT NULL,      -- heart_rate, temperature, spo2, sos
    severity          VARCHAR(20) NOT NULL,       -- low, medium, high, critical
    status            VARCHAR(20) DEFAULT 'active', -- active, acknowledged, resolved
    message           TEXT NOT NULL,
    created_at        TIMESTAMP DEFAULT NOW(),
    resolved_at       TIMESTAMP,
    CONSTRAINT chk_severity CHECK (severity IN ('low','medium','high','critical')),
    CONSTRAINT chk_status CHECK (status IN ('active','acknowledged','resolved'))
);

-- ============================================================
-- TABLE : emergencies
-- ============================================================
CREATE TABLE emergencies (
    id                  SERIAL PRIMARY KEY,
    alert_id            INTEGER UNIQUE REFERENCES alerts(id) ON DELETE CASCADE,
    gps_location        TEXT,
    sms_sent            BOOLEAN DEFAULT FALSE,
    response_time_secs  INTEGER,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : emergency_relative (M:N)
-- ============================================================
CREATE TABLE emergency_relative (
    emergency_id  INTEGER REFERENCES emergencies(id) ON DELETE CASCADE,
    relative_id   INTEGER REFERENCES relative_profiles(id) ON DELETE CASCADE,
    PRIMARY KEY (emergency_id, relative_id)
);

-- ============================================================
-- TABLE : crises
-- ============================================================
CREATE TABLE crises (
    id          SERIAL PRIMARY KEY,
    patient_id  INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    start_time  TIMESTAMP NOT NULL,
    end_time    TIMESTAMP,
    crisis_type VARCHAR(100),                     -- rhumatisme, épilepsie, etc.
    severity    VARCHAR(20),
    notes       TEXT,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : notifications
-- ============================================================
CREATE TABLE notifications (
    id                  SERIAL PRIMARY KEY,
    recipient_id        INTEGER REFERENCES users(id) ON DELETE CASCADE,
    alert_id            INTEGER REFERENCES alerts(id) ON DELETE SET NULL,
    notification_type   VARCHAR(20) NOT NULL,     -- push, sms, email
    title               VARCHAR(200) NOT NULL,
    message             TEXT NOT NULL,
    status              VARCHAR(20) DEFAULT 'pending', -- pending, sent, failed
    sent_at             TIMESTAMP,
    created_at          TIMESTAMP DEFAULT NOW(),
    CONSTRAINT chk_notif_type CHECK (notification_type IN ('push','sms','email'))
);

-- ============================================================
-- TABLE : sms_logs
-- ============================================================
CREATE TABLE sms_logs (
    id               SERIAL PRIMARY KEY,
    notification_id  INTEGER UNIQUE REFERENCES notifications(id) ON DELETE CASCADE,
    phone_number     VARCHAR(20) NOT NULL,
    provider         VARCHAR(50) DEFAULT 'Africa''s Talking',
    message_id       VARCHAR(100),
    cost             DECIMAL(10,4)
);

-- ============================================================
-- TABLE : push_notifications
-- ============================================================
CREATE TABLE push_notifications (
    id               SERIAL PRIMARY KEY,
    notification_id  INTEGER UNIQUE REFERENCES notifications(id) ON DELETE CASCADE,
    fcm_token        TEXT NOT NULL,
    fcm_message_id   VARCHAR(200)
);

-- ============================================================
-- TABLE : statistics
-- ============================================================
CREATE TABLE statistics (
    id              SERIAL PRIMARY KEY,
    patient_id      INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    period          VARCHAR(20) NOT NULL,         -- daily, weekly, monthly
    period_start    DATE NOT NULL,
    period_end      DATE NOT NULL,
    avg_heart_rate  DECIMAL(6,2),
    avg_temperature DECIMAL(5,2),
    avg_spo2        DECIMAL(5,2),
    total_alerts    INTEGER DEFAULT 0,
    total_crises    INTEGER DEFAULT 0,
    generated_at    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : reports
-- ============================================================
CREATE TABLE reports (
    id              SERIAL PRIMARY KEY,
    patient_id      INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    generated_by    INTEGER REFERENCES users(id) ON DELETE SET NULL,
    period_start    DATE NOT NULL,
    period_end      DATE NOT NULL,
    pdf_file        VARCHAR(500),
    summary         TEXT,
    generated_at    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : audit_logs
-- ============================================================
CREATE TABLE audit_logs (
    id           SERIAL PRIMARY KEY,
    user_id      INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action       VARCHAR(20) NOT NULL,            -- create, update, delete, login
    resource     VARCHAR(100) NOT NULL,
    resource_id  VARCHAR(50),
    ip_address   INET,
    details      JSONB DEFAULT '{}',
    timestamp    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : system_logs
-- ============================================================
CREATE TABLE system_logs (
    id           SERIAL PRIMARY KEY,
    level        VARCHAR(20) NOT NULL,            -- info, warning, error, critical
    module       VARCHAR(100) NOT NULL,
    message      TEXT NOT NULL,
    stack_trace  TEXT,
    timestamp    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABLE : backups
-- ============================================================
CREATE TABLE backups (
    id            SERIAL PRIMARY KEY,
    filename      VARCHAR(200) NOT NULL,
    file_size     BIGINT,
    backup_type   VARCHAR(50),                    -- full, incremental
    created_at    TIMESTAMP DEFAULT NOW(),
    created_by    INTEGER REFERENCES users(id) ON DELETE SET NULL,
    is_successful BOOLEAN DEFAULT TRUE
);

-- ============================================================
-- INDEX DE PERFORMANCE
-- ============================================================
CREATE INDEX idx_biometric_patient ON biometric_data(patient_id);
CREATE INDEX idx_biometric_recorded ON biometric_data(recorded_at DESC);
CREATE INDEX idx_alerts_patient ON alerts(patient_id);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_created ON alerts(created_at DESC);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_id);
CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role_id);
```

---

## Données de Test (Seeds)

```sql
-- seeds/01_roles.sql
INSERT INTO roles (name, description) VALUES
  ('admin',    'Administrateur système'),
  ('patient',  'Patient porteur du bracelet'),
  ('doctor',   'Médecin traitant'),
  ('relative', 'Proche du patient');

-- seeds/02_diseases.sql
INSERT INTO diseases (name, category, description, icd_code) VALUES
  ('Rhumatisme articulaire',  'rhumatisme', 'Douleurs articulaires chroniques',    'M79.3'),
  ('Polyarthrite rhumatoïde', 'rhumatisme', 'Maladie inflammatoire chronique',      'M05'),
  ('Épilepsie',               'neurologie', 'Trouble neurologique avec convulsions', 'G40'),
  ('Asthme',                  'respiratoire','Obstruction bronchique chronique',     'J45'),
  ('Diabète type 2',          'métabolique','Hyperglycémie chronique',               'E11');
```

---

## Règles de Seuils d'Alerte Médicaux

```sql
-- Table de configuration des seuils
CREATE TABLE alert_thresholds (
    id              SERIAL PRIMARY KEY,
    patient_id      INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    parameter       VARCHAR(50) NOT NULL,
    min_value       DECIMAL(8,2),
    max_value       DECIMAL(8,2),
    severity        VARCHAR(20),
    is_custom       BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- Seuils par défaut pour rhumatisme (Phase 1)
INSERT INTO alert_thresholds (patient_id, parameter, min_value, max_value, severity, is_custom) VALUES
-- Ces valeurs seront insérées par patient lors de la création du dossier
-- Fréquence cardiaque : normale 60-100 bpm
  (NULL, 'heart_rate',   60, 100, 'medium',   FALSE),
  (NULL, 'heart_rate',   40,  60, 'high',     FALSE),
  (NULL, 'heart_rate',  100, 150, 'high',     FALSE),
-- Température : normale 36.1 – 37.2 °C
  (NULL, 'body_temp',   36.1, 37.2, 'medium', FALSE),
  (NULL, 'joint_temp',  NULL, 38.5, 'high',   FALSE),  -- Inflammation articulaire
-- SpO2 : normale > 95%
  (NULL, 'spo2',        95, 100, 'medium',    FALSE),
  (NULL, 'spo2',        90,  95, 'high',      FALSE),
  (NULL, 'spo2',         0,  90, 'critical',  FALSE);
```
