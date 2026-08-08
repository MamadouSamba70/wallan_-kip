import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reflète BiometricReadingSerializer (biometric_data/serializers.py) :
// { id, patient, device, heart_rate, temperature, spo2, movement_data,
//   recorded_at, synced_at, is_synced_offline }
//
// heart_rate/spo2 : IntegerField → nombres JSON.
// temperature     : DecimalField → DRF le sérialise en STRING ("36.8"),
//                    comme value_detected/threshold_value sur Alert.
// ─────────────────────────────────────────────────────────────────────────────

double _asDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

/// Une mesure biométrique brute renvoyée par le bracelet ESP32, telle que
/// stockée par le backend Django.
@immutable
class BiometricReading {
  final String? patientId; // 'patient'
  final double heartRate;
  final double spo2;
  final double temperature;
  final DateTime recordedAt;
  final bool isSyncedOffline;

  const BiometricReading({
    this.patientId,
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.recordedAt,
    this.isSyncedOffline = false,
  });

  factory BiometricReading.fromJson(Map<String, dynamic> json) {
    return BiometricReading(
      patientId: json['patient']?.toString(),
      heartRate: _asDouble(json['heart_rate']),
      spo2: _asDouble(json['spo2']),
      temperature: _asDouble(json['temperature']),
      recordedAt: DateTime.tryParse(json['recorded_at']?.toString() ?? '') ?? DateTime.now(),
      isSyncedOffline: json['is_synced_offline'] == true,
    );
  }
}

/// Point agrégé (moyenne journalière) prêt pour l'affichage fl_chart.
/// Produit soit par agrégation de vraies [BiometricReading] (VitalsRepository),
/// soit par l'historique de repli simulé si l'API est indisponible.
@immutable
class VitalsPoint {
  final String dayLabel;    // Abréviation du jour (ex: 'Lun')
  final double heartRate;   // Moyenne du jour (bpm)
  final double spo2;        // Moyenne du jour (%)
  final double temperature; // Moyenne du jour (°C)

  const VitalsPoint({
    required this.dayLabel,
    required this.heartRate,
    required this.spo2,
    required this.temperature,
  });
}
