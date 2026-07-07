import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Console Admin Wallan'),
        actions: [
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
              // Welcome header
              Text(
                'Bonjour, Administrateur',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Supervisez le parc de bracelets connectés et l\'état du réseau.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      title: 'Bracelets Actifs',
                      value: '124',
                      icon: Icons.watch_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      title: 'Alertes Critiques',
                      value: '3',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Actions Quick Links
              Text(
                'Actions Rapides',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enregistrement du bracelet simulé')),
                        );
                      },
                      icon: const Icon(Icons.add_to_queue_rounded),
                      label: const Text('Enregistrer bracelet'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Association de patient simulée')),
                        );
                      },
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Associer Patient'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Device List Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bracelets Récents',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Device items list
              _buildDeviceItem(
                context,
                mac: 'ESP32-E8:9F:6D:8B:12:4A',
                patient: 'Mamadou Diallo',
                status: 'Actif',
                battery: '88%',
                isConnected: true,
              ),
              const SizedBox(height: 12),
              _buildDeviceItem(
                context,
                mac: 'ESP32-A1:2C:4D:5E:6F:70',
                patient: 'Fatoumata Sow',
                status: 'Actif',
                battery: '45%',
                isConnected: true,
              ),
              const SizedBox(height: 12),
              _buildDeviceItem(
                context,
                mac: 'ESP32-B2:3D:4E:5F:6A:71',
                patient: 'Non Assigné',
                status: 'En attente',
                battery: '100%',
                isConnected: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceItem(
    BuildContext context, {
    required String mac,
    required String patient,
    required String status,
    required String battery,
    required bool isConnected,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.watch_rounded,
              color: isConnected ? theme.colorScheme.primary : Colors.grey,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mac,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Patient : $patient', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? theme.colorScheme.primary : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      battery == '100%'
                          ? Icons.battery_full_rounded
                          : Icons.battery_3_bar_rounded,
                      size: 14,
                      color: isConnected ? Colors.teal : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      battery,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
