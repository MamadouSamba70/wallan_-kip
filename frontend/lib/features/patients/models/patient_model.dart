import 'package:flutter/material.dart';

/// Statut de santé général d'un patient
enum PatientStatus {
  stable,
  warning,
  critical;

  String get label {
    switch (this) {
      case PatientStatus.stable:
        return 'Stable';
      case PatientStatus.warning:
        return 'Surveillance';
      case PatientStatus.critical:
        return 'Critique';
    }
  }

  Color get color {
    switch (this) {
      case PatientStatus.stable:
        return const Color(0xFF2ECC71); // Vert
      case PatientStatus.warning:
        return const Color(0xFFF39C12); // Orange
      case PatientStatus.critical:
        return const Color(0xFFE74C3C); // Rouge
    }
  }

  IconData get icon {
    switch (this) {
      case PatientStatus.stable:
        return Icons.check_circle_rounded;
      case PatientStatus.warning:
        return Icons.warning_amber_rounded;
      case PatientStatus.critical:
        return Icons.error_rounded;
    }
  }
}

/// Modèle représentant un Patient dans le système Wallan
class PatientModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String braceletMac;
  final String roomNumber;
  final PatientStatus status;
  final int heartRate; // BPM
  final int spo2; // %
  final double temperature; // °C
  final DateTime lastUpdated;
  final List<double> historyHeartRate;
  final List<double> historySpo2;

  const PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.braceletMac,
    required this.roomNumber,
    required this.status,
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.lastUpdated,
    required this.historyHeartRate,
    required this.historySpo2,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    PatientStatus parseStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'critical':
          return PatientStatus.critical;
        case 'warning':
          return PatientStatus.warning;
        default:
          return PatientStatus.stable;
      }
    }

    return PatientModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Patient Inconnu',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'M/F',
      braceletMac: json['bracelet_mac'] ?? json['braceletMac'] ?? 'N/A',
      roomNumber: json['room_number'] ?? json['roomNumber'] ?? 'Ch. --',
      status: parseStatus(json['status']),
      heartRate: json['heart_rate'] ?? json['heartRate'] ?? 75,
      spo2: json['spo2'] ?? 98,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 36.6,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'].toString()) ?? DateTime.now()
          : DateTime.now(),
      historyHeartRate: (json['history_heart_rate'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [72, 75, 78, 74, 76, 80, 77, 75],
      historySpo2: (json['history_spo2'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [98, 97, 99, 98, 98, 97, 98, 99],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'bracelet_mac': braceletMac,
      'room_number': roomNumber,
      'status': status.name,
      'heart_rate': heartRate,
      'spo2': spo2,
      'temperature': temperature,
      'last_updated': lastUpdated.toIso8601String(),
      'history_heart_rate': historyHeartRate,
      'history_spo2': historySpo2,
    };
  }

  PatientModel copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? braceletMac,
    String? roomNumber,
    PatientStatus? status,
    int? heartRate,
    int? spo2,
    double? temperature,
    DateTime? lastUpdated,
    List<double>? historyHeartRate,
    List<double>? historySpo2,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      braceletMac: braceletMac ?? this.braceletMac,
      roomNumber: roomNumber ?? this.roomNumber,
      status: status ?? this.status,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      temperature: temperature ?? this.temperature,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      historyHeartRate: historyHeartRate ?? this.historyHeartRate,
      historySpo2: historySpo2 ?? this.historySpo2,
    );
  }
}
