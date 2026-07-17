import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// Écran de démarrage de l'application (Splash Screen).
/// Cet écran s'affiche au lancement de l'application, présente l'identité visuelle de Wallan
/// et redirige automatiquement l'utilisateur vers l'accueil après un court délai de 3 secondes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Contrôleur d'animation pour l'effet de fondu (Fade In)
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialisation de l'animation sur une durée de 1.5 seconde
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Définition de l'effet de fondu (de 0.0 complètement transparent à 1.0 visible)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Démarrage de l'animation
    _animationController.forward();

    // Déclenchement du délai de 3 secondes avant la redirection vers la page d'accueil
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Redirige vers la sélection du portail (HomeScreen) via go_router
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    // Libération du contrôleur d'animation pour éviter les fuites de mémoire
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Dégradé de fond bleu royal haut de gamme conforme à la nouvelle charte graphique
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue, // Bleu royal officiel
              Color(0xFF003087),   // Bleu marine plus profond
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation, // Applique l'effet de fondu
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Logo de l'application ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // --- Nom de la marque ---
                const Text(
                  'WALLAN',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 12),

                // --- Sous-titre descriptif ---
                const Text(
                  'Bracelet Intelligent de Surveillance Médicale',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 64),

                // --- Indicateur de chargement circulaire ---
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                
                // --- Texte de chargement ---
                const Text(
                  'Initialisation du système...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
