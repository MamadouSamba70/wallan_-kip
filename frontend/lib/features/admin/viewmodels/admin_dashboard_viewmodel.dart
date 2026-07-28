import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_stats_model.dart';
import '../repositories/dashboard_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CHANGEMENT CLÉ par rapport à la Semaine 3 :
//
// Avant : ref.read(adminServiceProvider)  → données simulées
// Après : ref.read(dashboardRepositoryProvider) → vraie API Django
//
// Le ViewModel lui-même ne change presque pas — c'est la force du Repository Pattern.
// ─────────────────────────────────────────────────────────────────────────────

/// État de l'écran Dashboard Administrateur.
class AdminDashboardState {
  final bool isLoading;
  final String? errorMessage;
  final AdminStatsModel stats;
  /// Indique si les données proviennent de l'API réelle (true) ou d'un fallback (false).
  final bool isFromApi;

  const AdminDashboardState({
    this.isLoading = false,
    this.errorMessage,
    required this.stats,
    this.isFromApi = false,
  });

  factory AdminDashboardState.initial() {
    return AdminDashboardState(
      isLoading: true,
      errorMessage: null,
      stats: AdminStatsModel.empty(),
    );
  }

  AdminDashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    AdminStatsModel? stats,
    bool? isFromApi,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      stats: stats ?? this.stats,
      isFromApi: isFromApi ?? this.isFromApi,
    );
  }
}

/// ViewModel gérant la logique métier et l'état réactif de l'Admin Dashboard.
/// Branché sur DashboardRepository pour les données réelles de l'API Django.
class AdminDashboardViewModel extends Notifier<AdminDashboardState> {
  @override
  AdminDashboardState build() {
    // État initial de chargement au lancement
    final initialState = AdminDashboardState.initial();

    // Chargement automatique asynchrone des statistiques au démarrage du widget
    Future.microtask(() => loadDashboardStats());

    return initialState;
  }

  // ── Chargement principal ───────────────────────────────────────────────────
  /// Charge ou rafraîchit les statistiques globales depuis l'API Django.
  ///
  /// Flux :
  /// 1. Active le spinner de chargement
  /// 2. Appelle DashboardRepository.fetchDashboardStats()
  /// 3. Met à jour l'état avec les données réelles ou l'erreur
  Future<void> loadDashboardStats() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Appel au Repository qui contacte GET /api/admin/dashboard/
      final repository = ref.read(dashboardRepositoryProvider);
      final fetchedStats = await repository.fetchDashboardStats();

      state = state.copyWith(
        isLoading: false,
        stats: fetchedStats,
        isFromApi: true, // Marque que les données viennent de la vraie API
      );
    } catch (e) {
      // En cas d'erreur, on garde les anciennes données si elles existent (UX)
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isFromApi: false,
      );
    }
  }

  // ── Rafraîchissement manuel ────────────────────────────────────────────────
  /// Déclenché par le bouton refresh ou le RefreshIndicator (pull-to-refresh).
  Future<void> refresh() async {
    await loadDashboardStats();
  }
}

/// Provider Riverpod exposant le ViewModel de l'Admin Dashboard.
final adminDashboardViewModelProvider =
    NotifierProvider<AdminDashboardViewModel, AdminDashboardState>(() {
  return AdminDashboardViewModel();
});
