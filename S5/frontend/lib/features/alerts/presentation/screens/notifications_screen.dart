import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/api_status_banner.dart';
import '../../models/alert_model.dart';
import '../../models/alert_notification_model.dart';
import '../../viewmodels/alerts_viewmodel.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import 'notifications_controller.dart';

/// Écran Notifications — Espace Proche.
///
/// Consomme désormais GET /api/alert-notifications/ (vraie ressource
/// AlertNotificationLog), via NotificationsViewModel — plus de dérivation
/// côté client. Chaque notification ne référence son alerte que par id
/// (alert_id) : pour afficher un contenu utile (type d'alerte, patient,
/// valeur mesurée), on croise avec les alertes déjà chargées par
/// AlertsViewModel. Si l'alerte correspondante n'est plus dans la liste
/// courante (filtrage par patient, pagination future...), un repli générique
/// s'affiche plutôt qu'un écran cassé.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsViewModelProvider);
    final alertsState = ref.watch(alertsViewModelProvider);
    final readIds = ref.watch(notificationsReadProvider);

    // Table de correspondance alert_id -> AlertModel, pour donner du contexte
    // à chaque notification (le backend ne renvoie que l'id de l'alerte).
    final alertsById = {for (final a in alertsState.alerts) a.id: a};

    final notifications = notificationsState.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Tout marquer comme lu',
            onPressed: () => ref
                .read(notificationsReadProvider.notifier)
                .markAllRead(notifications.map((n) => n.id).toList()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: notificationsState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
            : RefreshIndicator(
                onRefresh: () => ref.read(notificationsViewModelProvider.notifier).refresh(),
                child: notifications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          ApiStatusBanner(isFromApi: notificationsState.isFromApi, errorMessage: notificationsState.errorMessage),
                          const Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Center(child: Text('Aucune notification pour le moment', style: TextStyle(color: Colors.grey))),
                          ),
                        ],
                      )
                    : _buildGroupedList(context, ref, notificationsState, notifications, alertsById, readIds),
              ),
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    NotificationsState notificationsState,
    List<AlertNotificationModel> notifications,
    Map<String, AlertModel> alertsById,
    Set<String> readIds,
  ) {
    final Map<String, List<AlertNotificationModel>> groups = {};
    for (final n in notifications) {
      final day = formatFrenchDate(n.sentAt);
      groups.putIfAbsent(day, () => []).add(n);
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ApiStatusBanner(isFromApi: notificationsState.isFromApi, errorMessage: notificationsState.errorMessage),
        for (final group in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              group.key,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
            ),
          ),
          for (final n in group.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildNotificationCard(context, ref, n, alertsById[n.alertId], !readIds.contains(n.id)),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AlertNotificationModel notification,
    AlertModel? alert,
    bool unread,
  ) {
    final isCritical = alert?.severity == AlertSeverity.critical;

    final IconData channelIcon = switch (notification.channel) {
      NotificationChannel.sms => Icons.sms_rounded,
      NotificationChannel.push => Icons.notifications_active_rounded,
      NotificationChannel.email => Icons.email_rounded,
    };
    final String channelLabel = notification.channelDisplay ??
        switch (notification.channel) {
          NotificationChannel.sms => 'SMS',
          NotificationChannel.push => 'Push',
          NotificationChannel.email => 'Email',
        };

    final (Color statusColor, String statusLabel) = switch (notification.status) {
      NotificationDeliveryStatus.delivered => (AppTheme.successGreen, notification.statusDisplay ?? 'Livré'),
      NotificationDeliveryStatus.sent => (AppTheme.infoBlue, notification.statusDisplay ?? 'Envoyé'),
      NotificationDeliveryStatus.failed => (AppTheme.errorRed, notification.statusDisplay ?? 'Échec'),
    };

    // Contenu : contexte de l'alerte si trouvée, sinon repli générique.
    final String title = alert?.alertTypeDisplay ?? 'Alerte';
    final String subtitle = alert != null
        ? '${alert.patientName} — ${alert.valueDescription(unitSuffix: alert.unit)}'
        : 'Alerte #${notification.alertId.substring(0, notification.alertId.length.clamp(0, 8))}';

    return Card(
      color: unread ? AppTheme.primaryLight : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ref.read(notificationsReadProvider.notifier).markRead(notification.id),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(channelIcon, color: isCritical ? AppTheme.errorRed : AppTheme.warningOrange, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppTheme.secondaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            channelLabel,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                        const Spacer(),
                        Text(formatFrenchDateTime(notification.sentAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
