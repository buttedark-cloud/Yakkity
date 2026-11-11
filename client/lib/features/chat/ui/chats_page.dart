import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/network/api_error.dart';
import 'package:yakkity/di.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/chat/data/chat_repository.dart';

import 'chat_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final _repo = getIt<ChatRepository>();

  @override
  void initState() {
    super.initState();
    // Вошли в аккаунт: запускаем соединение с чатом
    final me = context.read<AuthCubit>().state.user!.id;
    unawaited(_repo.start(me));
  }

  @override
  void dispose() {
    // Вышли из аккаунта: закрываем соединение
    unawaited(_repo.stop());
    super.dispose();
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
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(peer: peer)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        actions: [IconButton(icon: const Icon(Icons.logout), tooltip: 'Выйти', onPressed: () => context.read<AuthCubit>().logout())],
      ),
      body: Center(child: Text('Ты вошла как ${user?.phone}\nНажми +, чтобы написать по номеру', textAlign: TextAlign.center)),
      floatingActionButton: FloatingActionButton(onPressed: _newChat, tooltip: 'Новый чат', child: const Icon(Icons.edit)),
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
