import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// ViewModel gérant toute la logique d'authentification.
/// Implémente les actions Login et Register et expose l'état réactif via Riverpod.
/// Structure MVVM : ce ViewModel est le lien entre la Vue et le Service.
// ─────────────────────────────────────────────────────────────────────────────
class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    // État initial : pas de chargement, pas d'erreur, pas d'utilisateur
    return const AuthState();
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  /// Tente de connecter l'utilisateur avec les identifiants fournis.
  /// Retourne true si la connexion réussit, false sinon.
  Future<bool> login(String email, String password) async {
    // 1. Active l'indicateur de chargement et efface les messages précédents
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      // 2. Appel au service (mock ou réel)
      final authService = ref.read(authServiceProvider);
      final user = await authService.login(email, password);

      // 3. Stocke l'utilisateur authentifié et désactive le chargement
      state = AuthState(
        isLoading: false,
        user: user,
      );
      return true;
    } catch (e) {
      // 4. En cas d'erreur, stocke le message et désactive le chargement
      state = AuthState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────
  /// Inscrit un nouvel utilisateur avec les données du formulaire.
  /// Retourne true si l'inscription réussit, false sinon.
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    // 1. Active l'indicateur de chargement
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      // 2. Appel au service d'inscription
      final authService = ref.read(authServiceProvider);
      await authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );

      // 3. Inscription réussie — ne connecte PAS automatiquement, redirige vers Login
      state = const AuthState(
        isLoading: false,
        successMessage: 'Compte créé avec succès ! Vous pouvez maintenant vous connecter.',
      );
      return true;
    } catch (e) {
      // 4. En cas d'erreur, stocke le message d'erreur
      state = AuthState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  /// Déconnecte l'utilisateur et remet l'état à son état initial.
  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AuthState();
  }

  // ── Utilitaires ────────────────────────────────────────────────────────────
  /// Efface manuellement le message d'erreur (ex: quand l'utilisateur commence à retaper).
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Efface manuellement le message de succès.
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }
}

/// Provider Riverpod v3 exposant l'instance unique d'AuthViewModel dans l'application.
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(() {
  return AuthViewModel();
});
