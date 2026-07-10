import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Espace santé du Patient.
/// Permet au patient de visualiser ses constantes vitales actuelles et de déclencher une alerte SOS en cas d'urgence.
class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Espace Santé'),
        actions: [
          // Accès à l'écran Alertes
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            tooltip: 'Voir les alertes',
            onPressed: () => context.push('/alerts'),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- En-tête Profil du Patient ---
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.person, size: 36, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mamadou Diallo',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'Bracelet connecté • Synchronisé à l\'instant',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Bouton SOS d'Urgence Critique ---
              // Déclenche l'envoi immédiat de SMS d'alerte aux proches
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alerte SOS envoyée par SMS aux proches !'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sos_rounded, size: 32),
                    SizedBox(width: 8),
                    Text(
                      'URGENCE (SOS)',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Section des Constantes Vitales ---
              Text(
                'Dernières Mesures Vitales',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // 1. Rythme Cardiaque (BPM)
              _buildBiometricCard(
                context,
                title: 'Rythme Cardiaque',
                value: '78 bpm',
                subtitle: 'Seuil : > 100 bpm',
                icon: Icons.favorite_rounded,
                color: Colors.red.shade400,
                status: 'Normal',
              ),
              const SizedBox(height: 12),

              // 2. Température Corporelle (°C)
              _buildBiometricCard(
                context,
                title: 'Température',
                value: '36.8 °C',
                subtitle: 'Seuil : > 38.0 °C',
                icon: Icons.thermostat_rounded,
                color: Colors.orange.shade400,
                status: 'Normal',
              ),
              const SizedBox(height: 12),

              // 3. Saturation en Oxygène (SpO2)
              _buildBiometricCard(
                context,
                title: 'Saturation en Oxygène (SpO2)',
                value: '98%',
                subtitle: 'Seuil : < 92%',
                icon: Icons.opacity_rounded,
                color: Colors.blue.shade400,
                status: 'Normal',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Génère une carte de mesure biométrique claire et lisible.
  Widget _buildBiometricCard(
    BuildContext context, {
    required String title, // Nom de la mesure
    required String value, // Valeur actuelle mesurée
    required String subtitle, // Seuil d'alerte configuré
    required IconData icon, // Icône représentative
    required Color color, // Couleur thématique de l'icône
    required String status, // Normal, Critique, etc.
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icône avec fond thématique coloré
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            
            // Textes descriptifs (Titre et Seuil d'alerte)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            // Valeur mesurée actuelle et statut de santé associé
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
