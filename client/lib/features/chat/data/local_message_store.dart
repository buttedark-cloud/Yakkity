import 'package:sembast/sembast.dart';

import 'package:yakkity/features/chat/domain/chat_message.dart';

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
}
