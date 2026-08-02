import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/admin_stats_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI un DashboardRepository Hybride ?
//
// 1. Si l'API Django est disponible -> GET /api/admin/dashboard/ (vraies données)
// 2. Si le backend n'est pas démarré/lié -> Fallback automatique sur les données
//    statistiques simulées initialMock() pour que l'interface admin s'affiche parfaitement.
// ─────────────────────────────────────────────────────────────────────────────

/// Repository du Dashboard Admin — couche d'accès aux données de supervision.
class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({required this._apiClient});

  // ── Fetch Dashboard Stats ────────────────────────────────────────────────────
  /// Récupère les statistiques globales du système depuis l'API Django.
  /// En cas de serveur non lié ou non démarré, bascule sur les données démo.
  Future<AdminStatsModel> fetchDashboardStats() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminDashboard,
      );

      // Désérialise la réponse JSON de Django vers AdminStatsModel
      return AdminStatsModel.fromJson(response.data!);
    } on DioException catch (e) {
      debugPrint('⚠️ Dashboard API non disponible (${e.type}) — Utilisation des données Démo');
      return AdminStatsModel.initialMock();
    } catch (e) {
      debugPrint('⚠️ Dashboard offline — Utilisation données Démo: $e');
      return AdminStatsModel.initialMock();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Provider Riverpod du DashboardRepository.
// ─────────────────────────────────────────────────────────────────────────────
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    apiClient: ref.watch(apiClientProvider),
  );
});
