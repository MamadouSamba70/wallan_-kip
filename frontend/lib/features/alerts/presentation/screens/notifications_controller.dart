import 'package:flutter/foundation.dart';                                // Fournit ValueNotifier (état observable léger)
import '../../../alerts/presentation/screens/alert_repository.dart';     // Dépôt partagé (AlertItem + AlertRepository)
import 'notification_log.dart';                                          // Dérive les entrées AlertNotificationLog simulées

/// Suivi de l'état "lu / non lu" des notifications côté Espace Proche.
///
/// Pourquoi ce fichier existe : `AlertRepository` reste la SEULE source de
/// vérité pour le contenu des alertes (titre, patient, valeur, date...),
/// et `NotificationLog` dérive de façon PURE la liste des notifications
/// envoyées (canal + statut de livraison), en miroir de la table
/// AlertNotificationLog du Plan de Travail. Ce contrôleur ajoute juste,
/// par-dessus ces deux sources, une couche "lu/non lu" propre à l'espace
/// Proche (concept d'affichage local, absent du schéma backend).
///
/// Comment ça marche : chaque NotificationLogEntry a une clé unique
/// (date + titre + patient + canal). `unreadCount` est un ValueNotifier
/// écouté par le badge de la cloche sur RelativeDashboard ET par
/// NotificationsScreen ; il se met à jour automatiquement dès qu'une
/// notification est marquée comme lue, ou qu'une nouvelle alerte arrive
/// dans AlertRepository (ex: un SOS déclenché, qui produit une nouvelle
/// notification push + sms).
///
/// ⚠️ Solution temporaire pour la phase de maquette (état gardé en mémoire,
/// perdu à la fermeture de l'app), comme AlertRepository.
class NotificationsController {
  NotificationsController._(); // Constructeur privé : empêche d'instancier la classe

  // Ensemble des clés de notifications déjà marquées comme lues.
  static final Set<String> _readKeys = <String>{};

  // Compteur réactif du nombre de notifications non lues.
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  static bool _listenerAttached = false;

  /// Branche le contrôleur sur AlertRepository.alerts si ce n'est pas déjà
  /// fait. Idempotent : peut être appelé sans risque depuis plusieurs écrans
  /// (RelativeDashboard, NotificationsScreen) au moment de leur build().
  static void ensureInitialized() {
    if (_listenerAttached) return; // Évite d'attacher le listener deux fois
    _listenerAttached = true;
    AlertRepository.alerts.addListener(_recompute); // Recalcule à chaque nouvelle alerte (ex: SOS)
    _recompute(); // Calcule le compteur initial dès le premier accès
  }

  /// Indique si une notification donnée a déjà été lue par le proche.
  static bool isRead(NotificationLogEntry entry) => _readKeys.contains(entry.key);

  /// Marque une notification comme lue (ex: au tap sur une carte).
  static void markRead(NotificationLogEntry entry) {
    _readKeys.add(entry.key);
    _recompute();
  }

  /// Marque toutes les notifications actuellement dérivées comme lues
  /// (bouton "Tout marquer comme lu").
  static void markAllRead() {
    for (final entry in NotificationLog.deriveFrom(AlertRepository.alerts.value)) {
      _readKeys.add(entry.key);
    }
    _recompute();
  }

  /// Recalcule le nombre de notifications non lues à partir de l'état actuel.
  static void _recompute() {
    final entries = NotificationLog.deriveFrom(AlertRepository.alerts.value);
    unreadCount.value = entries.where((e) => !isRead(e)).length;
  }
}