import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/token_storage.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI un Repository entre le ViewModel et l'ApiClient ?
//
// MVVM strict : ViewModel ne doit jamais manipuler Dio directement.
// Le Repository est la couche qui :
//   1. Appelle l'API via ApiClient
//   2. Transforme le JSON en modèles Dart
//   3. Sauvegarde les tokens dans TokenStorage
//   4. Traduit les DioException en messages utilisateur lisibles
//
// Le ViewModel reçoit soit un UserModel (succès) soit une Exception (échec).
// Il ne sait pas si c'est un appel réseau, un mock ou une base locale.
// ─────────────────────────────────────────────────────────────────────────────

/// Repository d'authentification — couche d'accès aux données.
///
/// Implémente le contrat [AuthService] existant pour rester compatible
/// avec le ViewModel actuel sans le modifier.
class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository({
    required this._apiClient,
    required this._tokenStorage,
  });

  // ── Login ──────────────────────────────────────────────────────────────────
  /// Connecte l'utilisateur via POST /api/auth/login/.
  ///
  /// Flux :
  /// 1. Appelle l'API avec {email, password}
  /// 2. Reçoit {access, refresh, user}
  /// 3. Stocke les deux tokens dans le Keystore/Keychain
  /// 4. Retourne le UserModel pour le ViewModel
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      // ── Parsing de la réponse ────────────────────────────────────────────
      final authResponse = AuthResponseModel.fromJson(response.data!);

      // ── Persistance des tokens ────────────────────────────────────────────
      // On sauvegarde IMMÉDIATEMENT les tokens avant de retourner le user.
      // Si on le fait après, un rechargement de page entre les deux perdrait la session.
      await Future.wait([
        _tokenStorage.saveAccessToken(authResponse.accessToken),
        _tokenStorage.saveRefreshToken(authResponse.refreshToken),
        _tokenStorage.saveUserId(authResponse.user.id),
        _tokenStorage.saveUserRole(authResponse.user.role),
      ]);

      // ── Construction du UserModel ─────────────────────────────────────────
      return UserModel(
        id: authResponse.user.id,
        email: authResponse.user.email,
        name: authResponse.user.name,
        phone: authResponse.user.phone,
        role: UserRoleExtension.fromString(authResponse.user.role),
      );
    } on DioException catch (e) {
      // Traduit les erreurs réseau/HTTP en messages lisibles
      throw Exception(_parseDioError(e));
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────
  /// Inscrit un nouvel utilisateur via POST /api/auth/register/.
  ///
  /// Retourne void : après inscription, l'utilisateur doit se connecter manuellement.
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'password': password,
          'role': role,
        },
      );
      // L'inscription réussie retourne 201 Created — pas besoin de parser la réponse
    } on DioException catch (e) {
      throw Exception(_parseDioError(e));
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  /// Déconnecte l'utilisateur : invalide le token côté serveur et vide le stockage local.
  Future<void> logout() async {
    try {
      // Tente d'invalider le refresh token côté serveur
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post<void>(
          ApiEndpoints.logout,
          data: {'refresh': refreshToken},
        );
      }
    } catch (_) {
      // Si l'API logout échoue (ex: token déjà expiré), on continue quand même
      // la déconnexion locale. L'utilisateur ne doit pas rester bloqué.
    } finally {
      // Suppression garantie des tokens locaux dans tous les cas
      await _tokenStorage.deleteAll();
    }
  }

  // ── Auto-Login ─────────────────────────────────────────────────────────────
  /// Vérifie si une session valide existe au démarrage de l'app.
  ///
  /// Si oui, reconstruit le UserModel depuis les données stockées localement
  /// sans rappeler l'API (meilleure UX, fonctionne hors ligne).
  Future<UserModel?> tryAutoLogin() async {
    final hasSession = await _tokenStorage.hasValidSession();
    if (!hasSession) return null;

    final userId = await _tokenStorage.readUserId();
    final userRole = await _tokenStorage.readUserRole();

    if (userId == null || userRole == null) {
      await _tokenStorage.deleteAll();
      return null;
    }

    // Reconstruction minimale du UserModel depuis le stockage local.
    // Un appel à GET /api/auth/profile/ pourrait enrichir ces données si nécessaire.
    return UserModel(
      id: userId,
      email: '', // Email non stocké localement (pas nécessaire pour la navigation)
      name: '',  // Nom non stocké localement
      role: UserRoleExtension.fromString(userRole),
    );
  }

  // ── Gestion des erreurs ────────────────────────────────────────────────────
  /// Traduit une DioException en message d'erreur lisible par l'utilisateur.
  ///
  /// Ordre de priorité :
  /// 1. Message de l'API Django (le plus précis)
  /// 2. Message basé sur le type d'erreur Dio (réseau, timeout, etc.)
  String _parseDioError(DioException e) {
    // ── Erreur avec réponse HTTP (4xx, 5xx) ──────────────────────────────────
    if (e.response?.data != null && e.response!.data is Map<String, dynamic>) {
      final apiError = ApiErrorModel.fromJson(
        e.response!.data as Map<String, dynamic>,
      );
      return apiError.message;
    }

    // ── Erreurs sans réponse (problèmes réseau) ───────────────────────────────
    return switch (e.type) {
      DioExceptionType.connectionTimeout =>
        'Connexion trop lente. Vérifiez votre réseau.',
      DioExceptionType.receiveTimeout =>
        'Le serveur met trop de temps à répondre.',
      DioExceptionType.sendTimeout =>
        'Envoi des données impossible. Vérifiez votre réseau.',
      DioExceptionType.connectionError =>
        'Impossible de joindre le serveur. Vérifiez que le backend est démarré.',
      DioExceptionType.badResponse => switch (e.response?.statusCode) {
          400 => 'Données invalides. Vérifiez vos informations.',
          401 => 'Email ou mot de passe incorrect.',
          403 => 'Accès refusé. Vous n\'avez pas les droits nécessaires.',
          404 => 'Service introuvable. Contactez l\'administrateur.',
          422 => 'Données non conformes. Vérifiez le formulaire.',
          500 => 'Erreur interne du serveur. Réessayez plus tard.',
          503 => 'Service temporairement indisponible.',
          _ => 'Erreur serveur (${e.response?.statusCode}). Réessayez.',
        },
      _ => 'Une erreur inattendue est survenue. Réessayez.',
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Provider Riverpod du AuthRepository.
///
/// On injecte apiClientProvider et tokenStorageProvider via ref.watch().
/// Riverpod gère automatiquement les dépendances et recrée le repository
/// si l'une de ses dépendances change (ex: URL backend modifiée en dev).
// ─────────────────────────────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
