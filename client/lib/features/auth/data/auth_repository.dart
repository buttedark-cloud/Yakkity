import 'package:dio/dio.dart';

import 'package:yakkity/core/storage/token_storage.dart';

class AuthUser {
  const AuthUser({required this.id, required this.phone});
  final int id;
  final String phone;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(id: json['id'] as int, phone: json['phone'] as String);
}

class AuthRepository {
  AuthRepository(this._dio, this._storage);
  final Dio _dio;
  final TokenStorage _storage;

  /// Возвращает devCode (пока нет настоящих SMS, сервер отдаёт код в ответе)
  Future<String?> sendCode(String phone) async {
    final response = await _dio.post('/auth/send-code', data: {'phone': phone});
    return response.data['devCode'] as String?;
  }

  Future<AuthUser> verify(String phone, String code) async {
    final response = await _dio.post('/auth/verify', data: {'phone': phone, 'code': code});
    final data = response.data['data'] as Map<String, dynamic>;
    await _storage.save(data['token'] as String);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Автологин: если токен есть и сервер его принимает, возвращаем пользователя
  Future<AuthUser?> restoreSession() async {
    final token = await _storage.read();
    if (token == null) return null;
    try {
      final response = await _dio.get('/auth/me');
      return AuthUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null; // токен просрочен
      rethrow; // например, нет связи: это не повод разлогинивать
    }
  }

  Future<void> logout() => _storage.clear();
}
