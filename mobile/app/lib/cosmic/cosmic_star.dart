import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CosmicStar extends PositionComponent {
  final double depth;
  final double baseSize;
  final double baseSpeed;

  final math.Random _random = math.Random();

  late final double _twinkleSpeed;
  late final double _twinkleOffset;
  late final double _baseOpacity;

  double _time = 0;

  CosmicStar({
    required Vector2 position,
    required this.depth,
    required this.baseSize,
    required this.baseSpeed,
  }) : super(
          position: position,
          anchor: Anchor.center,
        ) {
    _twinkleSpeed = 0.7 + _random.nextDouble() * 2.0;
    _twinkleOffset = _random.nextDouble() * math.pi * 2;

    _baseOpacity = (0.20 + depth * 0.65).clamp(0.20, 0.90);

    // Las estrellas cercanas pueden tener un halo ligeramente mayor.
    size = Vector2.all(
      baseSize * (2.0 + depth * 2.0),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;

    // ----------------------------------------------------------
    // MOVIMIENTO
    // ----------------------------------------------------------

    x += baseSpeed * depth * dt;

    // ----------------------------------------------------------
    // TWINKLE
    // ----------------------------------------------------------

    final pulse =
        0.5 +
        0.5 *
            math.sin(
              _time * _twinkleSpeed +
                  _twinkleOffset,
            );

    final glow = 0.72 + pulse * 0.28;

    scale = Vector2.all(
      0.88 + pulse * 0.12,
    );

    // ----------------------------------------------------------
    // REAPARECER
    // ----------------------------------------------------------

    if (x > 2200) {
      x = -30;
      y = _random.nextDouble() * 1200;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final pulse =
        0.5 +
        0.5 *
            math.sin(
              _time * _twinkleSpeed +
                  _twinkleOffset,
            );

    final opacity =
        (_baseOpacity * (0.78 + pulse * 0.22))
            .clamp(0.05, 1.0);

    // ==========================================================
    // SOFT HALO
    // ==========================================================

    final haloRadius =
        baseSize *
        (2.8 + depth * 2.2);

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(
            alpha: opacity * 0.20,
          ),
          const Color(0xFFB9C9FF).withValues(
            alpha: opacity * 0.08,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: haloRadius,
        ),
      );

    canvas.drawCircle(
      Offset.zero,
      haloRadius,
      haloPaint,
    );

    // ==========================================================
    // MAIN STAR
    // ==========================================================

    final starRadius =
        baseSize *
        (0.65 + depth * 0.35);

    final starPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(
            alpha: opacity,
          ),
          const Color(0xFFEAF1FF).withValues(
            alpha: opacity * 0.85,
          ),
          const Color(0xFF9FB8FF).withValues(
            alpha: opacity * 0.30,
          ),
          Colors.transparent,
        ],
        stops: const [
          0.0,
          0.28,
          0.62,
          1.0,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: starRadius * 2.2,
        ),
      );

    canvas.drawCircle(
      Offset.zero,
      starRadius * 1.8,
      starPaint,
    );

    // ==========================================================
    // BRIGHT CORE
    // ==========================================================

    final corePaint = Paint()
      ..color = Colors.white.withValues(
        alpha: opacity * 0.95,
      );

    canvas.drawCircle(
      Offset.zero,
      math.max(0.35, starRadius * 0.42),
      corePaint,
    );

    // ==========================================================
    // SUBTLE STAR CROSS
    // SOLO EN ESTRELLAS CERCANAS
    // ==========================================================

    if (depth > 0.75 && baseSize > 1.4) {
      final crossPaint = Paint()
        ..color = Colors.white.withValues(
          alpha: opacity * 0.20,
        )
        ..strokeWidth = 0.35
        ..strokeCap = StrokeCap.round;

      final length =
          starRadius * (2.8 + pulse * 0.7);

      canvas.drawLine(
        Offset(-length, 0),
        Offset(length, 0),
        crossPaint,
      );

      canvas.drawLine(
        Offset(0, -length),
        Offset(0, length),
        crossPaint,
      );
    }
  }
}