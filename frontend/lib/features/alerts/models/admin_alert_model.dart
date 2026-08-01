import 'package:flutter/material.dart';

/// Sévérité d'une alerte
enum AlertSeverity {
  info,
  warning,
  critical;

  String get label {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Attention';
      case AlertSeverity.critical:
        return 'Urgente (SOS)';
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.info:
        return const Color(0xFF3498DB); // Bleu
      case AlertSeverity.warning:
        return const Color(0xFFF39C12); // Orange
      case AlertSeverity.critical:
        return const Color(0xFFE74C3C); // Rouge
    }
  }
}

/// Statut de traitement d'une alerte
enum AlertStatus {
  active,
  acknowledged,
  resolved;

  String get label {
    switch (this) {
      case AlertStatus.active:
        return 'En cours';
      case AlertStatus.acknowledged:
        return 'Pris en charge';
      case AlertStatus.resolved:
        return 'Résolue';
    }
  }
}

/// Modèle d'une alerte système / biométrique pour la console Administrateur
class AdminAlertModel {
  final String id;
  final String patientName;
  final String patientId;
  final String roomNumber;
  final String braceletMac;
  final String title;
  final String description;
  final AlertSeverity severity;
  final AlertStatus status;
  final DateTime timestamp;

  const AdminAlertModel({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.roomNumber,
    required this.braceletMac,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.timestamp,
  });

  factory AdminAlertModel.fromJson(Map<String, dynamic> json) {
    AlertSeverity parseSeverity(String? s) {
      switch (s?.toLowerCase()) {
        case 'critical':
        case 'sos':
          return AlertSeverity.critical;
        case 'warning':
          return AlertSeverity.warning;
        default:
          return AlertSeverity.info;
      }
    }

    AlertStatus parseStatus(String? st) {
      switch (st?.toLowerCase()) {
        case 'acknowledged':
          return AlertStatus.acknowledged;
        case 'resolved':
          return AlertStatus.resolved;
        default:
          return AlertStatus.active;
      }
    }

    return AdminAlertModel(
      id: json['id']?.toString() ?? '',
      patientName: json['patient_name'] ?? json['patientName'] ?? 'Patient Inconnu',
      patientId: json['patient_id'] ?? json['patientId'] ?? 'N/A',
      roomNumber: json['room_number'] ?? json['roomNumber'] ?? 'Ch. --',
      braceletMac: json['bracelet_mac'] ?? json['braceletMac'] ?? 'N/A',
      title: json['title'] ?? 'Alerte Système',
      description: json['description'] ?? '',
      severity: parseSeverity(json['severity']),
      status: parseStatus(json['status']),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AdminAlertModel copyWith({
    String? id,
    String? patientName,
    String? patientId,
    String? roomNumber,
    String? braceletMac,
    String? title,
    String? description,
    AlertSeverity? severity,
    AlertStatus? status,
    DateTime? timestamp,
  }) {
    return AdminAlertModel(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientId: patientId ?? this.patientId,
      roomNumber: roomNumber ?? this.roomNumber,
      braceletMac: braceletMac ?? this.braceletMac,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
