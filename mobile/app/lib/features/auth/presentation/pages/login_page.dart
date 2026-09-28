import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase/supabase_service.dart';
import '../../../../core/services/supabase/institution_admin_context.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../institution_onboarding/domain/institution_onboarding_progress.dart';
import '../../../institution_onboarding/presentation/pages/institution_onboarding_flow_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Prevents Supabase auth events and manual login
  // from navigating at the same time.
  bool _isRouting = false;

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // Handles OAuth redirects and restores an existing session.
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      if (!mounted) return;

      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.initialSession) {
        await _goToCorrectPage();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // ROUTE USER BY ACCESS STATUS
  // ============================================================

  Future<void> _goToCorrectPage() async {
    // Prevent duplicate navigation.
    if (_isRouting) return;

    final user = SupabaseService.client.auth.currentUser;

    if (user == null || !mounted) return;

    _isRouting = true;

    try {
      // ----------------------------------------------------------
      // GET PROFILE
      // ----------------------------------------------------------

      final profile = await SupabaseService.getCurrentUserProfile();

      if (!mounted) return;

      final role = profile?['role'] as String?;

      debugPrint('==========================================');
      debugPrint('NAOS LOGIN ROUTING');
      debugPrint('User ID: ${user.id}');
      debugPrint('Role: $role');
      debugPrint('==========================================');

      // ----------------------------------------------------------
      // SUPER ADMIN
      // ----------------------------------------------------------

      if (role == 'super_admin') {
        debugPrint('→ Super Admin Dashboard');

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.admin,
          (route) => false,
        );

        return;
      }

      // ----------------------------------------------------------
      // INSTITUTION ADMIN
      // ----------------------------------------------------------

      if (role == 'institution_admin') {
        debugPrint('→ Institution Admin detected');

        // --------------------------------------------------------
        // FIND ADMIN'S INSTITUTION
        // --------------------------------------------------------

        final adminContext = await InstitutionAdminContextResolver(
          SupabaseService.client,
        ).resolve(user.id);

        if (!mounted) return;

        // --------------------------------------------------------
        // ADMIN WITHOUT ACTIVE INSTITUTION
        // --------------------------------------------------------

        final institutionId = adminContext.institutionId;

        if (institutionId == null || institutionId.isEmpty) {
          debugPrint('NAOS: Admin approved but has no institution yet.');
          debugPrint('NAOS: Opening institution onboarding.');

          if (!mounted) return;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const InstitutionOnboardingFlowPage(),
            ),
          );

          return;
        }
        debugPrint('Institution ID: $institutionId');

        // --------------------------------------------------------
        // GET INSTITUTION ONBOARDING STATUS
        // --------------------------------------------------------

        final institution = await SupabaseService.client
            .from('institutions')
            .select('id, name, onboarding_completed, onboarding_step')
            .eq('id', institutionId)
            .maybeSingle();

        if (!mounted) return;

        // --------------------------------------------------------
        // INSTITUTION NOT FOUND
        // --------------------------------------------------------

        if (institution == null) {
          debugPrint('❌ Institution not found.');

          _showMessage('Your institution could not be found.', isError: true);

          return;
        }

        final progress = InstitutionOnboardingProgress.fromValues(
          step: institution['onboarding_step'],
          completed: institution['onboarding_completed'],
        );

        debugPrint('Institution: ${institution['name']}');

        debugPrint('Onboarding completed: ${progress.isCompleted}');

        debugPrint('Onboarding step: ${progress.storedStep}');

        if (progress.message != null) {
          debugPrint('Onboarding state notice: ${progress.message}');
        }

        // --------------------------------------------------------
        // FIRST LOGIN / ONBOARDING NOT COMPLETED
        // --------------------------------------------------------

        if (!progress.isCompleted) {
          debugPrint('✨ ONBOARDING NOT COMPLETED');

          debugPrint('→ Opening NAOS Institution Onboarding');

          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRouter.institutionOnboardingWelcome,
            (route) => false,
          );

          return;
        }

        // --------------------------------------------------------
        // ONBOARDING ALREADY COMPLETED
        // --------------------------------------------------------

        debugPrint('✅ ONBOARDING ALREADY COMPLETED');

        debugPrint('→ Institution Dashboard');

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.institutionAdmin,
          (route) => false,
        );

        return;
      }

      // ----------------------------------------------------------
      // CHECK INSTITUTION MEMBERSHIP
      // ----------------------------------------------------------

      final membership = await SupabaseService.client
          .from('institution_memberships')
          .select('id, institution_id, status, requested_at, approved_at')
          .eq('user_id', user.id)
          .order('requested_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      // ----------------------------------------------------------
      // PENDING
      // ----------------------------------------------------------

      if (membership != null && membership['status'] == 'pending') {
        debugPrint('→ Institution membership pending');

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.accessPending,
          (route) => false,
        );

        return;
      }

      // ----------------------------------------------------------
      // APPROVED
      // ----------------------------------------------------------

      if (membership != null && membership['status'] == 'approved') {
        debugPrint('→ Institution membership approved');

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.home,
          (route) => false,
        );

        return;
      }

      // ----------------------------------------------------------
      // REJECTED
      // ----------------------------------------------------------

      if (membership != null && membership['status'] == 'rejected') {
        _showMessage(
          'Your institution access request was rejected.',
          isError: true,
        );

        return;
      }

      // ----------------------------------------------------------
      // NO INSTITUTION REQUEST
      // ----------------------------------------------------------

      debugPrint('→ No institution request');

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.academy,
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ACCESS STATUS ERROR: $e');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage('Access status error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _isRouting = false;
    }
  }

  // ============================================================
  // GOOGLE
  // ============================================================

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'http://localhost:YOUR_PORT/#/login',
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Google sign in failed. Please try again.', isError: true);
    }
  }

  // ============================================================
  // EMAIL / PASSWORD
  // ============================================================

  Future<void> _signInWithEmail() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // The Supabase auth listener may already have called
      // _goToCorrectPage(). The routing guard prevents
      // duplicate navigation.
      await _goToCorrectPage();
    } on AuthException catch (e) {
      if (!mounted) return;

      _showMessage(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Enter your email first.', isError: true);
      return;
    }

    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);

      if (!mounted) return;

      _showMessage('Password reset instructions have been sent to your email.');
    } on AuthException catch (e) {
      if (!mounted) return;

      _showMessage(e.message, isError: true);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFB4233C)
            : const Color(0xFF3949AB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SpacePainter(progress: _animationController.value),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x22080D2A),
                        Color(0x66050616),
                        Color(0xDD050816),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: _buildLoginCard(),
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

  // ============================================================
  // LOGIN CARD
  // ============================================================

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF11162B).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF7382FF).withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D5FEF).withValues(alpha: 0.16),
            blurRadius: 60,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 28),
          const Text(
            'Welcome to NAOS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your learning journey continues here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA7C7), fontSize: 15),
          ),
          const SizedBox(height: 30),
          _buildGoogleButton(),
          const SizedBox(height: 12),
          _buildAppleButton(),
          const SizedBox(height: 26),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildEmailField(),
          const SizedBox(height: 14),
          _buildPasswordField(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _forgotPassword,
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  color: Color(0xFF9EA9FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSignInButton(),
          const SizedBox(height: 26),
          _buildCreateAccount(),
          const SizedBox(height: 18),
          const Text(
            'By continuing, you agree to the NAOS Terms and Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF626B89),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF9D8CFF), Color(0xFF635BFF), Color(0xFF3426A8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7568FF).withValues(alpha: 0.5),
            blurRadius: 35,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 38),
    );
  }

  // ============================================================
  // GOOGLE BUTTON
  // ============================================================

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF161A2A),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'G',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
            Text(
              _isLoading ? 'Connecting...' : 'Continue with Google',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APPLE BUTTON
  // ============================================================

  Widget _buildAppleButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apple, size: 22),
            SizedBox(width: 10),
            Text(
              'Continue with Apple',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('or', style: TextStyle(color: Color(0xFF6D7590))),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10))),
      ],
    );
  }

  // ============================================================
  // EMAIL
  // ============================================================

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Email',
        icon: Icons.mail_outline_rounded,
      ),
    );
  }

  // ============================================================
  // PASSWORD
  // ============================================================

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      onSubmitted: (_) => _signInWithEmail(),
      decoration: _inputDecoration(
        label: 'Password',
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF8B94B3),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8B94B3)),
      prefixIcon: Icon(icon, color: const Color(0xFF8B94B3)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF090E20).withValues(alpha: 0.75),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6F72FF), width: 1.2),
      ),
    );
  }

  // ============================================================
  // SIGN IN BUTTON
  // ============================================================

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B6FFF),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF4B4E9A),
          elevation: 8,
          shadowColor: const Color(0xFF6265FF).withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  // ============================================================
  // CREATE ACCOUNT
  // ============================================================

  Widget _buildCreateAccount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(color: Color(0xFF777F99)),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.pushNamed(context, AppRouter.register);
                },
          child: const Text(
            'Create account',
            style: TextStyle(
              color: Color(0xFF9EA9FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SPACE BACKGROUND
// ============================================================

class _SpacePainter extends CustomPainter {
  final double progress;

  _SpacePainter({required this.progress});

  final List<Offset> stars = const [
    Offset(0.08, 0.14),
    Offset(0.15, 0.72),
    Offset(0.22, 0.30),
    Offset(0.29, 0.10),
    Offset(0.38, 0.82),
    Offset(0.46, 0.21),
    Offset(0.54, 0.68),
    Offset(0.62, 0.12),
    Offset(0.71, 0.35),
    Offset(0.79, 0.76),
    Offset(0.87, 0.18),
    Offset(0.94, 0.61),
    Offset(0.11, 0.47),
    Offset(0.34, 0.55),
    Offset(0.58, 0.43),
    Offset(0.68, 0.88),
    Offset(0.83, 0.48),
    Offset(0.91, 0.31),
    Offset(0.50, 0.08),
    Offset(0.04, 0.38),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.72, size.height * 0.22);

    final glowPaint = Paint();

    glowPaint.shader = RadialGradient(
      colors: [
        const Color(0xFF7357FF).withValues(alpha: 0.20),
        const Color(0xFF3B5BFF).withValues(alpha: 0.08),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.65));

    canvas.drawCircle(center, size.width * 0.65, glowPaint);

    for (int i = 0; i < stars.length; i++) {
      final star = stars[i];

      final twinkle =
          0.35 + (math.sin(progress * math.pi * 2 + i * 1.7) + 1) * 0.25;

      final radius = i % 5 == 0 ? 1.8 : 1.0;

      final paint = Paint()..color = Colors.white.withValues(alpha: twinkle);

      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        radius,
        paint,
      );
    }

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF8B7CFF).withValues(alpha: 0.07);

    canvas.save();

    canvas.translate(size.width * 0.72, size.height * 0.22);

    canvas.rotate(progress * math.pi * 2);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.75,
        height: size.height * 0.25,
      ),
      orbitPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpacePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
