class AppConfig {
  // Для запуска по Wi-Fi можно указать адрес ПК:
  // flutter run --dart-define=API_HOST=192.168.0.12
  static const _hostOverride = String.fromEnvironment('API_HOST');
  static const int port = 3000;

  // По умолчанию localhost: в Chrome он работает сам,
  // а на Android (телефон и эмулятор) работает через `adb reverse`.
  static String get host => _hostOverride.isNotEmpty ? _hostOverride : 'localhost';

  static String get httpBase => 'http://$host:$port';
  static String get wsBase => 'ws://$host:$port';
}
