import 'package:flutter/material.dart';

import '../../../../core/services/supabase/supabase_service.dart';

class AdminTeacherProfilePage extends StatefulWidget {
  final String teacherId;

  const AdminTeacherProfilePage({
    super.key,
    required this.teacherId,
  });

  @override
  State<AdminTeacherProfilePage> createState() =>
      _AdminTeacherProfilePageState();
}

class _AdminTeacherProfilePageState
    extends State<AdminTeacherProfilePage> {
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _teacher;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _institution;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _classes = [];

  int _studentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
  }

  // ================================================================
  // LOAD TEACHER
  // ================================================================

  Future<void> _loadTeacher() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = SupabaseService.client;

      // ------------------------------------------------------------
      // TEACHER
      // ------------------------------------------------------------

      final teacherResponse = await client
          .from('institution_teachers')
          .select('''
            id,
            user_id,
            institution_id,
            is_active,
            created_at,
            profiles:user_id (
              id,
              username,
              display_name,
              role,
              approval_status,
              account_status,
              created_at
            ),
            institutions:institution_id (
              id,
              name
            )
          ''')
          .eq('id', widget.teacherId)
          .maybeSingle();

      if (teacherResponse == null) {
        throw Exception('Teacher not found.');
      }

      _teacher = Map<String, dynamic>.from(teacherResponse);

      final profileData = teacherResponse['profiles'];
      final institutionData = teacherResponse['institutions'];

      _profile = profileData is Map
          ? Map<String, dynamic>.from(profileData)
          : null;

      _institution = institutionData is Map
          ? Map<String, dynamic>.from(institutionData)
          : null;

      // ------------------------------------------------------------
      // CLASSES
      // ------------------------------------------------------------

      final classTeacherResponse = await client
          .from('institution_class_teachers')
          .select('''
            id,
            class_id,
            teacher_id,
            is_primary,
            is_active,
            institution_classes:class_id (
              id,
              name,
              description,
              course_id,
              institution_id,
              is_active,
              institution_courses:course_id (
                id,
                name,
                description,
                is_active
              )
            )
          ''')
          .eq('teacher_id', widget.teacherId)
          .eq('is_active', true);

      final classTeacherRows =
          List<Map<String, dynamic>>.from(
        classTeacherResponse as List,
      );

      final classes = <Map<String, dynamic>>[];
      final courseMap = <String, Map<String, dynamic>>{};

      for (final row in classTeacherRows) {
        final classData = row['institution_classes'];

        if (classData is! Map) continue;

        final classItem =
            Map<String, dynamic>.from(classData);

        classes.add(classItem);

        final courseData =
            classItem['institution_courses'];

        if (courseData is Map) {
          final course =
              Map<String, dynamic>.from(courseData);

          final courseId = course['id']?.toString();

          if (courseId != null) {
            courseMap[courseId] = course;
          }
        }
      }

      // ------------------------------------------------------------
      // DIRECT COURSE ASSIGNMENTS
      // ------------------------------------------------------------

      final courseTeacherResponse = await client
          .from('institution_course_teachers')
          .select('''
            id,
            course_id,
            teacher_id,
            is_active,
            institution_courses:course_id (
              id,
              name,
              description,
              is_active
            )
          ''')
          .eq('teacher_id', widget.teacherId)
          .eq('is_active', true);

      final courseTeacherRows =
          List<Map<String, dynamic>>.from(
        courseTeacherResponse as List,
      );

      for (final row in courseTeacherRows) {
        final courseData =
            row['institution_courses'];

        if (courseData is Map) {
          final course =
              Map<String, dynamic>.from(courseData);

          final courseId = course['id']?.toString();

          if (courseId != null) {
            courseMap[courseId] = course;
          }
        }
      }

      // ------------------------------------------------------------
      // STUDENTS
      // ------------------------------------------------------------

      final membershipResponse = await client
          .from('institution_memberships')
          .select('id')
          .eq('teacher_id', widget.teacherId)
          .eq('status', 'active');

      _studentCount =
          (membershipResponse as List).length;

      if (!mounted) return;

      setState(() {
        _courses = courseMap.values.toList();
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('NAOS TEACHER PROFILE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ================================================================
  // MANAGE ASSIGNMENTS
  // ================================================================

  Future<void> _openManageAssignments() async {
    final result = await showDialog(
      context: context,
      builder: (context) {
        return _ManageAssignmentsDialog(
          teacherId: widget.teacherId,
          institutionId: _teacher?['institution_id']?.toString(),
          assignedCourseIds: _courses
              .map((e) => e['id'].toString())
              .toSet(),
          assignedClassIds: _classes
              .map((e) => e['id'].toString())
              .toSet(),
        );
      },
    );

    if (result == true) {
      await _loadTeacher();
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6972FF),
                      ),
                    )
                  : _error != null
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // TOP BAR
  // ================================================================

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFF080D22),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            'Teacher Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const Spacer(),

          // --------------------------------------------------------
          // MANAGE ASSIGNMENTS
          // --------------------------------------------------------

          ElevatedButton.icon(
            onPressed: _openManageAssignments,
            icon: const Icon(
              Icons.manage_accounts_rounded,
              size: 18,
            ),
            label: const Text('Manage Assignments'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF6972FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(width: 10),

          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadTeacher,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CONTENT
  // ================================================================

  Widget _buildContent() {
    final displayName =
        (_profile?['display_name'] ??
                _profile?['username'] ??
                'Teacher')
            .toString();

    final username =
        (_profile?['username'] ?? '').toString();

    final institutionName =
        (_institution?['name'] ??
                'No institution')
            .toString();

    final isActive =
        _teacher?['is_active'] == true;

    return RefreshIndicator(
      color: const Color(0xFF6972FF),
      onRefresh: _loadTeacher,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildTeacherHeader(
              displayName,
              username,
              institutionName,
              isActive,
            ),

            const SizedBox(height: 24),

            _buildOverview(),

            const SizedBox(height: 24),

            _buildCourses(),

            const SizedBox(height: 24),

            _buildClasses(),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // TEACHER HEADER
  // ================================================================

  Widget _buildTeacherHeader(
    String name,
    String username,
    String institution,
    bool isActive,
  ) {
    final initial =
        name.isNotEmpty
            ? name[0].toUpperCase()
            : 'T';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF11172F),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF283158),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFF292F68),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '@$username',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _Badge(
                      label: 'TEACHER',
                      color:
                          const Color(0xFF6972FF),
                    ),

                    const SizedBox(width: 8),

                    _Badge(
                      label: isActive
                          ? 'ACTIVE'
                          : 'INACTIVE',
                      color: isActive
                          ? const Color(0xFF36D9C4)
                          : const Color(0xFFFF5C82),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.business_rounded,
                      color: Colors.white38,
                      size: 16,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      institution,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // OVERVIEW
  // ================================================================

  Widget _buildOverview() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= 900
                    ? 4
                    : 2;

            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              children: [
                _OverviewCard(
                  title: 'Courses',
                  value: '${_courses.length}',
                  icon:
                      Icons.menu_book_rounded,
                  iconColor:
                      const Color(0xFF9B5CFF),
                ),

                _OverviewCard(
                  title: 'Classes',
                  value: '${_classes.length}',
                  icon:
                      Icons.groups_rounded,
                  iconColor:
                      const Color(0xFF6972FF),
                ),

                _OverviewCard(
                  title: 'Students',
                  value: '$_studentCount',
                  icon:
                      Icons.people_alt_rounded,
                  iconColor:
                      const Color(0xFF36D9C4),
                ),

                _OverviewCard(
                  title: 'Schedule',
                  value: 'Soon',
                  icon:
                      Icons.calendar_month_rounded,
                  iconColor:
                      const Color(0xFFFFB84D),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ================================================================
  // COURSES
  // ================================================================

  Widget _buildCourses() {
    return _Section(
      title: 'Courses',
      icon: Icons.menu_book_rounded,
      child: _courses.isEmpty
          ? const _EmptySection(
              message:
                  'No courses assigned yet.',
            )
          : Column(
              children:
                  _courses.map((course) {
                final name =
                    (course['name'] ??
                            'Unnamed course')
                        .toString();

                final description =
                    (course['description'] ??
                            '')
                        .toString();

                final courseId =
                    course['id']?.toString();

                final classCount = _classes
                    .where(
                      (classItem) =>
                          classItem['course_id']
                              ?.toString() ==
                          courseId,
                    )
                    .length;

                return Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF0B1025),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          const Color(0xFF252D50),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFF9B5CFF,
                          ).withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .menu_book_rounded,
                          color:
                              Color(0xFF9B5CFF),
                        ),
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              name,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontWeight:
                                    FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),

                            if (description
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                description,
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      Text(
                        '$classCount '
                        '${classCount == 1 ? 'class' : 'classes'}',
                        style:
                            const TextStyle(
                          color:
                              Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ================================================================
  // CLASSES
  // ================================================================

  Widget _buildClasses() {
    return _Section(
      title: 'Classes',
      icon: Icons.groups_rounded,
      child: _classes.isEmpty
          ? const _EmptySection(
              message:
                  'No classes assigned yet.',
            )
          : Column(
              children:
                  _classes.map((classItem) {
                final name =
                    (classItem['name'] ??
                            'Unnamed class')
                        .toString();

                final description =
                    (classItem['description'] ??
                            '')
                        .toString();

                final course =
                    classItem[
                        'institution_courses'];

                final courseName = course is Map
                    ? (course['name'] ??
                            'Unnamed course')
                        .toString()
                    : 'Unnamed course';

                return Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF0B1025),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          const Color(0xFF252D50),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        color:
                            Color(0xFF6972FF),
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              name,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              courseName,
                              style:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xFF6972FF,
                                ),
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),

                            if (description
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                description,
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding:
              const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                const Color(0xFF351A29),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color:
                  const Color(0xFF8C3555),
            ),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color:
                    Color(0xFFFF6B8A),
                size: 42,
              ),

              const SizedBox(height: 12),

              const Text(
                'Unable to load teacher profile.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _error ?? '',
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: _loadTeacher,
                child:
                    const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// MANAGE ASSIGNMENTS DIALOG
// ==================================================================

class _ManageAssignmentsDialog
    extends StatefulWidget {
  final String teacherId;
  final String? institutionId;
  final Set<String> assignedCourseIds;
  final Set<String> assignedClassIds;

  const _ManageAssignmentsDialog({
    required this.teacherId,
    required this.institutionId,
    required this.assignedCourseIds,
    required this.assignedClassIds,
  });

  @override
  State<_ManageAssignmentsDialog> createState() =>
      _ManageAssignmentsDialogState();
}

class _ManageAssignmentsDialogState
    extends State<_ManageAssignmentsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loadingCourses = true;
  bool _loadingClasses = true;
  bool _saving = false;

  String? _error;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _classes = [];

  final Set<String> _selectedCourses = {};
  final Set<String> _selectedClasses = {};

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _selectedCourses.addAll(
      widget.assignedCourseIds,
    );

    _selectedClasses.addAll(
      widget.assignedClassIds,
    );

    _loadOptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ================================================================
  // LOAD COURSES + CLASSES
  // ================================================================

  Future<void> _loadOptions() async {
    try {
      final client = SupabaseService.client;

      final institutionId =
          widget.institutionId;

      if (institutionId == null) {
        throw Exception(
          'Teacher has no institution assigned.',
        );
      }

      final courseResponse = await client
          .from('institution_courses')
          .select('''
            id,
            name,
            description,
            is_active
          ''')
          .eq(
            'institution_id',
            institutionId,
          )
          .eq('is_active', true)
          .order('name');

      final classResponse = await client
          .from('institution_classes')
          .select('''
            id,
            name,
            description,
            course_id,
            institution_id,
            is_active,
            institution_courses:course_id (
              id,
              name
            )
          ''')
          .eq(
            'institution_id',
            institutionId,
          )
          .eq('is_active', true)
          .order('name');

      if (!mounted) return;

      setState(() {
        _courses =
            List<Map<String, dynamic>>.from(
          courseResponse as List,
        );

        _classes =
            List<Map<String, dynamic>>.from(
          classResponse as List,
        );

        _loadingCourses = false;
        _loadingClasses = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loadingCourses = false;
        _loadingClasses = false;
      });
    }
  }

  // ================================================================
  // SAVE
  // ================================================================

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final client = SupabaseService.client;

      // ------------------------------------------------------------
      // COURSES
      // ------------------------------------------------------------

      final currentCourseResponse = await client
          .from('institution_course_teachers')
          .select('''
            id,
            course_id,
            is_active
          ''')
          .eq(
            'teacher_id',
            widget.teacherId,
          );

      final currentCourses =
          List<Map<String, dynamic>>.from(
        currentCourseResponse as List,
      );

      for (final row in currentCourses) {
        final id = row['course_id']
            ?.toString();

        if (id == null) continue;

        final assignmentId =
            row['id']?.toString();

        if (_selectedCourses.contains(id)) {
          if (row['is_active'] != true &&
              assignmentId != null) {
            await client
                .from(
                  'institution_course_teachers',
                )
                .update({
              'is_active': true,
              'assigned_at':
                  DateTime.now()
                      .toIso8601String(),
            }).eq(
              'id',
              assignmentId,
            );
          }
        } else {
          if (assignmentId != null &&
              row['is_active'] == true) {
            await client
                .from(
                  'institution_course_teachers',
                )
                .update({
              'is_active': false,
            }).eq(
              'id',
              assignmentId,
            );
          }
        }
      }

      final existingCourseIds =
          currentCourses
              .map(
                (e) =>
                    e['course_id']?.toString(),
              )
              .whereType<String>()
              .toSet();

      for (final courseId
          in _selectedCourses) {
        if (!existingCourseIds
            .contains(courseId)) {
          await client
              .from(
                'institution_course_teachers',
              )
              .insert({
            'course_id': courseId,
            'teacher_id':
                widget.teacherId,
            'is_active': true,
            'assigned_at':
                DateTime.now()
                    .toIso8601String(),
          });
        }
      }

      // ------------------------------------------------------------
      // CLASSES
      // ------------------------------------------------------------

      final currentClassResponse = await client
          .from(
            'institution_class_teachers',
          )
          .select('''
            id,
            class_id,
            is_active,
            is_primary
          ''')
          .eq(
            'teacher_id',
            widget.teacherId,
          );

      final currentClasses =
          List<Map<String, dynamic>>.from(
        currentClassResponse as List,
      );

      for (final row in currentClasses) {
        final classId =
            row['class_id']?.toString();

        if (classId == null) continue;

        final assignmentId =
            row['id']?.toString();

        if (_selectedClasses
            .contains(classId)) {
          if (row['is_active'] != true &&
              assignmentId != null) {
            await client
                .from(
                  'institution_class_teachers',
                )
                .update({
              'is_active': true,
              'assigned_at':
                  DateTime.now()
                      .toIso8601String(),
            }).eq(
              'id',
              assignmentId,
            );
          }
        } else {
          if (assignmentId != null &&
              row['is_active'] == true) {
            await client
                .from(
                  'institution_class_teachers',
                )
                .update({
              'is_active': false,
            }).eq(
              'id',
              assignmentId,
            );
          }
        }
      }

      final existingClassIds =
          currentClasses
              .map(
                (e) =>
                    e['class_id']?.toString(),
              )
              .whereType<String>()
              .toSet();

      for (final classId
          in _selectedClasses) {
        if (!existingClassIds
            .contains(classId)) {
          await client
              .from(
                'institution_class_teachers',
              )
              .insert({
            'class_id': classId,
            'teacher_id':
                widget.teacherId,
            'is_primary': false,
            'is_active': true,
            'assigned_at':
                DateTime.now()
                    .toIso8601String(),
          });
        }
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          const Color(0xFF11172F),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: SizedBox(
        width: 700,
        height: 650,
        child: Column(
          children: [
            // ------------------------------------------------------
            // HEADER
            // ------------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                24,
                22,
                16,
                12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.manage_accounts_rounded,
                    color:
                        Color(0xFF6972FF),
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Text(
                      'Manage Assignments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: _saving
                        ? null
                        : () =>
                            Navigator.pop(
                              context,
                            ),
                    icon: const Icon(
                      Icons.close_rounded,
                      color:
                          Colors.white54,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              color: Color(0xFF283158),
              height: 1,
            ),

            // ------------------------------------------------------
            // TABS
            // ------------------------------------------------------

            TabBar(
              controller: _tabController,
              indicatorColor:
                  const Color(0xFF6972FF),
              labelColor: Colors.white,
              unselectedLabelColor:
                  Colors.white38,
              tabs: const [
                Tab(
                  icon:
                      Icon(Icons.menu_book_rounded),
                  text: 'Courses',
                ),
                Tab(
                  icon:
                      Icon(Icons.groups_rounded),
                  text: 'Classes',
                ),
              ],
            ),

            // ------------------------------------------------------
            // BODY
            // ------------------------------------------------------

            Expanded(
              child: _error != null
                  ? _buildError()
                  : TabBarView(
                      controller:
                          _tabController,
                      children: [
                        _buildCoursesTab(),
                        _buildClassesTab(),
                      ],
                    ),
            ),

            const Divider(
              color: Color(0xFF283158),
              height: 1,
            ),

            // ------------------------------------------------------
            // FOOTER
            // ------------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${_selectedCourses.length} courses • '
                    '${_selectedClasses.length} classes',
                    style:
                        const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),

                  const Spacer(),

                  TextButton(
                    onPressed: _saving
                        ? null
                        : () =>
                            Navigator.pop(
                              context,
                            ),
                    child:
                        const Text('Cancel'),
                  ),

                  const SizedBox(width: 8),

                  ElevatedButton.icon(
                    onPressed:
                        _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : 'Save Changes',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF6972FF,
                      ),
                      foregroundColor:
                          Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // COURSES TAB
  // ================================================================

  Widget _buildCoursesTab() {
    if (_loadingCourses) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: Color(0xFF6972FF),
        ),
      );
    }

    if (_courses.isEmpty) {
      return const _EmptySection(
        message:
            'No active courses found for this institution.',
      );
    }

    return ListView.separated(
      padding:
          const EdgeInsets.all(20),
      itemCount: _courses.length,
      separatorBuilder:
          (_, __) =>
              const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final course =
            _courses[index];

        final id =
            course['id'].toString();

        final name =
            (course['name'] ??
                    'Unnamed course')
                .toString();

        final description =
            (course['description'] ??
                    '')
                .toString();

        final selected =
            _selectedCourses.contains(id);

        return _AssignmentTile(
          selected: selected,
          icon:
              Icons.menu_book_rounded,
          title: name,
          subtitle:
              description.isEmpty
                  ? null
                  : description,
          onTap: () {
            setState(() {
              if (selected) {
                _selectedCourses
                    .remove(id);
              } else {
                _selectedCourses
                    .add(id);
              }
            });
          },
        );
      },
    );
  }

  // ================================================================
  // CLASSES TAB
  // ================================================================

  Widget _buildClassesTab() {
    if (_loadingClasses) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: Color(0xFF6972FF),
        ),
      );
    }

    if (_classes.isEmpty) {
      return const _EmptySection(
        message:
            'No active classes found for this institution.',
      );
    }

    return ListView.separated(
      padding:
          const EdgeInsets.all(20),
      itemCount: _classes.length,
      separatorBuilder:
          (_, __) =>
              const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final classItem =
            _classes[index];

        final id =
            classItem['id'].toString();

        final name =
            (classItem['name'] ??
                    'Unnamed class')
                .toString();

        final description =
            (classItem['description'] ??
                    '')
                .toString();

        final course =
            classItem[
                'institution_courses'];

        final courseName =
            course is Map
                ? (course['name'] ??
                        'No course')
                    .toString()
                : 'No course';

        final selected =
            _selectedClasses.contains(id);

        return _AssignmentTile(
          selected: selected,
          icon:
              Icons.groups_rounded,
          title: name,
          subtitle:
              '$courseName'
              '${description.isEmpty ? '' : ' • $description'}',
          onTap: () {
            setState(() {
              if (selected) {
                _selectedClasses
                    .remove(id);
              } else {
                _selectedClasses
                    .add(id);
              }
            });
          },
        );
      },
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Text(
          _error ?? '',
          textAlign:
              TextAlign.center,
          style:
              const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// ASSIGNMENT TILE
// ==================================================================

class _AssignmentTile
    extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _AssignmentTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1A2050)
              : const Color(0xFF0B1025),
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF6972FF)
                : const Color(0xFF252D50),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFF6972FF)
                        .withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: Icon(
                icon,
                color:
                    const Color(0xFF6972FF),
                size: 21,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  if (subtitle != null &&
                      subtitle!.isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Checkbox(
              value: selected,
              onChanged: (_) =>
                  onTap(),
              activeColor:
                  const Color(0xFF6972FF),
              checkColor:
                  Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// SECTION
// ==================================================================

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            const Color(0xFF11172F),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFF283158),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color:
                    const Color(0xFF6972FF),
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }
}

// ==================================================================
// EMPTY
// ==================================================================

class _EmptySection
    extends StatelessWidget {
  final String message;

  const _EmptySection({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 30,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            color: Colors.white24,
            size: 38,
          ),

          const SizedBox(height: 10),

          Text(
            message,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// BADGE
// ==================================================================

class _Badge
    extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(alpha: 0.12),
        borderRadius:
            BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }
}

// ==================================================================
// OVERVIEW CARD
// ==================================================================

class _OverviewCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF11172F),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              const Color(0xFF283158),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  iconColor.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      Colors.white38,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}