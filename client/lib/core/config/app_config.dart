import 'package:flutter/foundation.dart';

class AppConfig {
  // Для запуска на телефоне: flutter run --dart-define=API_HOST=192.168.1.5
  static const _hostOverride = String.fromEnvironment('API_HOST');
  static const int port = 3000;

  static String get host {
    if (_hostOverride.isNotEmpty) return _hostOverride;
    if (kIsWeb) return 'localhost';
    // У Android-эмулятора localhost означает сам эмулятор, а не ПК
    return defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
  }

  static String get httpBase => 'http://$host:$port';
  static String get wsBase => 'ws://$host:$port';
}
