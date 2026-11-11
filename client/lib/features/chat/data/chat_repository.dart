import 'dart:async';

import 'package:dio/dio.dart';
import 'package:yakkity/core/network/chat_socket.dart';
import 'package:yakkity/features/chat/domain/chat_message.dart';

import 'local_message_store.dart';

class ChatPeer {
  const ChatPeer({required this.id, required this.phone});
  final int id;
  final String phone;
}

class ChatRepository {
  ChatRepository(this._dio, this._socket, this._store);

  final Dio _dio;
  final ChatSocket _socket;
  final LocalMessageStore _store;

  /// Если сервер не подтвердил сообщение за это время, считаем его неотправленным
  static const _ackTimeout = Duration(seconds: 10);

  int? _me;
  StreamSubscription<SocketEvent>? _eventsSub;
  StreamSubscription<SocketStatus>? _statusSub;
  final _ackTimers = <String, Timer>{};

  Stream<SocketStatus> get connection => _socket.status;
  SocketStatus get connectionStatus => _socket.currentStatus;

  /// Вызывается, когда пользователь вошёл
  Future<void> start(int me) async {
    if (_me == me) return;
    await stop();
    _me = me;
    _eventsSub = _socket.events.listen(_onEvent);
    _statusSub = _socket.status.listen((s) {
      // Связь появилась: досылаем всё, что не ушло
      if (s == SocketStatus.connected) _resendUnsent();
    });
    await _socket.connect();
  }

  Future<void> stop() async {
    _me = null;
    await _eventsSub?.cancel();
    await _statusSub?.cancel();
    _eventsSub = null;
    _statusSub = null;
    for (final t in _ackTimers.values) {
      t.cancel();
    }
    _ackTimers.clear();
    await _socket.disconnect();
  }

  void _onEvent(SocketEvent event) {
    final data = event.data;
    if (data is! Map) return;
    final json = Map<String, dynamic>.from(data);

    switch (event.name) {
      case 'new_message': // сообщение от собеседника
        _store.saveFromServer(ChatMessage.fromServerJson(json));
      case 'message_sent': // сервер подтвердил наше сообщение
        final clientId = json['clientId'] as String?;
        if (clientId == null) return;
        _ackTimers.remove(clientId)?.cancel();
        _store.confirmSent(clientId: clientId, serverMessage: ChatMessage.fromServerJson(json));
    }
  }

  /// Экран слушает только этот поток, то есть базу
  Stream<List<ChatMessage>> watch(int me, int peerId) => _store.watchConversation(me, peerId);

  /// Подтянуть историю с сервера и записать в базу
  Future<void> refreshHistory(int peerId) async {
    final response = await _dio.get('/chat/messages/$peerId', queryParameters: {'limit': 100});
    final rows = (response.data['data'] as List).cast<Map<String, dynamic>>();
    for (final row in rows) {
      await _store.saveFromServer(ChatMessage.fromServerJson(row));
    }
  }

  Future<void> send({required int me, required int peerId, required String text}) async {
    final message = ChatMessage.pending(senderId: me, receiverId: peerId, text: text);
    await _store.put(message); // сообщение появляется на экране сразу
    _deliver(message);
  }

  Future<void> retry(ChatMessage message) async {
    await _store.markPending(message.clientId);
    _deliver(message);
  }

  void _deliver(ChatMessage message) {
    final sent = _socket.send('send_message', {'to': message.receiverId, 'text': message.text, 'clientId': message.clientId});

    if (!sent) {
      _store.markFailed(message.clientId);
      return;
    }

    _ackTimers[message.clientId]?.cancel();
    _ackTimers[message.clientId] = Timer(_ackTimeout, () {
      _ackTimers.remove(message.clientId);
      _store.markFailed(message.clientId);
    });
  }

  Future<void> _resendUnsent() async {
    final me = _me;
    if (me == null) return;
    final unsent = await _store.unsent(me);
    for (final m in unsent) {
      if (_ackTimers.containsKey(m.clientId)) continue; // уже ждём ответа
      await _store.markPending(m.clientId);
      _deliver(m);
    }
  }

  /// Найти пользователя по номеру. null, если такого нет.
  Future<ChatPeer?> findUser(String phone) async {
    try {
      final response = await _dio.get('/chat/users/lookup', queryParameters: {'phone': phone});
      final data = response.data['data'] as Map<String, dynamic>;
      return ChatPeer(id: data['id'] as int, phone: data['phone'] as String);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
