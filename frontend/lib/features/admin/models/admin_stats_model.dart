import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI ajouter fromJson() maintenant ?
//
// En Semaine 3, ce modèle contenait seulement des données simulées.
// En Semaine 4, il doit désérialiser la réponse réelle de :
//   GET /api/admin/dashboard/
//
// Structure JSON attendue du backend Django :
// {
//   "patients": 86,
//   "bracelets": 124,
//   "active_alerts": 7,
//   "critical_alerts": 3,
//   "recent_devices": [
//     {
//       "id": "1",
//       "mac_address": "ESP32-E8:9F:6D:8B:12:4A",
//       "patient_name": "Mamadou Samba Diallo",
//       "status": "Actif",
//       "battery_level": 88,
//       "is_connected": true,
//       "last_seen": "Il y a 2 min"
//     }
//   ]
// }
// ─────────────────────────────────────────────────────────────────────────────

/// Modèle représentatif d'un bracelet connecté (ESP32) sous supervision.
@immutable
class AdminDeviceModel {
  final String id;
  final String macAddress;
  final String patientName;
  final String status; // 'Actif', 'En attente', 'Maintenance', 'Alerte Critique'
  final int batteryLevel; // 0 à 100
  final bool isConnected;
  final String lastSeen;

  const AdminDeviceModel({
    required this.id,
    required this.macAddress,
    required this.patientName,
    required this.status,
    required this.batteryLevel,
    required this.isConnected,
    required this.lastSeen,
  });

  /// Désérialise un objet device depuis le JSON de l'API Django.
  ///
  /// Supporte les conventions snake_case (Django) et camelCase (ancienne mock).
  factory AdminDeviceModel.fromJson(Map<String, dynamic> json) {
    return AdminDeviceModel(
      id: json['id'].toString(),
      // Support snake_case (backend) et camelCase (legacy)
      macAddress: (json['mac_address'] ?? json['macAddress'] ?? '') as String,
      patientName: (json['patient_name'] ?? json['patientName'] ?? 'Non assigné') as String,
      status: (json['status'] ?? 'Inconnu') as String,
      // Conversion sécurisée : le backend peut envoyer int ou String
      batteryLevel: (json['battery_level'] ?? json['batteryLevel'] ?? 0) as int,
      isConnected: (json['is_connected'] ?? json['isConnected'] ?? false) as bool,
      lastSeen: (json['last_seen'] ?? json['lastSeen'] ?? '') as String,
    );
  }

  /// Sérialise le modèle en JSON (pour les requêtes POST/PATCH vers Django).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mac_address': macAddress,
      'patient_name': patientName,
      'status': status,
      'battery_level': batteryLevel,
      'is_connected': isConnected,
      'last_seen': lastSeen,
    };
  }

  AdminDeviceModel copyWith({
    String? id,
    String? macAddress,
    String? patientName,
    String? status,
    int? batteryLevel,
    bool? isConnected,
    String? lastSeen,
  }) {
    return AdminDeviceModel(
      id: id ?? this.id,
      macAddress: macAddress ?? this.macAddress,
      patientName: patientName ?? this.patientName,
      status: status ?? this.status,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isConnected: isConnected ?? this.isConnected,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// Modèle de données immutables pour les statistiques globales du Dashboard Admin.
@immutable
class AdminStatsModel {
  final int patientCount;       // Nombre total de patients inscrits
  final int braceletCount;      // Nombre total de bracelets dans le parc
  final int activeAlertsCount;  // Nombre total d'alertes actives
  final int criticalAlertsCount; // Nombre total d'alertes critiques non résolues
  final List<AdminDeviceModel> recentDevices; // Liste des bracelets récents

  const AdminStatsModel({
    required this.patientCount,
    required this.braceletCount,
    required this.activeAlertsCount,
    required this.criticalAlertsCount,
    required this.recentDevices,
  });

  /// État initial vide — utilisé pendant le chargement initial.
  factory AdminStatsModel.empty() {
    return const AdminStatsModel(
      patientCount: 0,
      braceletCount: 0,
      activeAlertsCount: 0,
      criticalAlertsCount: 0,
      recentDevices: [],
    );
  }

  /// Désérialise les statistiques depuis la réponse JSON de GET /api/admin/dashboard/.
  ///
  /// Support multi-conventions pour compatibilité avec différentes versions du backend.
  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    // Parsing de la liste des bracelets récents
    final devicesJson = json['recent_devices'] ?? json['recentDevices'] ?? [];
    final devices = (devicesJson as List<dynamic>)
        .map((d) => AdminDeviceModel.fromJson(d as Map<String, dynamic>))
        .toList();

    return AdminStatsModel(
      // Support des deux nommages : "patients" (court) ou "patient_count" (explicite)
      patientCount: (json['patients'] ?? json['patient_count'] ?? 0) as int,
      braceletCount: (json['bracelets'] ?? json['bracelet_count'] ?? 0) as int,
      activeAlertsCount: (json['active_alerts'] ?? json['activeAlertsCount'] ?? 0) as int,
      criticalAlertsCount: (json['critical_alerts'] ?? json['criticalAlertsCount'] ?? 0) as int,
      recentDevices: devices,
    );
  }

  /// Sérialise le modèle en JSON.
  Map<String, dynamic> toJson() {
    return {
      'patients': patientCount,
      'bracelets': braceletCount,
      'active_alerts': activeAlertsCount,
      'critical_alerts': criticalAlertsCount,
      'recent_devices': recentDevices.map((d) => d.toJson()).toList(),
    };
  }

  AdminStatsModel copyWith({
    int? patientCount,
    int? braceletCount,
    int? activeAlertsCount,
    int? criticalAlertsCount,
    List<AdminDeviceModel>? recentDevices,
  }) {
    return AdminStatsModel(
      patientCount: patientCount ?? this.patientCount,
      braceletCount: braceletCount ?? this.braceletCount,
      activeAlertsCount: activeAlertsCount ?? this.activeAlertsCount,
      criticalAlertsCount: criticalAlertsCount ?? this.criticalAlertsCount,
      recentDevices: recentDevices ?? this.recentDevices,
    );
  }
}
