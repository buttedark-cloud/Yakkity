import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/network/api_error.dart';
import 'package:yakkity/core/theme/app_theme.dart';
import 'package:yakkity/core/utils/date_format.dart';
import 'package:yakkity/core/widgets/user_avatar.dart';
import 'package:yakkity/core/widgets/yakkity_logo.dart';
import 'package:yakkity/di.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/chat/cubit/chats_cubit.dart';
import 'package:yakkity/features/chat/data/chat_repository.dart';
import 'package:yakkity/features/chat/domain/chat_message.dart';
import 'package:yakkity/features/chat/domain/conversation_summary.dart';
import 'package:yakkity/features/chat/ui/chat_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final _search = TextEditingController();
  bool _onlyUnread = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openChat(ChatPeer peer) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(peer: peer)));
  }

  Future<void> _openByPhone(String phone) async {
    try {
      final peer = await getIt<ChatRepository>().findUser(phone);
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

  Future<void> _newChat() async {
    final phone = await showDialog<String>(context: context, builder: (_) => const _PhoneDialog());
    if (phone != null) await _openByPhone(phone);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthCubit>().state.user!.id;

    return BlocBuilder<ChatsCubit, ChatsState>(
      builder: (context, state) {
        final searching = state.query.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const YakkityLogo(size: 28),
                if (state.totalUnread > 0) ...[const SizedBox(width: AppSpacing.sm), _CountBadge(count: state.totalUnread, soft: true)],
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: IconButton.filled(
                  onPressed: _newChat,
                  tooltip: 'Новый чат',

                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(
                        'https://img.icons8.ru/?size=100&id=114092&format=png&color=ffffff',
                        width: 30,
                        height: 30,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Поиск сообщений и контактов...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searching
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              context.read<ChatsCubit>().setQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => context.read<ChatsCubit>().setQuery(v),
                ),
              ),
              if (!searching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      _FilterChip(label: 'Все', selected: !_onlyUnread, onTap: () => setState(() => _onlyUnread = false)),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(label: 'Непрочитанные', selected: _onlyUnread, onTap: () => setState(() => _onlyUnread = true)),
                    ],
                  ),
                ),
              Expanded(child: searching ? _buildSearch(state, me) : _buildList(state, me)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(ChatsState state, int me) {
    final items = _onlyUnread ? state.items.where((s) => state.unreadFor(s) > 0).toList() : state.items;

    if (items.isEmpty) {
      return Center(
        child: Text(
          _onlyUnread ? 'Непрочитанных сообщений нет' : 'Чатов пока нет.\nНайди человека по номеру в поиске или нажми на карандаш',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(indent: 72),
      itemBuilder: (context, i) {
        final item = items[i];
        final peer = state.peers[item.peerId] ?? ChatPeer(id: item.peerId, phone: '');
        return _ConversationTile(item: item, peer: peer, me: me, unread: state.unreadFor(item), onTap: () => _openChat(peer));
      },
    );
  }

  Widget _buildSearch(ChatsState state, int me) {
    final q = state.query.toLowerCase();
    final digits = state.query.replaceAll(RegExp(r'[^0-9]'), '');
    String onlyDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

    final contacts = state.peers.values
        .where((p) => p.displayName.toLowerCase().contains(q) || (digits.isNotEmpty && onlyDigits(p.phone).contains(digits)))
        .toList();

    final looksLikePhone = RegExp(r'^[+\d\s\-()]+$').hasMatch(state.query) && digits.length >= 8;
    final alreadyKnown = contacts.any((p) => onlyDigits(p.phone) == digits);
    final showLookup = looksLikePhone && !alreadyKnown;

    if (contacts.isEmpty && state.messageResults.isEmpty && !showLookup) {
      return const Center(child: Text('Ничего не найдено'));
    }

    return ListView(
      children: [
        if (showLookup) ...[
          const _SectionHeader('НОВЫЙ ЧАТ'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.person_add_alt_1, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text('Написать на +$digits'),
            subtitle: const Text('Найти в Yakkity по номеру'),
            onTap: () => _openByPhone('+$digits'),
          ),
        ],
        if (contacts.isNotEmpty) ...[
          const _SectionHeader('КОНТАКТЫ'),
          for (final p in contacts)
            ListTile(
              leading: UserAvatar(label: p.displayName, colorSeed: p.id, assetPath: p.avatarAsset),
              title: Text(p.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: p.phone.isEmpty ? null : Text(p.phone),
              onTap: () => _openChat(p),
            ),
        ],
        if (state.messageResults.isNotEmpty) ...[
          const _SectionHeader('СООБЩЕНИЯ'),
          for (final m in state.messageResults)
            _MessageResultTile(
              message: m,
              peer:
                  state.peers[m.senderId == me ? m.receiverId : m.senderId] ??
                  ChatPeer(id: m.senderId == me ? m.receiverId : m.senderId, phone: ''),
              onTap: (peer) => _openChat(peer),
            ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primary,
      backgroundColor: scheme.surfaceContainerHigh,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: selected ? scheme.onPrimary : scheme.onSurface),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }
}

/// Кружок со счётчиком. Без выравнивания внутри: иначе он растягивается
/// на всю ширину и ломает строку чата.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, this.soft = false});
  final int count;
  final bool soft; // мягкий (розовый) вариант для заголовка

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: soft ? scheme.primaryContainer : scheme.primary, borderRadius: BorderRadius.circular(10)),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: soft ? scheme.primary : scheme.onPrimary),
      ),
    );
  }
}

/// Сегодня показываем время, остальное словами: «Вчера», «5 ноября»
String _timeLabel(BuildContext context, DateTime utc) {
  final label = dayLabel(utc);
  if (label == 'Сегодня') {
    return TimeOfDay.fromDateTime(utc.toLocal()).format(context);
  }
  return label;
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.item, required this.peer, required this.me, required this.unread, required this.onTap});

  final ConversationSummary item;
  final ChatPeer peer;
  final int me;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = item.last.senderId == me;
    final hasUnread = unread > 0;

    return ListTile(
      onTap: onTap,
      leading: UserAvatar(label: peer.displayName, colorSeed: peer.id, assetPath: peer.avatarAsset),
      title: Text(
        peer.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600),
      ),
      subtitle: Text(
        mine ? 'Вы: ${item.last.text}' : item.last.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: hasUnread ? FontWeight.w600 : null, color: hasUnread ? scheme.onSurface : null),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_timeLabel(context, item.last.createdAt), style: Theme.of(context).textTheme.labelSmall),
          if (hasUnread) ...[const SizedBox(height: 4), _CountBadge(count: unread)],
        ],
      ),
    );
  }
}

class _MessageResultTile extends StatelessWidget {
  const _MessageResultTile({required this.message, required this.peer, required this.onTap});

  final ChatMessage message;
  final ChatPeer peer;
  final void Function(ChatPeer peer) onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTap(peer),
      leading: UserAvatar(label: peer.displayName, colorSeed: peer.id, assetPath: peer.avatarAsset),
      title: Text(peer.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(message.text, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(_timeLabel(context, message.createdAt), style: Theme.of(context).textTheme.labelSmall),
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
        decoration: const InputDecoration(hintText: 'Номер собеседника'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
        TextButton(onPressed: _submit, child: const Text('Открыть')),
      ],
    );
  }
}
