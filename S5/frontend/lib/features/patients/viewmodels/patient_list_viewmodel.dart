import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_model.dart';
import '../services/patient_repository.dart';

/// État réactif de la liste des patients
class PatientListState {
  final bool isLoading;
  final String? errorMessage;
  final List<PatientModel> patients;
  final String searchQuery;
  final PatientStatus? statusFilter;

  const PatientListState({
    this.isLoading = false,
    this.errorMessage,
    required this.patients,
    this.searchQuery = '',
    this.statusFilter,
  });

  factory PatientListState.initial() {
    return const PatientListState(
      isLoading: true,
      patients: [],
      searchQuery: '',
      statusFilter: null,
    );
  }

  /// Retourne la liste des patients filtrés selon la recherche et le statut sélectionné
  List<PatientModel> get filteredPatients {
    return patients.where((patient) {
      // 1. Filtrage par requête de recherche (nom, mac, chambre)
      final query = searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          patient.name.toLowerCase().contains(query) ||
          patient.braceletMac.toLowerCase().contains(query) ||
          patient.roomNumber.toLowerCase().contains(query) ||
          patient.id.toLowerCase().contains(query);

      // 2. Filtrage par statut de santé
      final matchesStatus = statusFilter == null || patient.status == statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  PatientListState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<PatientModel>? patients,
    String? searchQuery,
    PatientStatus? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return PatientListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      patients: patients ?? this.patients,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

/// ViewModel gérant la logique réactive de la liste des patients
class PatientListViewModel extends Notifier<PatientListState> {
  @override
  PatientListState build() {
    final state = PatientListState.initial();
    Future.microtask(() => loadPatients());
    return state;
  }

  /// Chargement des patients
  Future<void> loadPatients() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(patientRepositoryProvider);
      final list = await repo.fetchPatients();
      state = state.copyWith(isLoading: false, patients: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur de chargement des patients: ${e.toString()}',
      );
    }
  }

  /// Mise à jour de la recherche
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Filtrage par statut
  void setStatusFilter(PatientStatus? status) {
    if (status == state.statusFilter) {
      // Toggle pour désélectionner
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
  }

  /// Action de rafraîchissement
  Future<void> refresh() async {
    await loadPatients();
  }
}

/// Provider du ViewModel PatientListViewModel
final patientListViewModelProvider =
    NotifierProvider<PatientListViewModel, PatientListState>(() {
  return PatientListViewModel();
});
