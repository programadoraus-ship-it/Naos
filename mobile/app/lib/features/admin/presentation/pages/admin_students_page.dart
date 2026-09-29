import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_student_profile_page.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  final TextEditingController _searchController = TextEditingController();

  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedInstitution = 'All institutions';
  String _selectedStatus = 'All';

  List<_Student> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // LOAD REAL STUDENTS FROM SUPABASE
  // ==========================================================================

  Future<void> _loadStudents() async {
  if (!mounted) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final response = await _supabase
        .from('profiles')
        .select('''
          id,
          username,
          display_name,
          naos_level,
          xp,
          rank_id,
          avatar_id,
          created_at,
          updated_at,
          role,
          approval_status,
          account_status,
          approved_at,
          approved_by,
          blocked_at,
          blocked_by,
          rejection_reason,
          requested_role,
          ranks (
            id,
            name,
            sort_order
          ),
          institution_memberships (
            id,
            institution_id,
            status,
            english_level_id,
            course_id,
            class_id,
            teacher_id,
            requested_at,
            approved_at,
            left_at,
            requested_role,
            approved_by,
            reviewed_at,
            rejection_reason,
            institutions (
              id,
              name
            )
          )
        ''')
        .eq('role', 'student');

    final data = response as List;

    final List<_Student> loadedStudents = [];

    for (final rawProfile in data) {
      final profile =
          Map<String, dynamic>.from(rawProfile);

      final membershipsRaw =
          (profile['institution_memberships'] as List?) ?? [];

      final memberships = membershipsRaw
          .map(
            (item) => Map<String, dynamic>.from(
              item as Map,
            ),
          )
          .toList();

      // Prefer active membership.
      Map<String, dynamic>? membership;

      for (final item in memberships) {
        if ((item['status'] ?? '')
                .toString()
                .toLowerCase() ==
            'active') {
          membership = item;
          break;
        }
      }

      // If there is no active membership,
      // keep the first membership available.
      if (membership == null &&
          memberships.isNotEmpty) {
        membership = memberships.first;
      }

      final institution =
          membership?['institutions']
              as Map<String, dynamic>?;

      final rank =
          profile['ranks']
              as Map<String, dynamic>?;

      loadedStudents.add(
        _Student(
          id: profile['id']?.toString() ?? '',

          name:
              profile['display_name']
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? profile['display_name'].toString()
                  : profile['username']
                          ?.toString() ??
                      'Unnamed Student',

          username:
              profile['username']?.toString() ?? '',

          email: null,

          institutionId:
              institution?['id']?.toString(),

          institution:
              institution?['name']?.toString(),

          status:
              profile['account_status']
                      ?.toString() ??
                  'Unknown',

          approvalStatus:
              profile['approval_status']
                      ?.toString() ??
                  'Unknown',

          joined:
              profile['created_at']?.toString(),

          naosLevel:
              profile['naos_level'] as int? ?? 0,

          xp:
              profile['xp'] as int? ?? 0,

          rankName:
              rank?['name']?.toString(),

          avatarId:
              profile['avatar_id']?.toString(),

          membershipStatus:
              membership?['status']?.toString(),

          requestedRole:
              membership?['requested_role']
                  ?.toString(),

          requestedAt:
              membership?['requested_at']
                  ?.toString(),

          approvedAt:
              membership?['approved_at']
                  ?.toString(),

          englishLevel: null,
          course: null,
          className: null,
          teacherId:
              membership?['teacher_id']
                  ?.toString(),
        ),
      );
    }

    loadedStudents.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    if (!mounted) return;

    setState(() {
      _students = loadedStudents;
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = e.toString();
    });
  }
}

  // ==========================================================================
  // FILTERS
  // ==========================================================================

  List<_Student> get _filteredStudents {
    final search = _searchController.text.trim().toLowerCase();

    return _students.where((student) {
      final matchesSearch =
          search.isEmpty ||
          student.name.toLowerCase().contains(search) ||
          student.username.toLowerCase().contains(search);

      final matchesInstitution =
          _selectedInstitution == 'All institutions' ||
          student.institution == _selectedInstitution;

      final matchesStatus =
          _selectedStatus == 'All' ||
          student.status.toLowerCase() ==
              _selectedStatus.toLowerCase();

      return matchesSearch &&
          matchesInstitution &&
          matchesStatus;
    }).toList();
  }

  List<String> get _institutionNames {
    final names = _students
        .map((student) => student.institution)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();

    names.sort();

    return names;
  }

  int get _activeCount => _students
      .where(
        (student) =>
            student.status.toLowerCase() == 'active',
      )
      .length;

  int get _blockedCount => _students
      .where(
        (student) =>
            student.status.toLowerCase() == 'blocked',
      )
      .length;

  int get _academyCount => _students
      .where(
        (student) =>
            student.institution?.toLowerCase() == 'naos academy',
      )
      .length;

  // ==========================================================================
  // OPEN PROFILE
  // ==========================================================================

  void _openStudentProfile(_Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminStudentProfilePage(
          student: student.toProfileMap(),
        ),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final students = _filteredStudents;

    return Scaffold(
      backgroundColor: const Color(0xFF060918),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080D23),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 22,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Students',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadStudents,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: _buildBody(students),
      ),
    );
  }

  Widget _buildBody(List<_Student> students) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7565FF),
        ),
      );
    }

    if (_errorMessage != null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _loadStudents,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'View and manage students across NAOS institutions and NAOS Academy.',
            style: TextStyle(
              color: Color(0xFF8992B2),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 26),

          // ------------------------------------------------------------------
          // STATISTICS
          // ------------------------------------------------------------------

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              int columns = 4;

              if (width < 900) columns = 2;
              if (width < 560) columns = 1;

              final cardWidth =
                  (width - ((columns - 1) * 14)) / columns;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _StatCard(
                      title: 'Total Students',
                      value: '${_students.length}',
                      icon: Icons.school_rounded,
                      iconColor: const Color(0xFF7C6CFF),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _StatCard(
                      title: 'Active',
                      value: '$_activeCount',
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF22D3C5),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _StatCard(
                      title: 'NAOS Academy',
                      value: '$_academyCount',
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF9B6CFF),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _StatCard(
                      title: 'Blocked',
                      value: '$_blockedCount',
                      icon: Icons.block_rounded,
                      iconColor: const Color(0xFFFF5577),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------------------------
          // INSTITUTIONS
          // ------------------------------------------------------------------

          const Text(
            'Students by institution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          if (_institutionNames.isEmpty &&
              _academyCount == 0)
            const Text(
              'No institution memberships found.',
              style: TextStyle(
                color: Color(0xFF8992B2),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                int columns = 3;

                if (width < 900) columns = 2;
                if (width < 560) columns = 1;

                final cardWidth =
                    (width - ((columns - 1) * 14)) / columns;

                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    ..._institutionNames.map(
                      (institution) {
                        final count = _students
                            .where(
                              (student) =>
                                  student.institution ==
                                  institution,
                            )
                            .length;

                        return SizedBox(
                          width: cardWidth,
                          child: _InstitutionCard(
                            institution: institution,
                            students: count,
                            icon: Icons.apartment_rounded,
                          ),
                        );
                      },
                    ),

                    if (_academyCount > 0)
                      SizedBox(
                        width: cardWidth,
                        child: _InstitutionCard(
                          institution: 'NAOS Academy',
                          students: _academyCount,
                          icon: Icons.auto_awesome_rounded,
                          academy: true,
                        ),
                      ),
                  ],
                );
              },
            ),

          const SizedBox(height: 32),

          // ------------------------------------------------------------------
          // SEARCH
          // ------------------------------------------------------------------

          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Search by name or username...',
              hintStyle: const TextStyle(
                color: Color(0xFF69728F),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF8992B2),
              ),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF8992B2),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
              filled: true,
              fillColor: const Color(0xFF11172F),
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 17,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF29345F),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF29345F),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF7565FF),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ------------------------------------------------------------------
          // INSTITUTION FILTER
          // ------------------------------------------------------------------

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FilterButton(
                label: 'All institutions',
                selected:
                    _selectedInstitution ==
                        'All institutions',
                onTap: () {
                  setState(() {
                    _selectedInstitution =
                        'All institutions';
                  });
                },
              ),
              ..._institutionNames.map(
                (institution) => _FilterButton(
                  label: institution,
                  selected:
                      _selectedInstitution ==
                          institution,
                  onTap: () {
                    setState(() {
                      _selectedInstitution =
                          institution;
                    });
                  },
                ),
              ),
              if (_academyCount > 0)
                _FilterButton(
                  label: 'NAOS Academy',
                  selected:
                      _selectedInstitution ==
                          'NAOS Academy',
                  onTap: () {
                    setState(() {
                      _selectedInstitution =
                          'NAOS Academy';
                    });
                  },
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------------------
          // STATUS FILTER
          // ------------------------------------------------------------------

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FilterButton(
                label: 'All',
                selected: _selectedStatus == 'All',
                onTap: () {
                  setState(() {
                    _selectedStatus = 'All';
                  });
                },
              ),
              _FilterButton(
                label: 'Active',
                selected: _selectedStatus == 'Active',
                onTap: () {
                  setState(() {
                    _selectedStatus = 'Active';
                  });
                },
              ),
              _FilterButton(
                label: 'Blocked',
                selected:
                    _selectedStatus == 'Blocked',
                onTap: () {
                  setState(() {
                    _selectedStatus = 'Blocked';
                  });
                },
              ),
              _FilterButton(
                label: 'Pending',
                selected:
                    _selectedStatus == 'Pending',
                onTap: () {
                  setState(() {
                    _selectedStatus = 'Pending';
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            '${students.length} students found',
            style: const TextStyle(
              color: Color(0xFF8992B2),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------------------
          // STUDENT LIST
          // ------------------------------------------------------------------

          if (students.isEmpty)
            _EmptyState(
              searchActive:
                  _searchController.text.isNotEmpty ||
                  _selectedInstitution !=
                      'All institutions' ||
                  _selectedStatus != 'All',
            )
          else
            ...students.map(
              (student) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 10),
                child: _StudentCard(
                  student: student,
                  onTap: () =>
                      _openStudentProfile(student),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// STUDENT MODEL
// ============================================================================

class _Student {
  final String id;
  final String name;
  final String username;
  final String? email;

  final String? institutionId;
  final String? institution;

  final String status;
  final String approvalStatus;

  final String? joined;

  final int naosLevel;
  final int xp;

  final String? rankName;
  final String? avatarId;

  final String? membershipStatus;
  final String? requestedRole;
  final String? requestedAt;
  final String? approvedAt;

  final String? englishLevel;
  final String? course;
  final String? className;
  final String? teacherId;

  const _Student({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.institutionId,
    required this.institution,
    required this.status,
    required this.approvalStatus,
    required this.joined,
    required this.naosLevel,
    required this.xp,
    required this.rankName,
    required this.avatarId,
    required this.membershipStatus,
    required this.requestedRole,
    required this.requestedAt,
    required this.approvedAt,
    required this.englishLevel,
    required this.course,
    required this.className,
    required this.teacherId,
  });

  Map<String, dynamic> toProfileMap() {
    return {
      'id': id,
      'display_name': name,
      'username': username,
      'email': email,
      'institution_id': institutionId,
      'institution_name': institution,
      'account_status': status,
      'approval_status': approvalStatus,
      'created_at': joined,
      'naos_level': naosLevel,
      'xp': xp,
      'rank_name': rankName,
      'avatar_id': avatarId,
      'membership_status': membershipStatus,
      'requested_role': requestedRole,
      'requested_at': requestedAt,
      'approved_at': approvedAt,
      'english_level_name': englishLevel,
      'course_name': course,
      'class_name': className,
      'teacher_id': teacherId,
    };
  }
}

// ============================================================================
// STAT CARD
// ============================================================================

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
      height: 145,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF8992B2),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INSTITUTION CARD
// ============================================================================

class _InstitutionCard extends StatelessWidget {
  final String institution;
  final int students;
  final IconData icon;
  final bool academy;

  const _InstitutionCard({
    required this.institution,
    required this.students,
    required this.icon,
    this.academy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D132A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF29345F),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: academy
                  ? const Color(0xFF9B6CFF)
                      .withOpacity(0.14)
                  : const Color(0xFF6E63FF)
                      .withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: academy
                  ? const Color(0xFFB08CFF)
                  : const Color(0xFF8175FF),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  institution,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$students students',
                  style: const TextStyle(
                    color: Color(0xFF8992B2),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF69728F),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STUDENT CARD
// ============================================================================

class _StudentCard extends StatelessWidget {
  final _Student student;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF11172F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF29345F),
            ),
          ),
          child: Row(
            children: [
              _Avatar(
                name: student.name,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${student.username}',
                      style: const TextStyle(
                        color: Color(0xFF8992B2),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      student.institution ??
                          'No institution assigned',
                      style: const TextStyle(
                        color: Color(0xFFB1B8CE),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(
                status: student.status,
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF69728F),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// AVATAR
// ============================================================================

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF252F70),
        shape: BoxShape.circle,
      ),
      child: Text(
        name.isNotEmpty
            ? name[0].toUpperCase()
            : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
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
    final bool active =
        status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF0B4647)
            : const Color(0xFF4A2333),
        borderRadius: BorderRadius.circular(8),
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
// FILTER BUTTON
// ============================================================================

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6658E8)
                : const Color(0xFF11172F),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? const Color(0xFF8175FF)
                  : const Color(0xFF29345F),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFFB1B8CE),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState extends StatelessWidget {
  final bool searchActive;

  const _EmptyState({
    required this.searchActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 70,
      ),
      child: Column(
        children: [
          Icon(
            searchActive
                ? Icons.search_off_rounded
                : Icons.school_outlined,
            size: 48,
            color: const Color(0xFF4C5678),
          ),
          const SizedBox(height: 15),
          Text(
            searchActive
                ? 'No students found.'
                : 'No students available.',
            style: const TextStyle(
              color: Color(0xFF8992B2),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ERROR STATE
// ============================================================================

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Color(0xFFFF6D91),
            ),
            const SizedBox(height: 15),
            const Text(
              'Could not load students',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8992B2),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6658E8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}