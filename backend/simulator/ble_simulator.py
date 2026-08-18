"""
╔══════════════════════════════════════════════════════════════════╗
║           WALLAN — Simulateur BLE ESP32                          ║
║           Simule un bracelet connecté envoyant des               ║
║           données biométriques à l'API backend                   ║
╚══════════════════════════════════════════════════════════════════╝

Fonctionnement :
1. Se connecte à l'API et récupère un token JWT
2. Crée un bracelet simulé (Device) s'il n'existe pas encore
3. Envoie des données biométriques toutes les X secondes
4. Alterne entre scénarios normaux et critiques pour tester les alertes

Usage :
    python ble_simulator.py

Configuration :
    Modifier les variables dans la section CONFIG ci-dessous
"""

import requests
import random
import time
import json
import uuid
from datetime import datetime, timezone


# ══════════════════════════════════════════════════════════════════
# CONFIG — Modifier ces valeurs selon votre environnement
# ══════════════════════════════════════════════════════════════════

API_BASE_URL = "http://127.0.0.1:8000/api"  # URL de l'API Django

# Compte administrateur (doit exister dans la base)
ADMIN_EMAIL = "diallomamadouhady8906@gmail.com"
ADMIN_PASSWORD = "1234"

# Identifiant matériel du bracelet simulé (adresse MAC fictive)
DEVICE_HARDWARE_ID = "AA:BB:CC:DD:EE:FF"
DEVICE_MODEL = "Wallan-Simulator-v1"
DEVICE_FIRMWARE = "1.0.0-sim"

# UUID du patient à qui le bracelet est associé
# (doit exister dans la base — créer via l'admin Django d'abord)
PATIENT_UUID = None  # Sera demandé au lancement si non défini

# Intervalle entre chaque mesure en secondes
SEND_INTERVAL = 5

# Nombre de mesures à envoyer (None = infini)
MAX_READINGS = None

# ══════════════════════════════════════════════════════════════════
# COULEURS TERMINAL
# ══════════════════════════════════════════════════════════════════

GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
BLUE   = "\033[94m"
CYAN   = "\033[96m"
RESET  = "\033[0m"
BOLD   = "\033[1m"


def print_header():
    """Affiche le header du simulateur."""
    print(f"\n{BLUE}{BOLD}{'═' * 60}{RESET}")
    print(f"{BLUE}{BOLD}   WALLAN — Simulateur BLE ESP32{RESET}")
    print(f"{BLUE}{BOLD}   Bracelet : {DEVICE_HARDWARE_ID}{RESET}")
    print(f"{BLUE}{BOLD}{'═' * 60}{RESET}\n")


def print_reading(reading_data, response, alerts_count, index):
    """Affiche une mesure envoyée de façon lisible."""
    timestamp = datetime.now().strftime("%H:%M:%S")

    print(f"{CYAN}[{timestamp}] Mesure #{index}{RESET}")
    print(f"  ❤️  FC       : {reading_data['heart_rate']} bpm")
    print(f"  🌡️  Temp     : {reading_data['temperature']} °C")
    print(f"  💧 SpO2     : {reading_data['spo2']} %")

    if response.status_code == 201:
        if alerts_count > 0:
            print(f"  {RED}⚠️  ALERTES  : {alerts_count} alerte(s) déclenchée(s) !{RESET}")
        else:
            print(f"  {GREEN}✔  Statut   : OK — aucune alerte{RESET}")
    else:
        print(f"  {RED}✗  Erreur   : {response.status_code} — {response.text}{RESET}")

    print()


# ══════════════════════════════════════════════════════════════════
# SCÉNARIOS DE DONNÉES BIOMÉTRIQUES
# ══════════════════════════════════════════════════════════════════

def generate_normal_reading():
    """
    Génère des données biométriques normales.
    Valeurs dans les plages physiologiques standards.
    """
    return {
        "heart_rate": random.randint(60, 90),           # FC normale
        "temperature": round(random.uniform(36.1, 37.2), 1),  # Temp normale
        "spo2": random.randint(95, 100),                # SpO2 normale
        "movement_data": {
            "x": round(random.uniform(-1.0, 1.0), 2),
            "y": round(random.uniform(-1.0, 1.0), 2),
            "z": round(random.uniform(9.0, 10.0), 2),  # Gravité normale
        }
    }


def generate_tachycardia_reading():
    """
    Simule une tachycardie (FC élevée).
    Devrait déclencher une alerte heart_rate.
    """
    return {
        "heart_rate": random.randint(120, 160),          # FC anormalement haute
        "temperature": round(random.uniform(36.5, 37.5), 1),
        "spo2": random.randint(94, 98),
        "movement_data": {
            "x": round(random.uniform(-2.0, 2.0), 2),
            "y": round(random.uniform(-2.0, 2.0), 2),
            "z": round(random.uniform(8.0, 10.0), 2),
        }
    }


def generate_fever_reading():
    """
    Simule une fièvre (température élevée).
    Devrait déclencher une alerte temperature.
    """
    return {
        "heart_rate": random.randint(85, 105),
        "temperature": round(random.uniform(38.5, 40.0), 1),  # Fièvre
        "spo2": random.randint(93, 98),
        "movement_data": {
            "x": round(random.uniform(-0.5, 0.5), 2),
            "y": round(random.uniform(-0.5, 0.5), 2),
            "z": round(random.uniform(9.0, 10.0), 2),
        }
    }


def generate_low_spo2_reading():
    """
    Simule une hypoxémie (SpO2 basse).
    Devrait déclencher une alerte spo2.
    """
    return {
        "heart_rate": random.randint(90, 120),
        "temperature": round(random.uniform(36.0, 37.5), 1),
        "spo2": random.randint(80, 89),              # SpO2 dangereusement basse
        "movement_data": {
            "x": round(random.uniform(-1.0, 1.0), 2),
            "y": round(random.uniform(-1.0, 1.0), 2),
            "z": round(random.uniform(9.0, 10.0), 2),
        }
    }


def generate_critical_reading():
    """
    Simule une situation critique (tous les paramètres anormaux).
    Devrait déclencher plusieurs alertes critiques.
    """
    return {
        "heart_rate": random.randint(150, 200),       # FC critique
        "temperature": round(random.uniform(39.5, 41.0), 1),  # Fièvre critique
        "spo2": random.randint(70, 82),               # SpO2 critique
        "movement_data": {
            "x": round(random.uniform(-5.0, 5.0), 2),
            "y": round(random.uniform(-5.0, 5.0), 2),
            "z": round(random.uniform(5.0, 15.0), 2),  # Agitation
        }
    }


# Séquence de scénarios : 5 normaux, 1 tachycardie, 2 normaux, 1 fièvre, 2 normaux, 1 SpO2 basse, 1 critique
SCENARIO_SEQUENCE = [
    ("normal",       generate_normal_reading),
    ("normal",       generate_normal_reading),
    ("normal",       generate_normal_reading),
    ("normal",       generate_normal_reading),
    ("normal",       generate_normal_reading),
    ("tachycardie",  generate_tachycardia_reading),
    ("normal",       generate_normal_reading),
    ("normal",       generate_normal_reading),
    ("fièvre",       generate_fever_reading),
    ("normal",       generate_normal_reading),
    ("normal",       generate_normal_reading),
    ("SpO2 basse",   generate_low_spo2_reading),
    ("critique",     generate_critical_reading),
]


# ══════════════════════════════════════════════════════════════════
# FONCTIONS API
# ══════════════════════════════════════════════════════════════════

def get_jwt_token():
    """
    Authentifie le simulateur sur l'API et retourne le token JWT.
    """
    print(f"{YELLOW}🔐 Authentification en cours...{RESET}")

    try:
        response = requests.post(
            f"{API_BASE_URL}/auth/login/",
            json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
            timeout=10
        )

        if response.status_code == 200:
            token = response.json().get("access")
            print(f"{GREEN}✔ Token JWT obtenu{RESET}\n")
            return token
        else:
            print(f"{RED}✗ Échec authentification : {response.status_code}{RESET}")
            print(f"  Vérifiez que le compte {ADMIN_EMAIL} existe dans la base.")
            print(f"  Créez-le via : python manage.py createsuperuser")
            return None

    except requests.exceptions.ConnectionError:
        print(f"{RED}✗ Impossible de se connecter à {API_BASE_URL}{RESET}")
        print(f"  Vérifiez que le serveur Django tourne : python manage.py runserver")
        return None


def register_device(token):
    """
    Enregistre le bracelet simulé dans le système s'il n'existe pas déjà.
    Retourne l'UUID du bracelet créé ou existant.
    """
    headers = {"Authorization": f"Bearer {token}"}

    print(f"{YELLOW}📡 Enregistrement du bracelet simulé...{RESET}")

    # Tenter d'enregistrer le bracelet
    response = requests.post(
        f"{API_BASE_URL}/devices/register/",
        json={
            "hardware_id": DEVICE_HARDWARE_ID,
            "model": DEVICE_MODEL,
            "firmware_version": DEVICE_FIRMWARE,
        },
        headers=headers,
        timeout=10
    )

    if response.status_code == 201:
        device_id = response.json()["device"]["id"]
        print(f"{GREEN}✔ Bracelet enregistré — ID : {device_id}{RESET}\n")
        return device_id

    elif response.status_code == 400:
        # Le bracelet existe déjà — récupérer son ID via la liste
        list_response = requests.get(
            f"{API_BASE_URL}/devices/",
            headers=headers,
            timeout=10
        )
        if list_response.status_code == 200:
            devices = list_response.json()
            for device in devices:
                if device["hardware_id"] == DEVICE_HARDWARE_ID:
                    print(f"{GREEN}✔ Bracelet déjà enregistré — ID : {device['id']}{RESET}\n")
                    return device["id"]

    print(f"{RED}✗ Impossible d'enregistrer le bracelet{RESET}")
    return None


def send_biometric_reading(token, patient_id, device_id, reading_data):
    """
    Envoie une mesure biométrique à l'API.
    Retourne la réponse du serveur.
    """
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "patient": patient_id,
        "device": device_id,
        "heart_rate": reading_data["heart_rate"],
        "temperature": str(reading_data["temperature"]),
        "spo2": reading_data["spo2"],
        "movement_data": reading_data["movement_data"],
        "recorded_at": datetime.now(timezone.utc).isoformat(),
    }

    response = requests.post(
        f"{API_BASE_URL}/biometrics/",
        json=payload,
        headers=headers,
        timeout=10
    )

    return response


# ══════════════════════════════════════════════════════════════════
# BOUCLE PRINCIPALE DU SIMULATEUR
# ══════════════════════════════════════════════════════════════════

def run_simulator(patient_id):
    """
    Boucle principale du simulateur.
    Envoie des mesures biométriques selon la séquence de scénarios.
    """
    print_header()

    # 1. Authentification
    token = get_jwt_token()
    if not token:
        return

    # 2. Enregistrement du bracelet
    device_id = register_device(token)
    if not device_id:
        return

    print(f"{YELLOW}🚀 Démarrage de la simulation...{RESET}")
    print(f"   Patient ID : {patient_id}")
    print(f"   Device ID  : {device_id}")
    print(f"   Intervalle : {SEND_INTERVAL} secondes")
    print(f"   Scénarios  : {len(SCENARIO_SEQUENCE)} (en boucle)\n")
    print(f"   Appuyez sur CTRL+C pour arrêter\n")
    print(f"{'─' * 60}")

    reading_index = 0
    scenario_index = 0

    try:
        while True:
            # Sélectionner le scénario selon la séquence (en boucle)
            scenario_name, generate_fn = SCENARIO_SEQUENCE[scenario_index % len(SCENARIO_SEQUENCE)]
            reading_data = generate_fn()

            # Afficher le scénario en cours
            if scenario_name != "normal":
                print(f"{RED}{BOLD}⚡ Scénario : {scenario_name.upper()}{RESET}")
            else:
                print(f"{GREEN}● Scénario : normal{RESET}")

            # Envoyer la mesure à l'API
            try:
                response = send_biometric_reading(token, patient_id, device_id, reading_data)
                alerts_count = 0

                if response.status_code == 201:
                    alerts_count = response.json().get("alerts_created", 0)
                elif response.status_code == 401:
                    # Token expiré — se reconnecter
                    print(f"{YELLOW}⟳ Token expiré, reconnexion...{RESET}")
                    token = get_jwt_token()
                    if not token:
                        break
                    continue

                print_reading(reading_data, response, alerts_count, reading_index + 1)

            except requests.exceptions.ConnectionError:
                print(f"{RED}✗ Connexion perdue — serveur inaccessible{RESET}\n")

            reading_index += 1
            scenario_index += 1

            # Vérifier si on a atteint le nombre max de mesures
            if MAX_READINGS and reading_index >= MAX_READINGS:
                print(f"{GREEN}{BOLD}✔ Simulation terminée — {reading_index} mesures envoyées{RESET}")
                break

            # Attendre avant la prochaine mesure
            time.sleep(SEND_INTERVAL)

    except KeyboardInterrupt:
        print(f"\n{YELLOW}⏹  Simulation arrêtée manuellement{RESET}")
        print(f"   Total mesures envoyées : {reading_index}")


# ══════════════════════════════════════════════════════════════════
# POINT D'ENTRÉE
# ══════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print(f"\n{BOLD}WALLAN — BLE Simulator{RESET}")
    print("═" * 40)

    # Demander le patient UUID si non configuré
    patient_id = PATIENT_UUID
    if not patient_id:
        print("\nEntrez l'UUID du patient (depuis l'admin Django) :")
        patient_id = input("Patient UUID : ").strip()

        if not patient_id:
            print(f"{RED}✗ UUID patient requis. Arrêt.{RESET}")
            exit(1)

    run_simulator(patient_id)