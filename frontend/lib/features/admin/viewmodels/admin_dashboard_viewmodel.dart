import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_stats_model.dart';
import '../services/admin_service.dart';

/// État de l'écran Dashboard Administrateur.
class AdminDashboardState {
  final bool isLoading;
  final String? errorMessage;
  final AdminStatsModel stats;

  const AdminDashboardState({
    this.isLoading = false,
    this.errorMessage,
    required this.stats,
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
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      stats: stats ?? this.stats,
    );
  }
}

/// ViewModel gérant la logique métier et l'état réactif de l'Admin Dashboard.
/// Suit l'architecture MVVM du projet Wallan avec Riverpod 3.x.
class AdminDashboardViewModel extends Notifier<AdminDashboardState> {
  @override
  AdminDashboardState build() {
    // État initial de chargement au lancement
    final initialState = AdminDashboardState.initial();
    
    // Chargement automatique asynchrone des statistiques au démarrage
    Future.microtask(() => loadDashboardStats());

    return initialState;
  }

  /// Charge ou rafraîchit les statistiques globales de la console admin.
  Future<void> loadDashboardStats() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final adminService = ref.read(adminServiceProvider);
      final fetchedStats = await adminService.fetchDashboardStats();
      state = state.copyWith(
        isLoading: false,
        stats: fetchedStats,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossible de charger les statistiques : ${e.toString()}',
      );
    }
  }

  /// Action de rafraîchissement manuel
  Future<void> refresh() async {
    await loadDashboardStats();
  }
}

/// Provider Riverpod exposant le ViewModel de l'Admin Dashboard.
final adminDashboardViewModelProvider =
    NotifierProvider<AdminDashboardViewModel, AdminDashboardState>(() {
  return AdminDashboardViewModel();
});
