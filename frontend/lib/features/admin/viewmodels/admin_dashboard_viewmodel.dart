import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_stats_model.dart';
import '../repositories/dashboard_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OPTIMISATION Semaine 6 :
// - Ajout d'un cache temporel de 5 minutes pour éviter les requêtes inutiles
//   lors de la navigation inter-onglets (tab switching).
// - Guard contre les appels multiples simultanés (_isFetching).
// - Le ViewModel reste indépendant de la couche UI (MVVM strict).
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
  /// Timestamp du dernier chargement réussi (pour le cache de 5 min).
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 5);

  /// Guard anti-double appel simultané.
  bool _isFetching = false;

  @override
  AdminDashboardState build() {
    Future.microtask(() => loadDashboardStats());
    return AdminDashboardState.initial();
  }

  // ── Chargement principal ───────────────────────────────────────────────────
  /// Charge les statistiques depuis l'API Django.
  /// Respecte un cache de 5 minutes pour limiter les requêtes inutiles.
  Future<void> loadDashboardStats({bool forceRefresh = false}) async {
    if (_isFetching) return;

    if (!forceRefresh && _lastFetchTime != null) {
      final elapsed = DateTime.now().difference(_lastFetchTime!);
      if (elapsed < _cacheDuration) return;
    }

    _isFetching = true;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(dashboardRepositoryProvider);
      final fetchedStats = await repository.fetchDashboardStats();

      _lastFetchTime = DateTime.now();
      state = state.copyWith(
        isLoading: false,
        stats: fetchedStats,
        isFromApi: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isFromApi: false,
      );
    } finally {
      _isFetching = false;
    }
  }

  // ── Rafraîchissement manuel ────────────────────────────────────────────────
  /// Force le rechargement même si le cache n'est pas expiré.
  Future<void> refresh() async {
    await loadDashboardStats(forceRefresh: true);
  }
}

/// Provider Riverpod exposant le ViewModel de l'Admin Dashboard.
final adminDashboardViewModelProvider =
    NotifierProvider<AdminDashboardViewModel, AdminDashboardState>(() {
  return AdminDashboardViewModel();
});
