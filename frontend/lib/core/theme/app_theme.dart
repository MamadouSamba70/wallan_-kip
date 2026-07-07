import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Charte graphique et système de design global de l'application Wallan.
/// Gère la palette de couleurs officielle ainsi que les thèmes clairs et sombres.
class AppTheme {
  // --- Palette de couleurs de la marque Wallan (Inspirée du Mockup Bleu Royal) ---
  static const Color primaryBlue = Color(0xFF0A4DA2); // Bleu royal officiel (boutons, en-têtes)
  static const Color primaryLight = Color(0xFFEBF3FC); // Fond bleu très clair pour cartes et avatars
  static const Color secondaryBlue = Color(0xFF1E88E5); // Bleu secondaire vibrant pour surbrillances

  // --- Couleurs d'état fonctionnelles ---
  static const Color errorRed = Color(0xFFD32F2F); // Rouge pour les alertes critiques
  static const Color warningOrange = Color(0xFFED6C02); // Orange pour les avertissements
  static const Color successGreen = Color(0xFF2E7D32); // Vert pour l'état Normal
  static const Color infoBlue = Color(0xFF0288D1); // Bleu pour les infos système

  // --- Couleurs d'arrière-plan ---
  static const Color bgLight = Color(0xFFF5F8FD); // Fond d'écran global bleu-gris clair (Mockup)
  static const Color cardLight = Colors.white; // Fond des cartes blanc
  static const Color bgDark = Color(0xFF0F172A); // Fond sombre ardoise (Slate-900)
  static const Color cardDark = Color(0xFF1E293B); // Cartes sombres ardoise (Slate-800)

  /// Définition complète du Thème Clair de l'application.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, // Utilisation de Material Design 3.
      brightness: Brightness.light,
      
      // Configuration des couleurs principales
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: secondaryBlue,
        error: errorRed,
        surface: cardLight,
      ),
      scaffoldBackgroundColor: bgLight,

      // Configuration de la barre supérieure (AppBar)
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryBlue),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Configuration de la typographie (Polices Google Fonts Outfit & Inter)
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),

      // Configuration du style des boutons élevés (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue, // Bouton bleu royal du mockup
          foregroundColor: Colors.white,
          elevation: 1,
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

      // Configuration des champs de saisie (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2), // Liseré bleu au focus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
        hintStyle: const TextStyle(color: Colors.black38),
      ),

      // Configuration du style des cartes (Card)
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0.5, // Ombre très douce
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
        primary: primaryBlue,
        secondary: secondaryBlue,
        error: errorRed,
        surface: cardDark,
      ),
      scaffoldBackgroundColor: bgDark,

      // Barre supérieure en mode sombre
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryBlue),
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
          backgroundColor: primaryBlue,
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
          borderSide: const BorderSide(color: primaryBlue, width: 2),
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
