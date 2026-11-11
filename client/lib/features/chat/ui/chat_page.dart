import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/network/chat_socket.dart';
import 'package:yakkity/core/theme/app_theme.dart';
import 'package:yakkity/di.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/chat/cubit/chat_cubit.dart';
import 'package:yakkity/features/chat/cubit/chat_state.dart';
import 'package:yakkity/features/chat/data/chat_repository.dart';
import 'package:yakkity/features/chat/domain/chat_message.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.peer});
  final ChatPeer peer;

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthCubit>().state.user!.id;
    return BlocProvider(
      create: (_) => ChatCubit(getIt<ChatRepository>(), me: me, peerId: peer.id),
      child: _ChatView(peer: peer, me: me),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView({required this.peer, required this.me});
  final ChatPeer peer;
  final int me;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(peer.displayName)),
      body: Column(
        children: [
          // Плашка появляется, когда нет связи с сервером
          BlocBuilder<ChatCubit, ChatState>(
            buildWhen: (p, c) => p.connection != c.connection,
            builder: (context, state) {
              if (state.connection == SocketStatus.connected) {
                return const SizedBox.shrink();
              }
              final connecting = state.connection == SocketStatus.connecting;
              return Container(
                width: double.infinity,
                color: scheme.errorContainer,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  connecting ? 'Подключение...' : 'Нет соединения. Сообщения отправятся, когда связь появится',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state.messages.isEmpty) {
                  return Center(
                    child: state.loadingHistory ? const CircularProgressIndicator() : const Text('Сообщений пока нет. Напиши первым!'),
                  );
                }
                // reverse: список растёт снизу вверх, новое сообщение всегда внизу
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: state.messages.length,
                  itemBuilder: (context, i) {
                    final m = state.messages[i];
                    return MessageBubble(message: m, isMine: m.senderId == me, onRetry: () => context.read<ChatCubit>().retry(m));
                  },
                );
              },
            ),
          ),
          _Composer(onSend: (text) => context.read<ChatCubit>().send(text)),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isMine, this.onRetry});

  final ChatMessage message;
  final bool isMine;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(message.createdAt.toLocal()).format(context);
    final failed = message.status == MessageStatus.failed;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isMine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.text),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: Theme.of(context).textTheme.labelSmall),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    switch (message.status) {
                      MessageStatus.pending => const Icon(Icons.schedule, size: 14),
                      MessageStatus.sent => const Icon(Icons.done, size: 14),
                      MessageStatus.failed => Icon(Icons.error, size: 14, color: scheme.error),
                    },
                  ],
                ],
              ),
              if (failed && isMine)
                InkWell(
                  onTap: onRetry,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Не отправлено. Нажми, чтобы повторить', style: TextStyle(color: scheme.error, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.onSend});
  final void Function(String text) onSend;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(hintText: 'Сообщение', isDense: true),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(onPressed: _submit, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
