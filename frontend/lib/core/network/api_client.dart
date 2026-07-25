import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';

/// Client réseau HTTP personnalisé s'appuyant sur la bibliothèque `Dio`.
/// Prêt pour l'interconnexion future avec le backend Django du projet Wallan.
class ApiClient {
  late final Dio _dio;

  ApiClient({String? overrideBaseUrl}) {
    final baseUrl = overrideBaseUrl ?? (kIsWeb ? ApiEndpoints.webBaseUrl : ApiEndpoints.baseUrl);

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

    // Ajout d'interceptors pour le débogage et l'injection éventuelle de jetons Bearer
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            print('🌐 [API Request] ${options.method} ${options.uri}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('✅ [API Response] ${response.statusCode} from ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            print('⚠️ [API Error] ${error.type} : ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Requête GET générique
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  /// Requête POST générique
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// Requête PUT générique
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    return await _dio.put<T>(path, data: data, options: options);
  }

  /// Requête DELETE générique
  Future<Response<T>> delete<T>(
    String path, {
    Options? options,
  }) async {
    return await _dio.delete<T>(path, options: options);
  }
}

/// Provider global du client API
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
