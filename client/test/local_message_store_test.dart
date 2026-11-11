import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:yakkity/features/chat/domain/chat_message.dart';
import 'package:yakkity/features/chat/data/local_message_store.dart';

void main() {
  late LocalMessageStore store;

  setUp(() async {
    final db = await newDatabaseFactoryMemory().openDatabase(sembastInMemoryDatabasePath);
    store = LocalMessageStore(db);
  });

  ChatMessage fromServer(int id, {int sender = 1, int receiver = 2}) => ChatMessage(
    clientId: 'srv-$id',
    serverId: id,
    senderId: sender,
    receiverId: receiver,
    text: 'msg $id',
    createdAt: DateTime.utc(2026, 11, 5, 10, 0, id),
    status: MessageStatus.sent,
  );

  test('pending message becomes sent after server confirmation', () async {
    final pending = ChatMessage.pending(senderId: 1, receiverId: 2, text: 'Привет');
    await store.put(pending);
    expect((await store.conversation(1, 2)).single.status, MessageStatus.pending);

    await store.confirmSent(clientId: pending.clientId, serverMessage: fromServer(10));

    final list = await store.conversation(1, 2);
    expect(list, hasLength(1));
    expect(list.single.status, MessageStatus.sent);
    expect(list.single.serverId, 10);
  });

  test('history does not duplicate an already confirmed message', () async {
    final pending = ChatMessage.pending(senderId: 1, receiverId: 2, text: 'Привет');
    await store.put(pending);
    await store.confirmSent(clientId: pending.clientId, serverMessage: fromServer(10));

    // Сервер снова присылает то же сообщение в истории
    await store.saveFromServer(fromServer(10));

    expect(await store.conversation(1, 2), hasLength(1));
  });

  test('conversations are separated, newest first', () async {
    await store.saveFromServer(fromServer(1));
    await store.saveFromServer(fromServer(2));
    await store.saveFromServer(fromServer(3, receiver: 3)); // другой собеседник

    final list = await store.conversation(1, 2);
    expect(list.map((m) => m.serverId), [2, 1]);
  });

  test('unsent returns only failed and pending', () async {
    final a = ChatMessage.pending(senderId: 1, receiverId: 2, text: 'a');
    final b = ChatMessage.pending(senderId: 1, receiverId: 2, text: 'b');
    await store.put(a);
    await store.put(b);
    await store.markFailed(b.clientId);
    await store.saveFromServer(fromServer(5));

    final unsent = await store.unsent(1);
    expect(unsent, hasLength(2));
  });
}
