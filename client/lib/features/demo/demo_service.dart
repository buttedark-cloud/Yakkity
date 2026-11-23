import 'package:yakkity/core/storage/settings_store.dart';
import 'package:yakkity/features/chat/data/local_message_store.dart';
import 'package:yakkity/features/chat/domain/chat_message.dart';
import 'package:yakkity/features/chat/domain/chat_peer.dart';
import 'package:yakkity/features/demo/demo_data.dart';

/// Включает и выключает демо-данные. Всё лежит только в локальной базе
/// на устройстве, на сервер ничего не отправляется.
class DemoService {
  DemoService(this._store, this._settings);

  final LocalMessageStore _store;
  final SettingsStore _settings;

  static String _key(int me) => 'demo_$me';

  Future<bool> isEnabled(int me) async =>
      (await _settings.read(_key(me))) == 'true';

  Future<void> enable(int me) async {
    final now = DateTime.now();
    final peers = <ChatPeer>[];
    final messages = <ChatMessage>[];
    final reads = <int, int>{};

    for (final p in DemoData.people) {
      peers.add(ChatPeer(
        id: p.id,
        phone: p.phone,
        name: p.name,
        status: p.status,
        avatarAsset: p.asset,
      ));

      final sorted = [...p.messages]
        ..sort((a, b) => a.when(now).compareTo(b.when(now)));
      final built = <ChatMessage>[];
      for (var i = 0; i < sorted.length; i++) {
        final m = sorted[i];
        built.add(ChatMessage(
          clientId: 'demo-${p.id}-$i',
          senderId: m.mine ? me : p.id,
          receiverId: m.mine ? p.id : me,
          text: m.text,
          createdAt: m.when(now),
          status: MessageStatus.sent,
        ));
      }
      messages.addAll(built);

      // Прочитано всё, кроме последних p.unread входящих
      final incoming = built.where((m) => m.senderId == p.id).toList();
      final readIndex = incoming.length - p.unread - 1;
      if (readIndex >= 0) {
        reads[p.id] = incoming[readIndex].createdAt.millisecondsSinceEpoch;
      }
    }

    await _store.seedDemo(
        me: me, peers: peers, messages: messages, reads: reads);
    await _settings.write(_key(me), 'true');
  }

  Future<void> disable(int me) async {
    await _store.removeDemo(me, DemoData.people.map((p) => p.id));
    await _settings.write(_key(me), 'false');
  }
}
