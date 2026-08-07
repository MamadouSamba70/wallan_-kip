import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_alert_model.dart';

/// État réactif de la liste des alertes administrateur
class AdminAlertListState {
  final bool isLoading;
  final String? errorMessage;
  final List<AdminAlertModel> alerts;
  final String searchQuery;
  final AlertSeverity? severityFilter;
  final AlertStatus? statusFilter;

  const AdminAlertListState({
    this.isLoading = false,
    this.errorMessage,
    required this.alerts,
    this.searchQuery = '',
    this.severityFilter,
    this.statusFilter,
  });

  factory AdminAlertListState.initial() {
    return const AdminAlertListState(
      isLoading: true,
      alerts: [],
      searchQuery: '',
      severityFilter: null,
      statusFilter: null,
    );
  }

  /// Retourne les alertes filtrées par recherche, sévérité et statut
  List<AdminAlertModel> get filteredAlerts {
    return alerts.where((alert) {
      final query = searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          alert.patientName.toLowerCase().contains(query) ||
          alert.title.toLowerCase().contains(query) ||
          alert.braceletMac.toLowerCase().contains(query) ||
          alert.roomNumber.toLowerCase().contains(query);

      final matchesSeverity = severityFilter == null || alert.severity == severityFilter;
      final matchesStatus = statusFilter == null || alert.status == statusFilter;

      return matchesSearch && matchesSeverity && matchesStatus;
    }).toList();
  }

  AdminAlertListState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<AdminAlertModel>? alerts,
    String? searchQuery,
    AlertSeverity? severityFilter,
    bool clearSeverityFilter = false,
    AlertStatus? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return AdminAlertListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      alerts: alerts ?? this.alerts,
      searchQuery: searchQuery ?? this.searchQuery,
      severityFilter: clearSeverityFilter ? null : (severityFilter ?? this.severityFilter),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

/// ViewModel gérant les alertes de supervision admin
class AdminAlertViewModel extends Notifier<AdminAlertListState> {
  @override
  AdminAlertListState build() {
    final state = AdminAlertListState.initial();
    Future.microtask(() => loadAlerts());
    return state;
  }

  /// Chargement des alertes
  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 500));

    final mockAlerts = [
      AdminAlertModel(
        id: 'ALT-101',
        patientName: 'Fatoumata Binta Sow',
        patientId: 'PAT-002',
        roomNumber: 'Chambre 105',
        braceletMac: 'ESP32-D4:E5:F6:77',
        title: 'Chute de Saturation SpO2 (89%)',
        description: 'Niveau d\'oxygène en dessous du seuil critique (90%).',
        severity: AlertSeverity.critical,
        status: AlertStatus.active,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      AdminAlertModel(
        id: 'ALT-102',
        patientName: 'Fatoumata Binta Sow',
        patientId: 'PAT-002',
        roomNumber: 'Chambre 105',
        braceletMac: 'ESP32-D4:E5:F6:77',
        title: 'Tachycardie (128 BPM)',
        description: 'Fréquence cardiaque anormalement élevée au repos.',
        severity: AlertSeverity.critical,
        status: AlertStatus.active,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      AdminAlertModel(
        id: 'ALT-103',
        patientName: 'Ibrahima Bah',
        patientId: 'PAT-003',
        roomNumber: 'Chambre 110',
        braceletMac: 'ESP32-88:99:AA:BB',
        title: 'Alerte Bouton SOS Déclenché',
        description: 'Le patient a appuyé physiquement sur le bouton SOS du bracelet.',
        severity: AlertSeverity.critical,
        status: AlertStatus.acknowledged,
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      AdminAlertModel(
        id: 'ALT-104',
        patientName: 'Ousmane Camara',
        patientId: 'PAT-005',
        roomNumber: 'Chambre 118',
        braceletMac: 'ESP32-55:66:77:88',
        title: 'Batterie Bracelet Faible (15%)',
        description: 'Veuillez recharger le dispositif ESP32 rapidement.',
        severity: AlertSeverity.warning,
        status: AlertStatus.active,
        timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
      ),
      AdminAlertModel(
        id: 'ALT-105',
        patientName: 'Mamadou Samba Diallo',
        patientId: 'PAT-001',
        roomNumber: 'Chambre 102',
        braceletMac: 'ESP32-A1:B2:C3:44',
        title: 'Déconnexion Réseau Ponctuelle',
        description: 'Reconnexion automatique réussie après 10s.',
        severity: AlertSeverity.info,
        status: AlertStatus.resolved,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    state = state.copyWith(isLoading: false, alerts: mockAlerts);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSeverityFilter(AlertSeverity? severity) {
    if (severity == state.severityFilter) {
      state = state.copyWith(clearSeverityFilter: true);
    } else {
      state = state.copyWith(severityFilter: severity);
    }
  }

  void setStatusFilter(AlertStatus? status) {
    if (status == state.statusFilter) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
  }

  /// Action d'acquittement d'une alerte
  void acknowledgeAlert(String id) {
    final updatedList = state.alerts.map((a) {
      if (a.id == id) {
        return a.copyWith(status: AlertStatus.acknowledged);
      }
      return a;
    }).toList();
    state = state.copyWith(alerts: updatedList);
  }

  /// Action de résolution d'une alerte
  void resolveAlert(String id) {
    final updatedList = state.alerts.map((a) {
      if (a.id == id) {
        return a.copyWith(status: AlertStatus.resolved);
      }
      return a;
    }).toList();
    state = state.copyWith(alerts: updatedList);
  }

  Future<void> refresh() async {
    await loadAlerts();
  }
}

/// Provider pour AdminAlertViewModel
final adminAlertViewModelProvider =
    NotifierProvider<AdminAlertViewModel, AdminAlertListState>(() {
  return AdminAlertViewModel();
});
