import 'package:flutter/material.dart';

import '../../../../core/services/supabase/supabase_service.dart';

class AdminInstitutionsPage extends StatefulWidget {
  const AdminInstitutionsPage({super.key});

  @override
  State<AdminInstitutionsPage> createState() =>
      _AdminInstitutionsPageState();
}

class _AdminInstitutionsPageState
    extends State<AdminInstitutionsPage> {
  bool _loading = true;

  List<Map<String, dynamic>> _institutions = [];

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  // ============================================================
  // LOAD INSTITUTIONS
  // ============================================================

  Future<void> _loadInstitutions() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await SupabaseService.client
          .from('institutions')
          .select(
            'id, name, short_name, city, country, logo_url, theme_color',
          )
          .order('name');

      if (!mounted) return;

      setState(() {
        _institutions =
            List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not load institutions.',
        error: true,
      );

      debugPrint(
        'ADMIN INSTITUTIONS LOAD ERROR: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN INSTITUTION
  // ============================================================

  Future<void> _openInstitution(
    Map<String, dynamic> institution,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return _InstitutionDetailsDialog(
          institution: institution,
          onChanged: _loadInstitutions,
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? Colors.redAccent : Colors.green,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1125),
        elevation: 0,
        title: const Text(
          'Institutions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C83FF),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF7C83FF),
              onRefresh: _loadInstitutions,
              child: _institutions.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            'No institutions found.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const Text(
                          'Manage Institutions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Manage schools and assign their institution administrators.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 28),

                        ..._institutions.map(
                          (institution) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 16,
                              ),
                              child: _InstitutionCard(
                                institution:
                                    institution,
                                onTap: () =>
                                    _openInstitution(
                                  institution,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),
    );
  }
}

// ================================================================
// INSTITUTION CARD
// ================================================================

class _InstitutionCard extends StatelessWidget {
  final Map<String, dynamic> institution;
  final VoidCallback onTap;

  const _InstitutionCard({
    required this.institution,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        institution['name']?.toString() ??
            'Unnamed Institution';

    final shortName =
        institution['short_name']?.toString() ?? '';

    final city =
        institution['city']?.toString() ?? '';

    final country =
        institution['country']?.toString() ?? '';

    final logoUrl =
        institution['logo_url']?.toString();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF11162B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF30385C),
          ),
        ),
        child: Row(
          children: [
            _InstitutionLogo(
              logoUrl: logoUrl,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (shortName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      shortName,
                      style: const TextStyle(
                        color: Color(0xFF9DA6D8),
                        fontSize: 13,
                      ),
                    ),
                  ],

                  if (city.isNotEmpty ||
                      country.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: Color(0xFF7C83FF),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          [
                            city,
                            country,
                          ]
                              .where(
                                (e) => e.isNotEmpty,
                              )
                              .join(', '),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// LOGO
// ================================================================

class _InstitutionLogo extends StatelessWidget {
  final String? logoUrl;

  const _InstitutionLogo({
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null &&
        logoUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          logoUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _defaultLogo();
          },
        ),
      );
    }

    return _defaultLogo();
  }

  Widget _defaultLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2140),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.school_rounded,
        color: Color(0xFF7C83FF),
        size: 32,
      ),
    );
  }
}

// ================================================================
// INSTITUTION DETAILS DIALOG
// ================================================================

class _InstitutionDetailsDialog
    extends StatefulWidget {
  final Map<String, dynamic> institution;
  final Future<void> Function() onChanged;

  const _InstitutionDetailsDialog({
    required this.institution,
    required this.onChanged,
  });

  @override
  State<_InstitutionDetailsDialog> createState() =>
      _InstitutionDetailsDialogState();
}

class _InstitutionDetailsDialogState
    extends State<_InstitutionDetailsDialog> {
  bool _loading = true;
  bool _assigning = false;

  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _availableUsers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final institutionId =
          widget.institution['id'];

      final memberships =
          await SupabaseService.client
              .from('institution_memberships')
              .select(
                'id, user_id, status, requested_role, approved_at',
              )
              .eq(
                'institution_id',
                institutionId,
              )
              .eq(
                'status',
                'active',
              )
              .eq(
                'requested_role',
                'institution_admin',
              );

      final membershipList =
          List<Map<String, dynamic>>.from(
        memberships,
      );

      final adminIds = membershipList
          .map(
            (membership) =>
                membership['user_id'],
          )
          .whereType<String>()
          .toList();

      if (adminIds.isNotEmpty) {
        final profiles =
            await SupabaseService.client
                .from('profiles')
                .select(
                  'id, username, display_name, role, account_status',
                )
                .inFilter(
                  'id',
                  adminIds,
                );

        _admins =
            List<Map<String, dynamic>>.from(
          profiles,
        );
      } else {
        _admins = [];
      }

      // --------------------------------------------------------
      // AVAILABLE USERS
      // --------------------------------------------------------

      final users =
          await SupabaseService.client
              .from('profiles')
              .select(
                'id, username, display_name, role, account_status',
              )
              .neq(
                'role',
                'super_admin',
              )
              .neq(
                'role',
                'institution_admin',
              )
              .eq(
                'account_status',
                'active',
              )
              .order(
                'display_name',
              );

      _availableUsers =
          List<Map<String, dynamic>>.from(
        users,
      );
    } catch (e) {
      debugPrint(
        'INSTITUTION DETAILS ERROR: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // ASSIGN ADMIN
  // ============================================================

  Future<void> _assignAdmin(
    String userId,
  ) async {
    setState(() {
      _assigning = true;
    });

    try {
      final result =
          await SupabaseService.client.rpc(
        'assign_institution_admin',
        params: {
          'p_user_id': userId,
          'p_institution_id':
              widget.institution['id'],
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Institution administrator assigned successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint(
        'ASSIGN ADMIN RESULT: $result',
      );

      await widget.onChanged();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _assigning = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not assign administrator: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // SELECT USER
  // ============================================================

  Future<void> _showAssignDialog() async {
    if (_availableUsers.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'There are no available users to assign.',
          ),
        ),
      );

      return;
    }

    Map<String, dynamic>? selectedUser;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              backgroundColor:
                  const Color(0xFF11162B),
              title: const Text(
                'Assign Institution Administrator',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: DropdownButtonFormField<
                    Map<String, dynamic>>(
                  dropdownColor:
                      const Color(0xFF171D35),
                  value: selectedUser,
                  decoration:
                      InputDecoration(
                    labelText: 'User',
                    labelStyle:
                        const TextStyle(
                      color: Colors.white60,
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF30385C),
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF7C83FF),
                      ),
                    ),
                  ),
                  items: _availableUsers
                      .map(
                        (user) {
                          final name =
                              user['display_name']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? user[
                                      'display_name']
                                  .toString()
                              : user[
                                      'username']
                                  ?.toString() ??
                              'Unknown user';

                          return DropdownMenuItem<
                              Map<String,
                                  dynamic>>(
                            value: user,
                            child: Text(
                              name,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                              ),
                            ),
                          );
                        },
                      )
                      .toList(),
                  onChanged:
                      (value) {
                    setDialogState(() {
                      selectedUser =
                          value;
                    });
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      selectedUser ==
                                  null ||
                              _assigning
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                              );

                              _assignAdmin(
                                selectedUser![
                                    'id'],
                              );
                            },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF6C63FF,
                    ),
                  ),
                  child: const Text(
                    'Assign',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final name =
        widget.institution['name']
                ?.toString() ??
            'Institution';

    return AlertDialog(
      backgroundColor: const Color(0xFF11162B),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(24),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.school_rounded,
            color: Color(0xFF7C83FF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: _loading
            ? const SizedBox(
                height: 180,
                child: Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        Color(0xFF7C83FF),
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Institution Administrators',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_admins.isEmpty)
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(18),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFF0B1022,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                          border:
                              Border.all(
                            color:
                                const Color(
                              0xFF30385C,
                            ),
                          ),
                        ),
                        child:
                            const Text(
                          'No institution administrators assigned yet.',
                          style:
                              TextStyle(
                            color:
                                Colors.white54,
                          ),
                        ),
                      )
                    else
                      ..._admins.map(
                        (admin) {
                          final displayName =
                              admin[
                                      'display_name']
                                  ?.toString()
                                  .trim();

                          final username =
                              admin[
                                      'username']
                                  ?.toString();

                          final name =
                              displayName
                                          ?.isNotEmpty ==
                                      true
                                  ? displayName!
                                  : username ??
                                      'Unknown user';

                          return Container(
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 10,
                            ),
                            padding:
                                const EdgeInsets
                                    .all(14),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFF0B1022,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              border:
                                  Border.all(
                                color:
                                    const Color(
                                  0xFF30385C,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      const Color(
                                    0xFF242B52,
                                  ),
                                  child:
                                      const Icon(
                                    Icons
                                        .person_rounded,
                                    color:
                                        Color(
                                      0xFF7C83FF,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child:
                                      Column(
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
                                              FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 3,
                                      ),
                                      const Text(
                                        'Institution Administrator',
                                        style:
                                            TextStyle(
                                          color:
                                              Color(
                                            0xFF9DA6D8,
                                          ),
                                          fontSize:
                                              12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(
                                  Icons
                                      .verified_rounded,
                                  color:
                                      Colors.greenAccent,
                                  size: 20,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 50,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            _assigning
                                ? null
                                : _showAssignDialog,
                        icon: const Icon(
                          Icons
                              .person_add_alt_1_rounded,
                        ),
                        label:
                            const Text(
                          'Assign Administrator',
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF6C63FF,
                          ),
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Close',
          ),
        ),
      ],
    );
  }
}