import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/biometric_reading_model.dart';
import 'biometric_local_db.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI un Repository Hybride (API Réelle + File d'attente locale) ?
// (même principe que AuthRepository : bascule automatique si le backend
// est injoignable — sauf qu'ici on ne simule pas, on met en attente pour
// de vrai et on renvoie dès que le réseau revient)
//
// 1. Le bracelet envoie une mesure -> on tente POST /api/biometrics/ tout de suite
// 2. Si le serveur répond -> terminé, rien à stocker
// 3. Si le réseau est coupé (DioExceptionType.connectionError / timeout) ->
//    la mesure est sauvegardée dans SQLite (is_synced = 0)
// 4. Dès que le réseau revient, syncPending() renvoie tout ce qui est en
//    attente via POST /api/biometrics/sync/ (is_synced_offline=true côté Django)
//
// Semaine 7 — fiabilité : syncPending() envoie par lots de 200 (l'API accepte
// jusqu'à 500) et retente 3 fois avec un délai croissant avant d'abandonner
// un lot, pour rester fiable même après une coupure de plusieurs heures.
// ─────────────────────────────────────────────────────────────────────────────

class BiometricSyncSummary {
  final int syncedCount;
  final int failedCount;
  const BiometricSyncSummary({required this.syncedCount, required this.failedCount});
}

class BiometricRepository {
  final ApiClient _apiClient;
  final BiometricLocalDb _localDb;

  static const int _chunkSize = 200; // reste sous la limite backend de 500
  static const int _maxRetries = 3;

  BiometricRepository({
    required ApiClient apiClient,
    required BiometricLocalDb localDb,
  })  : _apiClient = apiClient,
        _localDb = localDb;

  // ── Réception d'une mesure (temps réel avec fallback offline) ──────────────
  /// Appelé à chaque mesure reçue du bracelet (via le service BLE).
  /// Retourne true si la mesure a été envoyée au serveur immédiatement,
  /// false si elle a été mise en attente localement.
  Future<bool> submitReading(BiometricReadingModel reading) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.biometricsReceive,
        data: reading.toApiPayload(),
      );
      return response.statusCode == 201;
    } on DioException catch (e) {
      // Erreur réseau (pas de connexion, timeout, serveur injoignable)
      // -> on stocke localement. Une vraie erreur de validation (400) côté
      // serveur remonte telle quelle, car la renvoyer plus tard ne la
      // corrigerait pas.
      if (_isNetworkError(e)) {
        await _localDb.insert(reading);
        debugPrint('📴 Hors-ligne — mesure mise en file d\'attente locale');
        return false;
      }
      rethrow;
    }
  }

  // ── Synchronisation des mesures en attente ──────────────────────────────────
  /// Envoie toutes les mesures en attente par lots de [_chunkSize].
  /// Boucle tant qu'il reste des mesures, pour gérer le cas d'une coupure
  /// prolongée où des centaines de mesures se sont accumulées.
  Future<BiometricSyncSummary> syncPending() async {
    int synced = 0;
    int failed = 0;

    while (true) {
      final pending = await _localDb.fetchPending(limit: _chunkSize);
      if (pending.isEmpty) break;

      final result = await _sendChunkWithRetry(pending);
      synced += result.syncedCount;
      failed += result.failedCount;

      // Un lot entièrement échoué -> on arrête pour ne pas boucler à l'infini
      // (le prochain changement de connectivité redéclenchera un essai).
      if (result.syncedCount == 0) break;
    }

    return BiometricSyncSummary(syncedCount: synced, failedCount: failed);
  }

  Future<BiometricSyncSummary> _sendChunkWithRetry(
    List<BiometricReadingModel> chunk,
  ) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final payload = chunk.map((r) => r.toApiPayload()).toList();
        final response = await _apiClient.post<dynamic>(
          ApiEndpoints.biometricsSync,
          data: payload,
        );

        if (response.statusCode == 201) {
          final ids = chunk.map((r) => r.localId!).toList();
          await _localDb.markSynced(ids);
          return BiometricSyncSummary(syncedCount: chunk.length, failedCount: 0);
        }
      } on DioException catch (e) {
        if (!_isNetworkError(e) || attempt == _maxRetries) {
          return BiometricSyncSummary(syncedCount: 0, failedCount: chunk.length);
        }
        // Backoff croissant : 2s, 8s, 18s — évite de marteler un réseau instable
        await Future.delayed(Duration(seconds: 2 * attempt * attempt));
      }
    }
    return BiometricSyncSummary(syncedCount: 0, failedCount: chunk.length);
  }

  Future<int> countPending() => _localDb.countPending();

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }
}

/// Provider Riverpod du BiometricRepository.
final biometricRepositoryProvider = Provider<BiometricRepository>((ref) {
  return BiometricRepository(
    apiClient: ref.watch(apiClientProvider),
    localDb: ref.watch(biometricLocalDbProvider),
  );
});
