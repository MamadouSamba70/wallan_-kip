import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_stats_model.dart';

/// Service gérant la récupération et la manipulation des données d'administration.
/// En phase de prototype (Semaine 3), il utilise des données simulées enrichies.
class AdminService {
  /// Simule la récupération des statistiques globales du Dashboard Admin.
  Future<AdminStatsModel> fetchDashboardStats() async {
    // Simulation d'un délai réseau de 600ms pour éprouver l'UX du chargement
    await Future.delayed(const Duration(milliseconds: 600));

    return const AdminStatsModel(
      patientCount: 86,
      braceletCount: 124,
      activeAlertsCount: 7,
      criticalAlertsCount: 3,
      recentDevices: [
        AdminDeviceModel(
          id: 'dev_01',
          macAddress: 'ESP32-E8:9F:6D:8B:12:4A',
          patientName: 'Mamadou Samba Diallo',
          status: 'Actif',
          batteryLevel: 88,
          isConnected: true,
          lastSeen: 'Il y a 2 min',
        ),
        AdminDeviceModel(
          id: 'dev_02',
          macAddress: 'ESP32-A1:2C:4D:5E:6F:70',
          patientName: 'Fatoumata Binta Sow',
          status: 'Actif',
          batteryLevel: 45,
          isConnected: true,
          lastSeen: 'Il y a 5 min',
        ),
        AdminDeviceModel(
          id: 'dev_03',
          macAddress: 'ESP32-B2:3D:4E:5F:6A:71',
          patientName: 'Non Assigné',
          status: 'En attente',
          batteryLevel: 100,
          isConnected: false,
          lastSeen: 'Il y a 1 heure',
        ),
        AdminDeviceModel(
          id: 'dev_04',
          macAddress: 'ESP32-C3:4E:5F:60:7B:82',
          patientName: 'Amadou Oury Bah',
          status: 'Alerte Critiques',
          batteryLevel: 12,
          isConnected: true,
          lastSeen: 'A l\'instant',
        ),
      ],
    );
  }

  /// Action simulée pour enregistrer un nouveau bracelet ESP32.
  Future<AdminDeviceModel> registerDevice(String macAddress) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return AdminDeviceModel(
      id: 'dev_${DateTime.now().millisecondsSinceEpoch}',
      macAddress: macAddress,
      patientName: 'Non Assigné',
      status: 'En attente',
      batteryLevel: 100,
      isConnected: false,
      lastSeen: 'Nouveau',
    );
  }
}

/// Provider Riverpod exposant le service AdminService.
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});
