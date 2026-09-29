import 'package:flutter/material.dart';

import '../../../../core/services/supabase/supabase_service.dart';
import 'admin_users_page.dart';
import 'admin_institutions_page.dart';
import 'admin_approvals_page.dart';
import 'admin_students_page.dart';
import 'admin_teachers_page.dart';
// ================================================================
// GLOBAL DASHBOARD COLORS
// ================================================================

const Color kDashboardBackground = Color(0xFF050816);
const Color kDashboardPanel = Color(0xFF11172F);
const Color kDashboardSidebar = Color(0xFF080D22);
const Color kDashboardPrimary = Color(0xFF6972FF);

// ================================================================
// ADMIN DASHBOARD PAGE
// ================================================================

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  String? _error;

  int _totalUsers = 0;
  int _pendingApprovals = 0;
  int _teachers = 0;
  int _institutions = 0;

  List<Map<String, dynamic>> _recentRequests = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = SupabaseService.client;

      // --------------------------------------------------------
      // TOTAL USERS
      // --------------------------------------------------------

      final profilesResponse = await client
          .from('profiles')
          .select('id');

      final totalUsers = (profilesResponse as List).length;

      // --------------------------------------------------------
      // PENDING ACCESS REQUESTS
      // --------------------------------------------------------

      final pendingResponse = await client
          .from('institution_memberships')
          .select('id')
          .eq('status', 'pending');

      final pendingApprovals = (pendingResponse as List).length;

      // --------------------------------------------------------
      // TEACHERS
      // --------------------------------------------------------

      final teachersResponse = await client
          .from('institution_teachers')
          .select('id')
          .eq('is_active', true);

      final teachers = (teachersResponse as List).length;

      // --------------------------------------------------------
      // INSTITUTIONS
      // --------------------------------------------------------

      final institutionsResponse = await client
          .from('institutions')
          .select('id');

      final institutions = (institutionsResponse as List).length;

      // --------------------------------------------------------
      // RECENT REQUESTS
      // --------------------------------------------------------

      final recentResponse = await client
          .from('institution_memberships')
          .select(
            '''
            id,
            user_id,
            institution_id,
            status,
            requested_role,
            requested_at,
            profiles:user_id (
              username,
              display_name
            ),
            institutions:institution_id (
              name,
              short_name
            )
            ''',
          )
          .order('requested_at', ascending: false)
          .limit(5);

      final recentRequests = List<Map<String, dynamic>>.from(
        recentResponse as List,
      );

      if (!mounted) return;

      setState(() {
        _totalUsers = totalUsers;
        _pendingApprovals = pendingApprovals;
        _teachers = teachers;
        _institutions = institutions;
        _recentRequests = recentRequests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('NAOS DASHBOARD ERROR: $e');

      if (!mounted) return;

      setState(() {
        _error = 'Unable to load dashboard data.';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDashboardBackground,

      drawer: MediaQuery.of(context).size.width < 900
          ? const _MobileDrawer()
          : null,

      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width < 900) {
            return _buildMobileLayout(context);
          }

          if (width < 1200) {
            return _buildTabletLayout(context);
          }

          return _buildDesktopLayout(context);
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        const _DesktopSidebar(),
        Expanded(
          child: _buildMainContent(
            context,
            showMenuButton: false,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TABLET
  // ============================================================

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        const _CompactSidebar(),
        Expanded(
          child: _buildMainContent(
            context,
            showMenuButton: false,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileLayout(BuildContext context) {
    return _buildMainContent(
      context,
      showMenuButton: true,
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent(
    BuildContext context, {
    required bool showMenuButton,
  }) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(
            context,
            showMenuButton: showMenuButton,
          ),

          Expanded(
            child: RefreshIndicator(
              color: kDashboardPrimary,
              backgroundColor: kDashboardPanel,
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal:
                      MediaQuery.of(context).size.width < 600 ? 16 : 28,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(),

                    const SizedBox(height: 28),

                    if (_error != null) ...[
                      _buildErrorCard(),
                      const SizedBox(height: 20),
                    ],

                    _buildStatistics(),

                    const SizedBox(height: 28),

                    _buildMiddleSection(),

                    const SizedBox(height: 28),

                    _buildRecentRequests(),

                    const SizedBox(height: 28),

                    _buildRecentActivity(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(
    BuildContext context, {
    required bool showMenuButton,
  }) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),

          if (showMenuButton) const SizedBox(width: 4),

          if (showMenuButton)
            const Row(
              children: [
                _NaosLogo(size: 38),
                SizedBox(width: 10),
                Text(
                  'NAOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

          const Spacer(),

          IconButton(
            onPressed: _loadDashboard,
            tooltip: 'Refresh dashboard',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white70,
            ),
          ),

          const SizedBox(width: 8),

          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kDashboardPrimary.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFF9FA6FF),
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          if (MediaQuery.of(context).size.width >= 650)
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Super Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'programadorus@gmail.com',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcomeHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, Super Admin 👑',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Here is what is happening across NAOS.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        if (MediaQuery.of(context).size.width >= 650)
          OutlinedButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 17,
            ),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(
                color: Color(0xFF303B6D),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
        int columns;

        if (constraints.maxWidth >= 1000) {
          columns = 4;
        } else if (constraints.maxWidth >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: columns == 1 ? 3.2 : 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              title: 'Total Users',
              value: _isLoading ? '...' : '$_totalUsers',
              icon: Icons.people_alt_rounded,
              iconColor: const Color(0xFF6972FF),
            ),
            _StatCard(
              title: 'Pending Approvals',
              value: _isLoading ? '...' : '$_pendingApprovals',
              icon: Icons.pending_actions_rounded,
              iconColor: const Color(0xFFFFB340),
            ),
            _StatCard(
              title: 'Teachers',
              value: _isLoading ? '...' : '$_teachers',
              icon: Icons.school_rounded,
              iconColor: const Color(0xFF9B5CFF),
            ),
            _StatCard(
              title: 'Institutions',
              value: _isLoading ? '...' : '$_institutions',
              icon: Icons.business_rounded,
              iconColor: const Color(0xFF36D9C4),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MIDDLE SECTION
  // ============================================================

  Widget _buildMiddleSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            children: [
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildAdministratorCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildQuickActions(),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildAdministratorCard(),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    final actions = [
      (
        'Create User',
        Icons.person_add_alt_1_rounded,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminUsersPage(),
            ),
          );
        },
      ),
      (
        'Approve Users',
        Icons.verified_rounded,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminApprovalsPage(),
            ),
          );
        },
      ),
      (
  'Manage Teachers',
  Icons.school_rounded,
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminTeachersPage(),
      ),
    );
  },
),
      (
        'Manage Institutions',
        Icons.business_rounded,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminInstitutionsPage(),
            ),
          );
        },
      ),
      (
        'Blocked Users',
        Icons.block_rounded,
        () {
          _showComingSoon('Blocked users');
        },
      ),
      (
        'Manage Academy',
        Icons.menu_book_rounded,
        () {
          _showComingSoon('Academy management');
        },
      ),
    ];

    return _DashboardPanel(
      title: 'Quick Actions',
      icon: Icons.bolt_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: actions.map((action) {
          return _QuickActionButton(
            label: action.$1,
            icon: action.$2,
            onPressed: action.$3,
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // ADMINISTRATOR
  // ============================================================

  Widget _buildAdministratorCard() {
    return _DashboardPanel(
      title: 'Administrator',
      icon: Icons.admin_panel_settings_rounded,
      child: Column(
        children: [
          const _InfoRow(
            label: 'Role',
            value: 'super_admin',
          ),
          const _InfoRow(
            label: 'Access',
            value: 'Full access',
          ),
          const _InfoRow(
            label: 'Status',
            value: 'Active',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF163148),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF36D9C4),
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Administrator access verified.',
                    style: TextStyle(
                      color: Color(0xFF55E6D2),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT REQUESTS
  // ============================================================

  Widget _buildRecentRequests() {
    return _DashboardPanel(
      title: 'Recent Access Requests',
      icon: Icons.pending_actions_rounded,
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 25),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kDashboardPrimary,
                ),
              ),
            )
          : _recentRequests.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          color: Colors.white30,
                          size: 40,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No access requests yet.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: _recentRequests.map((request) {
                    return _RequestItem(
                      request: request,
                      onReview: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminApprovalsPage(),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
    );
  }

  // ============================================================
  // RECENT ACTIVITY
  // ============================================================

  Widget _buildRecentActivity() {
    return _DashboardPanel(
      title: 'System Activity',
      icon: Icons.history_rounded,
      child: Column(
        children: [
          _ActivityItem(
            icon: Icons.login_rounded,
            text: 'Super Admin dashboard loaded',
            time: 'Just now',
          ),
          _ActivityItem(
            icon: Icons.people_alt_rounded,
            text: '$_totalUsers users currently registered',
            time: 'Current',
          ),
          _ActivityItem(
            icon: Icons.pending_actions_rounded,
            text: '$_pendingApprovals access requests pending',
            time: 'Current',
          ),
          _ActivityItem(
            icon: Icons.business_rounded,
            text: '$_institutions institutions registered',
            time: 'Current',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorCard() {
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
            onPressed: _loadDashboard,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  void _showComingSoon(String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kDashboardPanel,
        behavior: SnackBarBehavior.floating,
        content: Text(
          '$section will be implemented next.',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// DESKTOP SIDEBAR
// ================================================================

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: kDashboardSidebar,
      child: const SafeArea(
        child: _SidebarContent(),
      ),
    );
  }
}

// ================================================================
// TABLET SIDEBAR
// ================================================================

class _CompactSidebar extends StatelessWidget {
  const _CompactSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      color: kDashboardSidebar,
      child: const SafeArea(
        child: _SidebarContent(
          compact: true,
        ),
      ),
    );
  }
}

// ================================================================
// MOBILE DRAWER
// ================================================================

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kDashboardSidebar,
      child: SafeArea(
        child: _SidebarContent(
          onItemPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// ================================================================
// SIDEBAR CONTENT
// ================================================================

class _SidebarContent extends StatelessWidget {
  final bool compact;
  final VoidCallback? onItemPressed;

  const _SidebarContent({
    this.compact = false,
    this.onItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        if (!compact)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _NaosLogo(size: 40),
                SizedBox(width: 10),
                Text(
                  'NAOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          )
        else
          const _NaosLogo(size: 40),

        const SizedBox(height: 30),

        if (!compact)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ADMINISTRATION',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        _SidebarItem(
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          selected: true,
          compact: compact,
          onPressed: onItemPressed,
        ),

        _SidebarItem(
          icon: Icons.people_alt_rounded,
          label: 'Users',
          compact: compact,
          onPressed: () {
            if (onItemPressed != null) {
              onItemPressed!();
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminUsersPage(),
              ),
            );
          },
        ),

        _SidebarItem(
          icon: Icons.verified_rounded,
          label: 'Approvals',
          compact: compact,
          onPressed: () {
            if (onItemPressed != null) {
              onItemPressed!();
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminApprovalsPage(),
              ),
            );
          },
        ),

        _SidebarItem(
  icon: Icons.school_rounded,
  label: 'Students',
  compact: compact,
  onPressed: () {
    if (onItemPressed != null) {
      onItemPressed!();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminStudentsPage(),
      ),
    );
  },
),

        _SidebarItem(
  icon: Icons.person_rounded,
  label: 'Teachers',
  compact: compact,
  onPressed: () {
    if (onItemPressed != null) {
      onItemPressed!();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminTeachersPage(),
      ),
    );
  },
),

        _SidebarItem(
          icon: Icons.business_rounded,
          label: 'Institutions',
          compact: compact,
          onPressed: () {
            if (onItemPressed != null) {
              onItemPressed!();
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminInstitutionsPage(),
              ),
            );
          },
        ),

        _SidebarItem(
          icon: Icons.menu_book_rounded,
          label: 'Academy',
          compact: compact,
          onPressed: () {
            _showSidebarMessage(context, 'Academy');
          },
        ),

        const Spacer(),

        _SidebarItem(
          icon: Icons.security_rounded,
          label: 'Security',
          compact: compact,
          onPressed: () {
            _showSidebarMessage(context, 'Security');
          },
        ),

        _SidebarItem(
          icon: Icons.history_rounded,
          label: 'Audit Log',
          compact: compact,
          onPressed: () {
            _showSidebarMessage(context, 'Audit Log');
          },
        ),

        _SidebarItem(
          icon: Icons.settings_rounded,
          label: 'Settings',
          compact: compact,
          onPressed: () {
            _showSidebarMessage(context, 'Settings');
          },
        ),

        _SidebarItem(
          icon: Icons.logout_rounded,
          label: 'Sign Out',
          compact: compact,
          onPressed: () {
            _showSidebarMessage(context, 'Sign Out');
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  void _showSidebarMessage(
    BuildContext context,
    String section,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kDashboardPanel,
        behavior: SnackBarBehavior.floating,
        content: Text(
          '$section will be implemented next.',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SIDEBAR ITEM
// ================================================================

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback? onPressed;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.compact = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 3,
      ),
      child: Material(
        color: selected
            ? const Color(0xFF292F68)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onPressed,
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : 12,
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: selected
                      ? const Color(0xFF8C94FF)
                      : Colors.white60,
                  size: 20,
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// NAOS LOGO
// ================================================================

class _NaosLogo extends StatelessWidget {
  final double size;

  const _NaosLogo({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6E7CFF),
            Color(0xFF8B3DFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF765CFF).withValues(alpha: 0.4),
            blurRadius: 16,
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 22,
      ),
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
        color: kDashboardPanel,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
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
// DASHBOARD PANEL
// ================================================================

class _DashboardPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kDashboardPanel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF283158),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF8790FF),
                size: 19,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ================================================================
// QUICK ACTION BUTTON
// ================================================================

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          color: Color(0xFF303B6D),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 11,
        ),
      ),
    );
  }
}

// ================================================================
// INFO ROW
// ================================================================

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
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// REQUEST ITEM
// ================================================================

class _RequestItem extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onReview;

  const _RequestItem({
    required this.request,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final profile = request['profiles'];
    final institution = request['institutions'];

    final displayName = profile is Map
        ? (profile['display_name'] ??
            profile['username'] ??
            'Unknown user')
        : 'Unknown user';

    final institutionName = institution is Map
        ? (institution['name'] ??
            institution['short_name'] ??
            'Unknown institution')
        : 'Unknown institution';

    final role = request['requested_role'] ?? 'student';
    final status = request['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1025),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFF252E55),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF272D65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF8D96FF),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  institutionName.toString(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          if (MediaQuery.of(context).size.width >= 600)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF20264A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                role.toString(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),

          const SizedBox(width: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: status == 'pending'
                  ? const Color(0xFF3A2C13)
                  : const Color(0xFF15382F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toString(),
              style: TextStyle(
                color: status == 'pending'
                    ? const Color(0xFFFFC15A)
                    : const Color(0xFF5FE3CA),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            tooltip: 'Review request',
            onPressed: onReview,
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ACTIVITY ITEM
// ================================================================

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1B2554),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8991FF),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}