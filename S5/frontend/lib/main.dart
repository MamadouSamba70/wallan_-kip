import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// Point d'entrée principal de l'application Flutter.
void main() {
  runApp(
    // ProviderScope est requis pour initialiser Riverpod et gérer les états de l'application.
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// Widget racine de l'application Wallan.
/// Configure les thèmes (clair/sombre) et le système de routage global.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Utilisation de MaterialApp.router pour intégrer le système de navigation go_router.
    return MaterialApp.router(
      title: 'Wallan',
      debugShowCheckedModeBanner: false, // Désactive la bannière "DEBUG" dans le coin supérieur droit.
      
      // Configuration des thèmes graphiques
      theme: AppTheme.lightTheme, // Thème clair officiel
      darkTheme: AppTheme.darkTheme, // Thème sombre officiel
      themeMode: ThemeMode.light, // Force le thème clair pour avoir le même rendu sur tous les écrans.
      
      // Configuration de la navigation
      routerConfig: AppRouter.router, // Fichier contenant la liste des écrans et leurs chemins.
    );
  }
}
