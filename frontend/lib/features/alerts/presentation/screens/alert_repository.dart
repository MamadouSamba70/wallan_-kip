import 'package:flutter/foundation.dart';                                // Fournit ValueNotifier (état observable léger)

/// Représente une alerte, en attendant le modèle réel renvoyé par l'API
/// GET /api/alerts/ (prévue en Semaine 3, module backend de Fatima).
class AlertItem {                                                        // Petite classe de données locale
  final String title;                                                     // Type d'alerte (ex: "Température élevée")
  final String patient;                                                   // Nom du patient concerné par l'alerte
  final String value;                                                     // Valeur mesurée + seuil, déjà formatés en texte
  final String date;                                                      // Date/heure de déclenchement, déjà formatée
  final bool isCritical;                                                  // true = severity "critical", false = "warning"

  const AlertItem({                                                       // Constructeur : tous les champs sont requis
    required this.title,
    required this.patient,
    required this.value,
    required this.date,
    required this.isCritical,
  });
}

/// Dépôt simulé et PARTAGÉ des alertes, en attendant l'API réelle.
///
/// Pourquoi ce fichier existe : plusieurs écrans (AlertScreen, SosScreen,
/// RelativeDashboard) doivent tous voir les mêmes alertes, notamment pour
/// qu'une alerte SOS déclenchée sur le SosScreen apparaisse automatiquement
/// dans l'historique du Dashboard Proche, sans rien recharger manuellement.
///
/// Comment ça marche : `alerts` est un ValueNotifier, une liste "observable"
/// fournie par Flutter. N'importe quel écran peut l'écouter avec un
/// ValueListenableBuilder ; dès que la liste change (ex: nouvelle alerte
/// SOS ajoutée), tous les écrans qui l'affichent se mettent à jour
/// automatiquement, sans navigation ni rechargement.
///
/// ⚠️ Solution temporaire pour la phase de maquette (données simulées,
/// en mémoire, perdues à la fermeture de l'app). Sera remplacée par de
/// vrais appels HTTP (GET/POST /api/alerts/) une fois l'API branchée
/// (Semaine 5 selon le planning d'intégration Flutter / Django).
class AlertRepository {
  AlertRepository._();                                                   // Constructeur privé : empêche d'instancier la classe

  /// Liste réactive des alertes, triée de la plus récente à la plus ancienne.
  static final ValueNotifier<List<AlertItem>> alerts = ValueNotifier([    // État partagé entre tous les écrans
    const AlertItem(
      title: 'Température élevée',                                        // threshold_temperature dépassé côté Patient
      patient: 'Mamadou Diallo',
      value: '38.4 °C (Seuil : 38.0 °C)',
      date: '05 Juil 2026, 14:23',
      isCritical: true,
    ),
    const AlertItem(
      title: 'Fréquence cardiaque basse',                                  // threshold_heart_rate non atteint
      patient: 'Aïssatou Bah',
      value: '58 bpm (Seuil : 60 bpm)',
      date: '05 Juil 2026, 10:05',
      isCritical: false,
    ),
    const AlertItem(
      title: 'Saturation SpO2 basse',                                      // threshold_spo2 non atteint
      patient: 'Mamadou Diallo',
      value: '90% (Seuil : 92%)',
      date: '04 Juil 2026, 22:41',
      isCritical: true,
    ),
    const AlertItem(
      title: 'Mouvement anormal détecté',                                  // Anomalie dans movement_data (accéléromètre)
      patient: 'Fatoumata Camara',
      value: 'Chute possible',
      date: '04 Juil 2026, 18:12',
      isCritical: false,
    ),
  ]);

  /// Ajoute une nouvelle alerte en tête de liste (la plus récente en premier).
  /// Appelée notamment par SosScreen quand l'utilisateur déclenche une urgence.
  static void addAlert(AlertItem alert) {                                  // Point d'entrée unique pour ajouter une alerte
    alerts.value = [alert, ...alerts.value];                                // Nouvelle liste requise (ValueNotifier compare par référence)
  }

  /// Formate une date/heure au même style que les données simulées
  /// ci-dessus (ex: "14 Juil 2026, 09:41"), en français, sans dépendance
  /// externe (pas besoin du package intl pour ce format simple).
  static String formatDate(DateTime dt) {                                  // Utilisé pour horodater les nouvelles alertes
    const mois = [                                                          // Abréviations des mois en français
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
    ];
    final jour = dt.day.toString().padLeft(2, '0');                          // Jour sur 2 chiffres (ex: "05")
    final heure = dt.hour.toString().padLeft(2, '0');                        // Heure sur 2 chiffres (ex: "09")
    final minute = dt.minute.toString().padLeft(2, '0');                     // Minute sur 2 chiffres (ex: "41")
    return '$jour ${mois[dt.month - 1]} ${dt.year}, $heure:$minute';          // Assemble le format final
  }
}