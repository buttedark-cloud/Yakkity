import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/storage/settings_store.dart';
import 'package:yakkity/core/theme/app_theme.dart';
import 'package:yakkity/core/theme/theme_cubit.dart';
import 'package:yakkity/core/widgets/user_avatar.dart';
import 'package:yakkity/di.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/auth/data/auth_repository.dart';
import 'package:yakkity/features/chat/cubit/chats_cubit.dart';
import 'package:yakkity/features/chat/data/chat_repository.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

enum _PhotoAction { gallery, camera, remove }

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _notifKey = 'notifications';

  late final Stream<({int total, int mine})> _counts;
  bool _notifications = true;
  late final String _avatarKey;
  Uint8List? _avatar;
  @override
  void initState() {
    super.initState();
    final me = context.read<AuthCubit>().state.user!.id;
    _counts = getIt<ChatRepository>().watchMessageCounts(me);

    _avatarKey = 'avatar_$me';
    getIt<SettingsStore>().read(_avatarKey).then((value) {
      if (mounted && value != null && value.isNotEmpty) {
        setState(() => _avatar = base64Decode(value));
      }
    });

    getIt<SettingsStore>().read(_notifKey).then((value) {
      if (mounted && value != null) {
        setState(() => _notifications = value == 'true');
      }
    });
  }

  void _setNotifications(bool value) {
    setState(() => _notifications = value);
    getIt<SettingsStore>().write(_notifKey, value.toString());
  }

  Future<void> _editName(AuthUser user) async {
    final cubit = context.read<AuthCubit>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: user.name ?? ''),
    );
    if (name == null || name == user.name) return;

    await cubit.saveName(name);
    final error = cubit.state.error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Чтобы войти снова, понадобится код подтверждения.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Выйти')),
        ],
      ),
    );
    if (ok == true && mounted) context.read<AuthCubit>().logout();
  }

  Future<void> _changePhoto() async {
    final settings = getIt<SettingsStore>();
    final canUseCamera = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () => Navigator.pop(ctx, _PhotoAction.gallery),
            ),
            if (canUseCamera)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Сделать снимок'),
                onTap: () => Navigator.pop(ctx, _PhotoAction.camera),
              ),
            if (_avatar != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Удалить фото'),
                onTap: () => Navigator.pop(ctx, _PhotoAction.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    if (action == _PhotoAction.remove) {
      await settings.write(_avatarKey, '');
      if (mounted) setState(() => _avatar = null);
      return;
    }

    try {
      final picked = await ImagePicker().pickImage(
        source: action == _PhotoAction.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await settings.write(_avatarKey, base64Encode(bytes));
      if (mounted) setState(() => _avatar = bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось загрузить фото')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = context.select((AuthCubit c) => c.state.user);
    if (user == null) return const SizedBox.shrink();

    final isDark = scheme.brightness == Brightness.dark;
    final shownName = user.hasName ? user.name! : user.phone;
    final chatsCount = context.select((ChatsCubit c) => c.state.items.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль и настройки', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ---- Шапка профиля ----
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 90,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: isDark ? const [Color(0xFFC62828), Color(0xFF7F1D1D)] : const [Color(0xFFE04848), Color(0xFF9B2C2C)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _AvatarWithBadge(label: shownName, seed: user.id, image: _avatar, onCamera: _changePhoto),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          shownName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Изменить имя',
                        onPressed: () => _editName(user),
                      ),
                    ],
                  ),
                ),
                Text(user.phone, style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.md),
                const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: StreamBuilder<({int total, int mine})>(
                    stream: _counts,
                    builder: (context, snapshot) {
                      final counts = snapshot.data;
                      return Row(
                        children: [
                          _Stat(value: '$chatsCount', label: 'Чатов'),
                          const SizedBox(width: AppSpacing.sm),
                          _Stat(value: '${counts?.total ?? 0}', label: 'Сообщений'),
                          const SizedBox(width: AppSpacing.sm),
                          _Stat(value: '${counts?.mine ?? 0}', label: 'Отправлено'),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ---- Внешний вид и тема ----
          _Section(
            title: 'ВНЕШНИЙ ВИД И ТЕМА',
            children: [
              _SettingTile(
                icon: Icons.dark_mode_outlined,
                highlighted: true,
                title: 'Тёмная тема',
                subtitle: isDark ? 'Тёмное оформление включено' : 'Светлое оформление включено',
                trailing: Switch(value: isDark, onChanged: (v) => context.read<ThemeCubit>().set(v ? ThemeMode.dark : ThemeMode.light)),
                onTap: () => context.read<ThemeCubit>().set(isDark ? ThemeMode.light : ThemeMode.dark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ---- Настройки ----
          _Section(
            title: 'НАСТРОЙКИ',
            children: [
              _SettingTile(
                icon: Icons.notifications_none,
                title: 'Уведомления',
                subtitle: 'Звук и push-сообщения',
                trailing: Checkbox(value: _notifications, onChanged: (v) => _setNotifications(v ?? true)),
                onTap: () => _setNotifications(!_notifications),
              ),
              _SettingTile(
                icon: Icons.info_outline,
                title: 'О приложении',
                subtitle: 'Версия 1.0.0',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Yakkity',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Учебный проект: мессенджер на Flutter и Dart',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ---- Выход ----
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text(
                'Выйти из профиля',
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
              ),
              onTap: _logout,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({required this.label, required this.seed, required this.onCamera, this.image});

  final String label;
  final int seed;
  final Uint8List? image;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surfaceContainerLowest),
          child: UserAvatar(label: label, colorSeed: seed, radius: 46, image: image),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: scheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onCamera,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.photo_camera, size: 16, color: scheme.onPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: scheme.primary, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Карточка с серой полосой-заголовком и строками настроек
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(indent: 72), children[i]],
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap, this.highlighted = false});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: highlighted ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: highlighted ? scheme.primary : scheme.onSurfaceVariant),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Твоё имя'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 50,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
        TextButton(onPressed: _submit, child: const Text('Сохранить')),
      ],
    );
  }
}
