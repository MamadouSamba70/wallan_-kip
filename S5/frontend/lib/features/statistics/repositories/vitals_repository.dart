import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/biometric_reading_model.dart';

const List<String> _joursFr = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

/// Repository des constantes vitales — GET /api/biometrics/{patient_id}/history/.
///
/// CORRECTION SEMAINE 5 : l'endpoint réel prend le patient_id dans le CHEMIN
/// (pas en query parameter comme précédemment supposé), et enveloppe la
/// réponse dans { patient_id, total, limit, date_from, date_to, readings: [...] }
/// plutôt que de renvoyer une liste brute.
class VitalsRepository {
  final ApiClient _apiClient;

  VitalsRepository({required this._apiClient});

  /// Récupère l'historique des 7 derniers jours pour [patientId] et l'agrège
  /// en moyenne journalière. `date_from`/`date_to` sont envoyés au format
  /// YYYY-MM-DD (filtrage supporté nativement par BiometricHistoryView).
  Future<List<VitalsPoint>> fetchWeeklyVitals({required String? patientId}) async {
    if (patientId == null) return _mockWeeklyVitals();

    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.biometricsHistory(patientId),
        queryParameters: {
          'date_from': _isoDate(weekAgo),
          'date_to': _isoDate(now),
          'limit': 1000,
        },
      );

      final readingsRaw = response.data?['readings'];
      final List<dynamic> list = readingsRaw is List ? readingsRaw : const [];

      if (list.isEmpty) {
        debugPrint('ℹ️ Aucune mesure biométrique pour ce patient sur 7 jours — Historique simulé utilisé');
        return _mockWeeklyVitals();
      }

      final readings = list.map((e) => BiometricReading.fromJson(e as Map<String, dynamic>)).toList();
      return _aggregateByDay(readings);
    } on DioException catch (e) {
      debugPrint('⚠️ GET /api/biometrics/$patientId/history/ non disponible (${e.type}) — Historique simulé utilisé');
      return _mockWeeklyVitals();
    } catch (e) {
      debugPrint('⚠️ Statistiques hors-ligne — Historique simulé utilisé: $e');
      return _mockWeeklyVitals();
    }
  }

  String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Regroupe les mesures brutes par jour civil et calcule la moyenne de
  /// chaque constante par jour.
  List<VitalsPoint> _aggregateByDay(List<BiometricReading> readings) {
    final sorted = [...readings]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final Map<String, List<BiometricReading>> byDay = {};
    for (final r in sorted) {
      final key = '${r.recordedAt.year}-${r.recordedAt.month}-${r.recordedAt.day}';
      byDay.putIfAbsent(key, () => []).add(r);
    }

    if (byDay.isEmpty) return _mockWeeklyVitals();

    return byDay.entries.map((entry) {
      final dayReadings = entry.value;
      final avgHr = dayReadings.map((r) => r.heartRate).reduce((a, b) => a + b) / dayReadings.length;
      final avgSpo2 = dayReadings.map((r) => r.spo2).reduce((a, b) => a + b) / dayReadings.length;
      final avgTemp = dayReadings.map((r) => r.temperature).reduce((a, b) => a + b) / dayReadings.length;
      final sample = dayReadings.first.recordedAt;
      return VitalsPoint(
        dayLabel: _joursFr[(sample.weekday - 1) % 7],
        heartRate: avgHr,
        spo2: avgSpo2,
        temperature: avgTemp,
      );
    }).toList();
  }

  /// Historique simulé de repli, cohérent avec les valeurs "Aujourd'hui"
  /// affichées sur RelativeDashboard (78 bpm / 36.8°C / 98%).
  List<VitalsPoint> _mockWeeklyVitals() {
    return const [
      VitalsPoint(dayLabel: 'Lun', heartRate: 74, spo2: 97, temperature: 36.6),
      VitalsPoint(dayLabel: 'Mar', heartRate: 76, spo2: 98, temperature: 36.7),
      VitalsPoint(dayLabel: 'Mer', heartRate: 82, spo2: 96, temperature: 37.1),
      VitalsPoint(dayLabel: 'Jeu', heartRate: 77, spo2: 98, temperature: 36.8),
      VitalsPoint(dayLabel: 'Ven', heartRate: 75, spo2: 97, temperature: 36.7),
      VitalsPoint(dayLabel: 'Sam', heartRate: 79, spo2: 98, temperature: 36.9),
      VitalsPoint(dayLabel: 'Dim', heartRate: 78, spo2: 98, temperature: 36.8),
    ];
  }
}

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  return VitalsRepository(apiClient: ref.watch(apiClientProvider));
});
