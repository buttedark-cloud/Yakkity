import 'package:flutter/material.dart';
import 'package:yakkity/core/theme/app_theme.dart';
import 'package:yakkity/core/widgets/animated_background.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.onBack});
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // иначе Scaffold закроет фон
        appBar: onBack == null
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0,
                leading: BackButton(onPressed: onBack),
              ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: child),
            ),
          ),
        ),
      ),
    );
  }
}
