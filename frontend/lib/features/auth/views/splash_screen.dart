import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI ConsumerStatefulWidget ici ?
//
// Le SplashScreen doit :
//   1. Afficher l'animation de démarrage (durée minimum 2s pour le branding)
//   2. EN PARALLÈLE, vérifier si une session JWT valide existe dans le Keystore
//   3. Rediriger intelligemment avec un TIMEOUT DE SÉCURITÉ DE 3.5s :
//      - Session valide → Dashboard du bon rôle (Admin/Patient/Proche)
//      - Pas de session / Erreur / Timeout → LoginScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Écran de démarrage intelligent de l'application Wallan.
///
/// Gère simultanément l'animation de branding et la vérification de session JWT.
/// Redirige vers le bon écran en fonction de l'état de la session sans jamais se bloquer.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ── Animation de fade-in ─────────────────────────────────────────────────
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // ── Vérification de session + redirection sécurisée ────────────────────────
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // Lance la vérification de session et le délai branding minimum en parallèle.
      // Un timeout global de 3.5 secondes garantit que l'app ne reste JAMAIS bloquée.
      final results = await Future.wait([
        ref.read(authViewModelProvider.notifier).checkExistingSession(),
        Future.delayed(const Duration(seconds: 2)),
      ]).timeout(
        const Duration(milliseconds: 3500),
        onTimeout: () => [null, null],
      );

      if (!mounted) return;

      final user = results[0] as UserModel?;

      if (user != null) {
        // ✅ Session valide → rediriger vers le bon dashboard selon le rôle
        switch (user.role) {
          case UserRole.admin:
            context.go('/admin/dashboard');
            break;
          case UserRole.patient:
            context.go('/patient/dashboard');
            break;
          case UserRole.relative:
            context.go('/relative/dashboard');
            break;
        }
      } else {
        // ❌ Pas de session → aller au Login
        context.go('/login');
      }
    } catch (e) {
      debugPrint('SplashScreen navigation error: $e');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue,
              Color(0xFF003087),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ───────────────────────────────────────────────────
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

                // ── Nom de la marque ────────────────────────────────────────
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

                // ── Sous-titre ──────────────────────────────────────────────
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

                // ── Indicateur de chargement ────────────────────────────────
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Texte de statut ─────────────────────────────────────────
                const Text(
                  'Vérification de la session...',
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
