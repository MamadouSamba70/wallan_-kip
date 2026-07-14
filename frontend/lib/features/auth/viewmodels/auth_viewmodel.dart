import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../services/auth_service.dart';

/// ViewModel gérant la logique d'authentification et l'état associé de la vue.
/// Utilise la nouvelle API Notifier de Riverpod v3.
class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  /// Tente de connecter l'utilisateur avec l'email et le mot de passe saisis.
  /// Renvoie true si la connexion réussit, false sinon.
  Future<bool> login(String email, String password) async {
    // Active l'indicateur de chargement et efface les anciennes erreurs
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.login(email, password);

      // Stocke l'utilisateur authentifié
      state = AuthState(isLoading: false, user: user);
      return true;
    } catch (e) {
      // Stocke le message d'erreur si la connexion échoue
      state = AuthState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Déconnecte l'utilisateur et réinitialise l'état d'authentification.
  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = AuthState();
  }
}

/// Provider Riverpod v3 exposant l'instance unique d'AuthViewModel.
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(() {
  return AuthViewModel();
});

