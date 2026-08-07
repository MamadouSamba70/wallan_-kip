import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/alert_model.dart';

/// Repository des alertes — couche d'accès au vrai backend Django
/// (alerts/views.py::AlertViewSet).
class AlertsRepository {
  final ApiClient _apiClient;

  AlertsRepository({required this._apiClient});

  /// Récupère les alertes.
  ///
  /// Si [patientId] est fourni, utilise GET /api/alerts/by_patient/?patient_id=X
  /// — qui a deux avantages sur GET /api/alerts/ brut :
  ///   1. Ne renvoie que les alertes du patient suivi par ce Proche.
  ///   2. Utilise AlertSerializer COMPLET (status, threshold_value, patient,
  ///      patient_email inclus), car self.action == 'by_patient' et non 'list'
  ///      côté Django — contrairement à GET /api/alerts/ qui utilise le
  ///      AlertListSerializer allégé.
  ///
  /// Sans [patientId] (lien Proche→Patient non résolu), retombe sur la liste
  /// complète GET /api/alerts/ (allégée), pour ne jamais laisser l'écran vide.
  Future<List<AlertModel>> fetchAlerts({String? patientId}) async {
    try {
      final response = patientId != null
          ? await _apiClient.get<dynamic>(
              ApiEndpoints.alertsByPatient,
              queryParameters: {'patient_id': patientId},
            )
          : await _apiClient.get<dynamic>(ApiEndpoints.alerts);

      final raw = response.data;
      final List<dynamic> list = raw is List
          ? raw
          : (raw is Map<String, dynamic> && raw['results'] is List ? raw['results'] as List : const []);

      final alerts = list.map((e) => AlertModel.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return alerts;
    } on DioException catch (e) {
      debugPrint('⚠️ GET /api/alerts/ non disponible (${e.type}) — Utilisation des données démo');
      return demoAlerts();
    } catch (e) {
      debugPrint('⚠️ Alertes hors-ligne — Utilisation des données démo: $e');
      return demoAlerts();
    }
  }

  /// Crée une nouvelle alerte via POST /api/alerts/ (déclenche automatiquement
  /// l'envoi des notifications SMS/Push côté backend — voir
  /// alerts/services.py::dispatch_alert_notifications, appelé dans
  /// AlertViewSet.perform_create).
  ///
  /// Le schéma Alert n'a pas de notion native de "SOS manuel" (alert_type ne
  /// connaît que heart_rate / temperature / spo2 / movement). Un SOS manuel
  /// est donc représenté avec alert_type='movement', severity='critical',
  /// value_detected=1 / threshold_value=0 (valeurs symboliques : "déclenché
  /// manuellement"). Signalé comme piste d'amélioration côté backend (ajouter
  /// un type 'manual' ou 'sos').
  Future<AlertModel> createAlert({
    required String patientId,
    required AlertType alertType,
    required AlertSeverity severity,
    required double valueDetected,
    required double thresholdValue,
  }) async {
    final body = buildAlertCreatePayload(
      patientId: patientId,
      alertType: alertType,
      severity: severity,
      valueDetected: valueDetected,
      thresholdValue: thresholdValue,
    );

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.alerts,
      data: body,
    );
    return AlertModel.fromJson(response.data!);
  }

  /// Marque une alerte comme résolue via POST /api/alerts/{id}/resolve/.
  Future<AlertModel?> resolveAlert(String id) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(ApiEndpoints.resolveAlert(id));
      return AlertModel.fromJson(response.data!);
    } catch (e) {
      debugPrint('⚠️ Résolution d\'alerte impossible: $e');
      return null;
    }
  }

  /// Jeu de données démo (repli hors-ligne / absence de patient lié), au
  /// format réel AlertModel.
  List<AlertModel> demoAlerts() {
    final now = DateTime.now();
    return [
      AlertModel(
        id: 'demo-1',
        patientName: 'Mamadou Diallo',
        alertType: AlertType.temperature,
        alertTypeDisplay: 'Température',
        severity: AlertSeverity.critical,
        severityDisplay: 'Critique',
        valueDetected: 38.4,
        thresholdValue: 38.0,
        status: AlertStatus.active,
        createdAt: now.subtract(const Duration(hours: 20)),
      ),
      AlertModel(
        id: 'demo-2',
        patientName: 'Mamadou Diallo',
        alertType: AlertType.heartRate,
        alertTypeDisplay: 'Rythme Cardiaque',
        severity: AlertSeverity.warning,
        severityDisplay: 'Avertissement',
        valueDetected: 58,
        thresholdValue: 60,
        status: AlertStatus.active,
        createdAt: now.subtract(const Duration(hours: 26)),
      ),
      AlertModel(
        id: 'demo-3',
        patientName: 'Mamadou Diallo',
        alertType: AlertType.spo2,
        alertTypeDisplay: 'SpO2',
        severity: AlertSeverity.critical,
        severityDisplay: 'Critique',
        valueDetected: 90,
        thresholdValue: 92,
        status: AlertStatus.active,
        createdAt: now.subtract(const Duration(hours: 34)),
      ),
      AlertModel(
        id: 'demo-4',
        patientName: 'Mamadou Diallo',
        alertType: AlertType.movement,
        alertTypeDisplay: 'Mouvement',
        severity: AlertSeverity.warning,
        severityDisplay: 'Avertissement',
        valueDetected: 1,
        thresholdValue: 0,
        status: AlertStatus.resolved,
        createdAt: now.subtract(const Duration(hours: 38)),
        resolvedAt: now.subtract(const Duration(hours: 37)),
      ),
    ];
  }
}

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(apiClient: ref.watch(apiClientProvider));
});
