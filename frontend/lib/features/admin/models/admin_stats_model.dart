import 'package:flutter/foundation.dart';

/// Modèle représentatif d'un bracelet connecté (ESP32) sous supervision.
@immutable
class AdminDeviceModel {
  final String id;
  final String macAddress;
  final String patientName;
  final String status; // 'Actif', 'En attente', 'Maintenance'
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
  final int patientCount; // Nombre total de patients inscrits
  final int braceletCount; // Nombre total de bracelets dans le parc
  final int activeAlertsCount; // Nombre total d'alertes actives
  final int criticalAlertsCount; // Nombre total d'alertes critiques non résolues
  final List<AdminDeviceModel> recentDevices; // Liste des bracelets récents

  const AdminStatsModel({
    required this.patientCount,
    required this.braceletCount,
    required this.activeAlertsCount,
    required this.criticalAlertsCount,
    required this.recentDevices,
  });

  /// État initial vide
  factory AdminStatsModel.empty() {
    return const AdminStatsModel(
      patientCount: 0,
      braceletCount: 0,
      activeAlertsCount: 0,
      criticalAlertsCount: 0,
      recentDevices: [],
    );
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
