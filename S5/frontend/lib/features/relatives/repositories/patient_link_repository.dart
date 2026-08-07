import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI ce repository ?
//
// Le backend n'expose PAS d'endpoint "mon patient lié" tout prêt. Le Plan de
// Travail suggérait que GET /api/patients/ serait "filtré par rôle", mais le
// code réel (PatientViewSet.queryset = Patient.objects.all()) renvoie TOUS
// les patients, sans filtrage. Idem pour GET /api/patient-relatives/, qui
// renvoie TOUS les liens patient↔proche de la base, tous utilisateurs confondus.
//
// Ce repository reconstitue donc le lien côté client, en 2 appels :
//   1. GET /api/auth/me/            → email de l'utilisateur connecté
//   2. GET /api/patient-relatives/  → recherche de la ligne où
//                                      relative_email == mon email
//
// Si aucun lien n'est trouvé (compte de démo non configuré côté backend),
// patientId reste null : les écrans en aval (Alertes, Statistiques, SOS)
// basculent alors sur leurs données de démonstration plutôt que d'interroger
// l'API avec un identifiant inventé.
// ─────────────────────────────────────────────────────────────────────────────

/// Résultat de la résolution du lien Proche → Patient.
class LinkedPatientResult {
  final String? myEmail;
  final String? patientId;
  final String? patientName;

  const LinkedPatientResult({this.myEmail, this.patientId, this.patientName});

  bool get hasLink => patientId != null;
}

class PatientLinkRepository {
  final ApiClient _apiClient;

  PatientLinkRepository({required this._apiClient});

  Future<LinkedPatientResult> fetchLinkedPatient() async {
    // 1. Qui suis-je ? (GET /api/auth/me/)
    String? myEmail;
    try {
      final meResponse = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.profile);
      myEmail = meResponse.data?['email'] as String?;
    } on DioException catch (e) {
      debugPrint('⚠️ GET /api/auth/me/ indisponible (${e.type}) — Impossible de résoudre le patient lié');
      return const LinkedPatientResult();
    }

    if (myEmail == null) return const LinkedPatientResult();

    // 2. Quel patient suis-je censé suivre ? (GET /api/patient-relatives/,
    //    filtré côté client car non filtré côté serveur)
    try {
      final response = await _apiClient.get<dynamic>(ApiEndpoints.patientRelatives);
      final raw = response.data;
      final List<dynamic> list = raw is List
          ? raw
          : (raw is Map<String, dynamic> && raw['results'] is List ? raw['results'] as List : const []);

      final matches = list
          .cast<Map<String, dynamic>>()
          .where((e) => (e['relative_email'] as String?)?.toLowerCase() == myEmail!.toLowerCase())
          .toList();

      if (matches.isEmpty) {
        debugPrint('ℹ️ Aucun lien PatientRelative trouvé pour $myEmail — mode démo utilisé en aval');
        return LinkedPatientResult(myEmail: myEmail);
      }

      // S'il y a plusieurs patients suivis, on privilégie le contact prioritaire
      // (is_primary_contact=true), sinon le premier de la liste.
      final chosen = matches.firstWhere(
        (e) => e['is_primary_contact'] == true,
        orElse: () => matches.first,
      );

      return LinkedPatientResult(
        myEmail: myEmail,
        patientId: chosen['patient']?.toString(),
        patientName: chosen['patient_name']?.toString(),
      );
    } on DioException catch (e) {
      debugPrint('⚠️ GET /api/patient-relatives/ indisponible (${e.type})');
      return LinkedPatientResult(myEmail: myEmail);
    } catch (e) {
      debugPrint('⚠️ Résolution du patient lié échouée: $e');
      return LinkedPatientResult(myEmail: myEmail);
    }
  }
}

final patientLinkRepositoryProvider = Provider<PatientLinkRepository>((ref) {
  return PatientLinkRepository(apiClient: ref.watch(apiClientProvider));
});
