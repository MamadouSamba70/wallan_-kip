import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'api_endpoints.dart';
import 'token_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI cette architecture pour l'ApiClient ?
//
// 1. SÉPARATION DES RESPONSABILITÉS :
//    - ApiClient ne gère QUE la communication HTTP
//    - TokenStorage gère QUE le stockage des tokens
//    - Les intercepteurs gèrent QUE les cross-cutting concerns (auth, logs)
//
// 2. INTERCEPTEUR JWT (pattern classique) :
//    - onRequest  → injecte le Bearer token dans chaque requête
//    - onError    → intercepte les 401 pour tenter un refresh (préparé)
//    - onResponse → hook disponible pour logging ou transformations globales
//
// 3. SINGLETON via Riverpod :
//    - Une seule instance d'ApiClient dans toute l'app (économie mémoire)
//    - Accès depuis n'importe quel Repository via ref.read(apiClientProvider)
// ─────────────────────────────────────────────────────────────────────────────

/// Client HTTP central de l'application Wallan.
/// Configure Dio avec l'URL de base, les timeouts, les headers et les intercepteurs.
class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiClient({required this._tokenStorage, String? overrideBaseUrl}) {
    // ── URL de base ──────────────────────────────────────────────────────────
    // kIsWeb détecte si l'app tourne dans un navigateur (Flutter Web).
    // Sur émulateur Android, 10.0.2.2 pointe vers localhost de la machine hôte.
    final baseUrl =
        overrideBaseUrl ?? (kIsWeb ? ApiEndpoints.webBaseUrl : ApiEndpoints.baseUrl);

    // ── Configuration Dio ────────────────────────────────────────────────────
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiEndpoints.connectTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── Intercepteur 1 : JWT Auth ────────────────────────────────────────────
    // Injecte automatiquement le Bearer token dans chaque requête sortante.
    // Si un 401 est reçu, on peut y brancher la logique de refresh ici.
    _dio.interceptors.add(
      InterceptorsWrapper(
        // INJECTION DU TOKEN : appelé avant chaque requête
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            // Le header Authorization suit le standard RFC 6750 (Bearer Token)
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },

        // GESTION DES ERREURS : intercepte les réponses d'erreur HTTP
        onError: (DioException error, handler) async {
          // ── 401 Unauthorized → Token expiré ou invalide ──────────────────
          if (error.response?.statusCode == 401) {
            // TODO Semaine 5 : implémenter le refresh token automatique ici
            // Pour l'instant, on supprime la session et on retourne l'erreur
            await _tokenStorage.deleteAll();
          }
          return handler.next(error);
        },

        // HOOK POST-RÉPONSE : disponible pour transformations globales
        onResponse: (response, handler) {
          return handler.next(response);
        },
      ),
    );

    // ── Intercepteur 2 : Logger HTTP (mode debug uniquement) ────────────────
    // PrettyDioLogger affiche chaque requête/réponse de manière lisible dans
    // la console. Désactivé en production pour éviter les fuites d'information.
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,   // Affiche les headers de la requête
          requestBody: true,     // Affiche le corps de la requête
          responseBody: true,    // Affiche le corps de la réponse
          responseHeader: false, // Cache les headers de réponse (trop verbeux)
          error: true,           // Affiche les erreurs en rouge
          compact: false,        // Format étendu pour meilleure lisibilité
          maxWidth: 120,         // Limite la largeur des logs
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MÉTHODES HTTP GÉNÉRIQUES
  // Chaque méthode est typée avec <T> pour permettre la désérialisation
  // automatique du corps de la réponse vers n'importe quel type Dart.
  // ─────────────────────────────────────────────────────────────────────────

  /// Requête GET — pour récupérer des ressources (lecture seule).
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Requête POST — pour créer une ressource ou s'authentifier.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Requête PUT — pour mettre à jour intégralement une ressource.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    return await _dio.put<T>(path, data: data, options: options);
  }

  /// Requête PATCH — pour mettre à jour partiellement une ressource.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    return await _dio.patch<T>(path, data: data, options: options);
  }

  /// Requête DELETE — pour supprimer une ressource.
  Future<Response<T>> delete<T>(
    String path, {
    Options? options,
  }) async {
    return await _dio.delete<T>(path, options: options);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Provider global du client API.
///
/// On utilise ref.watch(tokenStorageProvider) pour injecter le TokenStorage
/// dans l'ApiClient. Ainsi, si le TokenStorage change, l'ApiClient est
/// automatiquement reconstruit (principe de réactivité Riverpod).
// ─────────────────────────────────────────────────────────────────────────────
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: tokenStorage);
});
