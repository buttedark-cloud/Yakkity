import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/network/chat_socket.dart';
import 'package:yakkity/features/chat/data/chat_repository.dart';
import 'package:yakkity/features/chat/domain/chat_message.dart';

import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(ChatRepository repo, {required this.me, required this.peerId})
    : _repo = repo,
      super(ChatState(connection: repo.connectionStatus)) {
    // Сообщения экран берёт только из базы
    _messagesSub = _repo.watch(me, peerId).listen((messages) => emit(state.copyWith(messages: messages)));

    _statusSub = _repo.connection.listen((status) {
      emit(state.copyWith(connection: status));
      // Связь вернулась: подтягиваем то, что пропустили
      if (status == SocketStatus.connected) _loadHistory();
    });

    _loadHistory();
  }

  final ChatRepository _repo;
  final int me;
  final int peerId;
  late final StreamSubscription<List<ChatMessage>> _messagesSub;
  late final StreamSubscription<SocketStatus> _statusSub;
  bool _loading = false;

  Future<void> _loadHistory() async {
    if (_loading) return;
    _loading = true;
    try {
      await _repo.refreshHistory(peerId);
    } catch (_) {
      // Нет сети: остаёмся с тем, что есть в базе
    }
    _loading = false;
    if (!isClosed) emit(state.copyWith(loadingHistory: false));
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _repo.send(me: me, peerId: peerId, text: trimmed);
  }

  Future<void> retry(ChatMessage message) => _repo.retry(message);

  @override
  Future<void> close() {
    _messagesSub.cancel();
    _statusSub.cancel();
    return super.close();
  }
}
