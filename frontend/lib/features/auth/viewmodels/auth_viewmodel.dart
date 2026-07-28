import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI ce ViewModel ne change presque pas ?
//
// C'est le bénéfice de l'architecture MVVM + Repository Pattern :
// Le ViewModel ne sait pas SI les données viennent d'un mock, d'une API REST
// ou d'une base locale. Il appelle juste le Repository et met à jour l'état.
//
// La seule chose qui change ici : on injecte AuthRepository (réel)
// à la place de MockAuthService (simulé). Zéro changement dans la logique.
// ─────────────────────────────────────────────────────────────────────────────

/// ViewModel gérant toute la logique d'authentification.
/// Structure MVVM : lien réactif entre la Vue et le Repository.
class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    // État initial : pas de chargement, pas d'erreur, pas d'utilisateur
    return const AuthState();
  }

  // ── Auto-Login (démarrage de l'application) ────────────────────────────────
  /// Vérifie au démarrage si une session valide existe.
  ///
  /// Appelé par le SplashScreen. Si un token valide est trouvé,
  /// l'utilisateur est automatiquement connecté sans passer par le Login.
  /// Retourne le UserModel si session valide, null sinon.
  Future<UserModel?> checkExistingSession() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.tryAutoLogin();

      if (user != null) {
        state = AuthState(isLoading: false, user: user);
      } else {
        state = const AuthState(isLoading: false);
      }
      return user;
    } catch (_) {
      state = const AuthState(isLoading: false);
      return null;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  /// Tente de connecter l'utilisateur via l'API réelle.
  /// Retourne true si succès (tokens stockés + user en état), false sinon.
  Future<bool> login(String email, String password) async {
    // 1. Active le chargement et efface les messages précédents
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      // 2. Délègue au Repository qui appelle l'API et stocke les tokens
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.login(email, password);

      // 3. Succès : stocke l'utilisateur dans l'état Riverpod
      state = AuthState(isLoading: false, user: user);
      return true;
    } catch (e) {
      // 4. Échec : stocke le message d'erreur pour l'afficher dans la Vue
      state = AuthState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────
  /// Inscrit un nouvel utilisateur via l'API réelle.
  /// Retourne true si succès. Après inscription, l'utilisateur doit se connecter.
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );

      // Succès : affiche le message de succès et redirige vers Login
      state = const AuthState(
        isLoading: false,
        successMessage: 'Compte créé avec succès ! Vous pouvez maintenant vous connecter.',
      );
      return true;
    } catch (e) {
      state = AuthState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  /// Déconnecte l'utilisateur : vide les tokens locaux + invalide côté serveur.
  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout(); // Supprime les tokens locaux + appelle /auth/logout/
    state = const AuthState(); // Remet l'état à zéro → la Vue redirige vers Login
  }

  // ── Utilitaires ────────────────────────────────────────────────────────────
  /// Efface manuellement le message d'erreur (ex: quand l'utilisateur retape).
  void clearError() => state = state.copyWith(clearError: true);

  /// Efface manuellement le message de succès.
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}

/// Provider Riverpod v3 exposant l'instance unique d'AuthViewModel dans l'application.
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(() {
  return AuthViewModel();
});
