import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// ============================================================
/// NAOS — CYBERPUNK MAJESTIC SHIP
/// ============================================================
///
/// Nave completamente procedural.
/// No utiliza imágenes ni assets.
///
/// Características:
/// - Fuselaje curvo
/// - Armadura multicapa
/// - Alas integradas
/// - Dos propulsores unidos al fuselaje
/// - Plasma
/// - Partículas
/// - Estela dinámica
/// - Cockpit energético
/// - Iluminación cyberpunk
/// - Bloom reforzado
/// - Movimiento flotante
/// ============================================================

class CosmicShip extends PositionComponent {
  CosmicShip({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(340, 190),
          anchor: Anchor.center,
        );

  final math.Random _random = math.Random();

  final List<_EngineParticle> _particles = [];
  final List<_TrailPoint> _trail = [];

  double _time = 0;
  double velocityX = 42;

  double _lastFloat = 0;

  // ==========================================================
  // GEOMETRÍA PRINCIPAL
  // ==========================================================

  static const double _engineX = -105;

  static const double _upperEngineY = -27;

  static const double _lowerEngineY = 27;

  // ==========================================================
  // CARGA
  // ==========================================================

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    for (int i = 0; i < 70; i++) {
      _particles.add(
        _EngineParticle(
          engine: i.isEven ? 0 : 1,
          random: _random,
        ),
      );
    }
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;

    x += velocityX * dt;

    final float =
        math.sin(_time * 1.25) * 3.0 +
        math.sin(_time * 2.4) * 0.8;

    y += float - _lastFloat;

    _lastFloat = float;

    angle = math.sin(_time * 1.1) * 0.018;

    for (final particle in _particles) {
      particle.update(
        dt,
        _time,
      );
    }

    _updateTrail(dt);

    if (x > 2350) {
      x = -350;
      _trail.clear();
    }
  }

  // ==========================================================
  // TRAIL UPDATE
  // ==========================================================

  void _updateTrail(double dt) {
    for (final point in _trail) {
      point.x -= velocityX * dt;

      point.y +=
          math.sin(
                _time * 7 +
                    point.phase,
              ) *
              dt *
              3.0;

      point.age += dt;
    }

    _trail.add(
      _TrailPoint(
        x: _engineX - 2,
        y: _upperEngineY,
        age: 0,
        engine: 0,
        phase: _random.nextDouble() * math.pi * 2,
      ),
    );

    _trail.add(
      _TrailPoint(
        x: _engineX - 2,
        y: _lowerEngineY,
        age: 0,
        engine: 1,
        phase: _random.nextDouble() * math.pi * 2,
      ),
    );

    // La estela dura menos de un segundo.
    _trail.removeWhere(
      (point) => point.age > 0.75,
    );
  }

  // ==========================================================
  // RENDER
  // ==========================================================

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();

    final center = Offset(
      size.x / 2,
      size.y / 2,
    );

    canvas.translate(
      center.dx,
      center.dy,
    );

    // ========================================================
    // BLOOM GENERAL DE LA NAVE
    // ========================================================

    _drawAtmosphericGlow(canvas);
    // ========================================================
// ILUMINACIÓN AVANZADA
// ========================================================

_drawAdvancedLighting(canvas);

    // ========================================================
    // ESTELA
    // ========================================================

    _drawTrail(canvas);

    // ========================================================
    // PROPULSORES
    // ========================================================

    _drawEnginePlasma(
      canvas,
      const Offset(
        _engineX,
        _upperEngineY,
      ),
      0,
    );

    _drawEnginePlasma(
      canvas,
      const Offset(
        _engineX,
        _lowerEngineY,
      ),
      1,
    );

    // ========================================================
    // PARTÍCULAS
    // ========================================================

    _drawEngineParticles(canvas);

    // ========================================================
    // SOMBRA
    // ========================================================

    _drawHullShadow(canvas);

    // ========================================================
    // FUSELAJE
    // ========================================================

    _drawMainFuselage(canvas);

    // ========================================================
    // MOTORES
    // ========================================================

    _drawEngineNacelles(canvas);

    // ========================================================
    // ALAS
    // ========================================================

    _drawUpperWing(canvas);

    _drawLowerWing(canvas);

    // ========================================================
    // ARMADURA
    // ========================================================

    _drawRearArmor(canvas);

    // ========================================================
    // ESPINA CENTRAL
    // ========================================================

    _drawCentralSpine(canvas);

    // ========================================================
    // COCKPIT
    // ========================================================

    _drawCockpit(canvas);

    // ========================================================
    // CANALES DE ENERGÍA
    // ========================================================

    _drawEnergyChannels(canvas);

    // ========================================================
    // PANELES
    // ========================================================

    _drawHullPanels(canvas);

    // ========================================================
    // LUCES
    // ========================================================

    _drawMicroLights(canvas);

    // ========================================================
    // BOQUILLAS
    // ========================================================

    _drawEngineNozzle(
      canvas,
      const Offset(
        _engineX,
        _upperEngineY,
      ),
      0,
    );

    _drawEngineNozzle(
      canvas,
      const Offset(
        _engineX,
        _lowerEngineY,
      ),
      1,
    );

    // ========================================================
    // LUCES DE BORDE
    // ========================================================

    _drawEdgeLights(canvas);

    canvas.restore();
  }

  // ============================================================
  // ATMOSPHERIC BLOOM
  // ============================================================

  void _drawAtmosphericGlow(Canvas canvas) {
    final pulse =
        0.85 +
        math.sin(_time * 2.5) * 0.15;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(
            0xFF625CFF,
          ).withValues(
            alpha: 0.16 * pulse,
          ),
          const Color(
            0xFF20D9FF,
          ).withValues(
            alpha: 0.065 * pulse,
          ),
          const Color(
            0xFF8A4FFF,
          ).withValues(
            alpha: 0.025 * pulse,
          ),
          Colors.transparent,
        ],
        stops: const [
          0.0,
          0.35,
          0.62,
          1.0,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: 155,
        ),
      );

    canvas.drawCircle(
      Offset.zero,
      155,
      paint,
    );

    // Halo secundario mucho más pequeño.
    final innerGlow = Paint()
      ..color = const Color(
        0xFF66B8FF,
      ).withValues(
        alpha: 0.045 * pulse,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        20,
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 215,
        height: 105,
      ),
      innerGlow,
    );
  }
// ============================================================
// ADVANCED LIGHTING
// ============================================================

void _drawAdvancedLighting(Canvas canvas) {
  final enginePulse =
      0.88 +
      math.sin(_time * 9.0) * 0.07 +
      math.sin(_time * 17.0) * 0.025;

  final cockpitPulse =
      0.90 +
      math.sin(_time * 4.0) * 0.10;

  // ==========================================================
  // LUZ AMBIENTAL DEL COCKPIT
  // ==========================================================

  final cockpitLight = Paint()
    ..shader = RadialGradient(
      colors: [
        const Color(0xFF62BFFF).withValues(
          alpha: 0.13 * cockpitPulse,
        ),
        const Color(0xFF397DFF).withValues(
          alpha: 0.055 * cockpitPulse,
        ),
        Colors.transparent,
      ],
      stops: const [
        0.0,
        0.42,
        1.0,
      ],
    ).createShader(
      Rect.fromCircle(
        center: const Offset(58, 0),
        radius: 85,
      ),
    );

  canvas.drawCircle(
    const Offset(58, 0),
    85,
    cockpitLight,
  );

  // ==========================================================
  // REFLEJO SOBRE LA PARTE SUPERIOR DEL FUSELAJE
  // ==========================================================

  final upperReflection = Paint()
    ..shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        const Color(0xFF6FDFFF).withValues(
          alpha: 0.05 * cockpitPulse,
        ),
        const Color(0xFFB7E9FF).withValues(
          alpha: 0.12 * cockpitPulse,
        ),
        Colors.transparent,
      ],
      stops: const [
        0.0,
        0.35,
        0.65,
        1.0,
      ],
    ).createShader(
      const Rect.fromLTWH(
        -55,
        -34,
        130,
        18,
      ),
    );

  final upperReflectionPath = Path()
    ..moveTo(-55, -28)
    ..cubicTo(
      -15,
      -39,
      35,
      -39,
      76,
      -25,
    )
    ..cubicTo(
      38,
      -32,
      -10,
      -33,
      -55,
      -28,
    )
    ..close();

  canvas.drawPath(
    upperReflectionPath,
    upperReflection,
  );

  // ==========================================================
  // LUZ DE PROPULSORES
  // ==========================================================

  _drawEngineLight(
    canvas,
    const Offset(
      _engineX + 15,
      _upperEngineY,
    ),
    enginePulse,
    0,
  );

  _drawEngineLight(
    canvas,
    const Offset(
      _engineX + 15,
      _lowerEngineY,
    ),
    enginePulse,
    1,
  );

  // ==========================================================
  // REFLEJO INFERIOR
  // ==========================================================

  final lowerReflection = Paint()
    ..shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        const Color(0xFF755BFF).withValues(
          alpha: 0.035 * enginePulse,
        ),
        const Color(0xFF5FA5FF).withValues(
          alpha: 0.075 * enginePulse,
        ),
        Colors.transparent,
      ],
    ).createShader(
      const Rect.fromLTWH(
        -70,
        15,
        120,
        20,
      ),
    );

  final lowerPath = Path()
    ..moveTo(-70, 23)
    ..cubicTo(
      -25,
      37,
      28,
      39,
      68,
      23,
    )
    ..cubicTo(
      32,
      34,
      -18,
      35,
      -70,
      23,
    )
    ..close();

  canvas.drawPath(
    lowerPath,
    lowerReflection,
  );
}

// ============================================================
// ENGINE LIGHT
// ============================================================

void _drawEngineLight(
  Canvas canvas,
  Offset position,
  double pulse,
  int engineIndex,
) {
  final phase =
      engineIndex * 1.73;

  final variation =
      0.90 +
      math.sin(
            _time * 11.0 +
                phase,
          ) *
          0.06;

  // ==========================================================
  // AURA GRANDE
  // ==========================================================

  final aura = Paint()
    ..shader = RadialGradient(
      colors: [
        const Color(0xFF8EBBFF).withValues(
          alpha: 0.12 * pulse * variation,
        ),
        const Color(0xFF625CFF).withValues(
          alpha: 0.055 * pulse * variation,
        ),
        Colors.transparent,
      ],
      stops: const [
        0.0,
        0.42,
        1.0,
      ],
    ).createShader(
      Rect.fromCircle(
        center: position,
        radius: 48,
      ),
    );

  canvas.drawCircle(
    position,
    48,
    aura,
  );

  // ==========================================================
  // REFLEJO CONCENTRADO
  // ==========================================================

  final reflection = Paint()
    ..color = const Color(
      0xFF8FC8FF,
    ).withValues(
      alpha: 0.08 * pulse * variation,
    )
    ..maskFilter = const MaskFilter.blur(
      BlurStyle.normal,
      8,
    );

  canvas.drawOval(
    Rect.fromCenter(
      center: position.translate(
        18,
        0,
      ),
      width: 50,
      height: 24,
    ),
    reflection,
  );
}
  // ============================================================
  // TRAIL
  // ============================================================

  void _drawTrail(Canvas canvas) {
    for (final point in _trail) {
      final life =
          1.0 -
          (point.age / 0.75);

      if (life <= 0) {
        continue;
      }

      final fade =
          math.pow(
            life,
            1.6,
          ).toDouble();

      final color =
          point.engine == 0
              ? const Color(
                  0xFF765BFF,
                )
              : const Color(
                  0xFF4C8CFF,
                );

      // --------------------------------------------------------
      // BLOOM EXTERIOR
      // --------------------------------------------------------

      final outerGlow = Paint()
        ..color = color.withValues(
          alpha: 0.10 * fade,
        )
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          13 + 12 * fade,
        );

      canvas.drawCircle(
        Offset(
          point.x,
          point.y,
        ),
        8 + 9 * fade,
        outerGlow,
      );

      // --------------------------------------------------------
      // GLOW PRINCIPAL
      // --------------------------------------------------------

      final glow = Paint()
        ..color = color.withValues(
          alpha: 0.22 * fade,
        )
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          8 + 7 * fade,
        );

      canvas.drawCircle(
        Offset(
          point.x,
          point.y,
        ),
        5 + 7 * fade,
        glow,
      );

      // --------------------------------------------------------
      // CUERPO
      // --------------------------------------------------------

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(
              alpha: 0.70 * fade,
            ),
            color.withValues(
              alpha: 0.60 * fade,
            ),
            color.withValues(
              alpha: 0.16 * fade,
            ),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(
            point.x,
            point.y - 4,
            70,
            8,
          ),
        )
        ..strokeWidth =
            3.8 * fade
        ..style =
            PaintingStyle.stroke
        ..strokeCap =
            StrokeCap.round;

      canvas.drawLine(
        Offset(
          point.x,
          point.y,
        ),
        Offset(
          point.x - 25 - 35 * life,
          point.y,
        ),
        paint,
      );

      // --------------------------------------------------------
      // NÚCLEO
      // --------------------------------------------------------

      final core = Paint()
        ..color = Colors.white.withValues(
          alpha: 0.48 * fade,
        )
        ..strokeWidth =
            1.2 * fade
        ..strokeCap =
            StrokeCap.round;

      canvas.drawLine(
        Offset(
          point.x,
          point.y,
        ),
        Offset(
          point.x - 18 - 22 * life,
          point.y,
        ),
        core,
      );
    }
  }

  // ============================================================
  // HULL SHADOW
  // ============================================================

  void _drawHullShadow(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(
        0x55000000,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        13,
      );

    final path = Path()
      ..moveTo(-92, 12)
      ..cubicTo(
        -35,
        48,
        55,
        48,
        105,
        10,
      )
      ..cubicTo(
        58,
        60,
        -35,
        60,
        -92,
        12,
      )
      ..close();

    canvas.drawPath(
      path,
      paint,
    );
  }

  // ============================================================
  // MAIN FUSELAGE
  // ============================================================

  void _drawMainFuselage(Canvas canvas) {
    final hull = Path()
      ..moveTo(120, 0)
      ..cubicTo(
        105,
        -12,
        87,
        -29,
        55,
        -36,
      )
      ..cubicTo(
        18,
        -45,
        -37,
        -43,
        -82,
        -27,
      )
      ..cubicTo(
        -105,
        -19,
        -116,
        -8,
        -114,
        0,
      )
      ..cubicTo(
        -116,
        8,
        -105,
        19,
        -82,
        27,
      )
      ..cubicTo(
        -37,
        43,
        18,
        45,
        55,
        36,
      )
      ..cubicTo(
        87,
        29,
        105,
        12,
        120,
        0,
      )
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE4EDFF),
          Color(0xFF9AAAD1),
          Color(0xFF526181),
          Color(0xFF182039),
        ],
        stops: [
          0,
          0.28,
          0.65,
          1,
        ],
      ).createShader(
        const Rect.fromLTWH(
          -120,
          -45,
          240,
          90,
        ),
      );

    canvas.drawPath(
      hull,
      paint,
    );

    // --------------------------------------------------------
    // PANEL CENTRAL
    // --------------------------------------------------------

    final centerPanel = Path()
      ..moveTo(-78, -12)
      ..cubicTo(
        -35,
        -29,
        32,
        -30,
        80,
        -13,
      )
      ..cubicTo(
        40,
        -20,
        -25,
        -21,
        -78,
        -12,
      )
      ..close();

    final panelPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF8799C4),
          Color(0xFF3C4868),
        ],
      ).createShader(
        const Rect.fromLTWH(
          -80,
          -30,
          165,
          25,
        ),
      );

    canvas.drawPath(
      centerPanel,
      panelPaint,
    );

    // --------------------------------------------------------
    // UNDERSIDE
    // --------------------------------------------------------

    final underside = Path()
      ..moveTo(-90, 9)
      ..cubicTo(
        -45,
        32,
        18,
        36,
        76,
        17,
      )
      ..cubicTo(
        38,
        39,
        -34,
        42,
        -84,
        24,
      )
      ..close();

    final undersidePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF465475),
          Color(0xFF101527),
        ],
      ).createShader(
        const Rect.fromLTWH(
          -95,
          8,
          175,
          38,
        ),
      );

    canvas.drawPath(
      underside,
      undersidePaint,
    );
  }

  // ============================================================
  // ENGINE NACELLES
  // ============================================================

  void _drawEngineNacelles(Canvas canvas) {
    final metal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFAAB9D8),
          Color(0xFF596A91),
          Color(0xFF171D32),
        ],
      ).createShader(
        const Rect.fromLTWH(
          -115,
          -48,
          62,
          96,
        ),
      );

    final upper = Path()
      ..moveTo(-114, -12)
      ..cubicTo(
        -105,
        -27,
        -91,
        -38,
        -67,
        -34,
      )
      ..lineTo(-54, -24)
      ..cubicTo(
        -72,
        -23,
        -91,
        -18,
        -106,
        -7,
      )
      ..close();

    canvas.drawPath(
      upper,
      metal,
    );

    final lower = Path()
      ..moveTo(-114, 12)
      ..cubicTo(
        -105,
        27,
        -91,
        38,
        -67,
        34,
      )
      ..lineTo(-54, 24)
      ..cubicTo(
        -72,
        23,
        -91,
        18,
        -106,
        7,
      )
      ..close();

    canvas.drawPath(
      lower,
      metal,
    );

    // --------------------------------------------------------
    // UNIONES
    // --------------------------------------------------------

    final connectorPaint = Paint()
      ..color = const Color(
        0xFF697A9D,
      );

    final upperConnector = Path()
      ..moveTo(-86, -25)
      ..lineTo(-61, -21)
      ..lineTo(-58, -13)
      ..lineTo(-91, -14)
      ..close();

    canvas.drawPath(
      upperConnector,
      connectorPaint,
    );

    final lowerConnector = Path()
      ..moveTo(-86, 25)
      ..lineTo(-61, 21)
      ..lineTo(-58, 13)
      ..lineTo(-91, 14)
      ..close();

    canvas.drawPath(
      lowerConnector,
      connectorPaint,
    );
  }

  // ============================================================
  // UPPER WING
  // ============================================================

  void _drawUpperWing(Canvas canvas) {
    final wing = Path()
      ..moveTo(35, -28)
      ..cubicTo(
        8,
        -31,
        -25,
        -36,
        -54,
        -31,
      )
      ..cubicTo(
        -70,
        -29,
        -88,
        -38,
        -103,
        -51,
      )
      ..cubicTo(
        -82,
        -49,
        -58,
        -45,
        -31,
        -40,
      )
      ..cubicTo(
        -4,
        -35,
        24,
        -31,
        48,
        -25,
      )
      ..cubicTo(
        43,
        -24,
        39,
        -25,
        35,
        -28,
      )
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFC5D5F7),
          Color(0xFF687AA2),
          Color(0xFF1A223C),
        ],
      ).createShader(
        const Rect.fromLTWH(
          -105,
          -54,
          155,
          32,
        ),
      );

    canvas.drawPath(
      wing,
      paint,
    );

    final edge = Paint()
      ..color = const Color(
        0xFF55E9FF,
      ).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final edgePath = Path()
      ..moveTo(34, -27)
      ..cubicTo(
        4,
        -32,
        -27,
        -36,
        -53,
        -32,
      )
      ..cubicTo(
        -71,
        -30,
        -88,
        -39,
        -102,
        -50,
      );

    canvas.drawPath(
      edgePath,
      edge,
    );

    final energy = Paint()
      ..color = const Color(
        0xFFB76CFF,
      ).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final energyPath = Path()
      ..moveTo(20, -29)
      ..cubicTo(
        -5,
        -33,
        -29,
        -37,
        -49,
        -34,
      )
      ..cubicTo(
        -65,
        -32,
        -78,
        -38,
        -88,
        -45,
      );

    canvas.drawPath(
      energyPath,
      energy,
    );
  }

  // ============================================================
  // LOWER WING
  // ============================================================

  void _drawLowerWing(Canvas canvas) {
    final wing = Path()
      ..moveTo(35, 28)
      ..cubicTo(
        8,
        31,
        -25,
        36,
        -54,
        31,
      )
      ..cubicTo(
        -70,
        29,
        -88,
        38,
        -103,
        51,
      )
      ..cubicTo(
        -82,
        49,
        -58,
        45,
        -31,
        40,
      )
      ..cubicTo(
        -4,
        35,
        24,
        31,
        48,
        25,
      )
      ..cubicTo(
        43,
        24,
        39,
        25,
        35,
        28,
      )
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF9EAFD4),
          Color(0xFF596B91),
          Color(0xFF161D34),
        ],
      ).createShader(
        const Rect.fromLTWH(
          -105,
          22,
          155,
          32,
        ),
      );

    canvas.drawPath(
      wing,
      paint,
    );

    final edge = Paint()
      ..color = const Color(
        0xFFB56CFF,
      ).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final edgePath = Path()
      ..moveTo(34, 27)
      ..cubicTo(
        4,
        32,
        -27,
        36,
        -53,
        32,
      )
      ..cubicTo(
        -71,
        30,
        -88,
        39,
        -102,
        50,
      );

    canvas.drawPath(
      edgePath,
      edge,
    );
  }

  // ============================================================
  // REAR ARMOR
  // ============================================================

  void _drawRearArmor(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(
        0xFF27324F,
      );

    final upper = Path()
      ..moveTo(-91, -15)
      ..lineTo(-119, -5)
      ..lineTo(-119, -17)
      ..lineTo(-91, -26)
      ..close();

    final lower = Path()
      ..moveTo(-91, 15)
      ..lineTo(-119, 5)
      ..lineTo(-119, 17)
      ..lineTo(-91, 26)
      ..close();

    canvas.drawPath(
      upper,
      paint,
    );

    canvas.drawPath(
      lower,
      paint,
    );
  }

  // ============================================================
  // CENTRAL SPINE
  // ============================================================

  void _drawCentralSpine(Canvas canvas) {
    final spine = Path()
      ..moveTo(-80, -7)
      ..cubicTo(
        -35,
        -12,
        30,
        -12,
        93,
        -5,
      )
      ..lineTo(104, 0)
      ..lineTo(93, 5)
      ..cubicTo(
        30,
        12,
        -35,
        12,
        -80,
        7,
      )
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFBFCDF0),
          Color(0xFF66789F),
          Color(0xFF252E49),
        ],
      ).createShader(
        const Rect.fromLTWH(
          -85,
          -14,
          195,
          28,
        ),
      );

    canvas.drawPath(
      spine,
      paint,
    );
  }

  // ============================================================
  // COCKPIT
  // ============================================================

  void _drawCockpit(Canvas canvas) {
    final pulse =
        0.90 +
        math.sin(_time * 4.0) * 0.10;

    // --------------------------------------------------------
    // BLOOM EXTERIOR
    // --------------------------------------------------------

    final outerGlow = Paint()
      ..color = const Color(
        0xFF4C9CFF,
      ).withValues(
        alpha: 0.11 * pulse,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        22,
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(
          79,
          0,
        ),
        width: 82,
        height: 60,
      ),
      outerGlow,
    );

    // --------------------------------------------------------
    // GLOW PRINCIPAL
    // --------------------------------------------------------

    final glow = Paint()
      ..color = const Color(
        0xFF4C9CFF,
      ).withValues(
        alpha: 0.20 * pulse,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        13,
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(
          79,
          0,
        ),
        width: 60,
        height: 45,
      ),
      glow,
    );

    final cockpit = Path()
      ..moveTo(49, -17)
      ..cubicTo(
        63,
        -24,
        82,
        -23,
        98,
        -13,
      )
      ..cubicTo(
        108,
        -7,
        111,
        0,
        108,
        0,
      )
      ..cubicTo(
        111,
        0,
        108,
        7,
        98,
        13,
      )
      ..cubicTo(
        82,
        23,
        63,
        24,
        49,
        17,
      )
      ..cubicTo(
        58,
        9,
        61,
        -9,
        49,
        -17,
      )
      ..close();

    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFE9FAFF),
          Color(0xFF75C5FF),
          Color(0xFF194A9A),
          Color(0xFF08162F),
        ],
      ).createShader(
        Rect.fromCircle(
          center: const Offset(
            78,
            0,
          ),
          radius: 35,
        ),
      );

    canvas.drawPath(
      cockpit,
      paint,
    );

    final reflection = Paint()
      ..color = Colors.white.withValues(
        alpha: 0.48,
      )
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCenter(
        center: const Offset(
          78,
          -1,
        ),
        width: 46,
        height: 27,
      ),
      math.pi * 1.05,
      math.pi * 0.75,
      false,
      reflection,
    );
  }

  // ============================================================
  // ENERGY CHANNELS
  // ============================================================

  void _drawEnergyChannels(Canvas canvas) {
    final pulse =
        0.5 +
        ((math.sin(
                    _time * 4,
                  ) +
                1) /
            2) *
            0.5;

    final cyan = Paint()
      ..color = const Color(
        0xFF52ECFF,
      ).withValues(alpha: pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final violet = Paint()
      ..color = const Color(
        0xFFAE6CFF,
      ).withValues(alpha: pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final upper = Path()
      ..moveTo(-69, -13)
      ..cubicTo(
        -30,
        -23,
        20,
        -24,
        63,
        -12,
      );

    final lower = Path()
      ..moveTo(-69, 13)
      ..cubicTo(
        -30,
        23,
        20,
        24,
        63,
        12,
      );

    canvas.drawPath(
      upper,
      cyan,
    );

    canvas.drawPath(
      lower,
      violet,
    );
  }

  // ============================================================
  // HULL PANELS
  // ============================================================

  void _drawHullPanels(Canvas canvas) {
    final panelPaint = Paint()
      ..color = const Color(
        0xFF273451,
      ).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final upper = Path()
      ..moveTo(-47, -24)
      ..lineTo(-10, -30)
      ..lineTo(20, -27)
      ..lineTo(4, -19)
      ..close();

    final lower = Path()
      ..moveTo(-47, 24)
      ..lineTo(-10, 30)
      ..lineTo(20, 27)
      ..lineTo(4, 19)
      ..close();

    canvas.drawPath(
      upper,
      panelPaint,
    );

    canvas.drawPath(
      lower,
      panelPaint,
    );

    canvas.drawLine(
      const Offset(-30, -25),
      const Offset(-22, -11),
      panelPaint,
    );

    canvas.drawLine(
      const Offset(-30, 25),
      const Offset(-22, 11),
      panelPaint,
    );
  }

  // ============================================================
  // MICRO LIGHTS
  // ============================================================

  void _drawMicroLights(Canvas canvas) {
    final pulse =
        0.35 +
        ((math.sin(
                    _time * 6,
                  ) +
                1) /
            2) *
            0.65;

    final cyan = Paint()
      ..color = const Color(
        0xFF5DEFFF,
      ).withValues(alpha: pulse)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        3,
      );

    final violet = Paint()
      ..color = const Color(
        0xFFAE70FF,
      ).withValues(alpha: pulse)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        3,
      );

    const points = [
      Offset(-58, -15),
      Offset(-39, -19),
      Offset(-18, -22),
      Offset(5, -22),
      Offset(28, -18),
      Offset(48, -13),
      Offset(-58, 15),
      Offset(-39, 19),
      Offset(-18, 22),
      Offset(5, 22),
      Offset(28, 18),
      Offset(48, 13),
    ];

    for (final point in points) {
      canvas.drawCircle(
        point,
        1.1,
        cyan,
      );
    }

    canvas.drawCircle(
      const Offset(-76, -17),
      1.4,
      violet,
    );

    canvas.drawCircle(
      const Offset(-76, 17),
      1.4,
      violet,
    );
  }

  // ============================================================
  // ENGINE PLASMA
  // ============================================================

  void _drawEnginePlasma(
  Canvas canvas,
  Offset position,
  int engineIndex,
) {
  final phase = engineIndex * 1.73;

  final pulse =
      0.92 +
      math.sin(_time * 9.0 + phase) * 0.055 +
      math.sin(_time * 17.0 + phase) * 0.025;

  final turbulence =
      math.sin(_time * 13.0 + phase) * 0.06;

  final length = 92 * pulse;
  final width = 24 * pulse;

  // ========================================================
  // AURA EXTERIOR
  // ========================================================

  final outerGlow = Paint()
    ..color = const Color(
      0xFF735CFF,
    ).withValues(
      alpha: 0.065 + turbulence.abs() * 0.04,
    )
    ..maskFilter = const MaskFilter.blur(
      BlurStyle.normal,
      28,
    );

  canvas.drawOval(
    Rect.fromCenter(
      center: position.translate(
        -length * 0.46,
        0,
      ),
      width: length * 1.02,
      height: width * 2.0,
    ),
    outerGlow,
  );

  // ========================================================
  // HALO AZUL / VIOLETA
  // ========================================================

  final halo = Paint()
    ..shader = RadialGradient(
      colors: [
        const Color(0xFFB8D9FF).withValues(
          alpha: 0.30,
        ),
        const Color(0xFF687DFF).withValues(
          alpha: 0.17,
        ),
        const Color(0xFF9A45FF).withValues(
          alpha: 0.07,
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
        center: position.translate(
          -length * 0.42,
          0,
        ),
        radius: 50,
      ),
    );

  canvas.drawCircle(
    position.translate(
      -length * 0.42,
      0,
    ),
    50,
    halo,
  );

  // ========================================================
  // PLASMA EXTERIOR TURBULENTO
  // ========================================================

  final topWave = math.sin(
    _time * 12.0 + phase,
  );

  final bottomWave = math.sin(
    _time * 10.5 + phase + 1.4,
  );

  final plasma = Path()
    ..moveTo(
      position.dx + 2,
      position.dy - width * 0.15,
    )
    ..cubicTo(
      position.dx - length * 0.18,
      position.dy -
          width *
              (0.62 + topWave * 0.10),
      position.dx - length * 0.48,
      position.dy -
          width *
              (0.78 + topWave * 0.12),
      position.dx - length * 0.78,
      position.dy -
          width *
              (0.30 + topWave * 0.08),
    )
    ..cubicTo(
      position.dx - length * 0.90,
      position.dy -
          width *
              (0.12 + topWave * 0.05),
      position.dx - length,
      position.dy,
      position.dx - length,
      position.dy,
    )
    ..cubicTo(
      position.dx - length * 0.82,
      position.dy +
          width *
              (0.28 + bottomWave * 0.08),
      position.dx - length * 0.48,
      position.dy +
          width *
              (0.72 + bottomWave * 0.12),
      position.dx - length * 0.18,
      position.dy +
          width *
              (0.60 + bottomWave * 0.08),
    )
    ..cubicTo(
      position.dx - length * 0.05,
      position.dy + width * 0.26,
      position.dx,
      position.dy + width * 0.12,
      position.dx + 2,
      position.dy + width * 0.15,
    )
    ..close();

  final plasmaPaint = Paint()
    ..shader = const LinearGradient(
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFE5F4FF),
        Color(0xFF9BBEFF),
        Color(0xFF695DFF),
        Color(0xFFA13EFF),
        Colors.transparent,
      ],
      stops: [
        0.0,
        0.14,
        0.32,
        0.56,
        0.78,
        1.0,
      ],
    ).createShader(
      Rect.fromLTWH(
        position.dx - length,
        position.dy - width,
        length,
        width * 2,
      ),
    );

  canvas.drawPath(
    plasma,
    plasmaPaint,
  );

  // ========================================================
  // SEGUNDA CAPA DE PLASMA
  // ========================================================

  final innerLength = length * 0.72;

  final innerWave = math.sin(
    _time * 16.0 + phase,
  );

  final inner = Path()
    ..moveTo(
      position.dx + 1,
      position.dy - width * 0.065,
    )
    ..cubicTo(
      position.dx - innerLength * 0.20,
      position.dy -
          width *
              (0.20 + innerWave * 0.035),
      position.dx - innerLength * 0.55,
      position.dy -
          width *
              (0.30 + innerWave * 0.05),
      position.dx - innerLength,
      position.dy,
    )
    ..cubicTo(
      position.dx - innerLength * 0.55,
      position.dy +
          width *
              (0.30 + innerWave * 0.05),
      position.dx - innerLength * 0.20,
      position.dy +
          width *
              (0.20 + innerWave * 0.035),
      position.dx + 1,
      position.dy + width * 0.065,
    )
    ..close();

  final innerPaint = Paint()
    ..shader = const LinearGradient(
      colors: [
        Colors.white,
        Color(0xFFF4FBFF),
        Color(0xFFB8D7FF),
        Color(0xFF8C79FF),
        Colors.transparent,
      ],
      stops: [
        0.0,
        0.18,
        0.40,
        0.70,
        1.0,
      ],
    ).createShader(
      Rect.fromLTWH(
        position.dx - innerLength,
        position.dy - width * 0.35,
        innerLength,
        width * 0.70,
      ),
    );

  canvas.drawPath(
    inner,
    innerPaint,
  );

  // ========================================================
  // NÚCLEO BLANCO
  // ========================================================

  final coreGlow = Paint()
    ..color = Colors.white.withValues(
      alpha: 0.32,
    )
    ..maskFilter = const MaskFilter.blur(
      BlurStyle.normal,
      5,
    );

  canvas.drawOval(
    Rect.fromCenter(
      center: position.translate(
        -5,
        0,
      ),
      width: 20,
      height: 9,
    ),
    coreGlow,
  );

  final core = Paint()
    ..shader = const RadialGradient(
      colors: [
        Colors.white,
        Color(0xFFEAF7FF),
        Color(0xFFB5D4FF),
        Colors.transparent,
      ],
    ).createShader(
      Rect.fromCircle(
        center: position.translate(
          -5,
          0,
        ),
        radius: 12,
      ),
    );

  canvas.drawOval(
    Rect.fromCenter(
      center: position.translate(
        -5,
        0,
      ),
      width: 17,
      height: 7,
    ),
    core,
  );
}
  // ============================================================
  // ENGINE NOZZLE
  // ============================================================

  void _drawEngineNozzle(
    Canvas canvas,
    Offset position,
    int engineIndex,
  ) {
    final pulse =
        0.95 +
        math.sin(
              _time * 8 +
                  engineIndex * 1.7,
            ) *
            0.05;

    // --------------------------------------------------------
    // BLOOM EXTERIOR
    // --------------------------------------------------------

    final outerGlow = Paint()
      ..color = const Color(
        0xFF6EB9FF,
      ).withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        18,
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: position,
        width: 48,
        height: 34,
      ),
      outerGlow,
    );

    // --------------------------------------------------------
    // GLOW
    // --------------------------------------------------------

    final glow = Paint()
      ..color = const Color(
        0xFF6EB9FF,
      ).withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: position,
        width: 34,
        height: 23,
      ),
      glow,
    );

    // --------------------------------------------------------
    // METAL
    // --------------------------------------------------------

    final housing = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE4ECFB),
          Color(0xFF8998B5),
          Color(0xFF28324A),
        ],
      ).createShader(
        Rect.fromCenter(
          center: position,
          width: 32,
          height: 21,
        ),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: position,
        width: 32,
        height: 21,
      ),
      housing,
    );

    // --------------------------------------------------------
    // RECESS
    // --------------------------------------------------------

    final recess = Paint()
      ..color = const Color(
        0xFF081020,
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: position,
        width: 22,
        height: 14,
      ),
      recess,
    );

    // --------------------------------------------------------
    // CORE
    // --------------------------------------------------------

    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFBBD9FF),
          const Color(0xFF648EFF)
              .withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: position,
          radius: 13 * pulse,
        ),
      );

    canvas.drawCircle(
      position,
      10 * pulse,
      core,
    );

    // --------------------------------------------------------
    // ANILLO
    // --------------------------------------------------------

    final ring = Paint()
      ..color = const Color(
        0xFFBFD8FF,
      ).withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawOval(
      Rect.fromCenter(
        center: position,
        width: 22,
        height: 14,
      ),
      ring,
    );
  }

  // ============================================================
  // ENGINE PARTICLES
  // ============================================================

  void _drawEngineParticles(Canvas canvas) {
  for (final particle in _particles) {
    final engineY =
        particle.engine == 0
            ? _upperEngineY
            : _lowerEngineY;

    final px =
        _engineX -
        particle.distance;

    final py =
        engineY +
        particle.drift;

    if (particle.alpha <= 0) {
      continue;
    }

    final fade = math.pow(
      particle.alpha,
      1.25,
    ).toDouble();

    // ========================================================
    // HALO
    // ========================================================

    final glow = Paint()
      ..color = particle.color.withValues(
        alpha: 0.18 * fade,
      )
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        4.5 +
            particle.radius * 2.5,
      );

    canvas.drawCircle(
      Offset(px, py),
      particle.radius * 1.8,
      glow,
    );

    // ========================================================
    // CUERPO
    // ========================================================

    final paint = Paint()
      ..color = particle.color.withValues(
        alpha: 0.72 * fade,
      );

    canvas.drawCircle(
      Offset(px, py),
      particle.radius,
      paint,
    );

    // ========================================================
    // NÚCLEO
    // ========================================================

    if (particle.radius > 1.5) {
      final core = Paint()
        ..color = Colors.white.withValues(
          alpha: 0.55 * fade,
        );

      canvas.drawCircle(
        Offset(px, py),
        particle.radius * 0.35,
        core,
      );
    }
  }
}

  // ============================================================
  // EDGE LIGHTS
  // ============================================================

  void _drawEdgeLights(Canvas canvas) {
    final pulse =
        0.35 +
        ((math.sin(
                    _time * 3.5,
                  ) +
                1) /
            2) *
            0.55;

    final cyan = Paint()
      ..color = const Color(
        0xFF5AEFFF,
      ).withValues(alpha: pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final violet = Paint()
      ..color = const Color(
        0xFFAA69FF,
      ).withValues(alpha: pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final upper = Path()
      ..moveTo(-91, -8)
      ..cubicTo(
        -55,
        -29,
        -5,
        -39,
        42,
        -29,
      )
      ..cubicTo(
        72,
        -23,
        95,
        -10,
        115,
        0,
      );

    final lower = Path()
      ..moveTo(-91, 8)
      ..cubicTo(
        -55,
        29,
        -5,
        39,
        42,
        29,
      )
      ..cubicTo(
        72,
        23,
        95,
        10,
        115,
        0,
      );

    canvas.drawPath(
      upper,
      violet,
    );

    canvas.drawPath(
      lower,
      cyan,
    );

    final nose = Paint()
      ..color = Colors.white.withValues(
        alpha: 0.7 + pulse * 0.25,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        3,
      );

    canvas.drawCircle(
      const Offset(115, 0),
      1.7,
      nose,
    );
  }
}

// ============================================================
// TRAIL POINT
// ============================================================

class _TrailPoint {
  _TrailPoint({
    required this.x,
    required this.y,
    required this.age,
    required this.engine,
    required this.phase,
  });

  double x;
  double y;
  double age;

  final int engine;
  final double phase;
}

// ============================================================
// ENGINE PARTICLE
// ============================================================

class _EngineParticle {
  _EngineParticle({
    required this.engine,
    required math.Random random,
  })  : _random = random,
        distance =
            5 +
                random.nextDouble() *
                    88,
        radius =
            0.55 +
                random.nextDouble() *
                    2.35,
        phase =
            random.nextDouble() *
                math.pi *
                2,
        driftAmount =
            -6 +
                random.nextDouble() *
                    12,
        speed =
            0.70 +
                random.nextDouble() *
                    1.25,
        life =
            random.nextDouble();

  final int engine;

  final math.Random _random;

  final double distance;
  final double radius;
  final double phase;
  final double driftAmount;
  final double speed;

  double life;

  double alpha = 0;

  double drift = 0;

  Color get color {
    final value = _random.nextDouble();

    if (value < 0.55) {
      return const Color(
        0xFF8DB7FF,
      );
    }

    if (value < 0.85) {
      return const Color(
        0xFF9D7BFF,
      );
    }

    return const Color(
      0xFFE4EFFF,
    );
  }

  void update(
    double dt,
    double time,
  ) {
    life += dt * speed;

    if (life > 1) {
      life = 0;
    }

    // ========================================================
    // TURBULENCIA
    // ========================================================

    final turbulence =
        math.sin(
              time * 7.0 +
                  phase,
            ) *
            0.55 +
        math.sin(
              time * 15.0 +
                  phase * 1.7,
            ) *
            0.30;

    drift =
        driftAmount *
        turbulence *
        (0.25 + life * 0.75);

    // ========================================================
    // APARICIÓN
    // ========================================================

    final fadeIn =
        (life / 0.10).clamp(
      0.0,
      1.0,
    );

    // ========================================================
    // DESAPARICIÓN
    // ========================================================

    final fadeOut =
        ((1.0 - life) / 0.28).clamp(
      0.0,
      1.0,
    );

    alpha =
        fadeIn *
        fadeOut *
        0.72;
  }
}