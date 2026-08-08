/// Utilitaires de formatage de dates en français, partagés par plusieurs
/// écrans (Alertes, Notifications, Statistiques, SOS).
///
/// Remplace l'ancienne méthode `AlertRepository.formatDate` (Semaine 2) :
/// maintenant que les alertes ont un vrai `DateTime` (`AlertModel.createdAt`,
/// désérialisé depuis l'API Django) plutôt qu'une String déjà formatée, ce
/// formatage est centralisé ici pour rester DRY entre tous les écrans qui
/// en ont besoin.
library;

const List<String> _moisFr = [
  'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
  'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
];

/// Formate une date/heure complète, style "05 Juil 2026, 14:23".
String formatFrenchDateTime(DateTime dt) {
  final jour = dt.day.toString().padLeft(2, '0');
  final heure = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$jour ${_moisFr[dt.month - 1]} ${dt.year}, $heure:$minute';
}

/// Formate uniquement la date (sans l'heure), style "05 Juil 2026".
/// Utilisé pour regrouper les notifications par jour.
String formatFrenchDate(DateTime dt) {
  final jour = dt.day.toString().padLeft(2, '0');
  return '$jour ${_moisFr[dt.month - 1]} ${dt.year}';
}
