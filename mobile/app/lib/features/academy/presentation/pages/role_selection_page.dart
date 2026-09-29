import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/navigation/app_router.dart';

class RoleSelectionPage extends StatefulWidget {
  final String institutionId;
  final String name;
  final String shortName;
  final String location;
  final String? logoUrl;

  const RoleSelectionPage({
    super.key,
    required this.institutionId,
    required this.name,
    required this.shortName,
    required this.location,
    this.logoUrl,
  });

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String selectedRole = 'student';
  bool isSubmitting = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: SizedBox(
              width: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Choose Your Role',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Select the role you would like to request at this institution.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 35),

                  _RoleCard(
                    icon: Icons.school_rounded,
                    title: 'Student',
                    subtitle:
                        'Learn, complete courses and track your progress.',
                    value: 'student',
                    selected: selectedRole == 'student',
                    onTap: () {
                      setState(() {
                        selectedRole = 'student';
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  _RoleCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Teacher',
                    subtitle:
                        'Teach students and manage learning content.',
                    value: 'teacher',
                    selected: selectedRole == 'teacher',
                    onTap: () {
                      setState(() {
                        selectedRole = 'teacher';
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  _RoleCard(
                    icon: Icons.palette_rounded,
                    title: 'Designer',
                    subtitle:
                        'Create and manage NAOS visual content.',
                    value: 'designer',
                    selected: selectedRole == 'designer',
                    onTap: () {
                      setState(() {
                        selectedRole = 'designer';
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11162B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF30385C),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF7C83FF),
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your selected role is only a request. '
                            'Your institution administrator must approve '
                            'your access and assign your final role.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : _submitAccessRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C83FF),
                        disabledBackgroundColor:
                            const Color(0xFF3D4278),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Send Access Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitAccessRequest() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showError(
        'Your session could not be found. Please sign in again.',
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Check whether this user already has a pending request.
      final existingRequest = await _supabase
          .from('institution_memberships')
          .select('id, status')
          .eq('user_id', user.id)
          .eq('institution_id', widget.institutionId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingRequest != null) {
        if (!mounted) return;

        setState(() {
          isSubmitting = false;
        });

        _showInfo(
          'You already have a pending request for this institution.',
        );

        return;
      }

      // Create the access request.
      await _supabase.from('institution_memberships').insert({
        'user_id': user.id,
        'institution_id': widget.institutionId,
        'requested_role': selectedRole,
        'status': 'pending',
        'requested_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      _showRequestSentDialog();
    } on PostgrestException catch (error) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      _showError(
        error.message.isNotEmpty
            ? error.message
            : 'Could not submit your access request.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      _showError(
        'Something went wrong while submitting your request.',
      );
    }
  }

  void _showRequestSentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11162B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF42E8C2),
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Request submitted',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Your request to join ${widget.name} as a '
            '${_roleLabel(selectedRole)} has been submitted successfully. '
            'An institution administrator must review your request.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog first.
                Navigator.pop(dialogContext);

                // Then send the user to the waiting room.
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.accessPending,
                  (route) => false,
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF8B7CFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11162B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Request failed',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF8B7CFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInfo(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11162B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Access request',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF8B7CFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'teacher':
        return 'Teacher';
      case 'designer':
        return 'Designer';
      default:
        return 'Student';
    }
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF20275A)
              : const Color(0xFF11162B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF7C83FF)
                : const Color(0xFF30385C),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF7C83FF)
                    : const Color(0xFF1B2140),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: selected ? value : null,
              onChanged: (_) {
                onTap();
              },
              activeColor: const Color(0xFF8B7CFF),
            ),
          ],
        ),
      ),
    );
  }
}