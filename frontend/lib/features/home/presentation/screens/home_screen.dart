import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Écran d'accueil principal (Landing Screen).
/// Permet de sélectionner le portail utilisateur correspondant (Patient, Proche, Admin).
/// Propose également des raccourcis vers la Connexion et l'Inscription.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupération des informations sur le thème actuel
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Logo & Titre de l'Application ---
                Icon(
                  Icons.health_and_safety_rounded, // Icône de santé de signature
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'WALLAN',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bracelet Intelligent de Surveillance Médicale',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 48),

                // --- Section Portails ---
                Text(
                  'Portails Utilisateurs (Simulés)',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Portail 1 : Patient
                _buildPortalCard(
                  context,
                  title: 'Patient',
                  subtitle: 'Suivi des constantes & alertes',
                  icon: Icons.person_rounded,
                  color: theme.colorScheme.primary,
                  onTap: () => context.push('/patient/dashboard'), // Redirige vers le dashboard patient
                ),
                const SizedBox(height: 16),
                
                // Portail 2 : Proche / Famille
                _buildPortalCard(
                  context,
                  title: 'Proche / Famille',
                  subtitle: 'Surveillance à distance & urgences',
                  icon: Icons.family_restroom_rounded,
                  color: Colors.indigo,
                  onTap: () => context.push('/relative/dashboard'), // Redirige vers le dashboard proche
                ),
                const SizedBox(height: 16),
                
                // Portail 3 : Administrateur
                _buildPortalCard(
                  context,
                  title: 'Administrateur',
                  subtitle: 'Gestion des bracelets et des alertes',
                  icon: Icons.admin_panel_settings_rounded,
                  color: Colors.blueGrey,
                  onTap: () => context.push('/admin/dashboard'), // Redirige vers le dashboard admin
                ),
                const SizedBox(height: 32),

                // --- Ligne de Séparation ---
                const Divider(),
                const SizedBox(height: 16),

                // --- Boutons Raccourcis Connexion & Inscription ---
                Row(
                  children: [
                    // Bouton de connexion
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/login'), // Navigue vers l'écran de Login
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Connexion'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Bouton d'inscription
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push('/register'), // Navigue vers l'écran de Register
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Inscription'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget helper pour générer de belles cartes d'accès aux portails.
  Widget _buildPortalCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap, // Action déclenchée au clic
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Conteneur de l'icône avec fond légèrement transparent
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              // Textes d'information du portail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              // Flèche indiquant la possibilité de cliquer
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
