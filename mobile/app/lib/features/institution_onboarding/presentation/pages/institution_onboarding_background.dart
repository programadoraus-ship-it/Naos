import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Permanent visual background for the NAOS institution onboarding.
///
/// This file contains only the visual/cinematic layer extracted from
/// `institution_onboarding_intro_page.dart`.
///
/// It intentionally contains:
/// - cosmic gradient
/// - galaxies
/// - stars
/// - orbital systems
/// - planets
/// - meteors / shooting stars
/// - cinematic light
/// - cinematic ship
/// - foreground particles
///
/// It does NOT contain onboarding text, cards, buttons, navigation,
/// step indicators, or page-to-page navigation.
class InstitutionOnboardingBackground extends StatefulWidget {
  const InstitutionOnboardingBackground({
    super.key,
  });

  @override
  State<InstitutionOnboardingBackground> createState() =>
      _InstitutionOnboardingBackgroundState();
}
class _InstitutionOnboardingBackgroundState
    extends State<InstitutionOnboardingBackground>
    with TickerProviderStateMixin {
  late final AnimationController _cinematicController;
  late final AnimationController _shipController;
  late final AnimationController _ambientController;

  Offset _pointer = Offset.zero;

  @override
  void initState() {
    super.initState();

    _cinematicController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _shipController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _cinematicController.dispose();
    _shipController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _updatePointer(Offset position, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final dx = ((position.dx - center.dx) / (size.width / 2))
        .clamp(-1.0, 1.0);

    final dy = ((position.dy - center.dy) / (size.height / 2))
        .clamp(-1.0, 1.0);

    setState(() {
      _pointer = Offset(dx, dy);
    });
  }

  void _resetPointer() {
    setState(() {
      _pointer = Offset.zero;
    });
  }

  double _fade(double begin, double end) {
    return Curves.easeOutCubic.transform(
      ((_cinematicController.value - begin) / (end - begin))
          .clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return MouseRegion(
          onHover: (event) {
            _updatePointer(event.localPosition, size);
          },
          onExit: (_) {
            _resetPointer();
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _cinematicController,
              _ambientController,
              _shipController,
            ]),
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(
                    color: Color(0xFF020514),
                  ),

                  CustomPaint(
                    painter: _CosmicGradientPainter(
                      progress: _ambientController.value,
                      parallax: _pointer,
                    ),
                  ),

                  CustomPaint(
                    painter: _GalaxyPainter(
                      progress: _ambientController.value,
                      parallax: _pointer,
                    ),
                  ),

                  CustomPaint(
                    painter: _StarFieldPainter(
                      progress: _ambientController.value,
                      parallax: _pointer,
                    ),
                  ),

                  CustomPaint(
                    painter: _OrbitalSystemPainter(
                      progress: _ambientController.value,
                      parallax: _pointer,
                    ),
                  ),

                  CustomPaint(
                    painter: _PlanetFieldPainter(
                      progress: _ambientController.value,
                      parallax: _pointer,
                    ),
                  ),

                  CustomPaint(
                    painter: _MeteorFieldPainter(
                      progress: _ambientController.value,
                      parallax: _pointer,
                    ),
                  ),

                  CustomPaint(
                    painter: _CosmicLightPainter(
                      progress: _ambientController.value,
                      parallax: _pointer,
                    ),
                  ),

                  Positioned(
                    left: size.width * 0.5 - 100,
                    top: size.height * 0.04,
                    width: 200,
                    height: 200,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.72 * _fade(0.05, 0.35),
                        child: Lottie.asset(
                          'assets/animations/naos_cosmic_test.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                        ),
                      ),
                    ),
                  ),

                  CustomPaint(
                    painter: _CinematicShipPainter(
                      progress: _shipController.value,
                      parallax: _pointer,
                    ),
                  ),

                  CustomPaint(
                    painter: _ForegroundParticlePainter(
                      progress: _ambientController.value,
                      parallax: _pointer,
                    ),
                  ),

                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.95,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Color(0x47000000),
                            Color(0xAD000000),
                          ],
                          stops: [
                            0.0,
                            0.48,
                            0.78,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================
// COSMIC GRADIENT
// ============================================================

class _CosmicGradientPainter extends CustomPainter {
  final double progress;
  final Offset parallax;

  const _CosmicGradientPainter({
    required this.progress,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;

    final driftX = math.sin(t * 0.17) * 0.08;
    final driftY = math.cos(t * 0.13) * 0.05;

    final rect = Offset.zero & size;

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          -0.22 + driftX + parallax.dx * 0.035,
          -0.30 + driftY + parallax.dy * 0.025,
        ),
        radius: 1.18,
        colors: const [
          Color(0xFF101943),
          Color(0xFF07102D),
          Color(0xFF03071A),
          Color(0xFF01030D),
        ],
        stops: const [
          0.0,
          0.35,
          0.72,
          1.0,
        ],
      ).createShader(rect);

    canvas.drawRect(
      rect,
      paint,
    );

    // Secondary violet nebula.
    final nebula = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6657FF).withValues(
            alpha: 0.075,
          ),
          const Color(0xFF4237A8).withValues(
            alpha: 0.035,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.74 + parallax.dx * 30,
            size.height * 0.28 + parallax.dy * 20,
          ),
          radius: size.width * 0.46,
        ),
      );

    canvas.drawCircle(
      Offset(
        size.width * 0.74 + parallax.dx * 30,
        size.height * 0.28 + parallax.dy * 20,
      ),
      size.width * 0.46,
      nebula,
    );

    // Blue lower nebula.
    final lowerNebula = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF315DFF).withValues(
            alpha: 0.055,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.22 + parallax.dx * 18,
            size.height * 0.82 + parallax.dy * 12,
          ),
          radius: size.width * 0.36,
        ),
      );

    canvas.drawCircle(
      Offset(
        size.width * 0.22 + parallax.dx * 18,
        size.height * 0.82 + parallax.dy * 12,
      ),
      size.width * 0.36,
      lowerNebula,
    );
  }

  @override
  bool shouldRepaint(
    covariant _CosmicGradientPainter oldDelegate,
  ) {
    return true;
  }
}

// ============================================================
// GALAXIES
// ============================================================

class _GalaxyPainter extends CustomPainter {
  final double progress;
  final Offset parallax;

  const _GalaxyPainter({
    required this.progress,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;

    _drawGalaxy(
      canvas,
      center: Offset(
        size.width * 0.16 + parallax.dx * 8,
        size.height * 0.26 + parallax.dy * 5,
      ),
      radius: size.width * 0.15,
      rotation: t * 0.07,
      alpha: 0.085,
    );

    _drawGalaxy(
      canvas,
      center: Offset(
        size.width * 0.86 + parallax.dx * 5,
        size.height * 0.73 + parallax.dy * 4,
      ),
      radius: size.width * 0.12,
      rotation: -t * 0.055,
      alpha: 0.065,
    );

    _drawGalaxy(
      canvas,
      center: Offset(
        size.width * 0.82 + parallax.dx * 3,
        size.height * 0.15 + parallax.dy * 2,
      ),
      radius: size.width * 0.075,
      rotation: t * 0.04,
      alpha: 0.045,
    );
  }

  void _drawGalaxy(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double rotation,
    required double alpha,
  }) {
    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    canvas.rotate(
      rotation,
    );

    // Outer glow.
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9A8CFF).withValues(
            alpha: alpha,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: radius,
        ),
      );

    canvas.drawCircle(
      Offset.zero,
      radius,
      glow,
    );

    // Spiral arms.
    final armPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int arm = 0; arm < 3; arm++) {
      final path = Path();

      for (int i = 0; i <= 100; i++) {
        final p = i / 100;
        final angle =
            p * math.pi * 3.4 +
            arm * math.pi * 2 / 3;

        final r = radius *
            (0.04 + p * 0.86);

        final x =
            math.cos(angle) * r;

        final y =
            math.sin(angle) *
            r *
            0.32;

        if (i == 0) {
          path.moveTo(
            x,
            y,
          );
        } else {
          path.lineTo(
            x,
            y,
          );
        }
      }

      armPaint.color =
          const Color(0xFFAAA2FF).withValues(
        alpha: alpha * 0.55,
      );

      canvas.drawPath(
        path,
        armPaint,
      );
    }

    // Galaxy core.
    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(
            alpha: alpha * 2.2,
          ),
          const Color(0xFFAAA0FF).withValues(
            alpha: alpha,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: radius * 0.34,
        ),
      );

    canvas.drawCircle(
      Offset.zero,
      radius * 0.34,
      core,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _GalaxyPainter oldDelegate,
  ) {
    return true;
  }
}

// ============================================================
// STAR FIELD
// ============================================================

class _StarFieldPainter extends CustomPainter {
  final double progress;
  final Offset parallax;

  const _StarFieldPainter({
    required this.progress,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;

    final paint = Paint();

    // ----------------------------------------------------------
    // Far stars
    // ----------------------------------------------------------

    for (int i = 0; i < 420; i++) {
      final seed = i * 92821 + 17;

      final baseX =
          (seed % 10007) /
              10007 *
              size.width;

      final baseY =
          ((seed ~/ 7) % 10009) /
              10009 *
              size.height;

      final depth =
          0.08 +
          ((seed % 500) / 500) * 0.28;

      final phase =
          ((seed % 701) / 701) *
              math.pi *
              2;

      final twinkle =
          0.12 +
          ((math.sin(
                        t *
                            (0.30 +
                                depth * 0.9) +
                        phase,
                      ) +
                      1) /
                  2) *
              0.25;

      paint.color =
          Colors.white.withValues(
        alpha: twinkle.clamp(
          0.035,
          0.38,
        ),
      );

      canvas.drawCircle(
        Offset(
          baseX +
              parallax.dx *
                  depth *
                  18,
          baseY +
              parallax.dy *
                  depth *
                  14,
        ),
        0.35 +
            depth *
                0.55,
        paint,
      );
    }

    // ----------------------------------------------------------
    // Mid stars
    // ----------------------------------------------------------

    for (int i = 0; i < 260; i++) {
      final seed =
          i * 63197 + 173;

      final baseX =
          (seed % 10009) /
              10009 *
              size.width;

      final baseY =
          ((seed ~/ 9) % 10037) /
              10037 *
              size.height;

      final depth =
          0.34 +
          ((seed % 500) / 500) * 0.35;

      final phase =
          ((seed % 613) / 613) *
              math.pi *
              2;

      final twinkle =
          0.18 +
          ((math.sin(
                        t *
                            (0.65 +
                                depth * 1.4) +
                        phase,
                      ) +
                      1) /
                  2) *
              0.48;

      final x =
          baseX +
          parallax.dx *
              depth *
              32;

      final y =
          baseY +
          parallax.dy *
              depth *
              24;

      paint.color =
          Colors.white.withValues(
        alpha: twinkle.clamp(
          0.05,
          0.70,
        ),
      );

      canvas.drawCircle(
        Offset(
          x,
          y,
        ),
        0.45 +
            depth *
                0.85,
        paint,
      );

      if (i % 43 == 0) {
        _drawStarFlare(
          canvas,
          Offset(
            x,
            y,
          ),
          1.2 +
              depth *
                  2.0,
          twinkle,
        );
      }
    }

    // ----------------------------------------------------------
    // Close stars
    // ----------------------------------------------------------

    for (int i = 0; i < 65; i++) {
      final seed =
          i * 45991 + 713;

      final baseX =
          (seed % 10037) /
              10037 *
              size.width;

      final baseY =
          ((seed ~/ 5) % 10039) /
              10039 *
              size.height;

      final depth =
          0.72 +
          ((seed % 280) / 280) *
              0.28;

      final phase =
          ((seed % 401) / 401) *
              math.pi *
              2;

      final twinkle =
          0.25 +
          ((math.sin(
                        t *
                            (1.2 +
                                depth * 2.0) +
                        phase,
                      ) +
                      1) /
                  2) *
              0.68;

      final x =
          baseX +
          parallax.dx *
              depth *
              58;

      final y =
          baseY +
          parallax.dy *
              depth *
              45;

      paint.color =
          const Color(
            0xFFE9ECFF,
          ).withValues(
        alpha: twinkle.clamp(
          0.08,
          0.95,
        ),
      );

      canvas.drawCircle(
        Offset(
          x,
          y,
        ),
        0.7 +
            depth *
                1.15,
        paint,
      );

      if (i % 8 == 0) {
        _drawStarFlare(
          canvas,
          Offset(
            x,
            y,
          ),
          2.0 +
              depth *
                  3.0,
          twinkle,
        );
      }
    }
  }

  void _drawStarFlare(
    Canvas canvas,
    Offset center,
    double radius,
    double alpha,
  ) {
    final paint = Paint()
      ..color =
          const Color(
        0xFFC8D2FF,
      ).withValues(
        alpha: alpha * 0.35,
      )
      ..strokeWidth = 0.7;

    canvas.drawLine(
      Offset(
        center.dx - radius * 3,
        center.dy,
      ),
      Offset(
        center.dx + radius * 3,
        center.dy,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        center.dx,
        center.dy - radius * 3,
      ),
      Offset(
        center.dx,
        center.dy + radius * 3,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _StarFieldPainter oldDelegate,
  ) {
    return true;
  }
}

// ============================================================
// ORBITAL SYSTEM
// ============================================================

class _OrbitalSystemPainter extends CustomPainter {
  final double progress;
  final Offset parallax;

  const _OrbitalSystemPainter({
    required this.progress,
    required this.parallax,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final t =
        progress *
        math.pi *
        2;

    final center = Offset(
      size.width * 0.71 +
          parallax.dx * 18,
      size.height * 0.38 +
          parallax.dy * 12,
    );

    final orbitPaint = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 0.7;

    for (int i = 0; i < 7; i++) {
      orbitPaint.color =
          const Color(
        0xFF8179FF,
      ).withValues(
        alpha:
            0.025 +
            i * 0.004,
      );

      canvas.save();

      canvas.translate(
        center.dx,
        center.dy,
      );

      canvas.rotate(
        t *
            (0.008 +
                i * 0.003),
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width:
              size.width *
                  (0.26 +
                      i *
                          0.075),
          height:
              size.height *
                  (0.085 +
                      i *
                          0.022),
        ),
        orbitPaint,
      );

      canvas.restore();
    }

    // Moving orbital energy particles.
    for (int i = 0; i < 5; i++) {
      final angle =
          t *
              (0.20 +
                  i * 0.045) +
          i *
              math.pi *
              0.47;

      final radiusX =
          size.width *
              (0.16 +
                  i *
                      0.048);

      final radiusY =
          size.height *
              (0.05 +
                  i *
                      0.014);

      final point = Offset(
        center.dx +
            math.cos(angle) *
                radiusX,
        center.dy +
            math.sin(angle) *
                radiusY,
      );

      final glow = Paint()
        ..color =
            const Color(
          0xFFB6ADFF,
        ).withValues(
          alpha: 0.28,
        )
        ..maskFilter =
            const MaskFilter.blur(
          BlurStyle.normal,
          5,
        );

      canvas.drawCircle(
        point,
        3.0,
        glow,
      );

      final core = Paint()
        ..color = Colors.white
            .withValues(
          alpha: 0.78,
        );

      canvas.drawCircle(
        point,
        0.9,
        core,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _OrbitalSystemPainter oldDelegate,
  ) {
    return true;
  }
}

// ============================================================
// PLANET FIELD
// ============================================================

class _PlanetFieldPainter extends CustomPainter {
  final double progress;
  final Offset parallax;

  const _PlanetFieldPainter({
    required this.progress,
    required this.parallax,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final t =
        progress *
        math.pi *
        2;

    _planet(
      canvas,
      center: Offset(
        size.width * 0.075 +
            parallax.dx * 26,
        size.height * 0.17 +
            parallax.dy * 18,
      ),
      radius: 48,
      color: const Color(
        0xFF5969D9,
      ),
      rotation: t * 0.18,
      ring: true,
    );

    _planet(
      canvas,
      center: Offset(
        size.width * 0.94 +
            parallax.dx * 17,
        size.height * 0.20 +
            parallax.dy * 11,
      ),
      radius: 26,
      color: const Color(
        0xFF8B55D8,
      ),
      rotation: -t * 0.25,
      ring: false,
    );

    _planet(
      canvas,
      center: Offset(
        size.width * 0.91 +
            parallax.dx * 31,
        size.height * 0.82 +
            parallax.dy * 20,
      ),
      radius: 58,
      color: const Color(
        0xFF3E4A9D,
      ),
      rotation: t * 0.12,
      ring: true,
    );

    _planet(
      canvas,
      center: Offset(
        size.width * 0.055 +
            parallax.dx * 13,
        size.height * 0.76 +
            parallax.dy * 10,
      ),
      radius: 19,
      color: const Color(
        0xFF4779D5,
      ),
      rotation: t * 0.36,
      ring: false,
    );
  }

  void _planet(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double rotation,
    required bool ring,
  }) {
    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    // ----------------------------------------------------------
    // Atmospheric glow
    // ----------------------------------------------------------

    final atmosphere =
        Paint()
          ..color =
              color.withValues(
            alpha: 0.15,
          )
          ..maskFilter =
              MaskFilter.blur(
            BlurStyle.normal,
            radius *
                0.34,
          );

    canvas.drawCircle(
      Offset.zero,
      radius * 1.08,
      atmosphere,
    );

    // ----------------------------------------------------------
    // Rings behind planet
    // ----------------------------------------------------------

    if (ring) {
      canvas.save();

      canvas.rotate(
        -0.28,
      );

      final ringPaint =
          Paint()
            ..style =
                PaintingStyle.stroke
            ..strokeWidth =
                math.max(
              1.0,
              radius *
                  0.035,
            )
            ..color =
                const Color(
              0xFFAAA5FF,
            ).withValues(
              alpha: 0.28,
            );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width:
              radius *
                  3.1,
          height:
              radius *
                  0.82,
        ),
        ringPaint,
      );

      canvas.restore();
    }

    // ----------------------------------------------------------
    // Planet body
    // ----------------------------------------------------------

    final lightX =
        math.cos(
              rotation,
            ) *
            0.18;

    final lightY =
        math.sin(
              rotation,
            ) *
            0.18;

    final planetPaint =
        Paint()
          ..shader =
              RadialGradient(
            center:
                Alignment(
              -0.38 +
                  lightX,
              -0.42 +
                  lightY,
            ),
            radius: 1.0,
            colors: [
              Color.lerp(
                    Colors.white,
                    color,
                    0.22,
                  ) ??
                  color,
              color,
              const Color(
                0xFF03050E,
              ),
            ],
            stops: const [
              0.0,
              0.54,
              1.0,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset.zero,
              radius: radius,
            ),
          );

    canvas.drawCircle(
      Offset.zero,
      radius,
      planetPaint,
    );

    // ----------------------------------------------------------
    // Planet surface bands
    // ----------------------------------------------------------

    final surface =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              math.max(
            1.0,
            radius * 0.035,
          )
          ..color =
              Colors.white.withValues(
            alpha: 0.045,
          );

    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(
            -radius * 0.05,
            i * radius * 0.15,
          ),
          width:
              radius *
                  1.75,
          height:
              radius *
                  0.52,
        ),
        math.pi * 0.1,
        math.pi * 0.82,
        false,
        surface,
      );
    }

    // ----------------------------------------------------------
    // Atmosphere edge
    // ----------------------------------------------------------

    final edge =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              math.max(
            0.8,
            radius *
                0.018,
          )
          ..color =
              const Color(
            0xFFB4C5FF,
          ).withValues(
            alpha: 0.18,
          );

    canvas.drawCircle(
      Offset.zero,
      radius * 1.005,
      edge,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _PlanetFieldPainter oldDelegate,
  ) {
    return true;
  }
}

// ============================================================
// METEOR FIELD
// ============================================================

class _MeteorFieldPainter extends CustomPainter {
  final double progress;
  final Offset parallax;

  const _MeteorFieldPainter({
    required this.progress,
    required this.parallax,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    _meteor(
      canvas,
      size,
      progress,
      speed: 1.0,
      vertical: 0.14,
      offset: 0.0,
    );

    _meteor(
      canvas,
      size,
      (progress + 0.37) % 1.0,
      speed: 0.58,
      vertical: 0.52,
      offset: parallax.dx * 15,
    );

    _meteor(
      canvas,
      size,
      (progress + 0.73) % 1.0,
      speed: 0.36,
      vertical: 0.76,
      offset: parallax.dx * 9,
    );
  }

  void _meteor(
    Canvas canvas,
    Size size,
    double progress, {
    required double speed,
    required double vertical,
    required double offset,
  }) {
    final p =
        (progress * speed) % 1.0;

    final x =
        -180 +
        p *
            (size.width + 360);

    final y =
        size.height *
            vertical +
        p *
            size.height *
            0.04 +
        offset;

    final paint =
        Paint()
          ..strokeCap =
              StrokeCap.round
          ..style =
              PaintingStyle.stroke;

    for (int i = 0; i < 15; i++) {
      paint
        ..strokeWidth =
            math.max(
          0.4,
          2.6 -
              i *
                  0.15,
        )
        ..color =
            const Color(
          0xFFD8DEFF,
        ).withValues(
          alpha:
              (0.075 -
                      i *
                          0.004)
                  .clamp(
            0.008,
            0.075,
          ),
        );

      canvas.drawLine(
        Offset(
          x -
              i *
                  11,
          y -
              i *
                  5,
        ),
        Offset(
          x -
              (i + 1) *
                  17,
          y -
              (i + 1) *
                  8,
        ),
        paint,
      );
    }

    paint
      ..style =
          PaintingStyle.fill
      ..color =
          Colors.white.withValues(
        alpha: 0.86,
      );

    canvas.drawCircle(
      Offset(
        x,
        y,
      ),
      2.0,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _MeteorFieldPainter oldDelegate,
  ) {
    return true;
  }
}

// ============================================================
// COSMIC LIGHT
// ============================================================

class _CosmicLightPainter extends CustomPainter {
  final double progress;
  final Offset parallax;

  const _CosmicLightPainter({
    required this.progress,
    required this.parallax,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final t =
        progress *
        math.pi *
        2;

    // Slowly rotating volumetric light.
    final center = Offset(
      size.width * 0.50 +
          parallax.dx * 16,
      size.height * 0.46 +
          parallax.dy * 12,
    );

    final pulse =
        (math.sin(t * 0.8) + 1) /
            2;

    final glow =
        Paint()
          ..shader =
              RadialGradient(
            colors: [
              const Color(
                0xFF746BFF,
              ).withValues(
                alpha:
                    0.045 +
                    pulse *
                        0.025,
              ),
              const Color(
                0xFF4C51D4,
              ).withValues(
                alpha: 0.018,
              ),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius:
                  size.width *
                      0.38,
            ),
          );

    canvas.drawCircle(
      center,
      size.width * 0.38,
      glow,
    );

    // Diagonal cinematic light beam.
    final beamX =
        -size.width * 0.75 +
        progress *
            size.width *
            2.5;

    final beamPaint =
        Paint()
          ..shader =
              const LinearGradient(
            colors: [
              Colors.transparent,
              Color(
                0x056F7CFF,
              ),
              Color(
                0x126D7BFF,
              ),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(
              beamX - 260,
              0,
              520,
              size.height,
            ),
          );

    canvas.save();

    canvas.rotate(
      -0.07,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        beamX - 260,
        -100,
        520,
        size.height + 200,
      ),
      beamPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _CosmicLightPainter oldDelegate,
  ) {
    return true;
  }
}

// ============================================================
// CINEMATIC SCI-FI SHIP
// ============================================================

class _CinematicShipPainter extends CustomPainter {
  final double progress;
  final Offset parallax;

  const _CinematicShipPainter({
    required this.progress,
    required this.parallax,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    //
    // Cinematic flight path.
    //

    final p =
        Curves.easeInOutCubic
            .transform(
      progress,
    );

    final x =
        -260 +
        p *
            (size.width + 520);

    final y =
        size.height *
            (
              0.24 +
                  p * 0.36 +
                  math.sin(
                        p *
                            math.pi *
                            4,
                      ) *
                      0.055
            );

    final nextP =
        (p + 0.004)
            .clamp(
      0.0,
      1.0,
    )
            .toDouble();

    final nextX =
        -260 +
        nextP *
            (size.width + 520);

    final nextY =
    size.height *
    (0.24 +
        nextP * 0.36 +
        math.sin(nextP * math.pi * 4.0) * 0.055);

    final angle =
        math.atan2(
              nextY - y,
              nextX - x,
            ) *
            0.42;

    final scale =
        0.68 +
        math.sin(
              p * math.pi,
            ) *
            0.34;

    canvas.save();

    canvas.translate(
      x +
          parallax.dx *
              24,
      y +
          parallax.dy *
              15,
    );

    canvas.rotate(
      angle,
    );

    canvas.scale(
      scale,
    );

    _shipTrail(
      canvas,
    );

    _shipGlow(
      canvas,
    );

    _shipShadow(
      canvas,
    );

    _shipHull(
      canvas,
    );

    _shipTopHull(
      canvas,
    );

    _shipBottomHull(
      canvas,
    );

    _shipCockpit(
      canvas,
    );

    _shipEngines(
      canvas,
    );

    _shipLights(
      canvas,
    );

    _shipDetails(
      canvas,
    );

    canvas.restore();
  }

  // ============================================================
  // TRAIL
  // ============================================================

  void _shipTrail(
    Canvas canvas,
  ) {
    final trail =
        Path()
          ..moveTo(
            -24,
            -11,
          )
          ..quadraticBezierTo(
            -105,
            -14,
            -230,
            -30,
          )
          ..quadraticBezierTo(
            -150,
            -4,
            -255,
            0,
          )
          ..quadraticBezierTo(
            -150,
            4,
            -230,
            30,
          )
          ..quadraticBezierTo(
            -105,
            14,
            -24,
            11,
          )
          ..close();

    final paint =
        Paint()
          ..shader =
              const LinearGradient(
            begin:
                Alignment.centerLeft,
            end:
                Alignment.centerRight,
            colors: [
              Color(
                0x00071222,
              ),
              Color(
                0x102D4F9A,
              ),
              Color(
                0x4B487EFF,
              ),
              Color(
                0xB4A9D8FF,
              ),
              Color(
                0xFFF1F7FF,
              ),
            ],
          ).createShader(
            const Rect.fromLTWH(
              -255,
              -32,
              255,
              64,
            ),
          );

    canvas.drawPath(
      trail,
      paint,
    );

    final plasma =
        Paint()
          ..color =
              const Color(
            0xFF6EA8FF,
          ).withValues(
            alpha: 0.30,
          )
          ..maskFilter =
              const MaskFilter.blur(
            BlurStyle.normal,
            12,
          );

    canvas.drawOval(
      const Rect.fromLTWH(
        -75,
        -7,
        85,
        14,
      ),
      plasma,
    );
  }

  // ============================================================
  // GLOW
  // ============================================================

  void _shipGlow(
    Canvas canvas,
  ) {
    final glow =
        Paint()
          ..color =
              const Color(
            0xFF4E7DFF,
          ).withValues(
            alpha: 0.16,
          )
          ..maskFilter =
              const MaskFilter.blur(
            BlurStyle.normal,
            32,
          );

    canvas.drawOval(
      const Rect.fromLTWH(
        -90,
        -43,
        155,
        86,
      ),
      glow,
    );

    final engineGlow =
        Paint()
          ..color =
              const Color(
            0xFFBBD9FF,
          ).withValues(
            alpha: 0.42,
          )
          ..maskFilter =
              const MaskFilter.blur(
            BlurStyle.normal,
            9,
          );

    canvas.drawOval(
      const Rect.fromLTWH(
        -68,
        -9,
        58,
        18,
      ),
      engineGlow,
    );
  }

  // ============================================================
  // SHADOW
  // ============================================================

  void _shipShadow(
    Canvas canvas,
  ) {
    final shadow =
        Paint()
          ..color =
              Colors.black.withValues(
            alpha: 0.55,
          )
          ..maskFilter =
              const MaskFilter.blur(
            BlurStyle.normal,
            9,
          );

    canvas.drawOval(
      const Rect.fromLTWH(
        -68,
        -29,
        130,
        58,
      ),
      shadow,
    );
  }

  // ============================================================
  // MAIN HULL
  // ============================================================

  void _shipHull(
    Canvas canvas,
  ) {
    final paint =
        Paint()
          ..shader =
              const LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Color(
                0xFFB6C0D3,
              ),
              Color(
                0xFF606A7E,
              ),
              Color(
                0xFF222938,
              ),
              Color(
                0xFF070A12,
              ),
            ],
            stops: [
              0.0,
              0.28,
              0.68,
              1.0,
            ],
          ).createShader(
            const Rect.fromLTWH(
              -85,
              -42,
              175,
              84,
            ),
          );

    final hull =
        Path()
          ..moveTo(
            90,
            0,
          )
          ..lineTo(
            50,
            -11,
          )
          ..lineTo(
            20,
            -24,
          )
          ..lineTo(
            -23,
            -28,
          )
          ..lineTo(
            -59,
            -18,
          )
          ..lineTo(
            -80,
            -8,
          )
          ..lineTo(
            -59,
            0,
          )
          ..lineTo(
            -80,
            8,
          )
          ..lineTo(
            -59,
            18,
          )
          ..lineTo(
            -23,
            28,
          )
          ..lineTo(
            20,
            24,
          )
          ..lineTo(
            50,
            11,
          )
          ..close();

    canvas.drawPath(
      hull,
      paint,
    );
  }

  // ============================================================
  // TOP HULL
  // ============================================================

  void _shipTopHull(
    Canvas canvas,
  ) {
    final paint =
        Paint()
          ..shader =
              const LinearGradient(
            begin:
                Alignment.topCenter,
            end:
                Alignment.bottomCenter,
            colors: [
              Color(
                0xFFD2D9E8,
              ),
              Color(
                0xFF737D92,
              ),
              Color(
                0xFF282F40,
              ),
            ],
          ).createShader(
            const Rect.fromLTWH(
              -65,
              -32,
              145,
              32,
            ),
          );

    final path =
        Path()
          ..moveTo(
            84,
            0,
          )
          ..lineTo(
            45,
            -12,
          )
          ..lineTo(
            15,
            -28,
          )
          ..lineTo(
            -20,
            -25,
          )
          ..lineTo(
            -52,
            -14,
          )
          ..lineTo(
            -12,
            -8,
          )
          ..lineTo(
            40,
            -5,
          )
          ..close();

    canvas.drawPath(
      path,
      paint,
    );
  }

  // ============================================================
  // BOTTOM HULL
  // ============================================================

  void _shipBottomHull(
    Canvas canvas,
  ) {
    final paint =
        Paint()
          ..shader =
              const LinearGradient(
            begin:
                Alignment.topCenter,
            end:
                Alignment.bottomCenter,
            colors: [
              Color(
                0xFF394356,
              ),
              Color(
                0xFF151A28,
              ),
              Color(
                0xFF05070D,
              ),
            ],
          ).createShader(
            const Rect.fromLTWH(
              -65,
              0,
              145,
              32,
            ),
          );

    final path =
        Path()
          ..moveTo(
            84,
            0,
          )
          ..lineTo(
            45,
            12,
          )
          ..lineTo(
            15,
            28,
          )
          ..lineTo(
            -20,
            25,
          )
          ..lineTo(
            -52,
            14,
          )
          ..lineTo(
            -12,
            8,
          )
          ..lineTo(
            40,
            5,
          )
          ..close();

    canvas.drawPath(
      path,
      paint,
    );
  }

  // ============================================================
  // COCKPIT
  // ============================================================

  void _shipCockpit(
    Canvas canvas,
  ) {
    final paint =
        Paint()
          ..shader =
              const RadialGradient(
            center:
                Alignment(
              -0.38,
              -0.35,
            ),
            colors: [
              Color(
                0xFFF2FAFF,
              ),
              Color(
                0xFF8DC5FF,
              ),
              Color(
                0xFF315A9D,
              ),
              Color(
                0xFF0B1429,
              ),
            ],
            stops: [
              0.0,
              0.25,
              0.60,
              1.0,
            ],
          ).createShader(
            const Rect.fromLTWH(
              15,
              -14,
              45,
              28,
            ),
          );

    canvas.drawOval(
      const Rect.fromLTWH(
        15,
        -12,
        43,
        24,
      ),
      paint,
    );

    // Reflection.
    final reflection =
        Paint()
          ..color =
              Colors.white.withValues(
            alpha: 0.27,
          );

    final reflectionPath =
        Path()
          ..moveTo(
            23,
            -7,
          )
          ..quadraticBezierTo(
            34,
            -12,
            44,
            -7,
          )
          ..lineTo(
            35,
            -3,
          )
          ..close();

    canvas.drawPath(
      reflectionPath,
      reflection,
    );
  }

  // ============================================================
  // ENGINES
  // ============================================================

  void _shipEngines(
    Canvas canvas,
  ) {
    final engine =
        Paint()
          ..shader =
              const RadialGradient(
            colors: [
              Color(
                0xFFFFFFFF,
              ),
              Color(
                0xFFC1E5FF,
              ),
              Color(
                0xFF5B9CFF,
              ),
              Color(
                0xFF183C86,
              ),
            ],
          ).createShader(
            const Rect.fromLTWH(
              -70,
              -13,
              28,
              26,
            ),
          );

    canvas.drawOval(
      const Rect.fromLTWH(
        -67,
        -11,
        25,
        9,
      ),
      engine,
    );

    canvas.drawOval(
      const Rect.fromLTWH(
        -67,
        2,
        25,
        9,
      ),
      engine,
    );

    final ring =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              1.4
          ..color =
              const Color(
            0xFF7EB1FF,
          ).withValues(
            alpha: 0.76,
          );

    canvas.drawOval(
      const Rect.fromLTWH(
        -71,
        -12,
        27,
        11,
      ),
      ring,
    );

    canvas.drawOval(
      const Rect.fromLTWH(
        -71,
        1,
        27,
        11,
      ),
      ring,
    );
  }

  // ============================================================
  // LIGHTS
  // ============================================================

  void _shipLights(
    Canvas canvas,
  ) {
    final blue =
        Paint()
          ..color =
              const Color(
            0xFF75A8FF,
          )
          ..maskFilter =
              const MaskFilter.blur(
            BlurStyle.normal,
            5,
          );

    final white =
        Paint()
          ..color =
              Colors.white;

    canvas.drawCircle(
      const Offset(
        48,
        -9,
      ),
      2.2,
      blue,
    );

    canvas.drawCircle(
      const Offset(
        48,
        -9,
      ),
      0.9,
      white,
    );

    canvas.drawCircle(
      const Offset(
        48,
        9,
      ),
      2.2,
      blue,
    );

    canvas.drawCircle(
      const Offset(
        48,
        9,
      ),
      0.9,
      white,
    );

    final nose =
        Paint()
          ..color =
              const Color(
            0xFFC5E0FF,
          ).withValues(
            alpha: 0.8,
          )
          ..maskFilter =
              const MaskFilter.blur(
            BlurStyle.normal,
            5,
          );

    canvas.drawCircle(
      const Offset(
        86,
        0,
      ),
      2.5,
      nose,
    );

    canvas.drawCircle(
      const Offset(
        86,
        0,
      ),
      1.0,
      white,
    );
  }

  // ============================================================
  // SHIP DETAILS
  // ============================================================

  void _shipDetails(
    Canvas canvas,
  ) {
    final edge =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              1.25
          ..strokeCap =
              StrokeCap.round
          ..color =
              const Color(
            0xFFBED0ED,
          ).withValues(
            alpha: 0.62,
          );

    final top =
        Path()
          ..moveTo(
            79,
            0,
          )
          ..lineTo(
            46,
            -10,
          )
          ..lineTo(
            17,
            -23,
          )
          ..lineTo(
            -20,
            -26,
          )
          ..lineTo(
            -53,
            -17,
          );

    canvas.drawPath(
      top,
      edge,
    );

    final bottom =
        Path()
          ..moveTo(
            79,
            0,
          )
          ..lineTo(
            46,
            10,
          )
          ..lineTo(
            17,
            23,
          )
          ..lineTo(
            -20,
            26,
          )
          ..lineTo(
            -53,
            17,
          );

    edge.color =
        const Color(
      0xFF52617A,
    ).withValues(
      alpha: 0.55,
    );

    canvas.drawPath(
      bottom,
      edge,
    );

    // Futuristic panel lines.
    final panel =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              0.7
          ..color =
              const Color(
            0xFFA4B7DA,
          ).withValues(
            alpha: 0.28,
          );

    canvas.drawLine(
      const Offset(
        -20,
        -21,
      ),
      const Offset(
        8,
        -17,
      ),
      panel,
    );

    canvas.drawLine(
      const Offset(
        -20,
        21,
      ),
      const Offset(
        8,
        17,
      ),
      panel,
    );

    canvas.drawLine(
      const Offset(
        -45,
        -13,
      ),
      const Offset(
        -25,
        -10,
      ),
      panel,
    );

    canvas.drawLine(
      const Offset(
        -45,
        13,
      ),
      const Offset(
        -25,
        10,
      ),
      panel,
    );

    // Small navigation indicators.
    final indicator =
        Paint()
          ..color =
              const Color(
            0xFF9FC8FF,
          ).withValues(
            alpha: 0.78,
          );

    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(
          -5 +
              i * 8.0,
          -4,
        ),
        1.0,
        indicator,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _CinematicShipPainter oldDelegate,
  ) {
    return true;
  }
}

// ============================================================
// FOREGROUND PARTICLES
// ============================================================

class _ForegroundParticlePainter extends CustomPainter {
  final double progress;
  final Offset parallax;

  const _ForegroundParticlePainter({
    required this.progress,
    required this.parallax,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final t = progress * math.pi * 2.0;
    final paint = Paint();

    // Foreground particles only.
    // The ship is already drawn by _CinematicShipPainter.
    for (int i = 0; i < 55; i++) {
      final seed = i * 7919 + 113;

      final baseX =
          (seed % 100003) / 100003.0 * size.width;
      final baseY =
          ((seed ~/ 11) % 100019) / 100019.0 * size.height;

      final depth =
          0.55 + ((seed % 450) / 450.0) * 0.45;

      final phase =
          ((seed % 997) / 997.0) * math.pi * 2.0;

      final drift =
          math.sin(t * (0.18 + depth * 0.28) + phase);

      final x =
          baseX +
          parallax.dx * depth * 42.0 +
          drift * (2.0 + depth * 4.0);

      final y =
          baseY +
          parallax.dy * depth * 32.0 +
          math.cos(
                t * (0.14 + depth * 0.22) + phase,
              ) *
              (1.5 + depth * 3.0);

      final alpha =
          (0.10 +
                  ((math.sin(
                            t * (0.7 + depth) + phase,
                          ) +
                          1.0) /
                      2.0) *
                      0.30)
              .clamp(0.05, 0.42);

      paint.color = const Color(0xFFDCE5FF).withValues(
        alpha: alpha,
      );

      canvas.drawCircle(
        Offset(x, y),
        0.45 + depth * 0.9,
        paint,
      );
    }

    // Larger cinematic motes.
    for (int i = 0; i < 10; i++) {
      final seed = i * 1543 + 29;

      final baseX =
          (seed % 9973) / 9973.0 * size.width;
      final baseY =
          ((seed ~/ 7) % 9967) / 9967.0 * size.height;

      final phase =
          ((seed % 313) / 313.0) * math.pi * 2.0;

      final x =
          baseX +
          math.sin(t * 0.11 + phase) * 18.0 +
          parallax.dx * 55.0;

      final y =
          baseY +
          math.cos(t * 0.09 + phase) * 12.0 +
          parallax.dy * 42.0;

      final glow = Paint()
        ..color = const Color(0xFFB9C8FF).withValues(
          alpha: 0.12,
        )
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          7.0,
        );

      canvas.drawCircle(
        Offset(x, y),
        2.0,
        glow,
      );

      paint.color = Colors.white.withValues(
        alpha: 0.55,
      );

      canvas.drawCircle(
        Offset(x, y),
        0.7,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _ForegroundParticlePainter oldDelegate,
  ) {
    return true;
  }
}
