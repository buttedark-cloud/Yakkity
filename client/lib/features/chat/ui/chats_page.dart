import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/network/api_error.dart';
import 'package:yakkity/di.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/chat/cubit/chats_cubit.dart';
import 'package:yakkity/features/chat/data/chat_repository.dart';
import 'package:yakkity/features/chat/domain/conversation_summary.dart';
import 'package:yakkity/features/chat/ui/chat_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final _repo = getIt<ChatRepository>();
  late final int _me;

  @override
  void initState() {
    super.initState();
    // Вошли в аккаунт: запускаем соединение с чатом
    _me = context.read<AuthCubit>().state.user!.id;
    unawaited(_repo.start(_me));
  }

  @override
  void dispose() {
    // Вышли из аккаунта: закрываем соединение
    unawaited(_repo.stop());
    super.dispose();
  }

  void _openChat(ChatPeer peer) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(peer: peer)));
  }

  Future<void> _newChat() async {
    final phone = await showDialog<String>(context: context, builder: (_) => const _PhoneDialog());
    if (phone == null || !mounted) return;

    try {
      final peer = await _repo.findUser(phone);
      if (!mounted) return;
      if (peer == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Пользователь не найден. Он должен сначала войти в приложение')));
        return;
      }
      _openChat(peer);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatsCubit(_repo, _me),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Чаты'),
          actions: [IconButton(icon: const Icon(Icons.logout), tooltip: 'Выйти', onPressed: () => context.read<AuthCubit>().logout())],
        ),
        body: BlocBuilder<ChatsCubit, ChatsState>(
          builder: (context, state) {
            if (state.items.isEmpty) {
              return const Center(child: Text('Чатов пока нет.\nНажми на карандаш, чтобы написать по номеру', textAlign: TextAlign.center));
            }
            return ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) {
                final item = state.items[i];
                final peer = state.peers[item.peerId] ?? ChatPeer(id: item.peerId, phone: '');
                return _ConversationTile(item: item, peer: peer, me: _me, onTap: () => _openChat(peer));
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(onPressed: _newChat, tooltip: 'Новый чат', child: const Icon(Icons.edit)),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.item, required this.peer, required this.me, required this.onTap});

  final ConversationSummary item;
  final ChatPeer peer;
  final int me;
  final VoidCallback onTap;

  String _time(BuildContext context, DateTime utc) {
    final t = utc.toLocal();
    final now = DateTime.now();
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return TimeOfDay.fromDateTime(t).format(context);
    }
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.primaries[peer.id % Colors.primaries.length].shade400;
    final mine = item.last.senderId == me;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: color,
        child: Text(peer.initial, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
      title: Text(peer.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(mine ? 'Вы: ${item.last.text}' : item.last.text, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(_time(context, item.last.createdAt), style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _PhoneDialog extends StatefulWidget {
  const _PhoneDialog();

  @override
  State<_PhoneDialog> createState() => _PhoneDialogState();
}

class _PhoneDialogState extends State<_PhoneDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final digits = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 8) Navigator.of(context).pop('+$digits');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый чат'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Номер собеседника'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
        FilledButton(onPressed: _submit, child: const Text('Открыть')),
      ],
    );
  }
}
