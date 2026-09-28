import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'institution_brand_draft.dart';
import 'institution_ocean_ambience.dart';

class InstitutionAmbienceLayer extends StatelessWidget {
  const InstitutionAmbienceLayer({
    super.key,
    required this.ambience,
    required this.intensityPercent,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.dark,
    this.oceanVariant = OceanVariant.turtleReef,
    this.oceanForegroundPlacement = false,
  });

  final InstitutionAmbience ambience;
  final int intensityPercent;
  final Color primary;
  final Color secondary;
  final Color accent;
  final bool dark;
  final OceanVariant oceanVariant;
  final bool oceanForegroundPlacement;

  @override
  Widget build(BuildContext context) {
    if (ambience == InstitutionAmbience.none || intensityPercent == 0) {
      return const SizedBox.expand(key: ValueKey('ambience-none'));
    }
    if (ambience == InstitutionAmbience.ocean) {
      return InstitutionOceanAmbience(
        key: const ValueKey('ambience-ocean'),
        intensityPercent: intensityPercent,
        variant: oceanVariant,
        foregroundPlacement: oceanForegroundPlacement,
      );
    }
    return RepaintBoundary(
      key: ValueKey('ambience-${ambience.name}'),
      child: CustomPaint(
        painter: _AmbiencePainter(
          ambience: ambience,
          intensityPercent: intensityPercent,
          primary: primary,
          secondary: secondary,
          accent: accent,
          dark: dark,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _AmbiencePainter extends CustomPainter {
  const _AmbiencePainter({
    required this.ambience,
    required this.intensityPercent,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.dark,
  });

  final InstitutionAmbience ambience;
  final int intensityPercent;
  final Color primary;
  final Color secondary;
  final Color accent;
  final bool dark;

  double get alpha => .24 * (intensityPercent.clamp(0, 100) / 100);

  Paint _stroke(Color color, [double width = 2, double multiplier = 1]) =>
      Paint()
        ..color = color.withValues(alpha: (alpha * multiplier).clamp(0.0, .48))
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  Paint _fill(Color color, [double multiplier = 1]) => Paint()
    ..color = color.withValues(alpha: (alpha * multiplier).clamp(0.0, .48))
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    switch (ambience) {
      case InstitutionAmbience.none:
        return;
      case InstitutionAmbience.my:
        return;
      case InstitutionAmbience.space:
        _space(canvas, size);
      case InstitutionAmbience.animals:
        _animals(canvas, size);
      case InstitutionAmbience.ocean:
        _ocean(canvas, size);
      case InstitutionAmbience.nature:
        _nature(canvas, size);
      case InstitutionAmbience.fantasy:
        _fantasy(canvas, size);
    }
  }

  Offset _point(Size size, double x, double y) =>
      Offset(size.width * x, size.height * y);

  void _star(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final length = i.isEven ? radius : radius * .32;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * length;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, _fill(color, 1.35));
  }

  void _leaf(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    Color color,
    double angle,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(-width / 2, 0)
      ..quadraticBezierTo(0, -height / 2, width / 2, 0)
      ..quadraticBezierTo(0, height / 2, -width / 2, 0)
      ..close();
    canvas.drawPath(path, _fill(color, 1.05));
    canvas.drawLine(
      Offset(-width * .32, 0),
      Offset(width * .32, 0),
      _stroke(color, 1, 1.5),
    );
    canvas.restore();
  }

  void _space(Canvas canvas, Size size) {
    final nebula = Rect.fromCircle(
      center: _point(size, .53, .38),
      radius: math.max(size.width, size.height) * .34,
    );
    canvas.drawOval(
      nebula,
      Paint()
        ..shader = RadialGradient(
          colors: [
            secondary.withValues(alpha: alpha * .75),
            primary.withValues(alpha: alpha * .24),
            Colors.transparent,
          ],
        ).createShader(nebula),
    );
    for (final star in <(double, double, double)>[
      (.06, .12, 3.0),
      (.17, .28, 2.2),
      (.29, .08, 3.6),
      (.42, .20, 2.0),
      (.59, .10, 2.8),
      (.71, .29, 2.0),
      (.90, .08, 3.2),
      (.80, .64, 2.5),
      (.94, .83, 2.0),
      (.58, .88, 3.0),
      (.31, .79, 2.1),
      (.09, .88, 3.3),
    ]) {
      _star(
        canvas,
        _point(size, star.$1, star.$2),
        star.$3,
        dark ? Colors.white : primary,
      );
    }
    final constellation = [
      _point(size, .22, .16),
      _point(size, .28, .23),
      _point(size, .35, .18),
      _point(size, .39, .28),
    ];
    canvas.drawPath(
      Path()
        ..moveTo(constellation.first.dx, constellation.first.dy)
        ..lineTo(constellation[1].dx, constellation[1].dy)
        ..lineTo(constellation[2].dx, constellation[2].dy)
        ..lineTo(constellation[3].dx, constellation[3].dy),
      _stroke(accent, 1.4, 1.2),
    );
    for (final point in constellation) {
      canvas.drawCircle(point, 3, _fill(accent, 1.45));
    }

    final planet = _point(size, .87, .23);
    final radius = math.min(size.width, size.height) * .085;
    final planetRect = Rect.fromCircle(center: planet, radius: radius);
    canvas.drawCircle(
      planet,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.35),
          colors: [
            accent.withValues(alpha: alpha * 1.55),
            primary.withValues(alpha: alpha * 1.25),
            secondary.withValues(alpha: alpha * .85),
          ],
        ).createShader(planetRect),
    );
    canvas.save();
    canvas.translate(planet.dx, planet.dy);
    canvas.rotate(-.28);
    canvas.translate(-planet.dx, -planet.dy);
    final orbit = Rect.fromCenter(
      center: planet,
      width: radius * 2.9,
      height: radius * .62,
    );
    canvas.drawOval(orbit, _stroke(accent, 3, 1.5));
    canvas.drawArc(
      orbit,
      0,
      math.pi,
      false,
      _stroke(dark ? Colors.white : primary, 2, .8),
    );
    canvas.restore();
    canvas.drawCircle(
      planet + Offset(-radius * .28, -radius * .18),
      radius * .14,
      _fill(Colors.white, .45),
    );

    final rocketCenter = _point(size, .13, .72);
    canvas.save();
    canvas.translate(rocketCenter.dx, rocketCenter.dy);
    canvas.rotate(-.62);
    final body = Path()
      ..moveTo(-34, 0)
      ..quadraticBezierTo(-8, -23, 32, 0)
      ..quadraticBezierTo(-8, 23, -34, 0)
      ..close();
    canvas.drawPath(body, _fill(primary, 1.35));
    canvas.drawCircle(const Offset(5, 0), 8, _fill(accent, 1.55));
    canvas.drawPath(
      Path()
        ..moveTo(-20, -10)
        ..lineTo(-31, -25)
        ..lineTo(-4, -15)
        ..close(),
      _fill(secondary, 1.4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-33, -7)
        ..quadraticBezierTo(-55, 0, -33, 7),
      _stroke(accent, 5, 1.5),
    );
    canvas.restore();
  }

  void _animals(Canvas canvas, Size size) {
    final ground = Path()
      ..moveTo(0, size.height * .82)
      ..quadraticBezierTo(
        size.width * .24,
        size.height * .70,
        size.width * .46,
        size.height * .84,
      )
      ..quadraticBezierTo(
        size.width * .72,
        size.height * .94,
        size.width,
        size.height * .76,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ground, _fill(secondary, .70));
    for (final base in [
      _point(size, .06, .89),
      _point(size, .18, .91),
      _point(size, .70, .91),
      _point(size, .94, .87),
    ]) {
      canvas.drawLine(base, base - const Offset(0, 46), _stroke(primary, 3));
      _leaf(canvas, base - const Offset(10, 25), 28, 14, secondary, -.45);
      _leaf(canvas, base + const Offset(10, -38), 30, 15, primary, .45);
    }

    final fox = _point(size, .86, .23);
    canvas.drawPath(
      Path()
        ..moveTo(fox.dx - 38, fox.dy - 18)
        ..lineTo(fox.dx - 28, fox.dy - 60)
        ..lineTo(fox.dx - 5, fox.dy - 28)
        ..close(),
      _fill(accent, 1.30),
    );
    canvas.drawPath(
      Path()
        ..moveTo(fox.dx + 38, fox.dy - 18)
        ..lineTo(fox.dx + 28, fox.dy - 60)
        ..lineTo(fox.dx + 5, fox.dy - 28)
        ..close(),
      _fill(accent, 1.30),
    );
    canvas.drawOval(
      Rect.fromCenter(center: fox, width: 82, height: 70),
      _fill(primary, 1.25),
    );
    canvas.drawPath(
      Path()
        ..moveTo(fox.dx - 27, fox.dy + 5)
        ..quadraticBezierTo(fox.dx, fox.dy + 42, fox.dx + 27, fox.dy + 5)
        ..quadraticBezierTo(fox.dx, fox.dy + 20, fox.dx - 27, fox.dy + 5)
        ..close(),
      _fill(Colors.white, .65),
    );
    canvas.drawCircle(fox + const Offset(-17, -7), 3, _fill(accent, 1.7));
    canvas.drawCircle(fox + const Offset(17, -7), 3, _fill(accent, 1.7));
    canvas.drawCircle(fox + const Offset(0, 10), 5, _fill(accent, 1.7));

    final rabbit = _point(size, .13, .68);
    canvas.drawOval(
      Rect.fromCenter(
        center: rabbit - const Offset(16, 43),
        width: 18,
        height: 62,
      ),
      _fill(secondary, 1.1),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: rabbit + const Offset(16, -43),
        width: 18,
        height: 62,
      ),
      _fill(secondary, 1.1),
    );
    canvas.drawCircle(rabbit, 37, _fill(secondary, 1.25));
    canvas.drawCircle(rabbit + const Offset(-13, -5), 3, _fill(accent, 1.6));
    canvas.drawCircle(rabbit + const Offset(13, -5), 3, _fill(accent, 1.6));
    canvas.drawCircle(rabbit + const Offset(0, 9), 4, _fill(primary, 1.6));

    final bird = _point(size, .48, .15);
    canvas.drawPath(
      Path()
        ..moveTo(bird.dx - 24, bird.dy)
        ..quadraticBezierTo(bird.dx - 10, bird.dy - 18, bird.dx, bird.dy)
        ..quadraticBezierTo(bird.dx + 10, bird.dy - 18, bird.dx + 24, bird.dy),
      _stroke(accent, 3, 1.3),
    );
  }

  void _ocean(Canvas canvas, Size size) {
    for (var i = 0; i < 5; i++) {
      canvas.drawPath(
        Path()
          ..moveTo(size.width * (.06 + i * .21), 0)
          ..lineTo(size.width * (.14 + i * .20), size.height * .72)
          ..lineTo(size.width * (.22 + i * .18), 0)
          ..close(),
        _fill(dark ? Colors.white : secondary, .30),
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .86)
        ..quadraticBezierTo(
          size.width * .22,
          size.height * .77,
          size.width * .43,
          size.height * .88,
        )
        ..quadraticBezierTo(
          size.width * .73,
          size.height,
          size.width,
          size.height * .82,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      _fill(accent, .58),
    );

    void coral(Offset base, double scale, Color color) {
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..cubicTo(
            base.dx - 8 * scale,
            base.dy - 34 * scale,
            base.dx + 8 * scale,
            base.dy - 70 * scale,
            base.dx,
            base.dy - 104 * scale,
          )
          ..moveTo(base.dx, base.dy - 45 * scale)
          ..quadraticBezierTo(
            base.dx - 32 * scale,
            base.dy - 55 * scale,
            base.dx - 34 * scale,
            base.dy - 82 * scale,
          )
          ..moveTo(base.dx + 2 * scale, base.dy - 66 * scale)
          ..quadraticBezierTo(
            base.dx + 30 * scale,
            base.dy - 78 * scale,
            base.dx + 31 * scale,
            base.dy - 98 * scale,
          ),
        _stroke(color, 5 * scale, 1.25),
      );
    }

    coral(_point(size, .09, .94), .75, primary);
    coral(_point(size, .90, .96), 1, accent);

    final whale = _point(size, .76, .22);
    canvas.drawPath(
      Path()
        ..moveTo(whale.dx - 54, whale.dy)
        ..quadraticBezierTo(
          whale.dx - 12,
          whale.dy - 38,
          whale.dx + 46,
          whale.dy,
        )
        ..quadraticBezierTo(
          whale.dx - 2,
          whale.dy + 42,
          whale.dx - 54,
          whale.dy,
        )
        ..close(),
      _fill(primary, 1.25),
    );
    canvas.drawCircle(whale + const Offset(23, -6), 3, _fill(accent, 1.7));
    canvas.drawPath(
      Path()
        ..moveTo(whale.dx - 48, whale.dy)
        ..lineTo(whale.dx - 72, whale.dy - 19)
        ..lineTo(whale.dx - 67, whale.dy + 2)
        ..lineTo(whale.dx - 75, whale.dy + 20)
        ..close(),
      _fill(secondary, 1.2),
    );
    canvas.drawPath(
      Path()
        ..moveTo(whale.dx + 5, whale.dy - 24)
        ..quadraticBezierTo(
          whale.dx + 3,
          whale.dy - 50,
          whale.dx - 8,
          whale.dy - 58,
        )
        ..moveTo(whale.dx + 5, whale.dy - 24)
        ..quadraticBezierTo(
          whale.dx + 20,
          whale.dy - 48,
          whale.dx + 29,
          whale.dy - 55,
        ),
      _stroke(secondary, 2.5, 1.25),
    );

    final turtle = _point(size, .24, .51);
    canvas.drawOval(
      Rect.fromCenter(center: turtle, width: 72, height: 46),
      _fill(secondary, 1.15),
    );
    canvas.drawCircle(turtle + const Offset(42, -2), 13, _fill(primary, 1.2));
    for (final delta in [
      const Offset(-20, -25),
      const Offset(18, -23),
      const Offset(-20, 25),
      const Offset(18, 23),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: turtle + delta, width: 24, height: 11),
        _fill(accent, .95),
      );
    }
    for (final bubble in [
      _point(size, .12, .18),
      _point(size, .17, .12),
      _point(size, .58, .37),
      _point(size, .88, .49),
    ]) {
      canvas.drawCircle(
        bubble,
        7,
        _stroke(dark ? Colors.white : primary, 2, 1.2),
      );
      canvas.drawCircle(bubble + const Offset(8, -11), 3, _stroke(accent, 1.3));
    }
  }

  void _nature(Canvas canvas, Size size) {
    final sun = _point(size, .80, .17);
    canvas.drawCircle(sun, 37, _fill(accent, 1.15));
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi / 5;
      canvas.drawLine(
        sun + Offset(math.cos(angle), math.sin(angle)) * 48,
        sun + Offset(math.cos(angle), math.sin(angle)) * 63,
        _stroke(accent, 2, .9),
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(0, size.height * .70)
        ..lineTo(size.width * .19, size.height * .37)
        ..lineTo(size.width * .36, size.height * .70)
        ..lineTo(size.width * .57, size.height * .29)
        ..lineTo(size.width * .82, size.height * .70)
        ..lineTo(size.width, size.height * .49)
        ..lineTo(size.width, size.height)
        ..close(),
      _fill(primary, .64),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(0, size.height * .83)
        ..lineTo(size.width * .28, size.height * .58)
        ..lineTo(size.width * .48, size.height * .82)
        ..lineTo(size.width * .74, size.height * .48)
        ..lineTo(size.width, size.height * .79)
        ..lineTo(size.width, size.height)
        ..close(),
      _fill(secondary, .82),
    );
    for (final peak in [
      _point(size, .19, .37),
      _point(size, .57, .29),
      _point(size, .74, .48),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(peak.dx - 20, peak.dy + 35)
          ..lineTo(peak.dx, peak.dy)
          ..lineTo(peak.dx + 22, peak.dy + 35)
          ..lineTo(peak.dx + 8, peak.dy + 28)
          ..lineTo(peak.dx, peak.dy + 36)
          ..lineTo(peak.dx - 7, peak.dy + 26)
          ..close(),
        _fill(Colors.white, .52),
      );
    }

    void tree(Offset base, double scale) {
      canvas.drawRect(
        Rect.fromCenter(
          center: base - Offset(0, 28 * scale),
          width: 7 * scale,
          height: 56 * scale,
        ),
        _fill(accent, .9),
      );
      for (var i = 0; i < 3; i++) {
        final y = base.dy - (45 + i * 22) * scale;
        canvas.drawPath(
          Path()
            ..moveTo(base.dx, y - 42 * scale)
            ..lineTo(base.dx - (34 - i * 5) * scale, y + 20 * scale)
            ..lineTo(base.dx + (34 - i * 5) * scale, y + 20 * scale)
            ..close(),
          _fill(primary, 1.05 - i * .08),
        );
      }
    }

    tree(_point(size, .09, .96), .75);
    tree(_point(size, .91, .97), .96);
    tree(_point(size, .68, .98), .55);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .13)
        ..quadraticBezierTo(
          size.width * .13,
          size.height * .20,
          size.width * .25,
          0,
        ),
      _stroke(accent, 4, .9),
    );
    for (final leaf in [
      (_point(size, .05, .12), -.5),
      (_point(size, .11, .13), .4),
      (_point(size, .17, .08), -.4),
      (_point(size, .22, .04), .5),
    ]) {
      _leaf(canvas, leaf.$1, 30, 15, primary, leaf.$2);
    }
  }

  void _fantasy(Canvas canvas, Size size) {
    final moon = _point(size, .83, .17);
    canvas.drawCircle(moon, 42, _fill(accent, .95));
    canvas.drawCircle(
      moon + const Offset(15, -8),
      38,
      _fill(dark ? const Color(0xFF10172E) : Colors.white, 1.2),
    );
    for (final point in [
      _point(size, .10, .12),
      _point(size, .27, .21),
      _point(size, .48, .10),
      _point(size, .66, .28),
      _point(size, .93, .36),
    ]) {
      _star(canvas, point, 7, accent);
    }

    final baseY = size.height * .88;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .68, baseY - 132, size.width * .25, 132),
        const Radius.circular(4),
      ),
      _fill(primary, 1.0),
    );
    for (final x in [.67, .84]) {
      final tower = Rect.fromLTWH(size.width * x, baseY - 178, 54, 178);
      canvas.drawRRect(
        RRect.fromRectAndRadius(tower, const Radius.circular(7)),
        _fill(primary, 1.2),
      );
      canvas.drawPath(
        Path()
          ..moveTo(tower.left - 8, tower.top + 4)
          ..lineTo(tower.center.dx, tower.top - 44)
          ..lineTo(tower.right + 8, tower.top + 4)
          ..close(),
        _fill(secondary, 1.25),
      );
      canvas.drawLine(
        Offset(tower.center.dx, tower.top - 44),
        Offset(tower.center.dx, tower.top - 70),
        _stroke(accent, 2),
      );
      canvas.drawPath(
        Path()
          ..moveTo(tower.center.dx, tower.top - 69)
          ..lineTo(tower.center.dx + 24, tower.top - 60)
          ..lineTo(tower.center.dx, tower.top - 49)
          ..close(),
        _fill(accent, 1.4),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(tower.center.dx, tower.top + 57),
            width: 13,
            height: 27,
          ),
          const Radius.circular(8),
        ),
        _fill(Colors.white, .65),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(size.width * .80, baseY - 35),
          width: 35,
          height: 70,
        ),
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
      ),
      _fill(accent, 1.1),
    );

    final book = _point(size, .19, .73);
    canvas.drawPath(
      Path()
        ..moveTo(book.dx, book.dy)
        ..quadraticBezierTo(
          book.dx - 45,
          book.dy - 30,
          book.dx - 91,
          book.dy - 10,
        )
        ..lineTo(book.dx - 78, book.dy + 48)
        ..quadraticBezierTo(book.dx - 35, book.dy + 31, book.dx, book.dy + 52)
        ..close(),
      _fill(dark ? Colors.white : primary, .85),
    );
    canvas.drawPath(
      Path()
        ..moveTo(book.dx, book.dy)
        ..quadraticBezierTo(
          book.dx + 45,
          book.dy - 30,
          book.dx + 91,
          book.dy - 10,
        )
        ..lineTo(book.dx + 78, book.dy + 48)
        ..quadraticBezierTo(book.dx + 35, book.dy + 31, book.dx, book.dy + 52)
        ..close(),
      _fill(dark ? Colors.white : primary, .85),
    );
    canvas.drawLine(book, book + const Offset(0, 51), _stroke(accent, 2));
    for (var i = 0; i < 3; i++) {
      final y = book.dy + 5 + i * 11;
      canvas.drawLine(
        Offset(book.dx - 66, y),
        Offset(book.dx - 18, y + 8),
        _stroke(secondary, 1.3, .8),
      );
      canvas.drawLine(
        Offset(book.dx + 18, y + 8),
        Offset(book.dx + 66, y),
        _stroke(secondary, 1.3, .8),
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(book.dx, book.dy - 6)
        ..cubicTo(
          book.dx - 32,
          book.dy - 62,
          book.dx + 45,
          book.dy - 82,
          book.dx + 9,
          book.dy - 136,
        ),
      _stroke(accent, 2.5, 1.3),
    );
    _star(canvas, book + const Offset(8, -145), 10, accent);

    final creature = _point(size, .45, .34);
    canvas.drawOval(
      Rect.fromCenter(center: creature, width: 76, height: 55),
      _fill(secondary, 1.1),
    );
    canvas.drawPath(
      Path()
        ..moveTo(creature.dx - 25, creature.dy - 18)
        ..lineTo(creature.dx - 39, creature.dy - 46)
        ..lineTo(creature.dx - 5, creature.dy - 25)
        ..moveTo(creature.dx + 25, creature.dy - 18)
        ..lineTo(creature.dx + 39, creature.dy - 46)
        ..lineTo(creature.dx + 5, creature.dy - 25),
      _stroke(primary, 6, 1.15),
    );
    canvas.drawCircle(creature + const Offset(-15, -4), 4, _fill(accent, 1.6));
    canvas.drawCircle(creature + const Offset(15, -4), 4, _fill(accent, 1.6));
    canvas.drawArc(
      Rect.fromCenter(
        center: creature + const Offset(0, 9),
        width: 26,
        height: 16,
      ),
      .15,
      math.pi - .3,
      false,
      _stroke(accent, 2, 1.4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(creature.dx - 35, creature.dy + 3)
        ..quadraticBezierTo(
          creature.dx - 72,
          creature.dy - 26,
          creature.dx - 65,
          creature.dy + 22,
        )
        ..moveTo(creature.dx + 35, creature.dy + 3)
        ..quadraticBezierTo(
          creature.dx + 72,
          creature.dy - 26,
          creature.dx + 65,
          creature.dy + 22,
        ),
      _stroke(secondary, 4, 1.1),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbiencePainter oldDelegate) =>
      ambience != oldDelegate.ambience ||
      intensityPercent != oldDelegate.intensityPercent ||
      primary != oldDelegate.primary ||
      secondary != oldDelegate.secondary ||
      accent != oldDelegate.accent ||
      dark != oldDelegate.dark;
}
