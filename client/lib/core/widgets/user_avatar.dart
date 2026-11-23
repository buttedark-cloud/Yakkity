import 'dart:typed_data';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.label,
    required this.colorSeed,
    this.radius = 24,
    this.image,
    this.assetPath,
  });

  final String label; // имя или номер, берём первую букву
  final int colorSeed; // id пользователя: цвет у человека всегда один и тот же
  final double radius;
  final Uint8List? image; // своё фото (из памяти устройства)
  final String? assetPath; // фото из assets (для демо-людей)

  String get _initial {
    final s = label.replaceAll('+', '').trim();
    return s.isEmpty ? '?' : String.fromCharCode(s.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasMemory = image != null;
    final hasAsset = !hasMemory && assetPath != null;

    return CircleAvatar(
      radius: radius,
      backgroundColor:
          Colors.primaries[colorSeed % Colors.primaries.length].shade400,
      backgroundImage: hasMemory ? MemoryImage(image!) : null,
      // Если файла в assets нет, остаётся буква: приложение не падает
      foregroundImage: hasAsset ? AssetImage(assetPath!) : null,
      onForegroundImageError: hasAsset ? (_, _) {} : null,
      child: hasMemory
          ? null
          : Text(_initial,
              style: TextStyle(color: Colors.white, fontSize: radius * 0.75)),
    );
  }
}
