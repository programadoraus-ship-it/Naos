import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/services/supabase/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // USERNAME
  // ------------------------------------------------------------

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  Future<bool> _isUsernameBlocked(String username) async {
    try {
      final normalized = _normalizeUsername(username);

      final result = await SupabaseService.client
          .from('username_restrictions')
          .select('id')
          .eq('restriction_type', 'blocked')
          .eq('is_active', true)
          .eq('value', normalized)
          .maybeSingle();

      return result != null;
    } catch (e) {
      // If the table cannot be queried from the client,
      // the database trigger will still protect the username.
      debugPrint('USERNAME BLOCK CHECK ERROR: $e');
      return false;
    }
  }

  Future<bool> _isUsernameReserved(String username) async {
    try {
      final normalized = _normalizeUsername(username);

      final result = await SupabaseService.client
          .from('username_restrictions')
          .select('id')
          .eq('restriction_type', 'reserved')
          .eq('is_active', true)
          .eq('value', normalized)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('USERNAME RESERVED CHECK ERROR: $e');
      return false;
    }
  }

  Future<bool> _isUsernameAlreadyUsed(String username) async {
    try {
      final normalized = _normalizeUsername(username);

      final result = await SupabaseService.client
          .rpc('is_username_taken', params: {'p_username': normalized});

      return result == true;
    } catch (e) {
      // The unique database index is still the final protection.
      debugPrint('USERNAME DUPLICATE CHECK ERROR: $e');
      return false;
    }
  }

  // ------------------------------------------------------------
  // REGISTER
  // ------------------------------------------------------------

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      _showFriendlyError(
        title: 'Almost there',
        message:
            'Please accept the NAOS Terms of Service and Privacy Policy '
            'before creating your account.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final fullName = _nameController.text.trim();
      final username = _normalizeUsername(_usernameController.text);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // --------------------------------------------------------
      // 1. Check blocked username
      // --------------------------------------------------------

      final isBlocked = await _isUsernameBlocked(username);

      if (isBlocked) {
        if (!mounted) return;

        _showFriendlyError(
          title: 'Username not available',
          message:
              'This username contains a word that cannot be used on NAOS.\n\n'
              'Please choose a different username.',
        );

        return;
      }

      // --------------------------------------------------------
      // 2. Check reserved username
      // --------------------------------------------------------

      final isReserved = await _isUsernameReserved(username);

      if (isReserved) {
        if (!mounted) return;

        _showFriendlyError(
          title: 'Username not available',
          message:
              'This username is reserved by NAOS and cannot be used.\n\n'
              'Please choose a different username.',
        );

        return;
      }

      // --------------------------------------------------------
      // 3. Check duplicate username
      // --------------------------------------------------------

      final alreadyUsed = await _isUsernameAlreadyUsed(username);

      if (alreadyUsed) {
        if (!mounted) return;

        _showFriendlyError(
          title: 'Username already taken',
          message:
              'That username is already being used by another NAOS user.\n\n'
              'Please choose a different username.',
        );

        return;
      }

      // --------------------------------------------------------
      // 4. Create Supabase account
      // --------------------------------------------------------

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': fullName,
          'full_name': fullName,
          'username': username,
        },
      );

      if (!mounted) return;

      if (response.user == null) {
        _showFriendlyError(
          title: 'We could not create your account',
          message:
              'Something went wrong while creating your NAOS account.\n\n'
              'Please try again.',
        );

        return;
      }

      // --------------------------------------------------------
      // 5. Account created
      // --------------------------------------------------------

      _showEmailVerificationDialog(email);
    } on AuthException catch (e) {
      if (!mounted) return;

      debugPrint('AUTH REGISTER ERROR: ${e.message}');

      final errorMessage = e.message.toLowerCase();

      if (errorMessage.contains('already registered') ||
          errorMessage.contains('already exists')) {
        _showFriendlyError(
          title: 'Email already registered',
          message:
              'An account already exists with this email address.\n\n'
              'Please sign in instead, or use a different email address.',
        );
      } else if (errorMessage.contains('password')) {
        _showFriendlyError(
          title: 'Password problem',
          message:
              'Your password could not be accepted.\n\n'
              'Please make sure it meets the password requirements.',
        );
      } else if (errorMessage.contains('database error saving new user')) {
        _showFriendlyError(
          title: 'Username not available',
          message:
              'We could not use this username.\n\n'
              'It may already be taken or may contain a word that is '
              'not allowed on NAOS. Please choose another username.',
        );
      } else {
        _showFriendlyError(
          title: 'Registration unsuccessful',
          message:
              'We could not create your account right now.\n\n'
              'Please check your information and try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('REGISTER ERROR: $e');

      _showFriendlyError(
        title: 'Something went wrong',
        message:
            'We could not create your NAOS account right now.\n\n'
            'Please try again in a moment.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // FRIENDLY ERROR DIALOG
  // ------------------------------------------------------------

  void _showFriendlyError({
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11172F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x332F2A66),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF9B8FFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF9B8FFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // EMAIL VERIFICATION DIALOG
  // ------------------------------------------------------------

  void _showEmailVerificationDialog(String email) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11172F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color: Color(0xFF42D6B5),
                size: 52,
              ),
              SizedBox(height: 16),
              Text(
                'Check your email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
                ),
              ),
            ],
          ),
          content: Text(
            'Your NAOS account has been created successfully.\n\n'
            'We sent a verification link to:\n'
            '$email\n\n'
            'Please verify your email address before continuing.\n\n'
            'After verifying your email, return to NAOS and sign in again. '
            'You will then be able to choose your institution and request '
            'your role.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await SupabaseService.client.auth.resend(
                    type: OtpType.signup,
                    email: email,
                  );

                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A new verification email has been sent.',
                      ),
                      backgroundColor: Color(0xFF168C78),
                    ),
                  );
                } catch (e) {
                  debugPrint('RESEND VERIFICATION ERROR: $e');

                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'We could not resend the email. Please try again later.',
                      ),
                      backgroundColor: Color(0xFFB4232C),
                    ),
                  );
                }
              },
              child: const Text(
                'Resend email',
                style: TextStyle(
                  color: Color(0xFF9B8FFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7167FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to sign in',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // INPUT DECORATION
  // ------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white60,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.white60,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF10162D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2A335A),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2A335A),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF7167FF),
          width: 2,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NaosColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/login');
          },
        ),
        title: const Text(
          'Create account',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 32,
                  vertical: 30,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 560,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(
                      isMobile ? 22 : 34,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11162F),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF28315A),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          Center(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF9B6CFF),
                                    Color(0xFF5144E8),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          const Text(
                            'Create your NAOS account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Start your learning journey with NAOS.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Full name
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration: _inputDecoration(
                              label: 'Full name',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter your full name.';
                              }

                              if (value.trim().length < 2) {
                                return 'Please enter a valid name.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Username
                          TextFormField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.none,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration: _inputDecoration(
                              label: 'Username',
                              icon: Icons.alternate_email,
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter a username.';
                              }

                              final username = value.trim();

                              if (username.length < 3) {
                                return 'Username must have at least 3 characters.';
                              }

                              if (username.length > 30) {
                                return 'Username must have 30 characters or less.';
                              }

                              final usernameRegex = RegExp(
                                r'^[a-zA-Z0-9_]+$',
                              );

                              if (!usernameRegex.hasMatch(username)) {
                                return 'Use only letters, numbers and underscores.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration: _inputDecoration(
                              label: 'Email',
                              icon: Icons.email_outlined,
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter your email.';
                              }

                              final emailRegex = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );

                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Please enter a valid email.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration: _inputDecoration(
                              label: 'Password',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white60,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password.';
                              }

                              if (value.length < 8) {
                                return 'Password must have at least 8 characters.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Confirm password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration: _inputDecoration(
                              label: 'Confirm password',
                              icon: Icons.lock_reset_outlined,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white60,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password.';
                              }

                              if (value != _passwordController.text) {
                                return 'Passwords do not match.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // Terms
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _acceptedTerms,
                                activeColor:
                                    const Color(0xFF7167FF),
                                onChanged: (value) {
                                  setState(() {
                                    _acceptedTerms =
                                        value ?? false;
                                  });
                                },
                              ),
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    'I agree to the NAOS Terms of Service and Privacy Policy.',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Create account
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  _loading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF7167FF),
                                disabledBackgroundColor:
                                    const Color(0xFF39365F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 23,
                                      height: 23,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Create account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: Colors.white60,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushReplacementNamed(
                                    '/login',
                                  );
                                },
                                child: const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: Color(0xFF9B8FFF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
