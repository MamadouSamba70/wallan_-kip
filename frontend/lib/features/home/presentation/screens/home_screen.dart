import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/wallan_logo.dart';

/// Écran d'accueil principal (Landing Screen).
/// Permet de sélectionner le portail utilisateur correspondant (Patient, Proche, Admin).
/// Propose également des raccourcis vers la Connexion et l'Inscription.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.bgLight,
              AppTheme.primaryLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Logo & Titre de l'Application ---
                    const Center(child: WallanLogo(size: 90, showBadge: true)),
                    const SizedBox(height: 20),
                    Text(
                      'WALLAN',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 34,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bracelet Intelligent de Surveillance Médicale',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- Section Portails ---
                    Text(
                      'Accéder à votre espace',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Portail 1 : Patient
                    _buildPortalCard(
                      context,
                      title: 'Patient',
                      subtitle: 'Suivi des constantes & alertes',
                      icon: Icons.monitor_heart_outlined,
                      color: AppTheme.primaryBlue,
                      onTap: () => context.go('/login'),
                    ),
                    const SizedBox(height: 12),

                    // Portail 2 : Proche / Famille
                    _buildPortalCard(
                      context,
                      title: 'Proche / Famille',
                      subtitle: 'Surveillance à distance & urgences',
                      icon: Icons.family_restroom_rounded,
                      color: Colors.indigo,
                      onTap: () => context.go('/login'),
                    ),
                    const SizedBox(height: 12),

                    // Portail 3 : Administrateur
                    _buildPortalCard(
                      context,
                      title: 'Administrateur',
                      subtitle: 'Gestion des bracelets et des alertes',
                      icon: Icons.admin_panel_settings_outlined,
                      color: Colors.blueGrey.shade700,
                      onTap: () => context.go('/login'),
                    ),
                    const SizedBox(height: 32),

                    // --- Ligne de Séparation ---
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 16),

                    // --- Boutons Raccourcis Connexion & Inscription ---
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/login'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.primaryBlue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Connexion',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.push('/register'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Inscription',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
