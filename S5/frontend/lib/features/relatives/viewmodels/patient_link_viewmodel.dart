import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/patient_link_repository.dart';

/// État réactif du lien Proche → Patient, partagé par AlertsViewModel,
/// NotificationsViewModel et VitalsViewModel (tous ont besoin soit du
/// patientId réel, soit de myEmail pour filtrer leurs appels API).
class PatientLinkState {
  final bool isLoading;
  final String? errorMessage;
  final String? myEmail;
  final String? patientId;
  final String? patientName;

  const PatientLinkState({
    this.isLoading = false,
    this.errorMessage,
    this.myEmail,
    this.patientId,
    this.patientName,
  });

  factory PatientLinkState.initial() => const PatientLinkState(isLoading: true);

  bool get hasLinkedPatient => patientId != null;

  PatientLinkState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? myEmail,
    String? patientId,
    String? patientName,
  }) {
    return PatientLinkState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      myEmail: myEmail ?? this.myEmail,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
    );
  }
}

class PatientLinkViewModel extends Notifier<PatientLinkState> {
  @override
  PatientLinkState build() {
    Future.microtask(() => load());
    return PatientLinkState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repository = ref.read(patientLinkRepositoryProvider);
    final result = await repository.fetchLinkedPatient();

    state = PatientLinkState(
      isLoading: false,
      myEmail: result.myEmail,
      patientId: result.patientId,
      patientName: result.patientName,
      errorMessage: result.hasLink
          ? null
          : (result.myEmail == null
              ? 'Impossible de contacter le serveur — mode démo'
              : 'Aucun patient lié à ce compte — mode démo'),
    );
  }

  Future<void> refresh() => load();
}

final patientLinkViewModelProvider =
    NotifierProvider<PatientLinkViewModel, PatientLinkState>(() {
  return PatientLinkViewModel();
});
