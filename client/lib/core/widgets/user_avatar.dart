import 'dart:typed_data';

import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.label, required this.colorSeed, this.radius = 24, this.image});

  final String label; // имя или номер, берём первую букву
  final int colorSeed; // id пользователя: цвет у человека всегда один и тот же
  final double radius;
  final Uint8List? image; // фото, если есть

  String get _initial {
    final s = label.replaceAll('+', '').trim();
    return s.isEmpty ? '?' : String.fromCharCode(s.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.primaries[colorSeed % Colors.primaries.length].shade400,
      backgroundImage: image == null ? null : MemoryImage(image!),
      child: image == null
          ? Text(
              _initial,
              style: TextStyle(color: Colors.white, fontSize: radius * 0.75),
            )
          : null,
    );
  }
}
