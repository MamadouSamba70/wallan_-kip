import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/admin_stats_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI un DashboardRepository et pas juste un Service ?
//
// En architecture propre, le Repository est la SEULE couche qui sait
// comment récupérer les données (API, cache, base locale).
// Le ViewModel reçoit toujours un AdminStatsModel propre, peu importe la source.
//
// Avantage : si demain on ajoute un cache SQLite ou un mode offline,
// on ne touche qu'au Repository. Le ViewModel et la Vue restent inchangés.
// ─────────────────────────────────────────────────────────────────────────────

/// Repository du Dashboard Admin — couche d'accès aux données de supervision.
///
/// Appelle GET /api/admin/dashboard/ et retourne un [AdminStatsModel] désérialisé.
/// Gère les erreurs réseau et les traduit en messages lisibles.
class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({required this._apiClient});

  // ── Fetch Dashboard Stats ────────────────────────────────────────────────────
  /// Récupère les statistiques globales du système depuis l'API Django.
  ///
  /// Endpoint : GET /api/admin/dashboard/
  /// Auth : Bearer Token (injecté automatiquement par l'intercepteur JWT)
  Future<AdminStatsModel> fetchDashboardStats() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminDashboard,
      );

      // Désérialise la réponse JSON vers AdminStatsModel
      return AdminStatsModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_parseDioError(e));
    }
  }

  // ── Gestion des erreurs ────────────────────────────────────────────────────
  /// Traduit les erreurs réseau/HTTP en messages lisibles pour l'admin.
  String _parseDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout =>
        'Connexion trop lente. Vérifiez le réseau.',
      DioExceptionType.receiveTimeout =>
        'Le serveur met trop de temps à répondre.',
      DioExceptionType.connectionError =>
        'Serveur Django inaccessible. Vérifiez qu\'il est démarré sur le port 8000.',
      DioExceptionType.badResponse => switch (e.response?.statusCode) {
          401 => 'Session expirée. Veuillez vous reconnecter.',
          403 => 'Accès refusé. Droits administrateur requis.',
          404 => 'Endpoint /api/admin/dashboard/ introuvable.',
          500 => 'Erreur interne du serveur Django.',
          _ => 'Erreur serveur (${e.response?.statusCode}).',
        },
      _ => 'Erreur réseau inattendue : ${e.message}',
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Provider Riverpod du DashboardRepository.
///
/// Injecte l'ApiClient (avec son intercepteur JWT) dans le Repository.
// ─────────────────────────────────────────────────────────────────────────────
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    apiClient: ref.watch(apiClientProvider),
  );
});
