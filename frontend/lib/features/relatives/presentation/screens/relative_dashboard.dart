import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../alerts/presentation/screens/alert_repository.dart'; // Dépôt partagé (AlertItem + AlertRepository)
import '../../../alerts/presentation/screens/notifications_controller.dart'; // Semaine 3 : état lu/non lu des notifications Proche

/// Espace Proche / Famille.
/// Permet à un proche de surveiller à distance les constantes de son parent patient,
/// de voir sa position GPS et de consulter l'historique des alertes déclenchées.
class RelativeDashboard extends StatelessWidget {
  const RelativeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    NotificationsController.ensureInitialized(); // Sécurise le branchement du contrôleur (idempotent)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Proche Wallan'),
        actions: [
          // Cloche de notifications avec badge du nombre de non-lues
          // (Semaine 3 : ouvre NotificationsScreen sur "/relative/notifications")
          ValueListenableBuilder<int>(
            valueListenable: NotificationsController.unreadCount,
            builder: (context, unread, _) {
              return IconButton(
                icon: Badge(
                  label: Text('$unread'),
                  isLabelVisible: unread > 0, // Cache le badge s'il n'y a rien à lire
                  child: const Icon(Icons.notifications_rounded),
                ),
                tooltip: 'Notifications',
                onPressed: () => context.push('/relative/notifications'),
              );
            },
          ),
          // Accès à l'écran Statistiques (Semaine 4)
          IconButton(
            icon: const Icon(Icons.show_chart_rounded),
            tooltip: 'Voir les statistiques',
            onPressed: () => context.push('/statistics'),
          ),
          // Déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/'),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- En-tête Proche ---
              Text(
                'Bonjour, Diallo Proche',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Vous surveillez l\'état de santé de : Mamadou Diallo',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // --- Carte de Résumé de Santé du Patient ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.heart_broken_rounded, color: Colors.green, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Santé Globale stable',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Text(
                            'Actif',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // Affichage rapide des constantes actuelles du patient
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniConst(context, '78 bpm', 'Cardiaque'),
                          _buildMiniConst(context, '36.8°C', 'Temp.'),
                          _buildMiniConst(context, '98%', 'SpO2'),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Section Localisation GPS (Simulation de Carte) ---
              Text(
                'Dernière Localisation GPS',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blueGrey.shade900 : Colors.blue.shade50,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Icône de carte d'arrière-plan en filigrane
                      Icon(Icons.map_rounded, size: 80, color: Colors.blue.withValues(alpha: 0.2)),
                      // Marqueur GPS rouge sur le centre de Conakry
                      const Positioned(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on_rounded, color: Colors.red, size: 36),
                            SizedBox(height: 4),
                            Text(
                              'Conakry, Guinée (Dernière sync : il y a 5 min)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Historique des Alertes Reçues ---
              Text(
                'Historique des alertes',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Liste connectée au dépôt partagé AlertRepository : toute nouvelle
              // alerte (y compris un SOS déclenché depuis SosScreen) apparaît ici
              // automatiquement, sans recharger l'écran manuellement.
              ValueListenableBuilder<List<AlertItem>>(                          // Écoute le dépôt partagé
                valueListenable: AlertRepository.alerts,                         // Source de données observée
                builder: (context, alertList, _) {                               // Reconstruit à chaque changement
                  if (alertList.isEmpty) {                                        // Cas d'une liste vide (bonne pratique)
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Aucune alerte pour le moment', style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return Column(                                                  // Empile toutes les cartes d'alerte
                    children: alertList.map((alert) {                             // Convertit chaque AlertItem en widget
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),                // Espace entre deux cartes
                        child: _buildAlertItem(
                          context,
                          title: alert.title,                                       // Type d'alerte (ex: "Alerte SOS manuelle")
                          value: alert.value,                                       // Valeur mesurée ou description de la cause
                          date: alert.date,                                         // Date/heure de déclenchement
                          severity: alert.isCritical ? 'Critique' : 'Avertissement', // Libellé du badge
                          isCritical: alert.isCritical,                             // Détermine la couleur du badge
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper pour générer l'affichage compact des constantes en ligne.
  Widget _buildMiniConst(BuildContext context, String val, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          val,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  /// Helper pour construire une ligne d'historique d'alertes.
  Widget _buildAlertItem(
    BuildContext context, {
    required String title, // Titre de l'alerte
    required String value, // Valeur mesurée problématique
    required String date, // Date et heure de survenue
    required String severity, // Niveau de sévérité (Critique, Avertissement)
    required bool isCritical, // Détermine le code couleur (rouge ou orange)
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.error_outline_rounded,
          color: isCritical ? Colors.red : Colors.orange,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(value),
            const SizedBox(height: 4),
            Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        // Badge de niveau de sévérité à droite
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCritical
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            severity,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isCritical ? Colors.red : Colors.orange,
            ),
          ),
        ),
      ),
    );
  }
}