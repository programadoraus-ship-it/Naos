import 'package:flutter/material.dart';

import '../../../../core/services/supabase/supabase_service.dart';
import 'admin_teacher_profile_page.dart';

const Color kTeachersBackground = Color(0xFF050816);
const Color kTeachersPanel = Color(0xFF11172F);
const Color kTeachersPrimary = Color(0xFF6972FF);

class AdminTeachersPage extends StatefulWidget {
  const AdminTeachersPage({super.key});

  @override
  State<AdminTeachersPage> createState() => _AdminTeachersPageState();
}

class _AdminTeachersPageState extends State<AdminTeachersPage> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _teachers = [];

  String _search = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = SupabaseService.client;

      // ==========================================================
      // GET TEACHERS
      // ==========================================================

      final teachersResponse = await client
    .from('institution_teachers')
    .select('''
      id,
      user_id,
      institution_id,
      is_active,
      created_at,
      profiles:user_id!inner (
        username,
        display_name,
        role,
        account_status,
        approval_status
      ),
      institutions:institution_id (
        id,
        name
      )
    ''')
    .eq('profiles.role', 'teacher')
    .order('created_at', ascending: false);

      final teachers = List<Map<String, dynamic>>.from(
        teachersResponse as List,
      );

      // ==========================================================
      // GET CLASSES
      //
      // Legacy teacher_id is still supported here.
      // The new teacher/class relationship will be used
      // inside the teacher profile.
      // ==========================================================

      final classesResponse = await client
          .from('institution_classes')
          .select('''
            id,
            teacher_id,
            course_id,
            name,
            is_active,
            institution_courses:course_id (
              id,
              name
            )
          ''');

      final classes = List<Map<String, dynamic>>.from(
        classesResponse as List,
      );

      // ==========================================================
      // GET MEMBERSHIPS
      // ==========================================================

      final membershipsResponse = await client
          .from('institution_memberships')
          .select('''
            id,
            user_id,
            teacher_id,
            class_id,
            institution_id,
            status
          ''');

      final memberships = List<Map<String, dynamic>>.from(
        membershipsResponse as List,
      );

      // ==========================================================
      // BUILD TEACHER DATA
      // ==========================================================

      final result = <Map<String, dynamic>>[];

      for (final teacher in teachers) {
        final teacherId = teacher['id'];

        final profile = teacher['profiles'];
        final institution = teacher['institutions'];

        final teacherClasses = classes.where((item) {
          return item['teacher_id'] == teacherId;
        }).toList();

        final teacherMemberships = memberships.where((item) {
          return item['teacher_id'] == teacherId &&
              item['status'] == 'active';
        }).toList();

        final courseIds = <String>{};

        for (final classItem in teacherClasses) {
          final courseId = classItem['course_id'];

          if (courseId != null) {
            courseIds.add(courseId.toString());
          }
        }

        result.add({
          'id': teacherId,
          'user_id': teacher['user_id'],
          'is_active': teacher['is_active'],
          'profile': profile,
          'institution': institution,
          'classes': teacherClasses,
          'course_count': courseIds.length,
          'class_count': teacherClasses.length,
          'student_count': teacherMemberships.length,
        });
      }

      if (!mounted) return;

      setState(() {
        _teachers = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('NAOS TEACHERS ERROR: $e');

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // OPEN TEACHER PROFILE
  // ============================================================

  void _openTeacherProfile(Map<String, dynamic> teacher) {
    final teacherId = teacher['id']?.toString();

    if (teacherId == null || teacherId.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminTeacherProfilePage(
          teacherId: teacherId,
        ),
      ),
    );
  }

  // ============================================================
  // FILTERING
  // ============================================================

  List<Map<String, dynamic>> get _filteredTeachers {
    return _teachers.where((teacher) {
      final profile = teacher['profile'];
      final institution = teacher['institution'];

      final displayName = profile is Map
          ? (profile['display_name'] ?? '').toString().toLowerCase()
          : '';

      final username = profile is Map
          ? (profile['username'] ?? '').toString().toLowerCase()
          : '';

      final institutionName = institution is Map
          ? (institution['name'] ?? '').toString().toLowerCase()
          : '';

      final search = _search.toLowerCase().trim();

      final matchesSearch = search.isEmpty ||
          displayName.contains(search) ||
          username.contains(search) ||
          institutionName.contains(search);

      final isActive = teacher['is_active'] == true;

      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'active' && isActive) ||
          (_statusFilter == 'inactive' && !isActive);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _activeTeachers {
    return _teachers.where((teacher) {
      return teacher['is_active'] == true;
    }).length;
  }

  int get _inactiveTeachers {
    return _teachers.where((teacher) {
      return teacher['is_active'] != true;
    }).length;
  }

  int get _totalCourses {
    return _teachers.fold<int>(
      0,
      (sum, teacher) =>
          sum + (teacher['course_count'] as int? ?? 0),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kTeachersBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: RefreshIndicator(
                color: kTeachersPrimary,
                backgroundColor: kTeachersPanel,
                onRefresh: _loadTeachers,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 24),

                      if (_error != null) ...[
                        _buildError(),
                        const SizedBox(height: 20),
                      ],

                      _buildStatistics(),

                      const SizedBox(height: 24),

                      _buildFilters(),

                      const SizedBox(height: 20),

                      _buildTeachersList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF080D22),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            'Teachers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const Spacer(),

          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadTeachers,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teacher Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Manage teachers across all NAOS institutions.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 600
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: columns == 1 ? 3.2 : 2.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              title: 'Total Teachers',
              value: _isLoading ? '...' : '${_teachers.length}',
              icon: Icons.people_alt_rounded,
              iconColor: const Color(0xFF6972FF),
            ),
            _StatCard(
              title: 'Active',
              value: _isLoading ? '...' : '$_activeTeachers',
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF36D9C4),
            ),
            _StatCard(
              title: 'Inactive',
              value: _isLoading ? '...' : '$_inactiveTeachers',
              icon: Icons.block_rounded,
              iconColor: const Color(0xFFFF5C82),
            ),
            _StatCard(
              title: 'Assigned Courses',
              value: _isLoading ? '...' : '$_totalCourses',
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF9B5CFF),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Column(
      children: [
        TextField(
          onChanged: (value) {
            setState(() {
              _search = value;
            });
          },
          style: const TextStyle(
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Search by name, username or institution...',
            hintStyle: const TextStyle(
              color: Colors.white38,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Colors.white54,
            ),
            filled: true,
            fillColor: kTeachersPanel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF283158),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF283158),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: kTeachersPrimary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            _FilterButton(
              label: 'All',
              selected: _statusFilter == 'all',
              onPressed: () {
                setState(() {
                  _statusFilter = 'all';
                });
              },
            ),
            const SizedBox(width: 10),
            _FilterButton(
              label: 'Active',
              selected: _statusFilter == 'active',
              onPressed: () {
                setState(() {
                  _statusFilter = 'active';
                });
              },
            ),
            const SizedBox(width: 10),
            _FilterButton(
              label: 'Inactive',
              selected: _statusFilter == 'inactive',
              onPressed: () {
                setState(() {
                  _statusFilter = 'inactive';
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // TEACHERS LIST
  // ============================================================

  Widget _buildTeachersList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 50),
        child: Center(
          child: CircularProgressIndicator(
            color: kTeachersPrimary,
          ),
        ),
      );
    }

    final teachers = _filteredTeachers;

    if (teachers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 70),
        child: const Column(
          children: [
            Icon(
              Icons.school_outlined,
              color: Colors.white24,
              size: 55,
            ),
            SizedBox(height: 14),
            Text(
              'No teachers found.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: teachers.map((teacher) {
        return _TeacherCard(
          teacher: teacher,
          onTap: () {
            _openTeacherProfile(teacher);
          },
        );
      }).toList(),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF351A29),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8C3555),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFF6B8A),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadTeachers,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// TEACHER CARD
// ================================================================

class _TeacherCard extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onTap;

  const _TeacherCard({
    required this.teacher,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profile = teacher['profile'];
    final institution = teacher['institution'];

    final name = profile is Map
        ? (profile['display_name'] ??
                profile['username'] ??
                'Unknown teacher')
            .toString()
        : 'Unknown teacher';

    final username = profile is Map
        ? (profile['username'] ?? '').toString()
        : '';

    final institutionName = institution is Map
        ? (institution['name'] ?? 'No institution').toString()
        : 'No institution';

    final isActive = teacher['is_active'] == true;

    final courseCount = teacher['course_count'] ?? 0;
    final classCount = teacher['class_count'] ?? 0;
    final studentCount = teacher['student_count'] ?? 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kTeachersPanel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF283158),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFF292F68),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty
                        ? name[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      institutionName,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (MediaQuery.of(context).size.width >= 800)
                Row(
                  children: [
                    _SmallStat(
                      label: 'Courses',
                      value: '$courseCount',
                    ),
                    const SizedBox(width: 25),
                    _SmallStat(
                      label: 'Classes',
                      value: '$classCount',
                    ),
                    const SizedBox(width: 25),
                    _SmallStat(
                      label: 'Students',
                      value: '$studentCount',
                    ),
                  ],
                ),

              const SizedBox(width: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF15382F)
                      : const Color(0xFF351A29),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF5FE3CA)
                        : const Color(0xFFFF6B8A),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SMALL STAT
// ================================================================

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;

  const _SmallStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// STAT CARD
// ================================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kTeachersPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF283158),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// FILTER BUTTON
// ================================================================

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected ? kTeachersPrimary : Colors.transparent,
        foregroundColor: Colors.white,
        side: BorderSide(
          color: selected
              ? kTeachersPrimary
              : const Color(0xFF303B6D),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
      child: Text(label),
    );
  }
}