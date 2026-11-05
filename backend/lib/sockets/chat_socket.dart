import 'package:flint_dart/flint_dart.dart';
import 'package:flint_dart/auth.dart';

/// Превращает DateTime в строку, иначе JSON не соберётся
Map<String, dynamic> _toJson(Map<String, dynamic> row) => row.map((k, v) => MapEntry(k, v is DateTime ? v.toIso8601String() : v));

/// WebSocket: ws://localhost:3000/ws/chat?token=<JWT>
void chatSocket(Context ctx) {
  final socket = ctx.socket;
  if (socket == null) return;

  // 1. Кто подключился? Проверяем токен.
  final token = ctx.req.query['token']?.toString() ?? ctx.req.bearerToken;
  final payload = token == null ? null : Auth.verifyToken(token);

  if (payload == null) {
    socket.emit('error', {'message': 'Authentication required.'});
    return; // обработчики не регистрируем: неавторизованный ничего не сможет
  }

  final userId = payload['id'];

  // 2. Личная комната пользователя: сюда будут приходить его сообщения
  socket.join('user:$userId');
  socket.emit('connected', {'userId': userId});

  // 3. Пользователь отправил сообщение
  socket.on('send_message', (data) async {
    try {
      if (data is! Map) return;

      final to = int.tryParse(data['to'].toString());
      final text = data['text']?.toString().trim() ?? '';

      if (to == null || text.isEmpty || text.length > 2000) {
        socket.emit('error', {'message': 'Invalid message.'});
        return;
      }

      // Получатель должен существовать
      final receiver = await DB.query(
        "SELECT id FROM users WHERE id = ?",
        positionalParams: [to],
      );
      if (receiver.isEmpty) {
        socket.emit('error', {'message': 'Recipient not found.'});
        return;
      }

      // Сначала сохраняем в базу
      final saved = await DB.query(
        "INSERT INTO messages (sender_id, receiver_id, text, created_at) "
        "VALUES (?, ?, ?, NOW()) "
        "RETURNING id, sender_id, receiver_id, text, created_at",
        positionalParams: [userId, to, text],
      );
      final message = _toJson(saved.first);

      // Потом доставляем получателю (если он онлайн, сообщение придёт сразу)
      socket.emitToRoom('user:$to', 'new_message', message);

      // И подтверждаем отправителю, возвращая его clientId
      socket.emit('message_sent', {
        ...message,
        'clientId': data['clientId'],
      });
    } catch (e) {
      socket.emit('error', {'message': 'Failed to send message.'});
    }
  });
}
