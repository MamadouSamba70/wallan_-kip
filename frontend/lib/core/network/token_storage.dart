import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI flutter_secure_storage + Sécurité Fallback ?
//
// Un token JWT doit être stocké de manière sécurisée :
//   - Android : EncryptedSharedPreferences (AES-256 via Keystore)
//   - iOS     : Keychain
//   - Windows : DPAPI
//   - Web     : localStorage / Web Crypto
//
// Pour éviter tout blocage (ex: sur Web ou OS sans Keystore initialisé),
// chaque méthode est protégée par un try/catch et un timeout de 2 secondes.
// ─────────────────────────────────────────────────────────────────────────────

/// Clés utilisées pour identifier chaque valeur dans le stockage sécurisé.
class _StorageKeys {
  static const String accessToken = 'wallan_access_token';
  static const String refreshToken = 'wallan_refresh_token';
  static const String userRole = 'wallan_user_role';
  static const String userId = 'wallan_user_id';
}

/// Service de gestion sécurisée des tokens JWT de l'application Wallan.
class TokenStorage {
  /// Instance de flutter_secure_storage avec configurations multi-plateformes.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    webOptions: WebOptions(
      dbName: 'wallan_secure_storage',
      publicKey: 'wallan_app_key',
    ),
  );

  // ── Access Token ────────────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) async {
    try {
      await _storage
          .write(key: _StorageKeys.accessToken, value: token)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('TokenStorage saveAccessToken error: $e');
    }
  }

  Future<String?> readAccessToken() async {
    try {
      return await _storage
          .read(key: _StorageKeys.accessToken)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (e) {
      debugPrint('TokenStorage readAccessToken error: $e');
      return null;
    }
  }

  // ── Refresh Token ───────────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage
          .write(key: _StorageKeys.refreshToken, value: token)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('TokenStorage saveRefreshToken error: $e');
    }
  }

  Future<String?> readRefreshToken() async {
    try {
      return await _storage
          .read(key: _StorageKeys.refreshToken)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (e) {
      debugPrint('TokenStorage readRefreshToken error: $e');
      return null;
    }
  }

  // ── Métadonnées utilisateur ─────────────────────────────────────────────────

  Future<void> saveUserRole(String role) async {
    try {
      await _storage
          .write(key: _StorageKeys.userRole, value: role)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('TokenStorage saveUserRole error: $e');
    }
  }

  Future<String?> readUserRole() async {
    try {
      return await _storage
          .read(key: _StorageKeys.userRole)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (e) {
      debugPrint('TokenStorage readUserRole error: $e');
      return null;
    }
  }

  Future<void> saveUserId(String userId) async {
    try {
      await _storage
          .write(key: _StorageKeys.userId, value: userId)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('TokenStorage saveUserId error: $e');
    }
  }

  Future<String?> readUserId() async {
    try {
      return await _storage
          .read(key: _StorageKeys.userId)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (e) {
      debugPrint('TokenStorage readUserId error: $e');
      return null;
    }
  }

  // ── Vérification de session ─────────────────────────────────────────────────

  Future<bool> hasValidSession() async {
    try {
      final token = await readAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ── Nettoyage ───────────────────────────────────────────────────────────────

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('TokenStorage deleteAll error: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Provider Riverpod exposant l'instance unique de TokenStorage.
// ─────────────────────────────────────────────────────────────────────────────
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});
