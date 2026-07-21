import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/admin_stats_model.dart';
import '../../viewmodels/admin_dashboard_viewmodel.dart';
import '../widgets/stat_card.dart';

/// Écran principal du Dashboard Administrateur en architecture MVVM.
/// Propose une vue synthétique des indicateurs clés (Patients, Bracelets, Alertes actives, Alertes critiques)
/// ainsi qu'une navigation fonctionnelle vers les autres modules du système Wallan.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardViewModelProvider);
    final viewModel = ref.read(adminDashboardViewModelProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Console Admin Wallan'),
        centerTitle: false,
        actions: [
          // Bouton Rafraîchir les données simulées
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rafraîchir les données',
            onPressed: () => viewModel.refresh(),
          ),
          // Bouton Déconnexion
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Déconnexion',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Déconnexion de la session Administrateur'),
                  duration: Duration(seconds: 2),
                ),
              );
              context.go('/');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryBlue),
                    SizedBox(height: 16),
                    Text('Chargement des statistiques...'),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => viewModel.refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- En-tête de bienvenue ---
                      _buildHeader(context),
                      const SizedBox(height: 20),

                      // --- Affichage d'erreur éventuel ---
                      if (state.errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.errorRed),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.errorRed),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: const TextStyle(color: AppTheme.errorRed),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // --- Section Cartes Statistiques (4 cartes demandées) ---
                      Text(
                        'Aperçu du Système',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatGrid(context, state.stats),
                      const SizedBox(height: 24),

                      // --- Section Actions Rapides & Navigation ---
                      Text(
                        'Actions Rapides & Navigation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActions(context),
                      const SizedBox(height: 28),

                      // --- Section Liste des Bracelets / Appareils sous supervision ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bracelets Connectés Récents',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Affichage de la liste complète des bracelets'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.list_alt_rounded, size: 18),
                            label: const Text('Voir tout'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDeviceList(context, state.stats.recentDevices),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// Widget de salutations personnalisé pour l'admin
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, Administrateur 👋',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Supervision du réseau et des bracelets en temps réel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grille affichant les 4 cartes statistiques clés demandées dans les spécifications
  Widget _buildStatGrid(BuildContext context, AdminStatsModel stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 1. Carte : Nombre de patients
        StatCard(
          title: 'Patients Inscrits',
          value: '${stats.patientCount}',
          subtitle: 'Patients suivis',
          icon: Icons.people_alt_rounded,
          iconColor: AppTheme.primaryBlue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gestion de ${stats.patientCount} patients')),
            );
          },
        ),

        // 2. Carte : Nombre de bracelets
        StatCard(
          title: 'Bracelets Actifs',
          value: '${stats.braceletCount}',
          subtitle: 'Bracelets gérés',
          icon: Icons.watch_rounded,
          iconColor: AppTheme.secondaryBlue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Supervision de ${stats.braceletCount} bracelets')),
            );
          },
        ),

        // 3. Carte : Alertes actives
        StatCard(
          title: 'Alertes Actives',
          value: '${stats.activeAlertsCount}',
          subtitle: 'Avis en cours',
          icon: Icons.notifications_active_rounded,
          iconColor: AppTheme.warningOrange,
          onTap: () => context.go('/alerts'),
        ),

        // 4. Carte : Alertes critiques
        StatCard(
          title: 'Alertes Critiques',
          value: '${stats.criticalAlertsCount}',
          subtitle: 'Traitement urgent',
          icon: Icons.warning_amber_rounded,
          iconColor: AppTheme.errorRed,
          onTap: () => context.go('/sos'),
        ),
      ],
    );
  }

  /// Range d'actions rapides et de raccourcis de navigation
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showRegisterDeviceDialog(context);
                },
                icon: const Icon(Icons.add_to_queue_rounded, size: 20),
                label: const Text('Nouveau Bracelet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/alerts'),
                icon: const Icon(Icons.notifications_active_outlined, size: 20),
                label: const Text('Voir Alertes'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/sos'),
                icon: const Icon(Icons.sos_rounded, color: AppTheme.errorRed, size: 20),
                label: const Text('Centre Urgences SOS', style: TextStyle(color: AppTheme.errorRed)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.errorRed),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Dialogue de simulation pour l'enregistrement d'un nouveau bracelet
  void _showRegisterDeviceDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enregistrer un Bracelet ESP32'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Saisissez l\'adresse MAC du bracelet :'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'ex: ESP32-F4:12:8A:99:3B:11',
                prefixIcon: Icon(Icons.qr_code_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final mac = controller.text.trim();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(mac.isNotEmpty
                      ? 'Bracelet $mac enregistré avec succès !'
                      : 'Nouveau bracelet généré et ajouté en attente.'),
                ),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  /// Génère la liste visuelle des dispositifs connectés
  Widget _buildDeviceList(BuildContext context, List<AdminDeviceModel> devices) {
    if (devices.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Aucun bracelet enregistré pour le moment.'),
        ),
      );
    }

    return Column(
      children: devices.map((device) => _buildDeviceCard(context, device)).toList(),
    );
  }

  /// Carte individuelle pour chaque bracelet connecté
  Widget _buildDeviceCard(BuildContext context, AdminDeviceModel device) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: device.isConnected
                  ? AppTheme.primaryLight
                  : Colors.grey.shade100,
              child: Icon(
                Icons.watch_rounded,
                color: device.isConnected
                    ? AppTheme.primaryBlue
                    : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.macAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        device.patientName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: device.isConnected
                        ? AppTheme.successGreen.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    device.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: device.isConnected
                          ? AppTheme.successGreen
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Badge batterie
                Row(
                  children: [
                    Icon(
                      device.batteryLevel > 20
                          ? Icons.battery_charging_full_rounded
                          : Icons.battery_alert_rounded,
                      size: 14,
                      color: device.batteryLevel > 20
                          ? Colors.teal
                          : AppTheme.errorRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${device.batteryLevel}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: device.batteryLevel > 20
                            ? Colors.black87
                            : AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
