import 'alert_repository.dart'; // Dépôt partagé (AlertItem + AlertRepository)

/// Canal d'envoi d'une notification, en miroir de l'ENUM `channel` de la
/// table AlertNotificationLog du Plan de Travail (section 3.5) : sms / push.
enum NotificationChannel { sms, push }

/// Statut de livraison, en miroir de l'ENUM `status` de la même table :
/// sent / failed / delivered.
enum NotificationDeliveryStatus { sent, failed, delivered }

/// Représente une ligne simulée de la table AlertNotificationLog, en
/// attendant les vrais endpoints POST /api/notifications/sms/ et
/// POST /api/notifications/push/ (prévus Semaine 4, module backend de
/// Fatima) et le futur GET /api/notifications/ (historique, Semaine 5).
///
/// Contrairement à AlertItem (qui représente l'ALERTE elle-même, déjà
/// géré par AlertRepository), ceci représente l'ENVOI de cette alerte à
/// un destinataire par un canal donné : une même alerte critique peut
/// donc produire plusieurs lignes (ex: une notification push ET un SMS).
class NotificationLogEntry {
  final AlertItem alert; // L'alerte à l'origine de cette notification (FK alert_id)
  final NotificationChannel channel; // sms ou push
  final NotificationDeliveryStatus status; // sent / failed / delivered
  final String sentAt; // Date d'envoi (recipient_user_id omis : un seul proche simulé pour l'instant)

  const NotificationLogEntry({
    required this.alert,
    required this.channel,
    required this.status,
    required this.sentAt,
  });

  /// Clé unique simulée (en attendant un vrai id renvoyé par l'API), utilisée
  /// par NotificationsController pour suivre l'état lu/non lu par entrée.
  String get key => '${alert.date}__${alert.title}__${alert.patient}__${channel.name}';
}

/// Dérive la liste simulée des notifications envoyées à partir des alertes
/// du dépôt partagé AlertRepository.
///
/// Règle de simulation (en attendant la vraie logique backend Semaine 4) :
/// - Chaque alerte génère toujours une notification push.
/// - Une alerte CRITIQUE génère en plus une notification SMS (canal de
///   secours pour les urgences, cohérent avec le principe du bracelet
///   Wallan : alerter même sans connexion internet via SMS).
/// - Le statut est simulé de façon déterministe (pas aléatoire) pour que
///   la démo du vendredi reste reproductible : push = toujours "delivered",
///   sms = "delivered" sur les alertes d'indice pair, "failed" sur les
///   alertes d'indice impair (afin d'illustrer les 3 statuts possibles).
class NotificationLog {
  NotificationLog._(); // Constructeur privé : classe utilitaire, non instanciable

  static List<NotificationLogEntry> deriveFrom(List<AlertItem> alerts) {
    final entries = <NotificationLogEntry>[];
    for (var i = 0; i < alerts.length; i++) {
      final alert = alerts[i];

      // Notification push : toujours envoyée, toujours "delivered" (simulation).
      entries.add(NotificationLogEntry(
        alert: alert,
        channel: NotificationChannel.push,
        status: NotificationDeliveryStatus.delivered,
        sentAt: alert.date,
      ));

      // Notification SMS : uniquement pour les alertes critiques.
      if (alert.isCritical) {
        entries.add(NotificationLogEntry(
          alert: alert,
          channel: NotificationChannel.sms,
          status: i.isEven ? NotificationDeliveryStatus.delivered : NotificationDeliveryStatus.failed,
          sentAt: alert.date,
        ));
      }
    }
    return entries;
  }
}