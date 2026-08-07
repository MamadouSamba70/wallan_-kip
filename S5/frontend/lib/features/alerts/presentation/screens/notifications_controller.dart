import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/notifications_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Suivi Riverpod de l'état "lu/non lu" des notifications côté Espace Proche.
//
// Depuis que les notifications viennent du vrai backend (AlertNotificationLog,
// via NotificationsViewModel), chaque entrée a un id réel et stable — plus
// besoin de la clé composite bricolée des versions précédentes.
//
// "Lu/non lu" reste un concept 100% côté client (absent du schéma backend),
// donc toujours géré ici plutôt que persisté côté serveur.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsReadNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  bool isRead(String notificationId) => state.contains(notificationId);

  void markRead(String notificationId) {
    if (state.contains(notificationId)) return;
    state = {...state, notificationId};
  }

  void markAllRead(List<String> notificationIds) {
    state = {...state, ...notificationIds};
  }
}

final notificationsReadProvider =
    NotifierProvider<NotificationsReadNotifier, Set<String>>(() {
  return NotificationsReadNotifier();
});

/// Nombre de notifications non lues, dérivé EN DIRECT des vraies
/// notifications (NotificationsViewModel) et de l'état lu/non lu ci-dessus.
/// Écouté par la cloche de RelativeDashboard.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsState = ref.watch(notificationsViewModelProvider);
  final readIds = ref.watch(notificationsReadProvider);
  return notificationsState.notifications.where((n) => !readIds.contains(n.id)).length;
});
