import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tableau de bord d'administration (Console Admin).
/// Permet à un administrateur de surveiller le parc de bracelets connectés (ESP32)
/// et d'associer un bracelet à un patient spécifique.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Console Admin Wallan'),
        actions: [
          // Bouton de déconnexion menant à l'accueil
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
              // En-tête de bienvenue personnalisé
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

              // --- Section des Indicateurs Clés (KPI) ---
              Row(
                children: [
                  // KPI 1 : Nombre de bracelets actifs
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
                  // KPI 2 : Nombre d'alertes critiques actives
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

              // --- Section des Actions Rapides ---
              Text(
                'Actions Rapides',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Action 1 : Enregistrer un nouveau bracelet (MAC address, etc.)
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
                  // Action 2 : Lier un bracelet existant à un compte patient
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

              // --- Section Liste des Bracelets ---
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

              // Génération de la liste des bracelets simulés
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

  /// Génère une carte KPI (Indicateur Clé de Performance).
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

  /// Génère un élément individuel de la liste des bracelets.
  Widget _buildDeviceItem(
    BuildContext context, {
    required String mac, // Adresse physique MAC du bracelet
    required String patient, // Nom du patient assigné
    required String status, // Statut du bracelet (Actif, Inactif, etc.)
    required String battery, // Niveau de batterie du bracelet
    required bool isConnected, // Statut de connexion Bluetooth
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icône de montre connectée (colorée si connectée, grise sinon)
            Icon(
              Icons.watch_rounded,
              color: isConnected ? theme.colorScheme.primary : Colors.grey,
              size: 36,
            ),
            const SizedBox(width: 16),
            
            // Détails du bracelet (Adresse MAC et Patient lié)
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
            
            // Colonne de droite : Statut textuel et Niveau de batterie
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Badge de statut
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
                // Icône de batterie dynamique avec pourcentage
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
