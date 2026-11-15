import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/network/chat_socket.dart';
import 'package:yakkity/core/theme/app_theme.dart';
import 'package:yakkity/core/utils/date_format.dart';
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

/// Два соседних сообщения считаются одной «группой»:
/// тот же автор, тот же день, пауза меньше 5 минут
bool _sameGroup(ChatMessage a, ChatMessage b) =>
    a.senderId == b.senderId && isSameDay(a.createdAt, b.createdAt) && a.createdAt.difference(b.createdAt).abs().inMinutes < 5;

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
                final messages = state.messages; // новые сообщения первыми
                if (messages.isEmpty) {
                  return Center(
                    child: state.loadingHistory ? const CircularProgressIndicator() : const Text('Сообщений пока нет. Напиши первым!'),
                  );
                }
                // reverse: список растёт снизу вверх, новое сообщение всегда внизу
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    // На экране newer ниже сообщения, older выше
                    final newer = i > 0 ? messages[i - 1] : null;
                    final older = i < messages.length - 1 ? messages[i + 1] : null;

                    final startsDay = older == null || !isSameDay(older.createdAt, m.createdAt);
                    final firstInGroup = startsDay || !_sameGroup(older, m);
                    final lastInGroup = newer == null || !_sameGroup(m, newer);

                    return Column(
                      key: ValueKey(m.clientId),
                      children: [
                        if (startsDay) _DayChip(label: dayLabel(m.createdAt)),
                        MessageBubble(
                          message: m,
                          isMine: m.senderId == me,
                          firstInGroup: firstInGroup,
                          lastInGroup: lastInGroup,
                          onRetry: () => context.read<ChatCubit>().retry(m),
                        ),
                      ],
                    );
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

/// Плашка с датой посреди чата
class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.firstInGroup,
    required this.lastInGroup,
    this.onRetry,
  });

  final ChatMessage message;
  final bool isMine;
  final bool firstInGroup;
  final bool lastInGroup;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(message.createdAt.toLocal()).format(context);
    final failed = message.status == MessageStatus.failed;
    // Время и статус: у последнего сообщения группы или если что-то не так
    final showMeta = lastInGroup || message.status != MessageStatus.sent;

    const round = Radius.circular(18);
    const sharp = Radius.circular(4);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: EdgeInsets.only(top: firstInGroup ? AppSpacing.sm : 2),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isMine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: round,
              topRight: round,
              bottomLeft: (!isMine && lastInGroup) ? sharp : round,
              bottomRight: (isMine && lastInGroup) ? sharp : round,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.text),
              if (showMeta) ...[
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
              ],
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
