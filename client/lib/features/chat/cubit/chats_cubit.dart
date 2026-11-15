import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/features/chat/data/chat_repository.dart';
import 'package:yakkity/features/chat/domain/chat_message.dart';
import 'package:yakkity/features/chat/domain/conversation_summary.dart';

class ChatsState extends Equatable {
  const ChatsState({this.items = const [], this.peers = const {}, this.reads = const {}, this.query = '', this.messageResults = const []});

  final List<ConversationSummary> items;
  final Map<int, ChatPeer> peers;

  /// peerId -> время (мс), до которого чат прочитан
  final Map<int, int> reads;
  final String query;
  final List<ChatMessage> messageResults;

  int unreadFor(ConversationSummary s) => s.unread(reads[s.peerId] ?? 0);
  int get totalUnread => items.fold(0, (sum, s) => sum + unreadFor(s));

  ChatsState copyWith({
    List<ConversationSummary>? items,
    Map<int, ChatPeer>? peers,
    Map<int, int>? reads,
    String? query,
    List<ChatMessage>? messageResults,
  }) => ChatsState(
    items: items ?? this.items,
    peers: peers ?? this.peers,
    reads: reads ?? this.reads,
    query: query ?? this.query,
    messageResults: messageResults ?? this.messageResults,
  );

  @override
  List<Object?> get props => [items, peers, reads, query, messageResults];
}

class ChatsCubit extends Cubit<ChatsState> {
  ChatsCubit(this._repo, this._me) : super(const ChatsState()) {
    _itemsSub = _repo.watchConversations(_me).listen((items) {
      emit(state.copyWith(items: items));
      // Для незнакомых собеседников узнаём имя и номер
      for (final item in items) {
        _repo.ensurePeer(item.peerId);
      }
      if (state.query.isNotEmpty) _runSearch(state.query);
    });
    _peersSub = _repo.watchPeers().listen((peers) => emit(state.copyWith(peers: peers)));
    _readsSub = _repo.watchReads(_me).listen((reads) => emit(state.copyWith(reads: reads)));
  }

  final ChatRepository _repo;
  final int _me;
  late final StreamSubscription<List<ConversationSummary>> _itemsSub;
  late final StreamSubscription<Map<int, ChatPeer>> _peersSub;
  late final StreamSubscription<Map<int, int>> _readsSub;

  Future<void> setQuery(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) {
      emit(state.copyWith(query: '', messageResults: const []));
      return;
    }
    emit(state.copyWith(query: q));
    await _runSearch(q);
  }

  Future<void> _runSearch(String q) async {
    final results = await _repo.searchMessages(_me, q);
    if (isClosed || state.query != q) return; // пока искали, запрос сменился
    emit(state.copyWith(messageResults: results));
  }

  @override
  Future<void> close() {
    _itemsSub.cancel();
    _peersSub.cancel();
    _readsSub.cancel();
    return super.close();
  }
}
