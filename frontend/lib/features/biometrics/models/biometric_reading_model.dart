// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI un seul modèle pour le local ET l'API ?
//
// La mesure biométrique a exactement la même forme, qu'elle vienne du bracelet
// en temps réel ou qu'elle soit relue depuis SQLite pour être synchronisée.
// On évite donc deux classes qui feraient doublon (comme AuthRepository qui
// n'a qu'un seul UserModel pour le mode réel et le mode démo).
// ─────────────────────────────────────────────────────────────────────────────

/// Représente une mesure biométrique captée par le bracelet Wallan.
/// Miroir exact du modèle Django `BiometricReading` (biometric_data/models.py).
class BiometricReadingModel {
  /// Identifiant local SQLite (null tant que la ligne n'est pas encore insérée).
  /// N'existe pas côté backend — sert uniquement à retrouver la ligne locale
  /// pour la marquer comme synchronisée après un envoi réussi.
  final int? localId;

  final String patientId; // UUID du patient (FK patients.Patient)
  final String deviceId; // UUID du bracelet (FK devices.Device)
  final int heartRate; // bpm
  final double temperature; // °C
  final int spo2; // %
  final Map<String, dynamic>? movementData; // Données accéléromètre brutes
  final DateTime recordedAt; // Heure réelle de la mesure sur le bracelet
  final bool isSynced; // true = déjà confirmé par le backend

  const BiometricReadingModel({
    this.localId,
    required this.patientId,
    required this.deviceId,
    required this.heartRate,
    required this.temperature,
    required this.spo2,
    this.movementData,
    required this.recordedAt,
    this.isSynced = false,
  });

  /// Copie l'objet en ne changeant que certains champs (pattern déjà utilisé
  /// dans PatientListState, AuthState, etc. sur ce projet).
  BiometricReadingModel copyWith({
    int? localId,
    bool? isSynced,
  }) {
    return BiometricReadingModel(
      localId: localId ?? this.localId,
      patientId: patientId,
      deviceId: deviceId,
      heartRate: heartRate,
      temperature: temperature,
      spo2: spo2,
      movementData: movementData,
      recordedAt: recordedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Format attendu par le backend (POST /api/biometrics/ et /sync/).
  /// Les noms de clés correspondent exactement aux serializers Django
  /// (BiometricReadingCreateSerializer / BiometricSyncSerializer).
  Map<String, dynamic> toApiPayload() {
    return {
      'patient': patientId,
      'device': deviceId,
      'heart_rate': heartRate,
      'temperature': temperature.toStringAsFixed(1),
      'spo2': spo2,
      if (movementData != null) 'movement_data': movementData,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
    };
  }
}
