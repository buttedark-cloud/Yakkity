import 'package:flutter/material.dart';

class YakkityLogo extends StatelessWidget {
  const YakkityLogo({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Yakkity',
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -size * 0.03,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
