import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI un nouveau modèle, séparé de AdminAlertModel ?
//
// AdminAlertModel (utilisé par l'écran Admin de Mamadou) a été construit avec
// des champs qui n'existent PAS dans le vrai backend : title, description,
// room_number, bracelet_mac, un statut "acknowledged", une sévérité "info"...
// Aucun de ces champs n'existe dans le modèle Django réel (alerts/models.py).
//
// Plutôt que de modifier AdminAlertModel (ce qui casserait la compilation de
// AdminAlertListScreen / AdminAlertViewModel, en cours de développement par
// Mamadou), ce fichier introduit AlertModel : un modèle DISTINCT, propre au
// périmètre Alpha (Alertes/Notifications/Statistiques/Proche), qui reflète
// fidèlement le vrai JSON renvoyé par GET /api/alerts/.
//
// ⚠️ À SIGNALER À MAMADOU : AdminAlertModel devra être corrigé de la même
// façon pour que la console Admin fonctionne contre le vrai backend.
//
// ─────────────────────────────────────────────────────────────────────────────
// Deux formes de JSON selon l'action appelée côté Django (voir alerts/views.py) :
//
// AlertListSerializer (self.action == 'list', ex: GET /api/alerts/) :
//   { id, patient_name, alert_type, alert_type_display,
//     severity, severity_display, value_detected, created_at }
//   → PAS de status, threshold_value, patient (id), patient_email !
//
// AlertSerializer complet (toutes les autres actions : by_patient, active,
// retrieve, create, resolve...) :
//   { id, patient, patient_name, patient_email,
//     alert_type, alert_type_display, severity, severity_display,
//     value_detected, threshold_value, status, status_display,
//     created_at, resolved_at }
//
// AlertModel.fromJson gère les deux formes : les champs absents de la version
// allégée restent `null` (patientId, thresholdValue, statusDisplay) ou
// prennent une valeur par défaut raisonnable (status → 'active').
// ─────────────────────────────────────────────────────────────────────────────

enum AlertType { heartRate, temperature, spo2, movement }

enum AlertSeverity { warning, critical }

enum AlertStatus { active, resolved, falseAlarm }

AlertType _parseAlertType(String? raw) {
  switch (raw) {
    case 'heart_rate':
      return AlertType.heartRate;
    case 'temperature':
      return AlertType.temperature;
    case 'spo2':
      return AlertType.spo2;
    case 'movement':
      return AlertType.movement;
    default:
      return AlertType.movement;
  }
}

String _alertTypeToApi(AlertType type) {
  switch (type) {
    case AlertType.heartRate:
      return 'heart_rate';
    case AlertType.temperature:
      return 'temperature';
    case AlertType.spo2:
      return 'spo2';
    case AlertType.movement:
      return 'movement';
  }
}

AlertSeverity _parseSeverity(String? raw) {
  return raw == 'critical' ? AlertSeverity.critical : AlertSeverity.warning;
}

AlertStatus _parseStatus(String? raw) {
  switch (raw) {
    case 'resolved':
      return AlertStatus.resolved;
    case 'false_alarm':
      return AlertStatus.falseAlarm;
    case 'active':
    default:
      return AlertStatus.active;
  }
}

double _asDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

/// Une alerte réelle, telle que renvoyée par GET /api/alerts/ (Django).
@immutable
class AlertModel {
  final String id;
  final String? patientId; // 'patient' — absent du AlertListSerializer allégé
  final String patientName;
  final String? patientEmail; // absent du AlertListSerializer allégé
  final AlertType alertType;
  final String alertTypeDisplay; // libellé FR fourni par le backend (ex: "Rythme Cardiaque")
  final AlertSeverity severity;
  final String severityDisplay;
  final double valueDetected;
  final double? thresholdValue; // absent du AlertListSerializer allégé
  final AlertStatus status; // défaut 'active' si absent (liste allégée)
  final String? statusDisplay;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const AlertModel({
    required this.id,
    this.patientId,
    required this.patientName,
    this.patientEmail,
    required this.alertType,
    required this.alertTypeDisplay,
    required this.severity,
    required this.severityDisplay,
    required this.valueDetected,
    this.thresholdValue,
    this.status = AlertStatus.active,
    this.statusDisplay,
    required this.createdAt,
    this.resolvedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'].toString(),
      patientId: json['patient']?.toString(),
      patientName: (json['patient_name'] ?? 'Patient inconnu').toString(),
      patientEmail: json['patient_email']?.toString(),
      alertType: _parseAlertType(json['alert_type'] as String?),
      alertTypeDisplay: (json['alert_type_display'] ?? json['alert_type'] ?? 'Anomalie').toString(),
      severity: _parseSeverity(json['severity'] as String?),
      severityDisplay: (json['severity_display'] ?? json['severity'] ?? '').toString(),
      valueDetected: _asDouble(json['value_detected']),
      thresholdValue: json['threshold_value'] != null ? _asDouble(json['threshold_value']) : null,
      status: _parseStatus(json['status'] as String?),
      statusDisplay: json['status_display']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'].toString()) : null,
    );
  }

  /// Texte de la valeur mesurée, avec le seuil si disponible.
  /// Ex: "82 bpm (Seuil : 70 bpm)" ou juste "82 bpm" si thresholdValue est absent.
  String valueDescription({String unitSuffix = ''}) {
    final value = valueDetected % 1 == 0 ? valueDetected.toInt().toString() : valueDetected.toStringAsFixed(1);
    if (thresholdValue == null) return '$value$unitSuffix';
    final threshold = thresholdValue! % 1 == 0 ? thresholdValue!.toInt().toString() : thresholdValue!.toStringAsFixed(1);
    return '$value$unitSuffix (Seuil : $threshold$unitSuffix)';
  }

  /// Unité d'affichage selon le type d'alerte (le backend ne la fournit pas).
  String get unit {
    switch (alertType) {
      case AlertType.heartRate:
        return ' bpm';
      case AlertType.temperature:
        return '°C';
      case AlertType.spo2:
        return '%';
      case AlertType.movement:
        return '';
    }
  }
}

/// Construit le body JSON attendu par POST /api/alerts/ (création manuelle,
/// ex: SOS). Fonction libre plutôt que méthode d'instance car il n'y a pas
/// encore d'AlertModel au moment de la création.
Map<String, dynamic> buildAlertCreatePayload({
  required String patientId,
  required AlertType alertType,
  required AlertSeverity severity,
  required double valueDetected,
  required double thresholdValue,
  AlertStatus status = AlertStatus.active,
}) {
  return {
    'patient': patientId,
    'alert_type': _alertTypeToApi(alertType),
    'severity': severity == AlertSeverity.critical ? 'critical' : 'warning',
    'value_detected': valueDetected,
    'threshold_value': thresholdValue,
    'status': switch (status) {
      AlertStatus.active => 'active',
      AlertStatus.resolved => 'resolved',
      AlertStatus.falseAlarm => 'false_alarm',
    },
  };
}
