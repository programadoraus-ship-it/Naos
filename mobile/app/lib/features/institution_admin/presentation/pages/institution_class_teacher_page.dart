import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstitutionClassTeacherPage extends StatefulWidget {
  final String classId;

  const InstitutionClassTeacherPage({super.key, required this.classId});

  @override
  State<InstitutionClassTeacherPage> createState() =>
      _InstitutionClassTeacherPageState();
}

class _InstitutionClassTeacherPageState
    extends State<InstitutionClassTeacherPage> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;

  String? _error;

  Map<String, dynamic>? _classData;
  Map<String, dynamic>? _currentTeacher;

  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // ----------------------------------------------------------
      // 1. Load class
      // ----------------------------------------------------------

      final classData = await _client
          .from('institution_classes')
          .select(
            'id, institution_id, course_id, teacher_id, name, description, is_active',
          )
          .eq('id', widget.classId)
          .maybeSingle();

      if (classData == null) {
        throw Exception('Class not found.');
      }

      final classMap = Map<String, dynamic>.from(classData);

      final String institutionId = classMap['institution_id'].toString();

      final String? currentTeacherId = classMap['teacher_id']?.toString();

      // ----------------------------------------------------------
      // 2. Load institution teachers
      // ----------------------------------------------------------

      final teacherRows = await _client
          .from('institution_teachers')
          .select('id, user_id, institution_id, is_active')
          .eq('institution_id', institutionId)
          .eq('is_active', true)
          .order('created_at');

      final List<Map<String, dynamic>> teachers = [];

      // ----------------------------------------------------------
      // 3. Load profiles
      // ----------------------------------------------------------

      for (final row in teacherRows) {
        final teacher = Map<String, dynamic>.from(row);

        final userId = teacher['user_id']?.toString();

        if (userId == null || userId.isEmpty) {
          continue;
        }

        final profile = await _client
            .from('profiles')
            .select('id, username, display_name, role, account_status')
            .eq('id', userId)
            .maybeSingle();

        if (profile == null) {
          // No profile found.
          // Do not display this as a teacher.
          continue;
        }

        final profileMap = Map<String, dynamic>.from(profile);

        // --------------------------------------------------------
        // IMPORTANT:
        // Only real teachers are allowed here.
        // Institution admins, designers, etc. are ignored.
        // --------------------------------------------------------

        final role = profileMap['role']?.toString();

        if (role != 'teacher') {
          continue;
        }

        final accountStatus = profileMap['account_status']?.toString();

        if (accountStatus != null && accountStatus != 'active') {
          continue;
        }

        teacher['profile'] = profileMap;

        teachers.add(teacher);
      }

      // ----------------------------------------------------------
      // 4. Find current teacher
      // ----------------------------------------------------------

      Map<String, dynamic>? currentTeacher;

      if (currentTeacherId != null && currentTeacherId.isNotEmpty) {
        for (final teacher in teachers) {
          if (teacher['id']?.toString() == currentTeacherId) {
            currentTeacher = teacher;
            break;
          }
        }

        // --------------------------------------------------------
        // If current teacher isn't in the active teacher list,
        // try loading it directly.
        // --------------------------------------------------------

        if (currentTeacher == null) {
          final teacher = await _client
              .from('institution_teachers')
              .select('id, user_id, institution_id, is_active')
              .eq('id', currentTeacherId)
              .maybeSingle();

          if (teacher != null) {
            final teacherMap = Map<String, dynamic>.from(teacher);

            final userId = teacherMap['user_id']?.toString();

            if (userId != null && userId.isNotEmpty) {
              final profile = await _client
                  .from('profiles')
                  .select('id, username, display_name, role, account_status')
                  .eq('id', userId)
                  .maybeSingle();

              if (profile != null) {
                final profileMap = Map<String, dynamic>.from(profile);

                if (profileMap['role'] == 'teacher') {
                  teacherMap['profile'] = profileMap;
                  currentTeacher = teacherMap;
                }
              }
            }
          }
        }
      }

      // ----------------------------------------------------------
      // 5. Update state
      // ----------------------------------------------------------

      if (!mounted) return;

      setState(() {
        _classData = classMap;
        _teachers = teachers;
        _currentTeacher = currentTeacher;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // ASSIGN TEACHER
  // ============================================================

  Future<void> _changeTeacher(Map<String, dynamic> teacher) async {
    final teacherId = teacher['id']?.toString();

    if (teacherId == null || teacherId.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _client
          .from('institution_classes')
          .update({
            'teacher_id': teacherId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.classId);

      if (!mounted) return;

      setState(() {
        _currentTeacher = teacher;
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher assigned successfully.'),
          backgroundColor: Color(0xFF123B3A),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to assign teacher: $e'),
          backgroundColor: Color(0xFF3B2030),
        ),
      );
    }
  }

  // ============================================================
  // REMOVE TEACHER
  // ============================================================

  Future<void> _removeTeacher() async {
    setState(() {
      _saving = true;
    });

    try {
      await _client
          .from('institution_classes')
          .update({
            'teacher_id': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.classId);

      if (!mounted) return;

      setState(() {
        _currentTeacher = null;
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher removed from this class.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to remove teacher: $e')));
    }
  }

  // ============================================================
  // TEACHER NAME
  // ============================================================

  String _teacherName(Map<String, dynamic> teacher) {
    final profile = teacher['profile'];

    if (profile is Map) {
      final displayName = profile['display_name']?.toString();

      if (displayName != null && displayName.trim().isNotEmpty) {
        return displayName.trim();
      }

      final username = profile['username']?.toString();

      if (username != null && username.trim().isNotEmpty) {
        return username.trim();
      }
    }

    return 'Unknown teacher';
  }

  // ============================================================
  // TEACHER USERNAME
  // ============================================================

  String _teacherUsername(Map<String, dynamic> teacher) {
    final profile = teacher['profile'];

    if (profile is Map) {
      final username = profile['username']?.toString();

      if (username != null && username.trim().isNotEmpty) {
        return '@${username.trim()}';
      }
    }

    return '';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050817),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080D24),
        foregroundColor: Colors.white,
        title: const Text(
          'Teacher',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C83FF)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: Color(0xFFFF5C7A),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load teachers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final className = _classData?['name']?.toString() ?? 'Class';

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF7C83FF),
      backgroundColor: const Color(0xFF111832),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teacher Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Manage the teacher assigned to $className.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 24),

            _buildCurrentTeacherCard(),

            const SizedBox(height: 24),

            _buildTeachersCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT TEACHER
  // ============================================================

  Widget _buildCurrentTeacherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111832),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF28345F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_rounded, color: Color(0xFF8B91FF), size: 22),
              SizedBox(width: 10),
              Text(
                'Current Teacher',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (_currentTeacher == null)
            _buildNoTeacher()
          else
            _buildTeacherTile(_currentTeacher!, showRemove: true),
        ],
      ),
    );
  }

  // ============================================================
  // NO TEACHER
  // ============================================================

  Widget _buildNoTeacher() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1026),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF28345F)),
      ),
      child: const Row(
        children: [
          Icon(Icons.person_off_rounded, color: Colors.white54, size: 30),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'No teacher is currently assigned to this class.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AVAILABLE TEACHERS
  // ============================================================

  Widget _buildTeachersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111832),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF28345F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_rounded, color: Color(0xFF8B91FF), size: 22),
              SizedBox(width: 10),
              Text(
                'Available Teachers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Select a teacher from your institution.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),

          const SizedBox(height: 18),

          if (_teachers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: Colors.white38,
                      size: 45,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No active teachers found.',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._teachers.map((teacher) => _buildTeacherOption(teacher)),
        ],
      ),
    );
  }

  // ============================================================
  // TEACHER OPTION
  // ============================================================

  Widget _buildTeacherOption(Map<String, dynamic> teacher) {
    final bool selected =
        _currentTeacher?['id']?.toString() == teacher['id']?.toString();

    final name = _teacherName(teacher);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF171E45) : const Color(0xFF0B1026),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF7C83FF) : const Color(0xFF28345F),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF252D70),
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'T',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          _teacherUsername(teacher),
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF39D6C5))
            : const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        onTap: selected || _saving
            ? null
            : () => _confirmTeacherChange(teacher),
      ),
    );
  }

  // ============================================================
  // CURRENT TEACHER TILE
  // ============================================================

  Widget _buildTeacherTile(
    Map<String, dynamic> teacher, {
    bool showRemove = false,
  }) {
    final name = _teacherName(teacher);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1026),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF28345F)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF252D70),
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'T',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _teacherUsername(teacher),
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),

          if (showRemove)
            IconButton(
              tooltip: 'Remove teacher',
              onPressed: _saving ? null : _removeTeacher,
              icon: const Icon(
                Icons.person_remove_rounded,
                color: Color(0xFFFF6B8A),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIRM CHANGE
  // ============================================================

  Future<void> _confirmTeacherChange(Map<String, dynamic> teacher) async {
    final name = _teacherName(teacher);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111832),
          title: const Text(
            'Assign Teacher',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Assign $name to this class?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _changeTeacher(teacher);
    }
  }
}
