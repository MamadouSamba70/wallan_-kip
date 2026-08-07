import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../relatives/viewmodels/patient_link_viewmodel.dart';
import '../models/alert_model.dart';
import '../repositories/alerts_repository.dart';

/// État réactif de la liste des alertes côté Espace Proche.
class AlertsState {
  final bool isLoading;
  final String? errorMessage;
  final List<AlertModel> alerts;
  final bool isFromApi;

  const AlertsState({
    this.isLoading = false,
    this.errorMessage,
    required this.alerts,
    this.isFromApi = false,
  });

  factory AlertsState.initial() => const AlertsState(isLoading: true, alerts: []);

  AlertsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<AlertModel>? alerts,
    bool? isFromApi,
  }) {
    return AlertsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      alerts: alerts ?? this.alerts,
      isFromApi: isFromApi ?? this.isFromApi,
    );
  }
}

/// ViewModel des alertes — branché sur AlertsRepository (vraie API) et sur
/// PatientLinkViewModel pour filtrer sur le bon patient. Se recharge
/// automatiquement dès que le lien Proche→Patient se résout (via ref.watch),
/// ce qui règle l'ancien souci de patient_id fixé en dur ("PAT-001").
class AlertsViewModel extends Notifier<AlertsState> {
  @override
  AlertsState build() {
    // ref.watch (et non ref.read) : ce Notifier se reconstruit automatiquement
    // quand PatientLinkViewModel change d'état (ex: résolution terminée),
    // et donc recharge les alertes avec le bon patient_id.
    ref.watch(patientLinkViewModelProvider);
    Future.microtask(() => loadAlerts());
    return AlertsState.initial();
  }

  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final linkState = ref.read(patientLinkViewModelProvider);
    final repository = ref.read(alertsRepositoryProvider);

    try {
      final fetched = await repository.fetchAlerts(patientId: linkState.patientId);
      state = state.copyWith(
        isLoading: false,
        alerts: fetched,
        // "Depuis l'API" seulement si on avait un vrai patient_id à interroger ;
        // sinon (aucun lien trouvé) on affiche honnêtement le mode démo, même
        // si la requête GET /api/alerts/ non filtrée a techniquement réussi.
        isFromApi: linkState.hasLinkedPatient,
        errorMessage: linkState.hasLinkedPatient ? null : linkState.errorMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        alerts: repository.demoAlerts(),
        isFromApi: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() => loadAlerts();

  /// Déclenche une alerte SOS. Nécessite un patient réellement lié : sans
  /// cela, créer une alerte pointerait vers un patient_id inventé, ce qui
  /// serait trompeur dans une app médicale. Lève une exception explicite que
  /// SosScreen intercepte pour afficher un message clair plutôt qu'un faux succès.
  Future<AlertModel> triggerSos() async {
    final linkState = ref.read(patientLinkViewModelProvider);
    if (!linkState.hasLinkedPatient) {
      throw StateError('Aucun patient lié à ce compte — impossible d\'envoyer une alerte réelle.');
    }

    final repository = ref.read(alertsRepositoryProvider);
    final created = await repository.createAlert(
      patientId: linkState.patientId!,
      alertType: AlertType.movement,
      severity: AlertSeverity.critical,
      valueDetected: 1,
      thresholdValue: 0,
    );
    state = state.copyWith(alerts: [created, ...state.alerts]);
    return created;
  }
}

final alertsViewModelProvider =
    NotifierProvider<AlertsViewModel, AlertsState>(() {
  return AlertsViewModel();
});
