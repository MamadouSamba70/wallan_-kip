import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/admin_stats_model.dart';
import '../../viewmodels/admin_dashboard_viewmodel.dart';
import '../widgets/stat_card.dart';
import '../widgets/simulated_line_chart.dart';
import '../widgets/simulated_bar_chart.dart';
import '../../../patients/presentation/screens/patient_list_screen.dart';
import '../../../alerts/presentation/screens/admin_alert_list_screen.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';

/// Console d'Administration complète du Projet Wallan (Semaine 3).
/// Architecture MVVM réactive, intégration responsive multi-écrans (Desktop/Tablette/Mobile),
/// graphiques simulés de télémétrie et prêt pour la connexion API Django.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardViewModelProvider);
    final viewModel = ref.read(adminDashboardViewModelProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;

    final isWideScreen = screenWidth >= 850;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rafraîchir les données',
            onPressed: () => viewModel.refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Déconnexion',
            onPressed: () async {
              // Vrai logout : supprime les tokens JWT et invalide la session côté serveur
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: isWideScreen
          ? Row(
              children: [
                // Rail de navigation pour grands écrans (Desktop / Tablette)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: AppTheme.primaryBlue, size: 28),
                  unselectedIconTheme: IconThemeData(color: Colors.grey.shade600),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_rounded),
                      label: Text('Aperçu'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_alt_rounded),
                      label: Text('Patients'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.notifications_active_rounded),
                      label: Text('Alertes'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.insights_rounded),
                      label: Text('Analytiques'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: _buildBodyTab(_selectedIndex, state, viewModel, isWideScreen),
                ),
              ],
            )
          : _buildBodyTab(_selectedIndex, state, viewModel, isWideScreen),
      bottomNavigationBar: !isWideScreen
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: AppTheme.primaryBlue,
              unselectedItemColor: Colors.grey.shade600,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Aperçu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_alt_rounded),
                  label: 'Patients',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_active_rounded),
                  label: 'Alertes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.insights_rounded),
                  label: 'Analytiques',
                ),
              ],
            )
          : null,
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Console Admin Wallan';
      case 1:
        return 'Gestion des Patients';
      case 2:
        return 'Supervision des Alertes';
      case 3:
        return 'Analytiques & Télémétrie';
      default:
        return 'Admin Wallan';
    }
  }

  Widget _buildBodyTab(int index, state, viewModel, bool isWideScreen) {
    switch (index) {
      case 0:
        return _buildOverviewTab(context, state, viewModel, isWideScreen);
      case 1:
        return const PatientListScreen();
      case 2:
        return const AdminAlertListScreen();
      case 3:
        return _buildAnalyticsTab(context);
      default:
        return _buildOverviewTab(context, state, viewModel, isWideScreen);
    }
  }

  /// Onglet 0 : Vue d'ensemble du Dashboard Admin
  Widget _buildOverviewTab(BuildContext context, state, viewModel, bool isWideScreen) {
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            SizedBox(height: 16),
            Text('Chargement du Dashboard...'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isWideScreen ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de bienvenue
            _buildHeader(context),
            const SizedBox(height: 20),

            // Message d'erreur si présent
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

            // --- Section Cartes Statistiques Clés ---
            Text(
              'Aperçu du Système',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatGrid(context, state.stats, isWideScreen),
            const SizedBox(height: 24),

            // --- Section Actions Rapides ---
            Text(
              'Actions Rapides & Supervision',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 28),

            // --- Section Graphiques Simulés (Jeudi) ---
            Text(
              'Télémétrie & Historique des Événements (Graphiques Simulés)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),

            if (isWideScreen)
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SimulatedLineChart(
                      title: 'Fréquence Cardiaque Moyenne (24h)',
                      subtitle: 'Évolution globale sur l\'ensemble du réseau',
                      dataPoints: [72, 74, 76, 80, 85, 82, 78, 75, 76, 74],
                      labels: ['00h', '03h', '06h', '09h', '12h', '15h', '18h', '21h', '24h'],
                      lineColor: AppTheme.primaryBlue,
                      unit: 'BPM',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: SimulatedBarChart(
                      title: 'Distribution des Alertes (Semaine)',
                      subtitle: 'Vérification par catégorie d\'incident',
                      dataGroups: [
                        BarChartDataGroup(label: 'SpO2', value: 14, color: AppTheme.errorRed),
                        BarChartDataGroup(label: 'Pouls', value: 9, color: AppTheme.warningOrange),
                        BarChartDataGroup(label: 'SOS', value: 6, color: AppTheme.errorRed),
                        BarChartDataGroup(label: 'Batt.', value: 12, color: AppTheme.secondaryBlue),
                        BarChartDataGroup(label: 'Net.', value: 4, color: Colors.teal),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              const SimulatedLineChart(
                title: 'Fréquence Cardiaque Moyenne (24h)',
                subtitle: 'Évolution globale sur l\'ensemble du réseau',
                dataPoints: [72, 74, 76, 80, 85, 82, 78, 75, 76, 74],
                labels: ['00h', '03h', '06h', '09h', '12h', '15h', '18h', '21h', '24h'],
                lineColor: AppTheme.primaryBlue,
                unit: 'BPM',
              ),
              const SizedBox(height: 16),
              const SimulatedBarChart(
                title: 'Distribution des Alertes (Semaine)',
                subtitle: 'Vérification par catégorie d\'incident',
                dataGroups: [
                  BarChartDataGroup(label: 'SpO2', value: 14, color: AppTheme.errorRed),
                  BarChartDataGroup(label: 'Pouls', value: 9, color: AppTheme.warningOrange),
                  BarChartDataGroup(label: 'SOS', value: 6, color: AppTheme.errorRed),
                  BarChartDataGroup(label: 'Batt.', value: 12, color: AppTheme.secondaryBlue),
                  BarChartDataGroup(label: 'Net.', value: 4, color: Colors.teal),
                ],
              ),
            ],
            const SizedBox(height: 28),

            // --- Section Bracelets Récent ---
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
                    setState(() => _selectedIndex = 1); // Basculer vers l'onglet patients
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Voir tous les patients'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDeviceList(context, state.stats.recentDevices),
          ],
        ),
      ),
    );
  }

  /// Header de salutation avec style moderne
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

  /// Grille de statistiques clés adaptative
  Widget _buildStatGrid(BuildContext context, AdminStatsModel stats, bool isWideScreen) {
    return GridView.count(
      crossAxisCount: isWideScreen ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isWideScreen ? 1.4 : 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          title: 'Patients Inscrits',
          value: '${stats.patientCount}',
          subtitle: 'Patients suivis',
          icon: Icons.people_alt_rounded,
          iconColor: AppTheme.primaryBlue,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        StatCard(
          title: 'Bracelets Actifs',
          value: '${stats.braceletCount}',
          subtitle: 'Bracelets gérés',
          icon: Icons.watch_rounded,
          iconColor: AppTheme.secondaryBlue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Supervision de ${stats.braceletCount} bracelets actifs')),
            );
          },
        ),
        StatCard(
          title: 'Alertes Actives',
          value: '${stats.activeAlertsCount}',
          subtitle: 'Avis en cours',
          icon: Icons.notifications_active_rounded,
          iconColor: AppTheme.warningOrange,
          onTap: () => setState(() => _selectedIndex = 2),
        ),
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

  /// Rangée d'actions rapides
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showRegisterDeviceDialog(context),
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
                onPressed: () => setState(() => _selectedIndex = 1),
                icon: const Icon(Icons.people_alt_outlined, size: 20),
                label: const Text('Liste Patients'),
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
                onPressed: () => setState(() => _selectedIndex = 2),
                icon: const Icon(Icons.notifications_active_outlined, size: 20),
                label: const Text('Gestion Alertes'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.warningOrange),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/sos'),
                icon: const Icon(Icons.sos_rounded, color: AppTheme.errorRed, size: 20),
                label: const Text('Centre Urgences', style: TextStyle(color: AppTheme.errorRed)),
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

  /// Dialogue pour enregistrer un bracelet ESP32
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

  /// Liste des dispositifs sous supervision
  Widget _buildDeviceList(BuildContext context, List<AdminDeviceModel> devices) {
    if (devices.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Aucun bracelet enregistré.'),
        ),
      );
    }

    return Column(
      children: devices.map((device) => _buildDeviceCard(context, device)).toList(),
    );
  }

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

  /// Onglet 3 : Analytiques & Télémétrie avec moniteur API Backend
  Widget _buildAnalyticsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut de connexion API — mis à jour dynamiquement selon isFromApi
          Builder(builder: (context) {
            final dashState = ref.watch(adminDashboardViewModelProvider);
            final isConnected = dashState.isFromApi;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isConnected
                    ? AppTheme.successGreen.withValues(alpha: 0.08)
                    : AppTheme.warningOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isConnected
                      ? AppTheme.successGreen.withValues(alpha: 0.4)
                      : AppTheme.warningOrange.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: isConnected ? AppTheme.successGreen : AppTheme.warningOrange,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected
                              ? '✅ API Django connectée — Données en direct'
                              : '⚠️ Mode fallback — Backend non joignable',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isConnected ? AppTheme.successGreen : AppTheme.warningOrange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isConnected
                              ? 'GET /api/admin/dashboard/ → ${dashState.stats.patientCount} patients, ${dashState.stats.braceletCount} bracelets'
                              : 'Endpoint : http://10.0.2.2:8000/api/admin/dashboard/',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          const SimulatedLineChart(
            title: 'Tendance Saturation en Oxygène (SpO2 %)',
            subtitle: 'Moyenne globale des patients suivis',
            dataPoints: [98, 97, 98, 99, 97, 98, 98, 99],
            labels: ['00h', '04h', '08h', '12h', '16h', '20h', '24h'],
            lineColor: Colors.teal,
            unit: '%',
          ),
          const SizedBox(height: 16),

          const SimulatedLineChart(
            title: 'Température Corporelle (°C)',
            subtitle: 'Moyenne réseau sur 24 heures',
            dataPoints: [36.5, 36.6, 36.7, 36.8, 36.6, 36.5, 36.6],
            labels: ['00h', '04h', '08h', '12h', '16h', '20h', '24h'],
            lineColor: AppTheme.warningOrange,
            unit: '°C',
          ),
        ],
      ),
    );
  }
}
