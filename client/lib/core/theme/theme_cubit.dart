import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/storage/settings_store.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._settings) : super(ThemeMode.system);

  final SettingsStore _settings;
  static const _key = 'theme_mode';

  /// Читаем сохранённый выбор. Вызывается один раз при старте приложения.
  Future<void> load() async {
    final saved = await _settings.read(_key);
    final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
    if (mode != null) emit(mode);
  }

  Future<void> set(ThemeMode mode) async {
    emit(mode);
    await _settings.write(_key, mode.name);
  }
}
