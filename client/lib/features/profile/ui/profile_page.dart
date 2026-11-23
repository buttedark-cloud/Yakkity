import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yakkity/core/storage/settings_store.dart';
import 'package:yakkity/core/theme/app_theme.dart';
import 'package:yakkity/core/theme/theme_cubit.dart';
import 'package:yakkity/core/utils/rune_length_formatter.dart';
import 'package:yakkity/core/widgets/emoji_panel.dart';
import 'package:yakkity/core/widgets/user_avatar.dart';
import 'package:yakkity/di.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/chat/cubit/chats_cubit.dart';
import 'package:yakkity/features/chat/data/chat_repository.dart';
import 'package:yakkity/features/chat/data/local_message_store.dart';
import 'package:yakkity/features/demo/demo_service.dart';

enum _PhotoAction { gallery, camera, remove }

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _notifKey = 'notifications';

  late final int _me;
  late final Stream<({int total, int mine})> _counts;
  late final String _avatarKey;
  late final DemoService _demo;

  bool _notifications = true;
  bool _demoOn = false;
  bool _demoBusy = false;
  Uint8List? _avatar;

  @override
  void initState() {
    super.initState();
    _me = context.read<AuthCubit>().state.user!.id;
    _counts = getIt<ChatRepository>().watchMessageCounts(_me);
    _avatarKey = 'avatar_$_me';
    _demo = DemoService(getIt<LocalMessageStore>(), getIt<SettingsStore>());

    final settings = getIt<SettingsStore>();
    settings.read(_notifKey).then((value) {
      if (mounted && value != null) {
        setState(() => _notifications = value == 'true');
      }
    });
    settings.read(_avatarKey).then((value) {
      if (mounted && value != null && value.isNotEmpty) {
        setState(() => _avatar = base64Decode(value));
      }
    });
    _demo.isEnabled(_me).then((value) {
      if (mounted) setState(() => _demoOn = value);
    });
  }

  void _setNotifications(bool value) {
    setState(() => _notifications = value);
    getIt<SettingsStore>().write(_notifKey, value.toString());
  }

  Future<void> _toggleDemo(bool value) async {
    if (_demoBusy) return;
    setState(() {
      _demoBusy = true;
      _demoOn = value;
    });
    try {
      if (value) {
        await _demo.enable(_me);
      } else {
        await _demo.disable(_me);
      }
      _showSnack(value
          ? 'Демо-данные добавлены: загляни во вкладку «Чаты»'
          : 'Демо-данные убраны');
    } catch (_) {
      if (mounted) setState(() => _demoOn = !value);
      _showSnack('Не удалось изменить демо-данные');
    } finally {
      if (mounted) setState(() => _demoBusy = false);
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---- Редактирование имени и статуса по нажатию ----
  Future<void> _editText({
    required String title,
    required String initial,
    required int maxLength,
    required bool allowEmpty,
    required Future<void> Function(String value) save,
  }) async {
    final cubit = context.read<AuthCubit>();
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(
        title: title,
        initial: initial,
        maxLength: maxLength,
        allowEmpty: allowEmpty,
      ),
    );
    if (value == null || value == initial) return;

    await save(value);
    final error = cubit.state.error;
    if (error != null) _showSnack(error);
  }

  // ---- Фото (хранится только на этом устройстве) ----
  Future<void> _changePhoto() async {
    final settings = getIt<SettingsStore>();
    final canUseCamera =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
        source: action == _PhotoAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await settings.write(_avatarKey, base64Encode(bytes));
      if (mounted) setState(() => _avatar = bytes);
    } catch (_) {
      _showSnack('Не удалось загрузить фото');
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Чтобы войти снова, понадобится код подтверждения.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Выйти')),
        ],
      ),
    );
    if (ok == true && mounted) context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = context.select((AuthCubit c) => c.state.user);
    if (user == null) return const SizedBox.shrink();

    final cubit = context.read<AuthCubit>();
    final isDark = scheme.brightness == Brightness.dark;
    final shownName = user.hasName ? user.name! : user.phone;
    final chatsCount = context.select((ChatsCubit c) => c.state.items.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль и настройки',
            style: TextStyle(fontWeight: FontWeight.w700)),
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
                              colors: isDark
                                  ? const [Color(0xFFC62828), Color(0xFF7F1D1D)]
                                  : const [Color(0xFFE04848), Color(0xFF9B2C2C)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _AvatarWithBadge(
                            label: shownName,
                            seed: user.id,
                            image: _avatar,
                            onCamera: _changePhoto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Имя: по центру, длинное переносится на следующие строки
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _editText(
                    title: 'Твоё имя',
                    initial: user.name ?? '',
                    maxLength: 50,
                    allowEmpty: false,
                    save: cubit.saveName,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                    child: Text(
                      shownName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Text(user.phone,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.md),

                // Статус: тоже по центру и с переносом строк
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Material(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _editText(
                        title: 'Статус',
                        initial: user.status ?? '',
                        maxLength: 100,
                        allowEmpty: true,
                        save: cubit.saveStatus,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 12),
                        child: Text(
                          user.hasStatus ? user.status! : 'Добавить статус',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: user.hasStatus
                                ? scheme.onSurface
                                : scheme.primary,
                            fontWeight: user.hasStatus
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Нажми на имя или статус, чтобы изменить',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
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
                          _Stat(
                              value: '${counts?.total ?? 0}',
                              label: 'Сообщений'),
                          const SizedBox(width: AppSpacing.sm),
                          _Stat(
                              value: '${counts?.mine ?? 0}',
                              label: 'Отправлено'),
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
                subtitle: isDark
                    ? 'Тёмное оформление включено'
                    : 'Светлое оформление включено',
                trailing: Switch(
                  value: isDark,
                  onChanged: (v) => context
                      .read<ThemeCubit>()
                      .set(v ? ThemeMode.dark : ThemeMode.light),
                ),
                onTap: () => context
                    .read<ThemeCubit>()
                    .set(isDark ? ThemeMode.light : ThemeMode.dark),
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
                trailing: Checkbox(
                  value: _notifications,
                  onChanged: (v) => _setNotifications(v ?? true),
                ),
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
                  applicationLegalese:
                      'Учебный проект: мессенджер на Flutter и Dart',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ---- Для превью ----
          _Section(
            title: 'ДЛЯ ПРЕВЬЮ',
            children: [
              _SettingTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Демо-данные',
                subtitle:
                    'Заполнить чаты вымышленными людьми. Хранятся только на этом устройстве',
                trailing: Switch(
                  value: _demoOn,
                  onChanged: _demoBusy ? null : _toggleDemo,
                ),
                onTap: _demoBusy ? null : () => _toggleDemo(!_demoOn),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ---- Выход ----
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Выйти из профиля',
                  style: TextStyle(
                      color: scheme.error, fontWeight: FontWeight.w600)),
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
  const _AvatarWithBadge({
    required this.label,
    required this.seed,
    required this.onCamera,
    this.image,
  });

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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerLowest,
          ),
          child: UserAvatar(
              label: label, colorSeed: seed, radius: 46, image: image),
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
                child:
                    Icon(Icons.photo_camera, size: 16, color: scheme.onPrimary),
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
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: scheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
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
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 10),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 72),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.highlighted = false,
  });

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
          color: highlighted
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            size: 22,
            color: highlighted ? scheme.primary : scheme.onSurfaceVariant),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
    );
  }
}

/// Диалог с одним полем для имени и статуса. Смайлики: кнопка в углу поля.
/// Это обычный Dialog, а не AlertDialog: сетка смайликов не ладит с его вёрсткой.
class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.initial,
    required this.maxLength,
    required this.allowEmpty,
  });

  final String title;
  final String initial;
  final int maxLength;
  final bool allowEmpty;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _focus = FocusNode();
  bool _emojiOpen = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus && _emojiOpen) setState(() => _emojiOpen = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggleEmoji() {
    if (_emojiOpen) {
      setState(() => _emojiOpen = false);
      _focus.requestFocus();
    } else {
      _focus.unfocus();
      setState(() => _emojiOpen = true);
    }
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty && !widget.allowEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final count = _controller.text.runes.length;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [RuneLengthFormatter(widget.maxLength)],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  counterText: '$count/${widget.maxLength}',
                  suffixIcon: IconButton(
                    tooltip: _emojiOpen ? 'Клавиатура' : 'Смайлики',
                    icon: Icon(_emojiOpen
                        ? Icons.keyboard_alt_outlined
                        : Icons.emoji_emotions_outlined),
                    onPressed: _toggleEmoji,
                  ),
                ),
              ),
              if (_emojiOpen)
                EmojiPanel(
                  height: 200,
                  onSelected: (e) {
                    insertTextAtCursor(_controller, e,
                        maxRunes: widget.maxLength);
                    setState(() {});
                  },
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                      onPressed: _submit, child: const Text('Сохранить')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
