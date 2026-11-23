import 'dart:math';

import 'package:flutter/material.dart';

/// ===================== НАСТРОЙКИ ФОНА =====================
/// Меняй значения и нажимай R (большая, полный перезапуск), а не r.
class BackgroundSettings {
  static const int count = 12; // сколько фигур на экране
  static const double minSize = 80; // минимальный радиус фигуры
  static const double maxSize = 180; // максимальный радиус
  static const double minOpacity = 0.10; // прозрачность: 0 = не видно, 1 = сплошная
  static const double maxOpacity = 0.30;
  static const double ringThickness = 3; // толщина линии у колец
  static const int periodSeconds = 70; // больше число = медленнее движение
  static const int seed = 20; // другое число = другая расстановка фигур

  // Какие фигуры показывать
  static const bool circles = true;
  static const bool rings = true;
  static const bool squares = true;

  // Цвета. null = взять из темы (красный для кругов и колец, серый для квадратов).
  // Если задать цвет, он будет одинаковым в светлой и тёмной теме.
  // Пример: static const Color? circleColor = Color(0xFFDC2626);
  static const Color? circleColor = null;
  static const Color? ringColor = null;
  static const Color? squareColor = null;
}

/// ===========================================================

enum _Shape { circle, ring, square }

class _Bubble {
  _Bubble(Random r, List<_Shape> shapes)
    : x = r.nextDouble(),
      phase = r.nextDouble(),
      radius = BackgroundSettings.minSize + r.nextDouble() * (BackgroundSettings.maxSize - BackgroundSettings.minSize),
      riseCycles = 1 + r.nextInt(3), // 1..3 подъёма за период
      swayCycles = 1 + r.nextInt(3),
      sway = 0.02 + r.nextDouble() * 0.05,
      alpha = BackgroundSettings.minOpacity + r.nextDouble() * (BackgroundSettings.maxOpacity - BackgroundSettings.minOpacity),
      shape = shapes[r.nextInt(shapes.length)];

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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: BackgroundSettings.periodSeconds),
  );

  late final List<_Bubble> _items = _createItems();

  List<_Bubble> _createItems() {
    final shapes = [
      if (BackgroundSettings.circles) _Shape.circle,
      if (BackgroundSettings.rings) _Shape.ring,
      if (BackgroundSettings.squares) _Shape.square,
    ];
    if (shapes.isEmpty) return const [];
    final random = Random(BackgroundSettings.seed);
    return List.generate(BackgroundSettings.count, (_) => _Bubble(random, shapes));
  }

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

  Color _colorFor(_Shape shape) => switch (shape) {
    _Shape.circle => BackgroundSettings.circleColor ?? primary,
    _Shape.ring => BackgroundSettings.ringColor ?? primary,
    _Shape.square => BackgroundSettings.squareColor ?? neutral,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value; // 0..1 за весь период

    for (final b in items) {
      // Подъём: из-под нижнего края до-за верхний, на концах полностью вне экрана
      final progress = (b.phase + t * b.riseCycles) % 1.0;
      final y = size.height + b.radius - progress * (size.height + 2 * b.radius);
      // Покачивание влево-вправо
      final x = size.width * (b.x + sin((b.phase + t * b.swayCycles) * 2 * pi) * b.sway);

      final paint = Paint()..color = _colorFor(b.shape).withValues(alpha: b.alpha);

      switch (b.shape) {
        case _Shape.circle:
          canvas.drawCircle(Offset(x, y), b.radius, paint);
        case _Shape.ring:
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = BackgroundSettings.ringThickness;
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
