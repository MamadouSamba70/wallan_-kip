import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_model.dart';

/// Service Repository gérant la récupération et le stockage des données Patients.
/// Prêt pour la connexion avec l'API Django tout en proposant un jeu de données de test simulées.
class PatientRepository {
  Future<List<PatientModel>> fetchPatients() async {
    // Simuler le délai réseau HTTP
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      PatientModel(
        id: 'PAT-001',
        name: 'Mamadou Samba Diallo',
        age: 68,
        gender: 'Homme',
        braceletMac: 'ESP32-A1:B2:C3:44',
        roomNumber: 'Chambre 102',
        status: PatientStatus.stable,
        heartRate: 74,
        spo2: 98,
        temperature: 36.6,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
        historyHeartRate: [70, 72, 75, 74, 73, 76, 74, 75, 74],
        historySpo2: [98, 98, 97, 98, 99, 98, 98, 98],
      ),
      PatientModel(
        id: 'PAT-002',
        name: 'Fatoumata Binta Sow',
        age: 74,
        gender: 'Femme',
        braceletMac: 'ESP32-D4:E5:F6:77',
        roomNumber: 'Chambre 105',
        status: PatientStatus.critical,
        heartRate: 128,
        spo2: 89,
        temperature: 38.5,
        lastUpdated: DateTime.now().subtract(const Duration(seconds: 45)),
        historyHeartRate: [85, 90, 105, 115, 122, 128, 130, 128],
        historySpo2: [96, 95, 92, 90, 89, 88, 89, 89],
      ),
      PatientModel(
        id: 'PAT-003',
        name: 'Ibrahima Bah',
        age: 81,
        gender: 'Homme',
        braceletMac: 'ESP32-88:99:AA:BB',
        roomNumber: 'Chambre 110',
        status: PatientStatus.warning,
        heartRate: 92,
        spo2: 94,
        temperature: 37.4,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
        historyHeartRate: [78, 82, 85, 88, 90, 93, 91, 92],
        historySpo2: [97, 96, 95, 95, 94, 94, 94, 94],
      ),
      PatientModel(
        id: 'PAT-004',
        name: 'Aïssatou Barry',
        age: 62,
        gender: 'Femme',
        braceletMac: 'ESP32-11:22:33:44',
        roomNumber: 'Chambre 112',
        status: PatientStatus.stable,
        heartRate: 68,
        spo2: 99,
        temperature: 36.4,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 12)),
        historyHeartRate: [65, 66, 68, 70, 69, 68, 67, 68],
        historySpo2: [99, 99, 98, 99, 99, 99, 99, 99],
      ),
      PatientModel(
        id: 'PAT-005',
        name: 'Ousmane Camara',
        age: 77,
        gender: 'Homme',
        braceletMac: 'ESP32-55:66:77:88',
        roomNumber: 'Chambre 118',
        status: PatientStatus.warning,
        heartRate: 98,
        spo2: 93,
        temperature: 37.8,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 8)),
        historyHeartRate: [80, 85, 88, 92, 95, 97, 98, 98],
        historySpo2: [96, 95, 94, 93, 93, 93, 93, 93],
      ),
    ];
  }
}

/// Provider du repository patients
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository();
});
