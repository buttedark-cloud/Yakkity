import 'package:sembast/sembast.dart';

import 'package:yakkity/features/chat/domain/chat_message.dart';
import 'package:yakkity/features/chat/domain/chat_peer.dart';
import 'package:yakkity/features/chat/domain/conversation_summary.dart';

class LocalMessageStore {
  LocalMessageStore(this._db);
  final Database _db;
  final _store = stringMapStoreFactory.store('messages');

  /// Переписка между me и peer, новые сообщения первыми.
  /// Учитываем оба направления; me входит в запрос, так что
  /// несколько аккаунтов на одном устройстве друг друга не видят.
  Finder _conversation(int me, int peer) => Finder(
    filter: Filter.or([
      Filter.and([Filter.equals('senderId', me), Filter.equals('receiverId', peer)]),
      Filter.and([Filter.equals('senderId', peer), Filter.equals('receiverId', me)]),
    ]),
    sortOrders: [SortOrder('createdAt', false)],
  );

  /// Живой поток: выдаёт новый список при любом изменении в базе.
  /// Именно его будет слушать экран чата.
  Stream<List<ChatMessage>> watchConversation(int me, int peer) => _store
      .query(finder: _conversation(me, peer))
      .onSnapshots(_db)
      .map((snaps) => snaps.map((s) => ChatMessage.fromMap(s.value)).toList());

  Future<List<ChatMessage>> conversation(int me, int peer) async {
    final snaps = await _store.find(_db, finder: _conversation(me, peer));
    return snaps.map((s) => ChatMessage.fromMap(s.value)).toList();
  }

  /// Сохранить сообщение как есть (например, только что написанное)
  Future<void> put(ChatMessage message) => _store.record(message.clientId).put(_db, message.toMap());

  /// Сообщение пришло с сервера (из истории или по WebSocket).
  /// Если такое serverId у нас уже есть, обновляем запись, а не плодим дубль.
  Future<void> saveFromServer(ChatMessage message) => _db.transaction((txn) async {
    final existing = await _store.findFirst(txn, finder: Finder(filter: Filter.equals('serverId', message.serverId)));
    if (existing != null) {
      await _store.record(existing.key).put(txn, message.copyWith(clientId: existing.key).toMap());
    } else {
      await _store.record(message.clientId).put(txn, message.toMap());
    }
  });

  /// Сервер подтвердил наше сообщение: добавляем serverId и время с сервера
  Future<void> confirmSent({required String clientId, required ChatMessage serverMessage}) => _db.transaction((txn) async {
    // На случай, если история успела принести то же сообщение раньше
    final duplicates = await _store.find(txn, finder: Finder(filter: Filter.equals('serverId', serverMessage.serverId)));
    for (final d in duplicates) {
      if (d.key != clientId) await _store.record(d.key).delete(txn);
    }
    await _store.record(clientId).put(txn, serverMessage.copyWith(clientId: clientId, status: MessageStatus.sent).toMap());
  });

  Future<void> markFailed(String clientId) => _store.record(clientId).update(_db, {'status': MessageStatus.failed.name});

  Future<void> markPending(String clientId) => _store.record(clientId).update(_db, {'status': MessageStatus.pending.name});

  /// Мои неотправленные сообщения (для повторной отправки)
  Future<List<ChatMessage>> unsent(int me) async {
    final snaps = await _store.find(
      _db,
      finder: Finder(
        filter: Filter.and([Filter.equals('senderId', me), Filter.notEquals('status', MessageStatus.sent.name)]),
        sortOrders: [SortOrder('createdAt')],
      ),
    );
    return snaps.map((s) => ChatMessage.fromMap(s.value)).toList();
  }

  // ---- Собеседники ----
  final _peers = intMapStoreFactory.store('peers');

  Future<void> putPeer(ChatPeer peer) => _peers.record(peer.id).put(_db, peer.toMap());

  Stream<Map<int, ChatPeer>> watchPeers() =>
      _peers.query().onSnapshots(_db).map((snaps) => {for (final s in snaps) s.key: ChatPeer.fromMap(s.value)});

  // ---- Список чатов ----
  /// Из всех моих сообщений берём по одному последнему на собеседника
  /// и запоминаем время всех входящих (для подсчёта непрочитанных).
  Stream<List<ConversationSummary>> watchConversations(int me) => _store
      .query(
        finder: Finder(
          filter: Filter.or([Filter.equals('senderId', me), Filter.equals('receiverId', me)]),
          sortOrders: [SortOrder('createdAt', false)],
        ),
      )
      .onSnapshots(_db)
      .map((snaps) {
        final last = <int, ChatMessage>{};
        final incoming = <int, List<int>>{};
        for (final s in snaps) {
          final m = ChatMessage.fromMap(s.value);
          final peerId = m.senderId == me ? m.receiverId : m.senderId;
          last.putIfAbsent(peerId, () => m); // первым идёт самое новое
          if (m.senderId != me) {
            (incoming[peerId] ??= []).add(m.createdAt.millisecondsSinceEpoch);
          }
        }
        return [for (final e in last.entries) ConversationSummary(peerId: e.key, last: e.value, incoming: incoming[e.key] ?? const [])];
      });

  // ---- Отметки «прочитано до» ----
  final _reads = StoreRef<String, int>('reads');

  Stream<Map<int, int>> watchReads(int me) => _reads
      .query()
      .onSnapshots(_db)
      .map(
        (snaps) => {
          for (final s in snaps)
            if (s.key.startsWith('$me:')) int.parse(s.key.substring('$me:'.length)): s.value,
        },
      );

  Future<void> markRead(int me, int peerId, int upToMs) => _db.transaction((txn) async {
    final key = '$me:$peerId';
    final current = await _reads.record(key).get(txn) ?? 0;
    if (upToMs > current) await _reads.record(key).put(txn, upToMs);
  });

  // ---- Поиск по тексту сообщений ----
  Future<List<ChatMessage>> searchMessages(int me, String query, {int limit = 30}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final snaps = await _store.find(
      _db,
      finder: Finder(
        filter: Filter.and([
          Filter.or([Filter.equals('senderId', me), Filter.equals('receiverId', me)]),
          Filter.custom((record) => ((record['text'] as String?) ?? '').toLowerCase().contains(q)),
        ]),
        sortOrders: [SortOrder('createdAt', false)],
        limit: limit,
      ),
    );
    return snaps.map((s) => ChatMessage.fromMap(s.value)).toList();
  }

  /// Сколько сообщений в моих переписках и сколько из них мои
  Stream<({int total, int mine})> watchMessageCounts(int me) => _store
      .query(finder: Finder(filter: Filter.or([Filter.equals('senderId', me), Filter.equals('receiverId', me)])))
      .onSnapshots(_db)
      .map((snaps) => (total: snaps.length, mine: snaps.where((s) => s.value['senderId'] == me).length));
}
