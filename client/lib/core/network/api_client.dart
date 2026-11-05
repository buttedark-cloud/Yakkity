import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'session_events.dart';

Dio createDio(TokenStorage storage, SessionEvents session) {
  final dio = Dio(
    BaseOptions(baseUrl: AppConfig.httpBase, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 15)),
  );
  dio.interceptors.add(AuthInterceptor(storage, session));
  return dio;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._session);
  final TokenStorage _storage;
  final SessionEvents _session;

  /// Перед каждым запросом подставляем токен, если он есть
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  /// Если сервер ответил 401, токен просрочен (живёт час): выходим из аккаунта.
  /// Но 401 на вводе кода означает "неверный код", а не "просрочен токен".
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final isLoginCall = path.contains('/auth/send-code') || path.contains('/auth/verify');

    if (err.response?.statusCode == 401 && !isLoginCall) {
      await _storage.clear();
      _session.expired();
    }
    handler.next(err);
  }
}
