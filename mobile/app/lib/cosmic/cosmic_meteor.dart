import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CosmicMeteor extends PositionComponent {
  final double depth;
  final double radius;
  final double speed;
  final double rotationSpeed;

  final math.Random _random;

  late final List<Offset> _surfacePoints;
  late final List<_MeteorCrater> _craters;
  late final List<_SurfaceMark> _surfaceMarks;

  CosmicMeteor({
    required Vector2 position,
    required this.depth,
    required this.radius,
    required this.speed,
    required this.rotationSpeed,
  })  : _random = math.Random(
          // Cada meteorito recibe una forma diferente.
          position.x.toInt() ^
              position.y.toInt() ^
              radius.toInt(),
        ),
        super(
          position: position,
          anchor: Anchor.center,
          size: Vector2.all(radius * 3.0),
        ) {
    _generateSurface();
    _generateCraters();
    _generateSurfaceMarks();

    // Flame utiliza angle para rotación.
    angle = _random.nextDouble() * math.pi * 2;
  }

  // ============================================================
  // SUPERFICIE ORGÁNICA
  // ============================================================

  void _generateSurface() {
    final int count = depth > 0.7
        ? 32
        : depth > 0.4
            ? 26
            : 20;

    _surfacePoints = [];

    for (int i = 0; i < count; i++) {
      final angle =
          (math.pi * 2 / count) * i;

      // Variación compuesta.
      //
      // En lugar de un simple "radio aleatorio",
      // combinamos varias ondas para eliminar
      // cualquier sensación de simetría.
      final wave1 =
          math.sin(angle * 2.0 + 0.7) * 0.045;

      final wave2 =
          math.sin(angle * 5.0 + 1.8) * 0.055;

      final wave3 =
          math.sin(angle * 7.0 + 2.4) * 0.035;

      final noise =
          (_random.nextDouble() - 0.5) * 0.075;

      final scale =
          1.0 +
          wave1 +
          wave2 +
          wave3 +
          noise;

      _surfacePoints.add(
        Offset(
          math.cos(angle) *
              radius *
              scale,
          math.sin(angle) *
              radius *
              scale,
        ),
      );
    }
  }

  // ============================================================
  // CRÁTERES
  // ============================================================

  void _generateCraters() {
    final int count = depth > 0.7
        ? 8
        : depth > 0.4
            ? 5
            : 3;

    _craters = [];

    for (int i = 0; i < count; i++) {
      final angle =
          _random.nextDouble() *
              math.pi *
              2;

      final distance =
          radius *
          (0.10 +
              _random.nextDouble() * 0.58);

      final craterRadius =
          radius *
          (0.055 +
              _random.nextDouble() * 0.11);

      _craters.add(
        _MeteorCrater(
          position: Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance,
          ),
          radius: craterRadius,
          rotation:
              _random.nextDouble() *
                  math.pi *
                  2,
          irregularity:
              0.10 +
              _random.nextDouble() * 0.25,
        ),
      );
    }
  }

  // ============================================================
  // MARCAS DE SUPERFICIE
  // ============================================================

  void _generateSurfaceMarks() {
    final int count = depth > 0.7 ? 10 : 5;

    _surfaceMarks = [];

    for (int i = 0; i < count; i++) {
      final angle =
          _random.nextDouble() *
              math.pi *
              2;

      final distance =
          radius *
          (0.15 +
              _random.nextDouble() * 0.65);

      _surfaceMarks.add(
        _SurfaceMark(
          position: Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance,
          ),
          length:
              radius *
              (0.05 +
                  _random.nextDouble() * 0.12),
          angle: angle +
              (_random.nextDouble() - 0.5),
        ),
      );
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  @override
  void update(double dt) {
    super.update(dt);

    // Movimiento hacia la izquierda.
    x -= speed * depth * dt;

    // Rotación orgánica.
    angle += rotationSpeed * dt;

    // ----------------------------------------------------------
    // RECICLAR METEORITO
    // ----------------------------------------------------------

    if (x < -radius * 4) {
      x =
          1900 +
          _random.nextDouble() * 700;

      y =
          70 +
          _random.nextDouble() * 850;
    }
  }

  // ============================================================
  // RENDER
  // ============================================================

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // ==========================================================
    // HALO ATMOSFÉRICO MUY SUTIL
    // ==========================================================

    final atmospherePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFB8C8DF).withValues(
            alpha: 0.045 * depth,
          ),
          const Color(0xFF78869A).withValues(
            alpha: 0.018 * depth,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: radius * 1.55,
        ),
      );

    canvas.drawCircle(
      Offset.zero,
      radius * 1.55,
      atmospherePaint,
    );

    // ==========================================================
    // CUERPO PRINCIPAL
    // ==========================================================

    final bodyPath =
        _createSmoothOrganicPath();

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(
          -0.40,
          -0.42,
        ),
        radius: 1.15,
        colors: [
          const Color(0xFF9BA7B7),
          const Color(0xFF737F8E),
          const Color(0xFF4A5563),
          const Color(0xFF2C3540),
          const Color(0xFF151B23),
        ],
        stops: const [
          0.0,
          0.25,
          0.48,
          0.74,
          1.0,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: radius * 1.2,
        ),
      );

    canvas.drawPath(
      bodyPath,
      bodyPaint,
    );

    // ==========================================================
    // SOMBRA SUAVE EN EL BORDE
    // ==========================================================

    final shadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(
          0.65,
          0.60,
        ),
        radius: 1.0,
        colors: [
          Colors.transparent,
          const Color(0xFF05080D).withValues(
            alpha: 0.42 * depth,
          ),
        ],
        stops: const [
          0.35,
          1.0,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: radius * 1.25,
        ),
      );

    canvas.drawPath(
      bodyPath,
      shadowPaint,
    );

    // ==========================================================
    // BORDE MUY SUAVE
    // ==========================================================

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          math.max(0.35, radius * 0.018)
      ..color = const Color(0xFFD6E0EF).withValues(
        alpha: 0.18 * depth,
      );

    canvas.drawPath(
      bodyPath,
      edgePaint,
    );

    // ==========================================================
    // CRÁTERES
    // ==========================================================

    for (final crater in _craters) {
      _drawCrater(
        canvas,
        crater,
      );
    }

    // ==========================================================
    // MARCAS NATURALES
    // ==========================================================

    if (depth > 0.4) {
      for (final mark in _surfaceMarks) {
        _drawSurfaceMark(
          canvas,
          mark,
        );
      }
    }

    // ==========================================================
    // PEQUEÑOS PUNTOS DE ROCA
    // ==========================================================

    if (depth > 0.7) {
      _drawFineRockDetails(canvas);
    }
  }

  // ============================================================
  // FORMA ORGÁNICA SUAVE
  // ============================================================

  Path _createSmoothOrganicPath() {
    final path = Path();

    final count = _surfacePoints.length;

    if (count < 3) {
      return path;
    }

    // ----------------------------------------------------------
    // Usamos puntos medios entre cada par de puntos.
    //
    // Esto hace que las transiciones sean curvas y elimina
    // los vértices visibles.
    // ----------------------------------------------------------

    Offset midpoint(
      Offset a,
      Offset b,
    ) {
      return Offset(
        (a.dx + b.dx) / 2,
        (a.dy + b.dy) / 2,
      );
    }

    final first =
        _surfacePoints[0];

    final last =
        _surfacePoints[count - 1];

    final firstMid =
        midpoint(last, first);

    path.moveTo(
      firstMid.dx,
      firstMid.dy,
    );

    for (int i = 0; i < count; i++) {
      final current =
          _surfacePoints[i];

      final next =
          _surfacePoints[
            (i + 1) % count
          ];

      final mid =
          midpoint(current, next);

      path.quadraticBezierTo(
        current.dx,
        current.dy,
        mid.dx,
        mid.dy,
      );
    }

    path.close();

    return path;
  }

  // ============================================================
  // CRÁTER ORGÁNICO
  // ============================================================

  void _drawCrater(
    Canvas canvas,
    _MeteorCrater crater,
  ) {
    canvas.save();

    canvas.translate(
      crater.position.dx,
      crater.position.dy,
    );

    canvas.rotate(
      crater.rotation,
    );

    final r = crater.radius;

    // ----------------------------------------------------------
    // BORDE EXTERIOR
    // ----------------------------------------------------------

    final outerPath =
        _createCraterPath(
      r,
      crater.irregularity,
    );

    final outerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(
          -0.35,
          -0.35,
        ),
        colors: [
          const Color(0xFF8D99A8).withValues(
            alpha: 0.25 * depth,
          ),
          const Color(0xFF333C48).withValues(
            alpha: 0.55,
          ),
          const Color(0xFF151B23).withValues(
            alpha: 0.75,
          ),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: r,
        ),
      );

    canvas.drawPath(
      outerPath,
      outerPaint,
    );

    // ----------------------------------------------------------
    // INTERIOR
    // ----------------------------------------------------------

    final innerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(
          -0.25,
          -0.30,
        ),
        colors: [
          const Color(0xFF080C12).withValues(
            alpha: 0.72,
          ),
          const Color(0xFF202832).withValues(
            alpha: 0.70,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: r * 0.72,
        ),
      );

    canvas.drawCircle(
      Offset.zero,
      r * 0.72,
      innerPaint,
    );

    // ----------------------------------------------------------
    // PARTE ILUMINADA DEL BORDE
    // ----------------------------------------------------------

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth =
          math.max(0.3, r * 0.08)
      ..color = const Color(0xFFD0D9E5).withValues(
        alpha: 0.16 * depth,
      );

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset.zero,
        radius: r * 0.82,
      ),
      math.pi * 0.95,
      math.pi * 0.80,
      false,
      rimPaint,
    );

    canvas.restore();
  }

  // ============================================================
  // FORMA IRREGULAR DEL CRÁTER
  // ============================================================

  Path _createCraterPath(
    double radius,
    double irregularity,
  ) {
    final path = Path();

    const points = 11;

    final offsets = <Offset>[];

    for (int i = 0; i < points; i++) {
      final angle =
          math.pi * 2 / points * i;

      final variation =
          1.0 +
          (_random.nextDouble() - 0.5) *
              irregularity;

      offsets.add(
        Offset(
          math.cos(angle) *
              radius *
              variation,
          math.sin(angle) *
              radius *
              variation,
        ),
      );
    }

    path.moveTo(
      offsets[0].dx,
      offsets[0].dy,
    );

    for (int i = 0; i < points; i++) {
      final current =
          offsets[i];

      final next =
          offsets[(i + 1) % points];

      final mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );

      path.quadraticBezierTo(
        current.dx,
        current.dy,
        mid.dx,
        mid.dy,
      );
    }

    path.close();

    return path;
  }

  // ============================================================
  // MARCAS DE SUPERFICIE
  // ============================================================

  void _drawSurfaceMark(
    Canvas canvas,
    _SurfaceMark mark,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF10161E).withValues(
        alpha: 0.22 * depth,
      )
      ..strokeWidth =
          math.max(0.3, radius * 0.009)
      ..strokeCap = StrokeCap.round;

    final dx =
        math.cos(mark.angle) *
            mark.length;

    final dy =
        math.sin(mark.angle) *
            mark.length;

    canvas.drawLine(
      mark.position,
      Offset(
        mark.position.dx + dx,
        mark.position.dy + dy,
      ),
      paint,
    );
  }

  // ============================================================
  // DETALLE FINO DE ROCA
  // ============================================================

  void _drawFineRockDetails(
    Canvas canvas,
  ) {
    final paint = Paint()
      ..color = const Color(0xFFD5DDE8).withValues(
        alpha: 0.10,
      );

    for (int i = 0; i < 8; i++) {
      final angle =
          _random.nextDouble() *
              math.pi *
              2;

      final distance =
          radius *
          (0.25 +
              _random.nextDouble() * 0.55);

      final position = Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );

      final size =
          radius *
          (0.008 +
              _random.nextDouble() * 0.018);

      canvas.drawCircle(
        position,
        size,
        paint,
      );
    }
  }
}

// ================================================================
// CRATER DATA
// ================================================================

class _MeteorCrater {
  final Offset position;
  final double radius;
  final double rotation;
  final double irregularity;

  const _MeteorCrater({
    required this.position,
    required this.radius,
    required this.rotation,
    required this.irregularity,
  });
}

// ================================================================
// SURFACE MARK DATA
// ================================================================

class _SurfaceMark {
  final Offset position;
  final double length;
  final double angle;

  const _SurfaceMark({
    required this.position,
    required this.length,
    required this.angle,
  });
}