import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/features/chat/data/chat_repository.dart';
import 'package:yakkity/features/chat/domain/conversation_summary.dart';

class ChatsState extends Equatable {
  const ChatsState({this.items = const [], this.peers = const {}});

  final List<ConversationSummary> items;
  final Map<int, ChatPeer> peers;

  @override
  List<Object?> get props => [items, peers];
}

class ChatsCubit extends Cubit<ChatsState> {
  ChatsCubit(this._repo, int me) : super(const ChatsState()) {
    _itemsSub = _repo.watchConversations(me).listen((items) {
      emit(ChatsState(items: items, peers: state.peers));
      // Для незнакомых собеседников узнаём имя и номер
      for (final item in items) {
        _repo.ensurePeer(item.peerId);
      }
    });
    _peersSub = _repo.watchPeers().listen((peers) => emit(ChatsState(items: state.items, peers: peers)));
  }

  final ChatRepository _repo;
  late final StreamSubscription<List<ConversationSummary>> _itemsSub;
  late final StreamSubscription<Map<int, ChatPeer>> _peersSub;

  @override
  Future<void> close() {
    _itemsSub.cancel();
    _peersSub.cancel();
    return super.close();
  }
}
