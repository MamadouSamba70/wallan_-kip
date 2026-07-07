import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Charte graphique et système de design global de l'application Wallan.
/// Gère la palette de couleurs officielle ainsi que les thèmes clairs et sombres.
class AppTheme {
  // --- Palette de couleurs de la marque Wallan ---
  static const Color primaryTeal = Color(0xFF008080); // Vert médical de signature (Teal)
  static const Color primaryLight = Color(0xFFE6F2F2); // Couleur de fond claire accentuée
  static const Color secondaryTeal = Color(0xFF00A8A8); // Couleur secondaire pour les surbrillances et accents

  // --- Couleurs d'état fonctionnelles ---
  static const Color errorRed = Color(0xFFD32F2F); // Rouge pour les alertes critiques et erreurs
  static const Color warningOrange = Color(0xFFED6C02); // Orange pour les avertissements modérés
  static const Color successGreen = Color(0xFF2E7D32); // Vert pour les états stables et réussites
  static const Color infoBlue = Color(0xFF0288D1); // Bleu pour les informations système

  // --- Couleurs d'arrière-plan ---
  static const Color bgLight = Color(0xFFF4F7F6); // Fond d'écran global pour le mode clair
  static const Color cardLight = Colors.white; // Fond des cartes pour le mode clair
  static const Color bgDark = Color(0xFF0B1414); // Fond d'écran global pour le mode sombre
  static const Color cardDark = Color(0xFF132222); // Fond des cartes pour le mode sombre

  /// Définition complète du Thème Clair de l'application.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, // Utilisation de Material Design 3 pour des composants modernes.
      brightness: Brightness.light,
      
      // Configuration des couleurs principales pour les widgets
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: secondaryTeal,
        error: errorRed,
        surface: cardLight,
      ),
      scaffoldBackgroundColor: bgLight,

      // Configuration de la barre supérieure (AppBar)
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0, // Supprime l'ombre sous l'app bar.
        centerTitle: true, // Titre centré horizontalement.
        iconTheme: IconThemeData(color: primaryTeal),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Configuration de la typographie (Polices Google Fonts)
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        // Police pour les grands titres
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        // Police pour les titres intermédiaires
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        // Police pour les textes importants
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.black87,
        ),
        // Police pour les petits textes secondaires
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),

      // Configuration du style des boutons élevés (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal, // Couleur de fond
          foregroundColor: Colors.white, // Couleur du texte
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Angles arrondis des boutons
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Configuration du style des champs de texte de formulaires (TextField / TextFormField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        // Bordure générale par défaut
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        // Bordure quand le champ est activé mais pas sélectionné
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        // Bordure quand l'utilisateur clique sur le champ
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        // Bordure en cas d'erreur de validation
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
        hintStyle: const TextStyle(color: Colors.black38),
      ),

      // Configuration du style des cartes (Card)
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Angles arrondis des cartes
        ),
      ),
    );
  }

  /// Définition complète du Thème Sombre de l'application.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Configuration des couleurs principales adaptées au mode sombre
      colorScheme: const ColorScheme.dark(
        primary: primaryTeal,
        secondary: secondaryTeal,
        error: errorRed,
        surface: cardDark,
      ),
      scaffoldBackgroundColor: bgDark,

      // Barre supérieure en mode sombre
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryTeal),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Typographie adaptée pour assurer un bon contraste en mode sombre
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white54,
        ),
      ),

      // Boutons en mode sombre
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Champs de saisie en mode sombre
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
        hintStyle: const TextStyle(color: Colors.white30),
      ),

      // Cartes en mode sombre
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
