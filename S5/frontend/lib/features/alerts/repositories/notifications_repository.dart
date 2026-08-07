import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/alert_notification_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CHANGEMENT MAJEUR vs Semaine 5 (version précédente) :
//
// Avant : les notifications étaient DÉRIVÉES côté client à partir des
// alertes (NotificationLog.deriveFrom), faute d'endpoint dédié connu.
//
// Maintenant : le backend réel expose bien AlertNotificationLog via
// GET /api/alert-notifications/, alimenté automatiquement par
// alerts/services.py::dispatch_alert_notifications() à chaque création
// d'alerte (SMS via Africa's Talking, Push via Firebase). On consomme donc
// une VRAIE ressource, sans plus rien reconstruire côté client.
//
// Le endpoint n'est pas filtré par destinataire côté serveur : le filtrage
// sur "mes notifications" (recipient_email == mon email) se fait ici,
// côté client, comme pour PatientLinkRepository.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsRepository {
  final ApiClient _apiClient;

  NotificationsRepository({required this._apiClient});

  /// Récupère les notifications réellement destinées à [recipientEmail].
  /// Sans email (lien utilisateur non résolu), retourne une liste vide
  /// plutôt que la totalité des notifications de tous les utilisateurs.
  Future<List<AlertNotificationModel>> fetchNotifications({String? recipientEmail}) async {
    if (recipientEmail == null) return const [];

    try {
      final response = await _apiClient.get<dynamic>(ApiEndpoints.alertNotifications);
      final raw = response.data;
      final List<dynamic> list = raw is List
          ? raw
          : (raw is Map<String, dynamic> && raw['results'] is List ? raw['results'] as List : const []);

      final all = list.map((e) => AlertNotificationModel.fromJson(e as Map<String, dynamic>)).toList();

      final mine = all
          .where((n) => n.recipientEmail?.toLowerCase() == recipientEmail.toLowerCase())
          .toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

      return mine;
    } on DioException catch (e) {
      debugPrint('⚠️ GET /api/alert-notifications/ non disponible (${e.type}) — Utilisation de données démo');
      return demoNotifications();
    } catch (e) {
      debugPrint('⚠️ Notifications hors-ligne — Utilisation de données démo: $e');
      return demoNotifications();
    }
  }

  /// Jeu de données démo (repli hors-ligne / absence de patient lié).
  List<AlertNotificationModel> demoNotifications() {
    final now = DateTime.now();
    return [
      AlertNotificationModel(
        id: 'demo-notif-1',
        alertId: 'demo-1',
        recipientEmail: 'demo@wallan.app',
        channel: NotificationChannel.sms,
        status: NotificationDeliveryStatus.delivered,
        sentAt: now.subtract(const Duration(hours: 20)),
      ),
      AlertNotificationModel(
        id: 'demo-notif-2',
        alertId: 'demo-1',
        recipientEmail: 'demo@wallan.app',
        channel: NotificationChannel.push,
        status: NotificationDeliveryStatus.failed,
        sentAt: now.subtract(const Duration(hours: 20)),
      ),
      AlertNotificationModel(
        id: 'demo-notif-3',
        alertId: 'demo-3',
        recipientEmail: 'demo@wallan.app',
        channel: NotificationChannel.sms,
        status: NotificationDeliveryStatus.delivered,
        sentAt: now.subtract(const Duration(hours: 34)),
      ),
    ];
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
});
