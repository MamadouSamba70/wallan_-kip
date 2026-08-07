import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI cette implémentation hybride (Web + Mobile) ?
//
// On Web (Chrome/Edge/localhost), flutter_secure_storage peut se bloquer
// ou lever des erreurs WebCrypto non gérées par le navigateur.
//
// Solution robuste :
//   - Sur Web (kIsWeb == true) : Utilisation d'un stockage mémoire/session ultra-rapide (0ms)
//   - Sur Mobile (Android/iOS) : Utilisation du Keystore/Keychain chiffré AES-256
// ─────────────────────────────────────────────────────────────────────────────

class _StorageKeys {
  static const String accessToken = 'wallan_access_token';
  static const String refreshToken = 'wallan_refresh_token';
  static const String userRole = 'wallan_user_role';
  static const String userId = 'wallan_user_id';
}

/// Service de gestion des tokens JWT (compatible Web, Android, iOS, Windows).
class TokenStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Stockage en mémoire pour le Web et en fallback d'urgence
  static final Map<String, String> _inMemoryStorage = {};

  // ── Méthodes génériques sécurisées ─────────────────────────────────────────

  Future<void> _write(String key, String value) async {
    _inMemoryStorage[key] = value;
    if (kIsWeb) return;

    try {
      await _secureStorage
          .write(key: key, value: value)
          .timeout(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('TokenStorage _write fallback: $e');
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) return _inMemoryStorage[key];

    try {
      final value = await _secureStorage
          .read(key: key)
          .timeout(const Duration(seconds: 1), onTimeout: () => null);
      return value ?? _inMemoryStorage[key];
    } catch (e) {
      debugPrint('TokenStorage _read fallback: $e');
      return _inMemoryStorage[key];
    }
  }

  Future<void> _delete(String key) async {
    _inMemoryStorage.remove(key);
    if (kIsWeb) return;

    try {
      await _secureStorage
          .delete(key: key)
          .timeout(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('TokenStorage _delete fallback: $e');
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) =>
      _write(_StorageKeys.accessToken, token);

  Future<String?> readAccessToken() => _read(_StorageKeys.accessToken);

  Future<void> saveRefreshToken(String token) =>
      _write(_StorageKeys.refreshToken, token);

  Future<String?> readRefreshToken() => _read(_StorageKeys.refreshToken);

  Future<void> saveUserRole(String role) =>
      _write(_StorageKeys.userRole, role);

  Future<String?> readUserRole() => _read(_StorageKeys.userRole);

  Future<void> saveUserId(String userId) =>
      _write(_StorageKeys.userId, userId);

  Future<String?> readUserId() => _read(_StorageKeys.userId);

  Future<bool> hasValidSession() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> deleteAll() async {
    _inMemoryStorage.clear();
    await _delete(_StorageKeys.accessToken);
    await _delete(_StorageKeys.refreshToken);
    await _delete(_StorageKeys.userRole);
    await _delete(_StorageKeys.userId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Provider Riverpod de TokenStorage.
// ─────────────────────────────────────────────────────────────────────────────
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});
