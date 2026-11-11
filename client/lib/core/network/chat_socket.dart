import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:yakkity/core/config/app_config.dart';
import 'package:yakkity/core/storage/token_storage.dart';
import 'package:yakkity/core/network/session_events.dart';

enum SocketStatus { connecting, connected, disconnected }

class SocketEvent {
  const SocketEvent(this.name, this.data);
  final String name;
  final dynamic data;
}

class ChatSocket {
  ChatSocket(this._storage, this._session);
  final TokenStorage _storage;
  final SessionEvents _session;

  final _events = StreamController<SocketEvent>.broadcast();
  final _status = StreamController<SocketStatus>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _retryTimer;
  int _attempt = 0;
  bool _wanted = false; // хотим ли мы быть подключены
  SocketStatus _current = SocketStatus.disconnected;

  Stream<SocketEvent> get events => _events.stream;
  Stream<SocketStatus> get status => _status.stream;
  SocketStatus get currentStatus => _current;

  void _setStatus(SocketStatus s) {
    if (_current == s) return;
    _current = s;
    _status.add(s);
  }

  Future<void> connect() async {
    _wanted = true;
    await _open();
  }

  Future<void> _open() async {
    if (!_wanted || _current == SocketStatus.connecting || _current == SocketStatus.connected) {
      return;
    }
    _retryTimer?.cancel();

    final token = await _storage.read();
    if (token == null) {
      _wanted = false; // не вошли в аккаунт, подключаться нечем
      return;
    }

    _setStatus(SocketStatus.connecting);
    try {
      final uri = Uri.parse(AppConfig.wsBase).replace(path: '/ws/chat', queryParameters: {'token': token});
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready; // бросит ошибку, если сервер недоступен
      _sub = channel.stream.listen(_onData, onError: (_) => _onClosed(), onDone: _onClosed);
    } catch (_) {
      _onClosed();
    }
  }

  void _onData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final name = json['event'] as String;
      final data = json['data'];

      // Сервер подтвердил, что узнал нас по токену
      if (name == 'connected') {
        _attempt = 0;
        _setStatus(SocketStatus.connected);
      }

      // Токен просрочен: больше не переподключаемся, а выходим из аккаунта
      if (name == 'error' && data is Map && data['message'] == 'Authentication required.') {
        unawaited(_handleAuthFailure());
        return;
      }

      _events.add(SocketEvent(name, data));
    } catch (_) {
      // непонятное сообщение игнорируем
    }
  }

  Future<void> _handleAuthFailure() async {
    _wanted = false;
    await _storage.clear();
    _session.expired();
    await _channel?.sink.close();
  }

  void _onClosed() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    _setStatus(SocketStatus.disconnected);
    if (!_wanted) return;

    // Пауза растёт: 1, 2, 4, 8, 16, 30 секунд
    final delay = Duration(seconds: min(30, 1 << min(_attempt, 5)));
    _attempt++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, _open);
  }

  /// false, если сейчас нет живого соединения
  bool send(String event, Map<String, dynamic> data) {
    if (_current != SocketStatus.connected || _channel == null) return false;
    _channel!.sink.add(jsonEncode({'event': event, 'data': data}));
    return true;
  }

  Future<void> disconnect() async {
    _wanted = false;
    _retryTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _sub = null;
    _channel = null;
    _setStatus(SocketStatus.disconnected);
  }
}
