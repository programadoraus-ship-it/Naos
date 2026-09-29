import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase/institution_admin_context.dart';
import 'institution_class_details_page.dart';

class InstitutionClassesPage extends StatefulWidget {
  const InstitutionClassesPage({super.key});

  @override
  State<InstitutionClassesPage> createState() => _InstitutionClassesPageState();
}

class _InstitutionClassesPageState extends State<InstitutionClassesPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _errorMessage;

  String? _institutionName;

  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      if (mounted) {
        setState(() {
          _loading = true;
          _errorMessage = null;
        });
      }

      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('No authenticated user was found.');
      }

      // ============================================================
      // 1. Resolve the authoritative administrator link
      // ============================================================

      final adminContext = await InstitutionAdminContextResolver(
        _supabase,
      ).resolve(user.id);
      final institutionId = adminContext.institutionId;

      if (institutionId == null || institutionId.isEmpty) {
        throw Exception('No institution was found for this account.');
      }

      // ============================================================
      // 2. Load institution information
      // ============================================================

      final institution = await _supabase
          .from('institutions')
          .select('id, name')
          .eq('id', institutionId)
          .maybeSingle();

      if (institution != null) {
        _institutionName = institution['name']?.toString();
      }

      // ============================================================
      // 3. Load courses belonging to this institution
      // ============================================================

      final coursesResult = await _supabase
          .from('institution_courses')
          .select('id, name, description, is_active')
          .eq('institution_id', institutionId);

      final courses = List<Map<String, dynamic>>.from(
        (coursesResult as List).map((item) => Map<String, dynamic>.from(item)),
      );

      // Create a quick course lookup.
      final Map<String, Map<String, dynamic>> courseMap = {};

      for (final course in courses) {
        final courseId = course['id']?.toString();

        if (courseId != null) {
          courseMap[courseId] = course;
        }
      }

      // ============================================================
      // 4. Load classes belonging to this institution
      // ============================================================

      final classesResult = await _supabase
          .from('institution_classes')
          .select('''
            id,
            institution_id,
            course_id,
            teacher_id,
            name,
            description,
            is_active,
            created_at,
            updated_at
          ''')
          .eq('institution_id', institutionId)
          .eq('is_active', true)
          .order('name');

      final loadedClasses = List<Map<String, dynamic>>.from(
        (classesResult as List).map((item) => Map<String, dynamic>.from(item)),
      );

      // ============================================================
      // 5. Attach course information to each class
      // ============================================================

      for (final classItem in loadedClasses) {
        final courseId = classItem['course_id']?.toString();

        if (courseId != null) {
          classItem['course'] = courseMap[courseId];
        }
      }

      if (!mounted) return;

      setState(() {
        _classes = loadedClasses;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Institution Classes Error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _getCourseName(Map<String, dynamic> classItem) {
    final course = classItem['course'];

    if (course is Map<String, dynamic>) {
      return course['name']?.toString() ?? 'Unknown course';
    }

    return 'Course not found';
  }

  bool _hasTeacher(Map<String, dynamic> classItem) {
    final teacherId = classItem['teacher_id'];

    return teacherId != null && teacherId.toString().isNotEmpty;
  }

  // ==============================================================
  // OPEN CLASS DETAILS
  // ==============================================================

  void _openClass(String classId, String className) {
    if (classId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this class.')),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstitutionClassDetailsPage(classId: classId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050817),

      appBar: AppBar(
        backgroundColor: const Color(0xFF080D24),
        foregroundColor: Colors.white,

        title: const Text(
          'Classes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadClasses,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ========================================================
            // HEADER
            // ========================================================
            const Text(
              'Classes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _institutionName != null
                  ? 'Manage classes for $_institutionName.'
                  : 'Manage classes for your institution.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 24),

            // ========================================================
            // CONTENT
            // ========================================================
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // ==============================================================
    // LOADING
    // ==============================================================

    if (_loading) {
      return _buildPanel(
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C83FF)),
        ),
      );
    }

    // ==============================================================
    // ERROR
    // ==============================================================

    if (_errorMessage != null) {
      return _buildPanel(
        error: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 50,
                  color: Color(0xFFFF6B8A),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Unable to load classes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _loadClasses,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ==============================================================
    // NO CLASSES
    // ==============================================================

    if (_classes.isEmpty) {
      return _buildPanel(
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Icon(Icons.groups_rounded, size: 52, color: Color(0xFF7C83FF)),

              SizedBox(height: 16),

              Text(
                'No classes found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Classes created by your institution '
                'will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // ==============================================================
    // CLASSES LIST
    // ==============================================================

    return ListView.separated(
      itemCount: _classes.length,

      separatorBuilder: (context, index) {
        return const SizedBox(height: 14);
      },

      itemBuilder: (context, index) {
        final classItem = _classes[index];

        return _buildClassCard(classItem);
      },
    );
  }

  Widget _buildPanel({required Widget child, bool error = false}) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: const Color(0xFF111832),
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: error ? const Color(0xFF7A2945) : const Color(0xFF28345F),
        ),
      ),

      child: child,
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classItem) {
    final className = classItem['name']?.toString() ?? 'Unnamed class';

    final description = classItem['description']?.toString();

    final courseName = _getCourseName(classItem);

    final hasTeacher = _hasTeacher(classItem);

    final classId = classItem['id']?.toString() ?? '';

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFF111832),
        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFF28345F)),
      ),

      child: Row(
        children: [
          // ==========================================================
          // CLASS ICON
          // ==========================================================
          Container(
            width: 56,
            height: 56,

            decoration: BoxDecoration(
              color: const Color(0xFF252C69),
              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.groups_rounded,
              color: Color(0xFF7C83FF),
              size: 30,
            ),
          ),

          const SizedBox(width: 18),

          // ==========================================================
          // CLASS INFORMATION
          // ==========================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  className,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  courseName,
                  style: const TextStyle(
                    color: Color(0xFF7C83FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 6),

                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 10),

                Row(
                  children: [
                    Icon(
                      hasTeacher
                          ? Icons.person_rounded
                          : Icons.person_off_rounded,
                      size: 16,
                      color: hasTeacher
                          ? const Color(0xFF36D9C5)
                          : Colors.white38,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      hasTeacher ? 'Teacher assigned' : 'No teacher assigned',
                      style: TextStyle(
                        color: hasTeacher
                            ? const Color(0xFF36D9C5)
                            : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ==========================================================
          // ACTIVE STATUS
          // ==========================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),

            decoration: BoxDecoration(
              color: const Color(0xFF103A39),
              borderRadius: BorderRadius.circular(20),
            ),

            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: Color(0xFF36D9C5),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ==========================================================
          // OPEN CLASS
          // ==========================================================
          IconButton(
            tooltip: 'Open class',

            onPressed: () {
              _openClass(classId, className);
            },

            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
