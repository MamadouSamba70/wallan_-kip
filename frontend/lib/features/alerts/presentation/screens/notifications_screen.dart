import 'package:flutter/material.dart';                                // Widgets Material de base
import 'package:go_router/go_router.dart';                              // Navigation entre écrans
import '../../../alerts/presentation/screens/alert_repository.dart';    // Dépôt partagé (AlertItem + AlertRepository)
import '../../../../core/theme/app_theme.dart';                         // Palette de couleurs officielle Wallan
import 'notification_log.dart';                                         // Modèle NotificationLogEntry (miroir AlertNotificationLog)
import 'notifications_controller.dart';    

/// Écran Notifications — Espace Proche (Semaine 3).
///
/// Représente la table AlertNotificationLog du Plan de Travail (section
/// 3.5) : chaque ligne est l'envoi d'UNE alerte à UN destinataire par UN
/// canal (sms ou push), avec un statut de livraison (sent/failed/delivered).
/// Les entrées sont dérivées de AlertRepository (voir NotificationLog),
/// donc toute nouvelle alerte (ex: un SOS déclenché depuis SosScreen)
/// produit automatiquement de nouvelles notifications ici.
///
/// Pas encore connecté à GET /api/notifications/ (prévu Semaine 5, une
/// fois que Fatima aura implémenté l'envoi SMS/push réel en Semaine 4).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationsController.ensureInitialized(); // Sécurise le branchement du contrôleur
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Marque toutes les notifications visibles comme lues d'un coup
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Tout marquer comme lu',
            onPressed: () => setState(() => NotificationsController.markAllRead()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<AlertItem>>(              // Écoute le dépôt partagé
          valueListenable: AlertRepository.alerts,
          builder: (context, alertList, _) {
            // Dérive les notifications (canal + statut) à partir des alertes actuelles.
            final entries = NotificationLog.deriveFrom(alertList);

            if (entries.isEmpty) {
              return const Center(
                child: Text('Aucune notification pour le moment', style: TextStyle(color: Colors.grey)),
              );
            }

            // Regroupe par date (ex: "05 Juil 2026"), en gardant l'ordre déjà
            // trié du plus récent au plus ancien fourni par AlertRepository.
            final Map<String, List<NotificationLogEntry>> groups = {};
            for (final entry in entries) {
              final day = entry.sentAt.split(',').first.trim(); // "05 Juil 2026, 14:23" -> "05 Juil 2026"
              groups.putIfAbsent(day, () => []).add(entry);
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                for (final group in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(
                      group.key,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  for (final entry in group.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildNotificationCard(context, entry),
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Construit une carte de notification : icône du canal (SMS/push),
  /// contenu de l'alerte source, badge de statut de livraison, et mise en
  /// forme différente selon que la notification a déjà été lue ou non.
  Widget _buildNotificationCard(BuildContext context, NotificationLogEntry entry) {
    final bool unread = !NotificationsController.isRead(entry);
    final alert = entry.alert;

    // --- Icône du canal d'envoi ---
    final IconData channelIcon =
        entry.channel == NotificationChannel.sms ? Icons.sms_rounded : Icons.notifications_active_rounded;
    final String channelLabel = entry.channel == NotificationChannel.sms ? 'SMS' : 'Push';

    // --- Couleur et libellé selon le statut de livraison ---
    // Expression switch (Dart 3) : exhaustivité vérifiée à la compilation.
    final (Color statusColor, String statusLabel) = switch (entry.status) {
      NotificationDeliveryStatus.delivered => (AppTheme.successGreen, 'Livré'),
      NotificationDeliveryStatus.sent => (AppTheme.infoBlue, 'Envoyé'),
      NotificationDeliveryStatus.failed => (AppTheme.errorRed, 'Échec'),
    };

    return Card(
      color: unread ? AppTheme.primaryLight : null, // Léger fond bleu pour les non-lues, sinon couleur par défaut
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => NotificationsController.markRead(entry)), // Marque comme lue au tap
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône du canal (SMS ou push), colorée selon la sévérité de l'alerte source
              Icon(channelIcon, color: alert.isCritical ? AppTheme.errorRed : AppTheme.warningOrange, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontWeight: unread ? FontWeight.bold : FontWeight.normal, // Gras si non lue
                            ),
                          ),
                        ),
                        // Petit point bleu tant que la notification n'a pas été lue
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppTheme.secondaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Patient : ${alert.patient}', style: const TextStyle(fontSize: 13)),
                    Text(alert.value, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    // --- Ligne canal + statut de livraison + date (le cœur d'AlertNotificationLog) ---
                    Row(
                      children: [
                        // Badge du canal (SMS / Push)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            channelLabel,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge du statut de livraison
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                        const Spacer(),
                        Text(entry.sentAt, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}