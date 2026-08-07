import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reflète fidèlement AlertNotificationLogSerializer (alerts/serializers.py) :
// { id, alert, alert_id, recipient, recipient_email,
//   channel, channel_display, status, status_display, sent_at, delivered_at }
//
// Contrairement à la Semaine 3/4 (notifications dérivées côté client des
// alertes), il s'agit désormais d'une VRAIE ressource backend, alimentée
// automatiquement par alerts/services.py::dispatch_alert_notifications()
// à chaque création d'alerte.
//
// Différences avec l'ancienne dérivation client :
//   - 3 canaux possibles : sms / push / ET email (nouveau, non prévu au plan).
//   - Pas de garantie qu'une notification push existe pour un proche : elle
//     n'est créée que si le compte a un fcm_token enregistré (jamais le cas
//     actuellement, ce champ n'existe pas encore sur le modèle User).
// ─────────────────────────────────────────────────────────────────────────────

enum NotificationChannel { sms, push, email }

enum NotificationDeliveryStatus { sent, failed, delivered }

NotificationChannel _parseChannel(String? raw) {
  switch (raw) {
    case 'push':
      return NotificationChannel.push;
    case 'email':
      return NotificationChannel.email;
    case 'sms':
    default:
      return NotificationChannel.sms;
  }
}

NotificationDeliveryStatus _parseDeliveryStatus(String? raw) {
  switch (raw) {
    case 'delivered':
      return NotificationDeliveryStatus.delivered;
    case 'failed':
      return NotificationDeliveryStatus.failed;
    case 'sent':
    default:
      return NotificationDeliveryStatus.sent;
  }
}

@immutable
class AlertNotificationModel {
  final String id;
  final String alertId;
  final String? recipientId;
  final String? recipientEmail;
  final NotificationChannel channel;
  final String? channelDisplay;
  final NotificationDeliveryStatus status;
  final String? statusDisplay;
  final DateTime sentAt;
  final DateTime? deliveredAt;

  const AlertNotificationModel({
    required this.id,
    required this.alertId,
    this.recipientId,
    this.recipientEmail,
    required this.channel,
    this.channelDisplay,
    required this.status,
    this.statusDisplay,
    required this.sentAt,
    this.deliveredAt,
  });

  factory AlertNotificationModel.fromJson(Map<String, dynamic> json) {
    return AlertNotificationModel(
      id: json['id'].toString(),
      // 'alert_id' est fourni en plus de 'alert' (les deux valent le même UUID) ;
      // on préfère 'alert_id', avec repli sur 'alert' si absent.
      alertId: (json['alert_id'] ?? json['alert'])?.toString() ?? '',
      recipientId: json['recipient']?.toString(),
      recipientEmail: json['recipient_email']?.toString(),
      channel: _parseChannel(json['channel'] as String?),
      channelDisplay: json['channel_display']?.toString(),
      status: _parseDeliveryStatus(json['status'] as String?),
      statusDisplay: json['status_display']?.toString(),
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
      deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'].toString()) : null,
    );
  }
}
