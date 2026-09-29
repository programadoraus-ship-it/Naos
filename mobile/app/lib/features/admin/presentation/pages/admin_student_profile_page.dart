import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStudentProfilePage extends StatefulWidget {
  final Map<String, dynamic> student;

  const AdminStudentProfilePage({
    super.key,
    required this.student,
  });

  @override
  State<AdminStudentProfilePage> createState() =>
      _AdminStudentProfilePageState();
}

class _AdminStudentProfilePageState
    extends State<AdminStudentProfilePage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late Map<String, dynamic> _student;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    _student = Map<String, dynamic>.from(widget.student);
  }

  String _value(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Not assigned';
    }

    return value.toString();
  }

  // ==========================================================================
  // EDIT ACCOUNT
  // ==========================================================================

  Future<void> _editAccount() async {
    final nameController = TextEditingController(
      text: _student['display_name']?.toString() ?? '',
    );

    final usernameController = TextEditingController(
      text: _student['username']?.toString() ?? '',
    );

    final levelController = TextEditingController(
      text: (_student['naos_level'] ?? 1).toString(),
    );

    final xpController = TextEditingController(
      text: (_student['xp'] ?? 0).toString(),
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11172F),
          title: const Text(
            'Edit Account',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _EditField(
                      controller: nameController,
                      label: 'Full name',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Name is required';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _EditField(
                      controller: usernameController,
                      label: 'Username',
                      icon: Icons.alternate_email_rounded,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Username is required';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _EditField(
                      controller: levelController,
                      label: 'NAOS Level',
                      icon: Icons.trending_up_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed =
                            int.tryParse(value ?? '');

                        if (parsed == null || parsed < 1) {
                          return 'Enter a valid level';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _EditField(
                      controller: xpController,
                      label: 'XP',
                      icon: Icons.bolt_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed =
                            int.tryParse(value ?? '');

                        if (parsed == null || parsed < 0) {
                          return 'Enter valid XP';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF9B8CFF),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6658E8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      nameController.dispose();
      usernameController.dispose();
      levelController.dispose();
      xpController.dispose();
      return;
    }

    await _saveAccountChanges(
      name: nameController.text.trim(),
      username: usernameController.text.trim(),
      naosLevel: int.parse(levelController.text.trim()),
      xp: int.parse(xpController.text.trim()),
    );

    nameController.dispose();
    usernameController.dispose();
    levelController.dispose();
    xpController.dispose();
  }

  Future<void> _saveAccountChanges({
    required String name,
    required String username,
    required int naosLevel,
    required int xp,
  }) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final studentId = _student['id']?.toString();

      if (studentId == null || studentId.isEmpty) {
        throw Exception('Student ID is missing.');
      }

      await _supabase
          .from('profiles')
          .update({
        'display_name': name,
        'username': username,
        'naos_level': naosLevel,
        'xp': xp,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('id', studentId);

      if (!mounted) return;

      setState(() {
        _student['display_name'] = name;
        _student['username'] = username;
        _student['naos_level'] = naosLevel;
        _student['xp'] = xp;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account updated successfully.'),
          backgroundColor: Color(0xFF167B78),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update account: $e',
          ),
          backgroundColor: const Color(0xFF7C304A),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // ==========================================================================
  // BLOCK / UNBLOCK ACCOUNT
  // ==========================================================================

  Future<void> _toggleAccountStatus() async {
    final status =
        (_student['account_status'] ?? '')
            .toString()
            .toLowerCase();

    if (status == 'blocked') {
      await _unblockAccount();
    } else {
      await _confirmBlockAccount();
    }
  }

  Future<void> _confirmBlockAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11172F),
          title: const Text(
            'Block Account?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'This student will lose access to NAOS until the account is unblocked.',
            style: TextStyle(
              color: Color(0xFFB1B8CE),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF9B8CFF),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C304A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Block Account'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _blockAccount();
    }
  }

  Future<void> _blockAccount() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final studentId = _student['id']?.toString();
      final adminId = _supabase.auth.currentUser?.id;

      if (studentId == null || studentId.isEmpty) {
        throw Exception('Student ID is missing.');
      }

      if (adminId == null || adminId.isEmpty) {
        throw Exception('Current administrator session is missing.');
      }

      await _supabase
          .from('profiles')
          .update({
        'account_status': 'blocked',
        'blocked_at':
            DateTime.now().toUtc().toIso8601String(),
        'blocked_by': adminId,
        'updated_at':
            DateTime.now().toUtc().toIso8601String(),
      })
          .eq('id', studentId);

      if (!mounted) return;

      setState(() {
        _student['account_status'] = 'blocked';
        _student['blocked_at'] =
            DateTime.now().toUtc().toIso8601String();
        _student['blocked_by'] = adminId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account blocked successfully.'),
          backgroundColor: Color(0xFF7C304A),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not block account: $e',
          ),
          backgroundColor: const Color(0xFF7C304A),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _unblockAccount() async {
    if (_isUpdating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11172F),
          title: const Text(
            'Unblock Account?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'This will restore the student\'s access to NAOS.',
            style: TextStyle(
              color: Color(0xFFB1B8CE),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF9B8CFF),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF167B78),
                foregroundColor: Colors.white,
              ),
              child: const Text('Unblock Account'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final studentId = _student['id']?.toString();

      if (studentId == null || studentId.isEmpty) {
        throw Exception('Student ID is missing.');
      }

      await _supabase
          .from('profiles')
          .update({
        'account_status': 'active',
        'blocked_at': null,
        'blocked_by': null,
        'updated_at':
            DateTime.now().toUtc().toIso8601String(),
      })
          .eq('id', studentId);

      if (!mounted) return;

      setState(() {
        _student['account_status'] = 'active';
        _student['blocked_at'] = null;
        _student['blocked_by'] = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account unblocked successfully.'),
          backgroundColor: Color(0xFF167B78),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not unblock account: $e',
          ),
          backgroundColor: const Color(0xFF7C304A),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final name = _value(_student['display_name']);
    final username = _value(_student['username']);
    final email = _value(_student['email']);
    final institution = _value(
      _student['institution_name'],
    );
    final status = _value(
      _student['account_status'],
    );
    final approvalStatus = _value(
      _student['approval_status'],
    );

    final naosLevel = _student['naos_level'] ?? 0;
    final xp = _student['xp'] ?? 0;
    final rank = _value(_student['rank_name']);
    final avatarId = _value(_student['avatar_id']);

    final englishLevel = _value(
      _student['english_level_name'],
    );
    final course = _value(
      _student['course_name'],
    );
    final className = _value(
      _student['class_name'],
    );
    final teacher = _value(
      _student['teacher_name'],
    );

    final isNaosAcademy =
        institution.toLowerCase() == 'naos academy';

    return Scaffold(
      backgroundColor: const Color(0xFF060918),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080D23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Student Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ----------------------------------------------------------
                  // PROFILE HEADER
                  // ----------------------------------------------------------

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11172F),
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF29345F),
                      ),
                    ),
                    child: Row(
                      children: [
                        _ProfileAvatar(
                          name: name,
                          avatarId: avatarId,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '@$username',
                                style: const TextStyle(
                                  color:
                                      Color(0xFF8992B2),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Badge(
                                    text: 'STUDENT',
                                    color:
                                        const Color(
                                      0xFF7C6CFF,
                                    ),
                                  ),
                                  _StatusBadge(
                                    status: status,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ----------------------------------------------------------
                  // ACCOUNT INFORMATION
                  // ----------------------------------------------------------

                  _SectionTitle(
                    icon:
                        Icons.person_outline_rounded,
                    title: 'Account Information',
                  ),

                  const SizedBox(height: 12),

                  _InfoCard(
                    children: [
                      _InfoRow(
                        label: 'Full name',
                        value: name,
                      ),
                      _InfoRow(
                        label: 'Username',
                        value: '@$username',
                      ),
                      _InfoRow(
                        label: 'Email',
                        value: email,
                      ),
                      _InfoRow(
                        label: 'Account status',
                        value: status,
                      ),
                      _InfoRow(
                        label: 'Approval status',
                        value: approvalStatus,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ----------------------------------------------------------
                  // NAOS INFORMATION
                  // ----------------------------------------------------------

                  _SectionTitle(
                    icon:
                        Icons.auto_awesome_rounded,
                    title: 'NAOS Progress',
                  ),

                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width =
                          constraints.maxWidth;

                      int columns = 3;

                      if (width < 700) {
                        columns = 2;
                      }

                      if (width < 480) {
                        columns = 1;
                      }

                      final cardWidth =
                          (width -
                                  ((columns - 1) * 14)) /
                              columns;

                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _ProgressCard(
                              title: 'NAOS Level',
                              value: '$naosLevel',
                              icon: Icons
                                  .trending_up_rounded,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _ProgressCard(
                              title: 'XP',
                              value: '$xp',
                              icon:
                                  Icons.bolt_rounded,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _ProgressCard(
                              title: 'Rank',
                              value: rank,
                              icon: Icons
                                  .emoji_events_outlined,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ----------------------------------------------------------
                  // INSTITUTION
                  // ----------------------------------------------------------

                  _SectionTitle(
                    icon: Icons.apartment_rounded,
                    title: 'Institution',
                  ),

                  const SizedBox(height: 12),

                  _InfoCard(
                    children: [
                      _InfoRow(
                        label: 'Institution',
                        value: institution,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ----------------------------------------------------------
                  // ACADEMIC INFORMATION
                  // ----------------------------------------------------------

                  _SectionTitle(
                    icon: Icons.school_outlined,
                    title: isNaosAcademy
                        ? 'NAOS Academy'
                        : 'Academic Information',
                  ),

                  const SizedBox(height: 12),

                  if (isNaosAcademy)
                    _InfoCard(
                      children: const [
                        _InfoRow(
                          label: 'Learning mode',
                          value: 'NAOS Academy',
                        ),
                        _InfoRow(
                          label: 'Courses',
                          value: 'Not applicable',
                        ),
                        _InfoRow(
                          label: 'Classes',
                          value: 'Not applicable',
                        ),
                        _InfoRow(
                          label: 'Teacher',
                          value: 'Not applicable',
                        ),
                      ],
                    )
                  else
                    _InfoCard(
                      children: [
                        _InfoRow(
                          label: 'English level',
                          value: englishLevel,
                        ),
                        _InfoRow(
                          label: 'Course',
                          value: course,
                        ),
                        _InfoRow(
                          label: 'Class',
                          value: className,
                        ),
                        _InfoRow(
                          label: 'Teacher',
                          value: teacher,
                        ),
                      ],
                    ),

                  const SizedBox(height: 28),

                  // ----------------------------------------------------------
                  // LEARNING
                  // ----------------------------------------------------------

                  _SectionTitle(
                    icon: Icons.insights_rounded,
                    title: 'Learning & Performance',
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11172F),
                      borderRadius:
                          BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF29345F),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.analytics_outlined,
                          size: 42,
                          color: Color(0xFF5D6789),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Learning analytics will appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Lessons, games, scores and learning activity '
                          'will be connected once those systems are created.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF8992B2),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ----------------------------------------------------------
                  // ADMINISTRATIVE ACTIONS
                  // ----------------------------------------------------------

                  _SectionTitle(
                    icon: Icons
                        .admin_panel_settings_outlined,
                    title: 'Administrative Actions',
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11172F),
                      borderRadius:
                          BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF29345F),
                      ),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit Account',
                          onPressed: _isUpdating
                              ? () {}
                              : _editAccount,
                        ),
                        _ActionButton(
                          icon: status.toLowerCase() ==
                                  'blocked'
                              ? Icons
                                  .lock_open_outlined
                              : Icons.block_outlined,
                          label:
                              status.toLowerCase() ==
                                      'blocked'
                                  ? 'Unblock Account'
                                  : 'Block Account',
                          onPressed: _isUpdating
                              ? () {}
                              : _toggleAccountStatus,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_isUpdating)
              Positioned.fill(
                child: Container(
                  color:
                      Colors.black.withOpacity(0.35),
                  child: const Center(
                    child:
                        CircularProgressIndicator(
                      color: Color(0xFF7565FF),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EDIT FIELD
// ============================================================================

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF8992B2),
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF8D80FF),
        ),
        filled: true,
        fillColor: const Color(0xFF0B1024),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF29345F),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF7565FF),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFF5577),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFF5577),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE AVATAR
// ============================================================================

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String avatarId;

  const _ProfileAvatar({
    required this.name,
    required this.avatarId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFF252F70),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF7565FF),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty
            ? name.substring(0, 1).toUpperCase()
            : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF8D80FF),
          size: 20,
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// INFO CARD
// ============================================================================

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF11172F),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF29345F),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ============================================================================
// INFO ROW
// ============================================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8992B2),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PROGRESS CARD
// ============================================================================

class _ProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ProgressCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF11172F),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF29345F),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7565FF)
                  .withOpacity(0.14),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF9B8CFF),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF8992B2),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BADGE
// ============================================================================

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.45),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================================
// STATUS BADGE
// ============================================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final active =
        status.toLowerCase() == 'active';

    final blocked =
        status.toLowerCase() == 'blocked';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF0B4647)
            : const Color(0xFF4A2333),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? const Color(0xFF167B78)
              : const Color(0xFF7C304A),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: active
              ? const Color(0xFF38D8C8)
              : const Color(0xFFFF6D91),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================================
// ACTION BUTTON
// ============================================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 17,
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor:
            const Color(0xFFB7BCE0),
        side: const BorderSide(
          color: Color(0xFF354064),
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),
    );
  }
}