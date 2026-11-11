import 'package:flint_dart/flint_dart.dart';
import 'package:flint_dart/auth.dart';

class ChatController extends Controller {
  /// id текущего пользователя из токена (null, если токен плохой)
  int? _currentUserId() {
    final token = req.bearerToken;
    final payload = token == null ? null : Auth.verifyToken(token);
    return int.tryParse(payload?['id'].toString() ?? '');
  }

  /// GET /chat/users/lookup?phone=%2B996700999888
  Future<Response> findUser() async {
    if (_currentUserId() == null) {
      return res.status(401).json({"status": "error", "message": "Authentication required."});
    }

    // Оставляем только цифры и ставим + в начале (в URL плюс превращается в пробел)
    final raw = req.query['phone']?.toString() ?? '';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return res.status(422).json({"status": "error", "message": "Phone is required."});
    }

    final users = await DB.query(
      "SELECT id, phone, name FROM users WHERE phone = ?",
      positionalParams: ['+$digits'],
    );
    if (users.isEmpty) {
      return res.status(404).json({"status": "error", "message": "User not found."});
    }
    return res.json({"status": "success", "data": users.first});
  }

  /// GET /chat/messages/:userId?limit=50
  /// Переписка текущего пользователя с userId, новые сообщения первыми.
  Future<Response> history() async {
    final me = _currentUserId();
    if (me == null) {
      return res.status(401).json({"status": "error", "message": "Authentication required."});
    }

    final otherId = int.tryParse(req.params['userId'] ?? '');
    if (otherId == null) {
      return res.status(400).json({"status": "error", "message": "Invalid user id."});
    }

    // limit проверяем и ограничиваем числом, поэтому вставлять его в запрос безопасно
    final limit = (int.tryParse(req.query['limit']?.toString() ?? '') ?? 50).clamp(1, 100).toInt();

    final rows = await DB.query(
      "SELECT id, sender_id, receiver_id, text, created_at FROM messages "
      "WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?) "
      "ORDER BY id DESC LIMIT $limit",
      positionalParams: [me, otherId, otherId, me],
    );

    return res.json({"status": "success", "data": rows});
  }

  /// GET /chat/peers/:id   (узнать номер и имя по id)
  Future<Response> getPeer() async {
    if (_currentUserId() == null) {
      return res.status(401).json({"status": "error", "message": "Authentication required."});
    }

    final id = int.tryParse(req.params['id'] ?? '');
    if (id == null) {
      return res.status(400).json({"status": "error", "message": "Invalid user id."});
    }

    final users = await DB.query(
      "SELECT id, phone, name FROM users WHERE id = ?",
      positionalParams: [id],
    );
    if (users.isEmpty) {
      return res.status(404).json({"status": "error", "message": "User not found."});
    }
    return res.json({"status": "success", "data": users.first});
  }
}
