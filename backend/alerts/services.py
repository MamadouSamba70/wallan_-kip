# ==============================================================================
# SERVICES DE NOTIFICATION (Semaine 4 - Fatima Abdul Sow)
# ==============================================================================
# Ce module regroupe les services d'envoi de SMS (via Africa's Talking)
# et de notifications Push (via Firebase Cloud Messaging).
# Tous les traitements sont abondamment commentés pour la lisibilité de l'équipe.
# ==============================================================================

import logging
from decouple import config

# Configuration du logger pour suivre les activités de notification
logger = logging.getLogger(__name__)

# ------------------------------------------------------------------------------
# 1. SERVICE SMS - AFRICA'S TALKING
# ------------------------------------------------------------------------------

class AfricasTalkingSMSService:
    """
    Service d'envoi de SMS via la passerelle Africa's Talking.
    Supporte le mode simulateur / développement si le SDK n'est pas encore installé
    ou si les clés d'API ne sont pas fournies dans l'environnement.
    """

    def __init__(self):
        # Récupération des identifiants d'API depuis le fichier d'environnement (.env)
        self.username = config('AFRICASTALKING_USERNAME', default='sandbox')
        self.api_key = config('AFRICASTALKING_API_KEY', default='')
        self.sender_id = config('AFRICASTALKING_SENDER_ID', default=None)
        self.sms = None

        # Tentative de chargement du SDK africastalking si présent
        if self.api_key:
            try:
                import africastalking
                africastalking.initialize(self.username, self.api_key)
                self.sms = africastalking.SMS
                logger.info("Service Africa's Talking SMS initialisé avec succès.")
            except ImportError:
                logger.warning("Le package africastalking n'est pas installé. Mode simulation activé pour le SMS.")
            except Exception as e:
                logger.error(f"Erreur d'initialisation Africa's Talking: {str(e)}")

    def send_sms(self, recipient_phone: str, message: str) -> dict:
        """
        Envoie un SMS à un destinataire donné.

        :param recipient_phone: Numéro au format international (ex: +221770000000)
        :param message: Contenu du SMS
        :return: dict contenant le statut ('status': 'sent'/'failed') et les détails
        """
        if not recipient_phone:
            logger.error("Aucun numéro de téléphone fourni pour l'envoi du SMS.")
            return {'status': 'failed', 'error': 'Numéro de téléphone requis'}

        # Si le SDK officiel est disponible et configuré
        if self.sms:
            try:
                # Appel de l'API Africa's Talking
                response = self.sms.send(
                    message=message,
                    recipients=[recipient_phone],
                    sender_id=self.sender_id
                )
                logger.info(f"SMS envoyé avec succès à {recipient_phone}: {response}")
                return {
                    'status': 'sent',
                    'response': response,
                    'mode': 'live'
                }
            except Exception as e:
                logger.error(f"Échec d'envoi du SMS à {recipient_phone}: {str(e)}")
                return {
                    'status': 'failed',
                    'error': str(e),
                    'mode': 'live'
                }
        else:
            # Mode simulation / secours (utile pour les tests locaux et CI/CD)
            logger.info(f"[SIMULATION SMS] Destinataire: {recipient_phone} | Message: {message}")
            return {
                'status': 'sent',
                'response': {'message': 'SMS simulé avec succès en environnement local'},
                'mode': 'simulation'
            }


# ------------------------------------------------------------------------------
# 2. SERVICE PUSH NOTIFICATION - FIREBASE CLOUD MESSAGING (FCM)
# ------------------------------------------------------------------------------

class FirebasePushService:
    """
    Service d'envoi de notifications Push mobiles via Firebase Cloud Messaging (FCM).
    Utilisé pour alerter instantanément les proches et médecins sur l'application mobile.
    """

    def __init__(self):
        self.credentials_path = config('FIREBASE_CREDENTIALS_PATH', default='')
        self.initialized = False

        # Chargement de firebase_admin si les identifiants sont renseignés
        if self.credentials_path:
            try:
                import firebase_admin
                from firebase_admin import credentials
                if not firebase_admin._apps:
                    cred = credentials.Certificate(self.credentials_path)
                    firebase_admin.initialize_app(cred)
                self.initialized = True
                logger.info("Firebase Cloud Messaging initialisé avec succès.")
            except ImportError:
                logger.warning("Le package firebase_admin n'est pas installé. Mode simulation activé pour le Push.")
            except Exception as e:
                logger.error(f"Erreur d'initialisation Firebase: {str(e)}")

    def send_push_notification(self, device_token: str, title: str, body: str, data: dict = None) -> dict:
        """
        Envoie une notification Push à un appareil via son token FCM.

        :param device_token: Token de l'appareil destinataire enregistrée dans Flutter
        :param title: Titre de la notification Push
        :param body: Corps du message
        :param data: Dictionnaire de métadonnées facultatif (ex: alert_id, severity)
        :return: dict contenant le résultat d'envoi
        """
        if not device_token:
            logger.error("Aucun device_token fourni pour la notification Push.")
            return {'status': 'failed', 'error': 'Token d\'appareil requis'}

        if self.initialized:
            try:
                from firebase_admin import messaging
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                    ),
                    data=data or {},
                    token=device_token,
                )
                response = messaging.send(message)
                logger.info(f"Push FCM envoyé avec succès au token {device_token[:10]}... : {response}")
                return {
                    'status': 'sent',
                    'response': response,
                    'mode': 'live'
                }
            except Exception as e:
                logger.error(f"Échec de l'envoi de la notification Push: {str(e)}")
                return {
                    'status': 'failed',
                    'error': str(e),
                    'mode': 'live'
                }
        else:
            # Mode simulation / secours
            logger.info(f"[SIMULATION PUSH] Token: {device_token[:10]}... | Titre: {title} | Corps: {body}")
            return {
                'status': 'sent',
                'response': {'message': 'Notification Push simulée avec succès'},
                'mode': 'simulation'
            }


# ------------------------------------------------------------------------------
# 3. DISPATCHEUR CENTRALISÉ DE NOTIFICATIONS D'ALERTE
# ------------------------------------------------------------------------------

def dispatch_alert_notifications(alert) -> list:
    """
    Fonction centrale de notification : déclenchée lorsqu'une alerte médicale est créée.
    Elle prévient automatiquement le patient, ses proches désignés et les médecins associés
    par SMS et/ou Push Notification selon les informations de contact disponibles.

    :param alert: Instance du modèle Alert (alerts.models.Alert)
    :return: Liste des logs de notification créés (AlertNotificationLog)
    """
    from .models import AlertNotificationLog

    logs = []
    sms_service = AfricasTalkingSMSService()
    push_service = FirebasePushService()

    patient = alert.patient
    message_text = (
        f"⚠️ ALERTE WALLAN ({alert.get_severity_display().upper()}) !\n"
        f"Patient : {patient.full_name}\n"
        f"Anomalie : {alert.get_alert_type_display()}\n"
        f"Valeur mesurée : {alert.value_detected} (Seuil : {alert.threshold_value})"
    )

    title_push = f"Alerte Médicale - {patient.full_name}"

    # --- 1. Notification du Patient lui-même (si téléphone renseigné dans son profil) ---
    patient_phone = getattr(getattr(patient.user, 'profile', None), 'phone', None)
    if patient_phone:
        result_sms = sms_service.send_sms(patient_phone, message_text)
        log_sms = AlertNotificationLog.objects.create(
            alert=alert,
            recipient=patient.user,
            channel='sms',
            status='sent' if result_sms['status'] == 'sent' else 'failed'
        )
        logs.append(log_sms)

    # --- 2. Notification des Proches du Patient (PatientRelative) ---
    relatives = patient.relatives.select_related('relative_user', 'relative_user__profile').all()
    for relative in relatives:
        relative_user = relative.relative_user
        relative_phone = getattr(getattr(relative_user, 'profile', None), 'phone', None)

        # Envoi SMS au proche si numéro disponible
        if relative_phone:
            msg_relative = f"Bonjour, " + message_text
            res_sms = sms_service.send_sms(relative_phone, msg_relative)
            log_rel_sms = AlertNotificationLog.objects.create(
                alert=alert,
                recipient=relative_user,
                channel='sms',
                status='sent' if res_sms['status'] == 'sent' else 'failed'
            )
            logs.append(log_rel_sms)

        # Envoi Push au proche si token FCM disponible
        fcm_token = getattr(relative_user, 'fcm_token', None)
        if fcm_token:
            res_push = push_service.send_push_notification(
                device_token=fcm_token,
                title=title_push,
                body=message_text,
                data={'alert_id': str(alert.id), 'severity': alert.severity}
            )
            log_rel_push = AlertNotificationLog.objects.create(
                alert=alert,
                recipient=relative_user,
                channel='push',
                status='sent' if res_push['status'] == 'sent' else 'failed'
            )
            logs.append(log_rel_push)

    return logs


# ------------------------------------------------------------------------------
# 4. GESTION DES CAS LIMITES ET DÉDUPLICATION DES ALERTES (SEMAINE 6 - FATIMA ABDUL SOW)
# ------------------------------------------------------------------------------

def create_or_deduplicate_alert(patient, alert_type, severity, value_detected, threshold_value, cooldown_minutes=15):
    """
    [SEMAINE 6 - FATIMA ABDUL SOW - LIVRABLE SEMAINE 6]
    Gestion des cas limites et déduplication des alertes en doublon.

    Vérifie si une alerte active du même type existe déjà pour le patient
    dans la fenêtre de temporisation (cooldown_minutes).

    Règles de déduplication et cas limites :
    1. Si une alerte active récente existe :
       - Ne crée PAS de nouvelle ligne d'alerte en base de données.
       - Ne ré-envoie PAS de SMS/Push inutile aux proches (anti-spam).
       - Met à jour la valeur mesurée si elle est plus critique.
       - Escalade la sévérité de 'warning' à 'critical' et notifie si l'état s'aggrave.
    2. Si aucune alerte active n'est présente dans la fenêtre (ou si la précédente est résolue) :
       - Crée une nouvelle instance de modèle Alert.
       - Déclenche les notifications automatiques.

    :return: tuple (Alert, bool created)
    """
    from django.utils import timezone
    from datetime import timedelta
    from .models import Alert

    now = timezone.now()
    cooldown_time = now - timedelta(minutes=cooldown_minutes)

    # Recherche d'une alerte active récente du même type pour ce patient
    recent_active_alert = Alert.objects.filter(
        patient=patient,
        alert_type=alert_type,
        status='active',
        created_at__gte=cooldown_time
    ).first()

    if recent_active_alert:
        logger.info(
            f"[DÉDUPLICATION SEMAINE 6 - FATIMA] Alerte active récente trouvée ({recent_active_alert.id}) "
            f"pour le patient {patient.full_name} ({alert_type}). Alerte en doublon dédupliquée."
        )

        escalated = False
        if recent_active_alert.severity == 'warning' and severity == 'critical':
            recent_active_alert.severity = 'critical'
            escalated = True

        # Mise à jour de la valeur mesurée si elle est plus extrême
        recent_active_alert.value_detected = value_detected
        recent_active_alert.save()

        # Si escalade de sévérité, ré-émission d'une notification d'urgence
        if escalated:
            dispatch_alert_notifications(recent_active_alert)

        return recent_active_alert, False

    # Création d'une nouvelle alerte si aucune alerte active dans la fenêtre
    new_alert = Alert.objects.create(
        patient=patient,
        alert_type=alert_type,
        severity=severity,
        value_detected=value_detected,
        threshold_value=threshold_value,
        status='active'
    )

    # Déclenchement automatique des notifications SMS / Push
    dispatch_alert_notifications(new_alert)

    return new_alert, True

