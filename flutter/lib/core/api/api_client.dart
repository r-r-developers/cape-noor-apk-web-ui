import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_storage.dart';

const String _baseUrl = 'https://mosque-admin.randrdevelopers.co.za/v2'; // Override via env/config

class ApiClient {
  static late final Dio _dio;
  static bool _initialized = false;

  static Dio get dio {
    if (!_initialized) {
      throw StateError('ApiClient not initialized. Call ApiClient.init() first.');
    }
    return _dio;
  }

  static void init({String baseUrl = _baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 45),
      // Disable redirect following so Dart's HttpClient never throws
      // RedirectException ("no location header"). Any 3xx the server sends
      // comes back as a DioException, caught by existing error handlers.
      followRedirects: false,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(_JwtInterceptor());

    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      if (kDebugMode) {
        client.badCertificateCallback = (cert, host, port) => true;
      }
      return client;
    };

    _initialized = true;
  }
}


/// Interceptor that attaches Authorization header and handles silent token refresh on 401.
class _JwtInterceptor extends QueuedInterceptor {
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = await TokenStorage.getRefreshToken();
        if (refreshToken == null) {
          _isRefreshing = false;
          return handler.next(err);
        }

        final refreshDio = Dio(BaseOptions(baseUrl: ApiClient.dio.options.baseUrl));
        final refreshResponse = await refreshDio.post('/auth/refresh', data: {
          'refresh_token': refreshToken,
        });

        if (refreshResponse.statusCode == 200) {
          final tokens = refreshResponse.data['tokens'];
          await TokenStorage.saveTokens(
            access:  tokens['access_token'],
            refresh: tokens['refresh_token'],
          );

          // Retry original request with new token
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer ${tokens['access_token']}';

          final retryResponse = await ApiClient.dio.fetch(retryOptions);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        // Refresh failed — clear tokens (user must re-login)
        await TokenStorage.clear();
      }

      _isRefreshing = false;
    }

    handler.next(err);
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────────
final apiClientProvider = Provider<Dio>((_) => ApiClient.dio);
