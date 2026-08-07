import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../relatives/viewmodels/patient_link_viewmodel.dart';
import '../models/biometric_reading_model.dart';
import '../repositories/vitals_repository.dart';

class VitalsState {
  final bool isLoading;
  final String? errorMessage;
  final List<VitalsPoint> weeklyVitals;
  final bool isFromApi;

  const VitalsState({
    this.isLoading = false,
    this.errorMessage,
    required this.weeklyVitals,
    this.isFromApi = false,
  });

  factory VitalsState.initial() => const VitalsState(isLoading: true, weeklyVitals: []);

  VitalsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<VitalsPoint>? weeklyVitals,
    bool? isFromApi,
  }) {
    return VitalsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      weeklyVitals: weeklyVitals ?? this.weeklyVitals,
      isFromApi: isFromApi ?? this.isFromApi,
    );
  }
}

/// ViewModel du Dashboard Statistiques — GET /api/biometrics/{patient_id}/history/.
/// Se recharge automatiquement une fois PatientLinkViewModel résolu, ce qui
/// remplace l'ancien identifiant fixé en dur ("PAT-001") par le vrai UUID
/// du patient suivi par ce Proche.
class VitalsViewModel extends Notifier<VitalsState> {
  @override
  VitalsState build() {
    ref.watch(patientLinkViewModelProvider);
    Future.microtask(() => loadVitals());
    return VitalsState.initial();
  }

  Future<void> loadVitals() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final linkState = ref.read(patientLinkViewModelProvider);
    final repository = ref.read(vitalsRepositoryProvider);

    final points = await repository.fetchWeeklyVitals(patientId: linkState.patientId);

    state = state.copyWith(
      isLoading: false,
      weeklyVitals: points,
      isFromApi: linkState.hasLinkedPatient,
      errorMessage: linkState.hasLinkedPatient ? null : linkState.errorMessage,
    );
  }

  Future<void> refresh() => loadVitals();
}

final vitalsViewModelProvider =
    NotifierProvider<VitalsViewModel, VitalsState>(() {
  return VitalsViewModel();
});
