import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/api_status_banner.dart';
import '../../../../core/widgets/wallan_logo.dart';
import '../../../alerts/models/alert_model.dart';
import '../../../alerts/viewmodels/alerts_viewmodel.dart';
import '../../../alerts/presentation/screens/notifications_controller.dart';
import '../../viewmodels/patient_link_viewmodel.dart';

/// Espace Proche / Famille.
/// Permet à un proche de surveiller à distance les constantes de son parent
/// patient, de voir sa position GPS et de consulter l'historique réel des
/// alertes (GET /api/alerts/by_patient/ via AlertsViewModel).
///
/// Le patient affiché (nom, alertes) est désormais résolu dynamiquement via
/// PatientLinkViewModel (GET /api/auth/me/ + GET /api/patient-relatives/),
/// et non plus codé en dur.
class RelativeDashboard extends ConsumerWidget {
  const RelativeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final alertsState = ref.watch(alertsViewModelProvider);
    final linkState = ref.watch(patientLinkViewModelProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final patientName = linkState.patientName ?? 'Aucun patient lié';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            WallanLogo(size: 28, showBadge: false),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Espace Proche Wallan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        actions: [
          // Accès au Dashboard Statistiques
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Statistiques',
            onPressed: () => context.push('/relative/statistics'),
          ),
          // Cloche de notifications, badge dérivé en direct des vraies notifications
          IconButton(
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_rounded),
            ),
            tooltip: 'Notifications',
            onPressed: () => context.push('/relative/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.read(alertsViewModelProvider.notifier).refresh(),
            ref.read(patientLinkViewModelProvider.notifier).refresh(),
          ]),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- En-tête Proche ---
                Text(
                  'Bonjour',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Vous surveillez l\'état de santé de : $patientName',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),

                ApiStatusBanner(isFromApi: alertsState.isFromApi, errorMessage: alertsState.errorMessage),

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
                        // Affichage rapide des constantes : reste statique ici.
                        // Les vraies dernières mesures (GET /api/biometrics/{id}/)
                        // sont visibles en détail sur le Dashboard Statistiques
                        // ci-dessous — éviter un 3e appel réseau redondant sur
                        // cet écran d'accueil.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniConst(context, '78 bpm', 'Cardiaque'),
                            _buildMiniConst(context, '36.8°C', 'Temp.'),
                            _buildMiniConst(context, '98%', 'SpO2'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Raccourci vers le Dashboard Statistiques ---
                Card(
                  child: ListTile(
                    onTap: () => context.push('/relative/statistics'),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.bar_chart_rounded, color: theme.colorScheme.primary),
                    ),
                    title: const Text('Statistiques détaillées', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Évolution des constantes et analyse des alertes'),
                    trailing: const Icon(Icons.chevron_right_rounded),
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
                        Icon(Icons.map_rounded, size: 80, color: Colors.blue.withValues(alpha: 0.2)),
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

                // Branché sur AlertsViewModel (GET /api/alerts/by_patient/) :
                // toute nouvelle alerte réelle (ou un SOS déclenché depuis
                // SosScreen) apparaît ici automatiquement.
                if (alertsState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (alertsState.alerts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Aucune alerte pour le moment', style: TextStyle(color: Colors.grey)),
                  )
                else
                  Column(
                    children: alertsState.alerts.map((alert) {
                      final isCritical = alert.severity == AlertSeverity.critical;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAlertItem(
                          context,
                          title: alert.alertTypeDisplay,
                          value: alert.valueDescription(unitSuffix: alert.unit),
                          date: formatFrenchDateTime(alert.createdAt),
                          severity: isCritical ? 'Critique' : 'Avertissement',
                          isCritical: isCritical,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
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
    required String title,
    required String value,
    required String date,
    required String severity,
    required bool isCritical,
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
