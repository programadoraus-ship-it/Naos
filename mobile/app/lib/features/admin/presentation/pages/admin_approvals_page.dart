import 'package:flutter/material.dart';

import '../../../../core/services/supabase/supabase_service.dart';

// ================================================================
// COLORS
// ================================================================

const Color kApprovalsBackground = Color(0xFF050816);
const Color kApprovalsPanel = Color(0xFF11172F);
const Color kApprovalsPrimary = Color(0xFF6972FF);

// ================================================================
// ADMIN APPROVALS PAGE
// ================================================================

class AdminApprovalsPage extends StatefulWidget {
  const AdminApprovalsPage({super.key});

  @override
  State<AdminApprovalsPage> createState() => _AdminApprovalsPageState();
}

class _AdminApprovalsPageState extends State<AdminApprovalsPage> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _requests = [];

  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  // ============================================================
  // LOAD REQUESTS
  // ============================================================

  Future<void> _loadRequests() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = SupabaseService.client;

      final response = await client
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
          .order('requested_at', ascending: false);

      final requests = List<Map<String, dynamic>>.from(
        response as List,
      );

      if (!mounted) return;

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('NAOS APPROVALS ERROR: $e');

      if (!mounted) return;

      setState(() {
        _error = 'Unable to load access requests.';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> get _filteredRequests {
    return _requests.where((request) {
      final status = (request['status'] ?? 'pending')
          .toString()
          .toLowerCase();

      final profile = request['profiles'];

      final username = profile is Map
          ? (profile['username'] ?? '').toString().toLowerCase()
          : '';

      final displayName = profile is Map
          ? (profile['display_name'] ?? '').toString().toLowerCase()
          : '';

      final institution = request['institutions'];

      final institutionName = institution is Map
          ? (institution['name'] ?? '').toString().toLowerCase()
          : '';

      final role = (request['requested_role'] ?? '')
          .toString()
          .toLowerCase();

      final search = _searchQuery.toLowerCase().trim();

      final matchesFilter =
          _selectedFilter == 'all' ||
          status == _selectedFilter;

      final matchesSearch =
          search.isEmpty ||
          username.contains(search) ||
          displayName.contains(search) ||
          institutionName.contains(search) ||
          role.contains(search);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  // ============================================================
  // COUNTS
  // ============================================================

  int _countStatus(String status) {
    return _requests.where(
      (request) =>
          (request['status'] ?? '').toString().toLowerCase() == status,
    ).length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kApprovalsBackground,
      appBar: AppBar(
        backgroundColor: kApprovalsBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Approvals',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadRequests,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 600 ? 16 : 28,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 24),

              _buildStatistics(),

              const SizedBox(height: 24),

              _buildSearch(),

              const SizedBox(height: 18),

              _buildFilters(),

              const SizedBox(height: 20),

              if (_isLoading)
                _buildLoading()
              else if (_error != null)
                _buildError()
              else if (_filteredRequests.isEmpty)
                _buildEmpty()
              else
                _buildRequestsList(),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
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
          'Access Requests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Review access requests across all NAOS institutions.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
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
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 4.0 : 2.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ApprovalStatCard(
              title: 'Total Requests',
              value: '${_requests.length}',
              icon: Icons.list_alt_rounded,
              iconColor: const Color(0xFF6972FF),
            ),
            _ApprovalStatCard(
              title: 'Pending',
              value: '${_countStatus('pending')}',
              icon: Icons.pending_actions_rounded,
              iconColor: const Color(0xFFFFB340),
            ),
            _ApprovalStatCard(
              title: 'Approved',
              value: '${_countStatus('approved')}',
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF36D9C4),
            ),
            _ApprovalStatCard(
              title: 'Rejected',
              value: '${_countStatus('rejected')}',
              icon: Icons.cancel_outlined,
              iconColor: const Color(0xFFFF6685),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: 'Search by name, username, institution or role...',
        hintStyle: const TextStyle(
          color: Colors.white38,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Colors.white54,
        ),
        filled: true,
        fillColor: kApprovalsPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFF283158),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFF283158),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: kApprovalsPrimary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    final filters = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('approved', 'Approved'),
      ('rejected', 'Rejected'),
    ];

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: filters.map((filter) {
        final selected = _selectedFilter == filter.$1;

        return ChoiceChip(
          label: Text(filter.$2),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _selectedFilter = filter.$1;
            });
          },
          labelStyle: TextStyle(
            color: selected
                ? Colors.white
                : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
          selectedColor: kApprovalsPrimary,
          backgroundColor: kApprovalsPanel,
          side: const BorderSide(
            color: Color(0xFF303B6D),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // REQUESTS LIST
  // ============================================================

  Widget _buildRequestsList() {
    return Column(
      children: _filteredRequests.map((request) {
        return _ApprovalRequestCard(
          request: request,
          onView: () {
            _showRequestDetails(request);
          },
        );
      }).toList(),
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  void _showRequestDetails(
    Map<String, dynamic> request,
  ) {
    final profile = request['profiles'];
    final institution = request['institutions'];

    final displayName = profile is Map
        ? (profile['display_name'] ??
                profile['username'] ??
                'Unknown user')
            .toString()
        : 'Unknown user';

    final username = profile is Map
        ? (profile['username'] ?? 'Unknown username')
            .toString()
        : 'Unknown username';

    final institutionName = institution is Map
        ? (institution['name'] ??
                institution['short_name'] ??
                'Unknown institution')
            .toString()
        : 'Unknown institution';

    final role =
        (request['requested_role'] ?? 'student').toString();

    final status =
        (request['status'] ?? 'pending').toString();

    final requestedAt =
        (request['requested_at'] ?? 'Unknown').toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kApprovalsPanel,
          title: const Text(
            'Request Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                label: 'Name',
                value: displayName,
              ),
              _DetailRow(
                label: 'Username',
                value: '@$username',
              ),
              _DetailRow(
                label: 'Institution',
                value: institutionName,
              ),
              _DetailRow(
                label: 'Requested role',
                value: role,
              ),
              _DetailRow(
                label: 'Status',
                value: status,
              ),
              _DetailRow(
                label: 'Requested at',
                value: requestedAt,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF9FA6FF),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: CircularProgressIndicator(
          color: kApprovalsPrimary,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              ),
            ),
          ),
          TextButton(
            onPressed: _loadRequests,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 60,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: kApprovalsPanel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF283158),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            color: Colors.white30,
            size: 50,
          ),
          SizedBox(height: 14),
          Text(
            'No access requests found.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try another filter or search.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// STAT CARD
// ================================================================

class _ApprovalStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _ApprovalStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kApprovalsPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF283158),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
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
// REQUEST CARD
// ================================================================

class _ApprovalRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onView;

  const _ApprovalRequestCard({
    required this.request,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final profile = request['profiles'];
    final institution = request['institutions'];

    final displayName = profile is Map
        ? (profile['display_name'] ??
                profile['username'] ??
                'Unknown user')
            .toString()
        : 'Unknown user';

    final username = profile is Map
        ? (profile['username'] ?? '').toString()
        : '';

    final institutionName = institution is Map
        ? (institution['name'] ??
                institution['short_name'] ??
                'Unknown institution')
            .toString()
        : 'Unknown institution';

    final role =
        (request['requested_role'] ?? 'student').toString();

    final status =
        (request['status'] ?? 'pending').toString().toLowerCase();

    Color statusColor;

    if (status == 'approved') {
      statusColor = const Color(0xFF5FE3CA);
    } else if (status == 'rejected') {
      statusColor = const Color(0xFFFF6685);
    } else {
      statusColor = const Color(0xFFFFC15A);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kApprovalsPanel,
        borderRadius: BorderRadius.circular(15),
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
              color: const Color(0xFF272D65),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF8D96FF),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '@$username',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                role,
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
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 5),

          IconButton(
            tooltip: 'View details',
            onPressed: onView,
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
// DETAIL ROW
// ================================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
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