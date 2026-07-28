import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI flutter_secure_storage ?
//
// Un token JWT ne doit JAMAIS être stocké dans SharedPreferences ou en clair
// dans un fichier. flutter_secure_storage utilise :
//   - Android : EncryptedSharedPreferences (via Keystore système)
//   - iOS     : Keychain (zone mémoire chiffrée gérée par le système)
//   - Windows : DPAPI (Data Protection API)
//
// Ainsi, même si un attaquant obtient accès au stockage interne de l'appareil,
// les tokens restent chiffrés et illisibles.
// ─────────────────────────────────────────────────────────────────────────────

/// Clés utilisées pour identifier chaque valeur dans le stockage sécurisé.
/// Centralisées ici pour éviter les fautes de frappe dans le code.
class _StorageKeys {
  static const String accessToken = 'wallan_access_token';
  static const String refreshToken = 'wallan_refresh_token';
  static const String userRole = 'wallan_user_role';
  static const String userId = 'wallan_user_id';
}

// ─────────────────────────────────────────────────────────────────────────────
/// Service de gestion sécurisée des tokens JWT de l'application Wallan.
///
/// Toutes les opérations sont asynchrones car elles accèdent à du stockage
/// système (Keystore/Keychain) qui peut nécessiter un accès disque chiffré.
// ─────────────────────────────────────────────────────────────────────────────
class TokenStorage {
  /// Instance de flutter_secure_storage.
  /// On utilise les options Android pour forcer le chiffrement AES-256.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // AES-256 via EncryptedSharedPreferences
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock, // Accessible après le premier déverrouillage
    ),
  );

  // ── Access Token ────────────────────────────────────────────────────────────

  /// Sauvegarde le token d'accès JWT dans le stockage sécurisé.
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _StorageKeys.accessToken, value: token);
  }

  /// Lit le token d'accès JWT. Retourne null si absent ou expiré.
  Future<String?> readAccessToken() async {
    return await _storage.read(key: _StorageKeys.accessToken);
  }

  // ── Refresh Token ───────────────────────────────────────────────────────────

  /// Sauvegarde le token de rafraîchissement JWT.
  /// Ce token a une durée de vie plus longue et permet de renouveler l'access token.
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _StorageKeys.refreshToken, value: token);
  }

  /// Lit le token de rafraîchissement JWT.
  Future<String?> readRefreshToken() async {
    return await _storage.read(key: _StorageKeys.refreshToken);
  }

  // ── Métadonnées utilisateur ─────────────────────────────────────────────────

  /// Sauvegarde le rôle de l'utilisateur (admin, patient, relative).
  /// Permet de reconstruire la session sans rappeler l'API au redémarrage.
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _StorageKeys.userRole, value: role);
  }

  /// Lit le rôle de l'utilisateur depuis le stockage sécurisé.
  Future<String?> readUserRole() async {
    return await _storage.read(key: _StorageKeys.userRole);
  }

  /// Sauvegarde l'identifiant unique de l'utilisateur.
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _StorageKeys.userId, value: userId);
  }

  /// Lit l'identifiant unique de l'utilisateur.
  Future<String?> readUserId() async {
    return await _storage.read(key: _StorageKeys.userId);
  }

  // ── Vérification de session ─────────────────────────────────────────────────

  /// Retourne true si un access token est présent (session potentiellement active).
  /// Utilisé au démarrage pour décider si on redirige vers Login ou Dashboard.
  Future<bool> hasValidSession() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Nettoyage ───────────────────────────────────────────────────────────────

  /// Supprime tous les tokens et données de session stockés.
  /// Appelé lors du logout pour garantir une déconnexion propre.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Provider Riverpod exposant l'instance unique de TokenStorage.
/// En utilisant un Provider simple (non AsyncNotifier), on garantit
/// que la même instance est partagée dans toute l'application.
// ─────────────────────────────────────────────────────────────────────────────
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});
