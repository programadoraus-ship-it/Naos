import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/supabase/institution_admin_context.dart';
import '../../../../core/services/supabase/supabase_service.dart';
import '../../../institution_onboarding/domain/institution_onboarding_progress.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  String? _accessError;
  late final AnimationController _controller;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.75, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    _startApp();
  }

  // ============================================================
  // START APPLICATION
  // ============================================================

  Future<void> _startApp() async {
    // Give Supabase enough time to restore the saved session.
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;

    await _checkUserAccess();
  }

  // ============================================================
  // CHECK USER ACCESS
  // ============================================================

  Future<void> _checkUserAccess() async {
    final supabase = SupabaseService.client;

    // ----------------------------------------------------------
    // GET CURRENT SESSION
    // ----------------------------------------------------------

    final session = supabase.auth.currentSession;
    final user = session?.user;

    // Debug information
    debugPrint('========================================');
    debugPrint('NAOS SPLASH - SESSION CHECK');
    debugPrint('Current URL: ${Uri.base}');
    debugPrint('Session exists: ${session != null}');
    debugPrint('User exists: ${user != null}');
    debugPrint('User ID: ${user?.id}');
    debugPrint('User email: ${user?.email}');
    debugPrint('========================================');

    // ----------------------------------------------------------
    // NO SESSION
    // ----------------------------------------------------------

    if (session == null || user == null) {
      debugPrint('NAOS: No active Supabase session. Going to Login.');

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.login,
        (route) => false,
      );

      return;
    }

    try {
      // --------------------------------------------------------
      // GET USER PROFILE
      // --------------------------------------------------------

      final profile = await SupabaseService.getCurrentUserProfile();

      debugPrint('NAOS: Profile found: ${profile != null}');

      if (!mounted) return;

      // --------------------------------------------------------
      // PROFILE NOT FOUND
      // --------------------------------------------------------

      if (profile == null) {
        debugPrint('NAOS: User session exists but profile was not found.');

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.login,
          (route) => false,
        );

        return;
      }

      final role = profile['role'] as String?;

      debugPrint('NAOS: User role = $role');

      // --------------------------------------------------------
      // SUPER ADMIN
      // --------------------------------------------------------

      if (role == 'super_admin') {
        debugPrint('NAOS: Super admin detected. Going to Admin.');

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.admin,
          (route) => false,
        );

        return;
      }

      // --------------------------------------------------------
      // INSTITUTION ADMIN
      // --------------------------------------------------------

      if (role == 'institution_admin') {
        final adminContext = await InstitutionAdminContextResolver(
          supabase,
        ).resolve(user.id);
        final institutionId = adminContext.institutionId;

        if (!mounted) return;

        if (institutionId == null) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRouter.institutionOnboardingWelcome,
            (route) => false,
          );
          return;
        }

        final institution = await supabase
            .from('institutions')
            .select('id, onboarding_completed, onboarding_step')
            .eq('id', institutionId)
            .maybeSingle();

        if (institution == null) {
          throw Exception('The linked institution could not be found.');
        }

        final progress = InstitutionOnboardingProgress.fromValues(
          step: institution['onboarding_step'],
          completed: institution['onboarding_completed'],
        );

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          progress.isCompleted
              ? AppRouter.institutionAdmin
              : AppRouter.institutionOnboardingWelcome,
          (route) => false,
        );
        return;
      }

      // --------------------------------------------------------
      // CHECK INSTITUTION MEMBERSHIP
      // --------------------------------------------------------

      debugPrint(
        'NAOS: Checking institution membership for '
        'user ${user.id}',
      );

      final membership = await supabase
          .from('institution_memberships')
          .select('id, institution_id, status, requested_at, approved_at')
          .eq('user_id', user.id)
          .order('requested_at', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint('NAOS: Membership = $membership');

      if (!mounted) return;

      // --------------------------------------------------------
      // PENDING
      // --------------------------------------------------------

      if (membership != null && membership['status'] == 'pending') {
        debugPrint(
          'NAOS: Membership is PENDING. '
          'Going to Access Pending.',
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.accessPending,
          (route) => false,
        );

        return;
      }

      // --------------------------------------------------------
      // APPROVED
      // --------------------------------------------------------

      if (membership != null && membership['status'] == 'approved') {
        debugPrint(
          'NAOS: Membership is APPROVED. '
          'Going to Home.',
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.home,
          (route) => false,
        );

        return;
      }

      // --------------------------------------------------------
      // REJECTED OR NO MEMBERSHIP
      // --------------------------------------------------------

      debugPrint(
        'NAOS: No pending/approved membership. '
        'Going to Academy.',
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.academy,
        (route) => false,
      );
    } catch (e, stackTrace) {
      // --------------------------------------------------------
      // ACCESS CHECK ERROR
      // --------------------------------------------------------

      debugPrint('========================================');
      debugPrint('NAOS SPLASH ACCESS ERROR');
      debugPrint('ERROR: $e');
      debugPrint('========================================');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      if (e is InstitutionAdminContextException) {
        setState(() {
          _accessError = e.message;
        });
        return;
      }

      // For now we return to Login if the access check itself
      // fails. The debug console will show exactly why.
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.login,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // ------------------------------------------------
              // BACKGROUND
              // ------------------------------------------------
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF050816),
                      Color(0xFF0B0A24),
                      Color(0xFF120B31),
                      Color(0xFF050816),
                    ],
                  ),
                ),
              ),

              // ------------------------------------------------
              // STARS
              // ------------------------------------------------
              Positioned.fill(
                child: CustomPaint(
                  painter: _StarsPainter(progress: _controller.value),
                ),
              ),

              // ------------------------------------------------
              // CENTRAL GLOW
              // ------------------------------------------------
              Positioned.fill(
                child: CustomPaint(
                  painter: _GlowPainter(intensity: _glowAnimation.value),
                ),
              ),

              // ------------------------------------------------
              // NAOS LOGO
              // ------------------------------------------------
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFF8B7CFF),
                                Color(0xFF694CFF),
                                Color(0xFF381B83),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF765CFF).withValues(
                                  alpha: 0.30 * _glowAnimation.value,
                                ),
                                blurRadius: 70,
                                spreadRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          'NAOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 10,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Opacity(
                          opacity: _fadeAnimation.value,
                          child: const Text(
                            'LEARN  •  EXPLORE  •  SHINE',
                            style: TextStyle(
                              color: Color(0xFFB9C1FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ------------------------------------------------
              // LOADING INDICATOR
              // ------------------------------------------------
              Positioned(
                bottom: 55,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Center(
                    child: _accessError == null
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF7C83FF),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _accessError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFFA8B5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// CENTRAL GLOW
// ============================================================

class _GlowPainter extends CustomPainter {
  final double intensity;

  _GlowPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);

    final radius = size.width * 0.55;

    final paint = Paint();

    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF704DFF).withValues(alpha: 0.15 * intensity),
        const Color(0xFF3B55FF).withValues(alpha: 0.08 * intensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}

// ============================================================
// STARS
// ============================================================

class _StarsPainter extends CustomPainter {
  final double progress;

  _StarsPainter({required this.progress});

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
    Offset(0.52, 0.08),
    Offset(0.27, 0.91),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _stars.length; i++) {
      final star = _stars[i];

      final twinkle = 0.30 + (math.sin(progress * math.pi * 2 + i) + 1) * 0.30;

      final radius = i % 5 == 0 ? 1.8 : 0.9;

      final paint = Paint()..color = Colors.white.withValues(alpha: twinkle);

      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
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
