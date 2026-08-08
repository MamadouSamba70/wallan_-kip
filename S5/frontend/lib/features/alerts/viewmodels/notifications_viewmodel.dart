import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../relatives/viewmodels/patient_link_viewmodel.dart';
import '../models/alert_notification_model.dart';
import '../repositories/notifications_repository.dart';

class NotificationsState {
  final bool isLoading;
  final String? errorMessage;
  final List<AlertNotificationModel> notifications;
  final bool isFromApi;

  const NotificationsState({
    this.isLoading = false,
    this.errorMessage,
    required this.notifications,
    this.isFromApi = false,
  });

  factory NotificationsState.initial() => const NotificationsState(isLoading: true, notifications: []);

  NotificationsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<AlertNotificationModel>? notifications,
    bool? isFromApi,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      notifications: notifications ?? this.notifications,
      isFromApi: isFromApi ?? this.isFromApi,
    );
  }
}

/// ViewModel des notifications — branché sur GET /api/alert-notifications/
/// (vraie ressource backend). Se recharge automatiquement une fois
/// PatientLinkViewModel résolu (pour connaître mon email).
class NotificationsViewModel extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    ref.watch(patientLinkViewModelProvider);
    Future.microtask(() => loadNotifications());
    return NotificationsState.initial();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final linkState = ref.read(patientLinkViewModelProvider);
    final repository = ref.read(notificationsRepositoryProvider);

    if (linkState.myEmail == null) {
      // Backend injoignable dès l'étape /auth/me/ : bascule démo.
      state = state.copyWith(
        isLoading: false,
        notifications: repository.demoNotifications(),
        isFromApi: false,
        errorMessage: linkState.errorMessage,
      );
      return;
    }

    final fetched = await repository.fetchNotifications(recipientEmail: linkState.myEmail);
    state = state.copyWith(
      isLoading: false,
      notifications: fetched,
      isFromApi: true,
    );
  }

  Future<void> refresh() => loadNotifications();
}

final notificationsViewModelProvider =
    NotifierProvider<NotificationsViewModel, NotificationsState>(() {
  return NotificationsViewModel();
});
