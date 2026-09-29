import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_router.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF050816),
                  const Color(0xFF100A2E),
                  const Color(0xFF170B3F),
                  const Color(0xFF050816),
                ],
                stops: [
                  0.0,
                  0.35 + (_controller.value * 0.05),
                  0.7,
                  1.0,
                ],
              ),
            ),
            child: Stack(
              children: [
                _buildGalaxyGlow(),
                _buildStars(),
                _buildContent(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGalaxyGlow() {
    final rotation = _controller.value * math.pi * 2;

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GalaxyPainter(rotation),
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _StarsPainter(
            progress: _controller.value,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 40,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // NAOS symbol
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF6E7CFF),
                      Color(0xFF8B3DFF),
                      Color(0xFFEC3BFF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CFF).withValues(alpha: 0.45),
                      blurRadius: 45,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 34),

              const Text(
                'NAOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Learn  •  Explore  •  Shine',
                style: TextStyle(
                  color: Color(0xFFBFC8FF),
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Your journey starts here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF858FB8),
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 52),

              SizedBox(
                width: 260,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.academy,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6478FF),
                    foregroundColor: Colors.white,
                    elevation: 12,
                    shadowColor: const Color(0xFF6478FF).withValues(
                      alpha: 0.45,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Begin Journey',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  final double rotation;

  _GalaxyPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width * 0.5,
      size.height * 0.42,
    );

    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        70,
      );

    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFB52CFF).withValues(alpha: 0.16),
        const Color(0xFF405DFF).withValues(alpha: 0.10),
        Colors.transparent,
      ],
    ).createShader(
      Rect.fromCircle(
        center: center,
        radius: size.width * 0.65,
      ),
    );

    canvas.drawCircle(
      center,
      size.width * 0.65,
      paint,
    );

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF8E6BFF).withValues(alpha: 0.06);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.9,
        height: size.height * 0.32,
      ),
      orbitPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}

class _StarsPainter extends CustomPainter {
  final double progress;

  _StarsPainter({
    required this.progress,
  });

  final List<Offset> _stars = const [
    Offset(0.08, 0.16),
    Offset(0.16, 0.72),
    Offset(0.24, 0.28),
    Offset(0.31, 0.11),
    Offset(0.39, 0.83),
    Offset(0.47, 0.20),
    Offset(0.54, 0.70),
    Offset(0.63, 0.14),
    Offset(0.71, 0.34),
    Offset(0.79, 0.76),
    Offset(0.87, 0.19),
    Offset(0.94, 0.62),
    Offset(0.11, 0.47),
    Offset(0.35, 0.56),
    Offset(0.58, 0.43),
    Offset(0.68, 0.88),
    Offset(0.84, 0.48),
    Offset(0.91, 0.31),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _stars.length; i++) {
      final star = _stars[i];

      final twinkle =
          0.45 + (math.sin((progress * math.pi * 2) + i) + 1) * 0.25;

      final radius = i % 4 == 0 ? 2.2 : 1.1;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: twinkle);

      canvas.drawCircle(
        Offset(
          star.dx * size.width,
          star.dy * size.height,
        ),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}