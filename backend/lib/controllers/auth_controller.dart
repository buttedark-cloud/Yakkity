import 'dart:math';
import 'package:flint_dart/flint_dart.dart';
import 'package:flint_dart/auth.dart';

class AuthController extends Controller {
  static final _random = Random.secure();

  /// Убираем пробелы, дефисы и скобки: "+996 (700) 12-34-56" -> "+996700123456"
  String _normalizePhone(String raw) => raw.replaceAll(RegExp(r'[\s\-()]'), '');

  bool _isValidPhone(String phone) => RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone);

  /// id текущего пользователя из токена (null, если токен плохой)
  int? _currentUserId() {
    final token = req.bearerToken ?? req.authToken;
    final payload = token == null ? null : Auth.verifyToken(token);
    return int.tryParse(payload?['id'].toString() ?? '');
  }

  /// POST /auth/send-code   { "phone": "+996700123456" }
  Future<Response> sendCode() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {"phone": "required|string"});

      final phone = _normalizePhone(body['phone'].toString());
      if (!_isValidPhone(phone)) {
        return res.status(422).json({
          "status": "error",
          "message": "Invalid phone number.",
        });
      }

      // Шестизначный код: от 100000 до 999999
      final code = (100000 + _random.nextInt(900000)).toString();

      // Старые коды этого номера больше не нужны
      await DB.execute(
        "DELETE FROM verification_codes WHERE phone = ?",
        positionalParams: [phone],
      );

      // Новый код живёт 5 минут. Время считает сама база.
      await DB.execute(
        "INSERT INTO verification_codes (phone, code, expires_at, created_at) "
        "VALUES (?, ?, NOW() + INTERVAL '5 minutes', NOW())",
        positionalParams: [phone, code],
      );

      // Вместо отправки SMS пока выводим код в консоль сервера.
      print('📲 Verification code for $phone: $code');

      return res.json({
        "status": "success",
        "message": "Code sent.",
        // Только для разработки! В продакшене эту строку нужно убрать.
        "devCode": code,
      });
    } on ValidationException catch (e) {
      return res.status(422).json({"status": "error", "errors": e.errors});
    } catch (e) {
      return res.status(500).json({"status": "error", "message": e.toString()});
    }
  }

  /// POST /auth/verify   { "phone": "...", "code": "123456" }
  Future<Response> verify() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {
        "phone": "required|string",
        "code": "required|string",
      });

      final phone = _normalizePhone(body['phone'].toString());
      final code = body['code'].toString().trim();

      // Ищем неистёкший код, который подходит к номеру
      final codes = await DB.query(
        "SELECT id FROM verification_codes "
        "WHERE phone = ? AND code = ? AND expires_at > NOW() "
        "ORDER BY id DESC LIMIT 1",
        positionalParams: [phone, code],
      );

      if (codes.isEmpty) {
        return res.status(401).json({
          "status": "error",
          "message": "Invalid or expired code.",
        });
      }

      // Код одноразовый: после успешного входа удаляем
      await DB.execute(
        "DELETE FROM verification_codes WHERE phone = ?",
        positionalParams: [phone],
      );

      // Ищем пользователя; если нет, создаём (так работает и вход, и регистрация)
      var users = await DB.query(
        "SELECT id, phone, name FROM users WHERE phone = ?",
        positionalParams: [phone],
      );
      if (users.isEmpty) {
        users = await DB.query(
          "INSERT INTO users (phone, created_at) VALUES (?, NOW()) "
          "RETURNING id, phone, name",
          positionalParams: [phone],
        );
      }
      final user = users.first;

      final token = Auth.generateToken({
        'id': user['id'],
        'phone': user['phone'],
      });

      return res.json({
        "status": "success",
        "data": {
          "token": token,
          "user": {
            "id": user['id'],
            "phone": user['phone'],
            "name": user['name'],
          },
        },
      });
    } on ValidationException catch (e) {
      return res.status(422).json({"status": "error", "errors": e.errors});
    } catch (e) {
      return res.status(500).json({"status": "error", "message": e.toString()});
    }
  }

  /// GET /auth/me   (заголовок Authorization: Bearer <token>)
  Future<Response> me() async {
    final userId = _currentUserId();
    if (userId == null) {
      return res.status(401).json({
        "status": "error",
        "message": "Authentication required.",
      });
    }

    final users = await DB.query(
      "SELECT id, phone, name, created_at FROM users WHERE id = ?",
      positionalParams: [userId],
    );
    if (users.isEmpty) {
      return res.status(401).json({
        "status": "error",
        "message": "User not found.",
      });
    }

    return res.json({"status": "success", "data": users.first});
  }

  /// PUT /auth/profile   { "name": "Вероника" }
  Future<Response> updateProfile() async {
    final userId = _currentUserId();
    if (userId == null) {
      return res.status(401).json({
        "status": "error",
        "message": "Authentication required.",
      });
    }

    try {
      final body = await req.json();
      final name = body['name']?.toString().trim() ?? '';
      if (name.isEmpty || name.length > 50) {
        return res.status(422).json({
          "status": "error",
          "message": "Name must be 1 to 50 characters.",
        });
      }

      final users = await DB.query(
        "UPDATE users SET name = ? WHERE id = ? RETURNING id, phone, name",
        positionalParams: [name, userId],
      );
      if (users.isEmpty) {
        return res.status(404).json({
          "status": "error",
          "message": "User not found.",
        });
      }
      return res.json({"status": "success", "data": users.first});
    } catch (e) {
      return res.status(500).json({"status": "error", "message": e.toString()});
    }
  }
}
