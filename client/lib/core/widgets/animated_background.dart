import 'dart:math';

import 'package:flutter/material.dart';

enum _Shape { circle, ring, square }

class _Bubble {
  _Bubble(Random r)
    : x = r.nextDouble(),
      phase = r.nextDouble(),
      radius = 28 + r.nextDouble() * 72,
      riseCycles = 1 + r.nextInt(3), // 1..3 подъёма за 60 секунд
      swayCycles = 1 + r.nextInt(3),
      sway = 0.02 + r.nextDouble() * 0.05,
      alpha = 0.07 + r.nextDouble() * 0.12,
      shape = _Shape.values[r.nextInt(_Shape.values.length)];

  final double x, phase, radius, sway, alpha;
  final int riseCycles, swayCycles;
  final _Shape shape;
}

/// Фон с плавающими фигурами. Оборачивает экран:
/// AnimatedBackground(child: Scaffold(backgroundColor: Colors.transparent, ...))
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 60));
  final _random = Random(42); // одинаковое расположение при каждом запуске
  late final List<_Bubble> _items = List.generate(12, (_) => _Bubble(_random));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Если в системе включено «уменьшить анимацию», фон стоит на месте
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = Color.alphaBlend(scheme.primary.withValues(alpha: 0.10), scheme.surface);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, scheme.surface]),
          ),
        ),
        RepaintBoundary(child: CustomPaint(painter: _BubblesPainter(_controller, _items, scheme.primary, scheme.onSurfaceVariant))),
        widget.child,
      ],
    );
  }
}

class _BubblesPainter extends CustomPainter {
  _BubblesPainter(this.animation, this.items, this.primary, this.neutral) : super(repaint: animation);

  final Animation<double> animation;
  final List<_Bubble> items;
  final Color primary;
  final Color neutral;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value; // 0..1 за 60 секунд

    for (final b in items) {
      // Подъём: из-под нижнего края до-за верхний, на концах полностью вне экрана
      final progress = (b.phase + t * b.riseCycles) % 1.0;
      final y = size.height + b.radius - progress * (size.height + 2 * b.radius);
      // Покачивание влево-вправо
      final x = size.width * (b.x + sin((b.phase + t * b.swayCycles) * 2 * pi) * b.sway);

      final paint = Paint()..color = (b.shape == _Shape.square ? neutral : primary).withValues(alpha: b.alpha);

      switch (b.shape) {
        case _Shape.circle:
          canvas.drawCircle(Offset(x, y), b.radius, paint);
        case _Shape.ring:
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;
          canvas.drawCircle(Offset(x, y), b.radius, paint);
        case _Shape.square:
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate((b.phase + t * b.swayCycles) * 2 * pi);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: b.radius * 1.6, height: b.radius * 1.6),
              Radius.circular(b.radius * 0.3),
            ),
            paint,
          );
          canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_BubblesPainter old) => old.primary != primary || old.neutral != neutral;
}
