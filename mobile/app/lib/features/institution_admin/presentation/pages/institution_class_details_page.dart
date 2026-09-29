import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'institution_class_teacher_page.dart';

class InstitutionClassDetailsPage extends StatefulWidget {
  final String classId;

  const InstitutionClassDetailsPage({super.key, required this.classId});

  @override
  State<InstitutionClassDetailsPage> createState() =>
      _InstitutionClassDetailsPageState();
}

class _InstitutionClassDetailsPageState
    extends State<InstitutionClassDetailsPage> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _classData;
  Map<String, dynamic>? _courseData;

  @override
  void initState() {
    super.initState();
    _loadClass();
  }

  Future<void> _loadClass() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final classData = await _client
          .from('institution_classes')
          .select()
          .eq('id', widget.classId)
          .maybeSingle();

      if (classData == null) {
        throw Exception('Class not found.');
      }

      Map<String, dynamic>? courseData;

      final courseId = classData['course_id'];

      if (courseId != null) {
        courseData = await _client
            .from('institution_courses')
            .select()
            .eq('id', courseId)
            .maybeSingle();
      }

      if (!mounted) return;

      setState(() {
        _classData = Map<String, dynamic>.from(classData);

        _courseData = courseData == null
            ? null
            : Map<String, dynamic>.from(courseData);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050817),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080D24),
        foregroundColor: Colors.white,
        title: const Text(
          'Class Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(),
    );
  }

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
                'Unable to load class',
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
                onPressed: _loadClass,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final classData = _classData!;

    final String name = classData['name']?.toString() ?? 'Unnamed Class';

    final String description =
        classData['description']?.toString() ?? 'No description';

    final bool isActive = classData['is_active'] == true;

    final String courseName =
        _courseData?['name']?.toString() ?? 'Unknown course';

    return RefreshIndicator(
      onRefresh: _loadClass,
      color: const Color(0xFF7C83FF),
      backgroundColor: const Color(0xFF111832),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Manage this class for your institution.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 24),

            _buildHeaderCard(
              name: name,
              courseName: courseName,
              isActive: isActive,
            ),

            const SizedBox(height: 20),

            _buildInfoCard(
              title: 'Class Information',
              icon: Icons.groups_rounded,
              children: [
                _buildInfoRow('Class name', name),

                _buildInfoRow('Course', courseName),

                _buildInfoRow('Description', description),

                _buildInfoRow('Status', isActive ? 'Active' : 'Inactive'),
              ],
            ),

            const SizedBox(height: 20),

            // =========================================================
            // PEOPLE
            // =========================================================
            _buildInfoCard(
              title: 'People',
              icon: Icons.people_alt_rounded,
              children: [
                // -----------------------------------------------------
                // STUDENTS
                // -----------------------------------------------------
                _buildActionRow(
                  icon: Icons.school_rounded,
                  title: 'Students',
                  subtitle: 'View students enrolled in this class',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Student management will be added next.'),
                      ),
                    );
                  },
                ),

                const Divider(color: Color(0xFF28345F), height: 1),

                // -----------------------------------------------------
                // TEACHER
                // -----------------------------------------------------
                _buildActionRow(
                  icon: Icons.person_rounded,
                  title: 'Teacher',
                  subtitle: 'View or change the assigned teacher',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InstitutionClassTeacherPage(
                          classId: widget.classId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // =========================================================
            // SCHEDULE
            // =========================================================
            _buildInfoCard(
              title: 'Schedule',
              icon: Icons.calendar_month_rounded,
              children: [
                _buildActionRow(
                  icon: Icons.schedule_rounded,
                  title: 'Class Schedule',
                  subtitle: 'View and manage the class schedule',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Schedule management will be added next.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HEADER CARD
  // ================================================================

  Widget _buildHeaderCard({
    required String name,
    required String courseName,
    required bool isActive,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111832),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF28345F)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF252D70),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Color(0xFF8B91FF),
              size: 34,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  courseName,
                  style: const TextStyle(
                    color: Color(0xFF8B91FF),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF123B3A)
                  : const Color(0xFF3B2030),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'ACTIVE' : 'INACTIVE',
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF39D6C5)
                    : const Color(0xFFFF6B8A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INFORMATION CARD
  // ================================================================

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111832),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF28345F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8B91FF), size: 21),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ...children,
        ],
      ),
    );
  }

  // ================================================================
  // INFORMATION ROW
  // ================================================================

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACTION ROW
  // ================================================================

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF252D70),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF8B91FF)),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
