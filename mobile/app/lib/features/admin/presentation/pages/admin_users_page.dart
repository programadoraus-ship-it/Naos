import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _searchController =
      TextEditingController();

  bool _isLoading = true;

  String _filter = 'all';
  String _roleFilter = 'all';
  String _searchQuery = '';

  List<Map<String, dynamic>> _users = [];

  static const Color _background = Color(0xFF050816);
  static const Color _panel = Color(0xFF10162F);
  static const Color _border = Color(0xFF28335C);
  static const Color _primary = Color(0xFF7075FF);

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchQuery =
            _searchController.text.trim().toLowerCase();
      });
    });

    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD USERS
  // ============================================================

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response =
          await _supabase.rpc('get_admin_users');

      if (!mounted) return;

      final rows =
          response is List ? response : <dynamic>[];

      final loadedUsers = rows
          .whereType<Map>()
          .map(
            (row) => Map<String, dynamic>.from(row),
          )
          .toList();

      setState(() {
        _users = loadedUsers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError(
        'Could not load users: $e',
      );
    }
  }

  // ============================================================
  // FILTERED USERS
  // ============================================================

  List<Map<String, dynamic>> get _filteredUsers {
    var result =
        List<Map<String, dynamic>>.from(_users);

    if (_filter == 'pending') {
      result = result
          .where(
            (u) =>
                u['approval_status'] == 'pending',
          )
          .toList();
    } else if (_filter == 'approved') {
      result = result
          .where(
            (u) =>
                u['approval_status'] == 'approved',
          )
          .toList();
    } else if (_filter == 'blocked') {
      result = result
          .where(
            (u) =>
                u['account_status'] == 'blocked',
          )
          .toList();
    }

    if (_roleFilter != 'all') {
      result = result
          .where(
            (u) =>
                u['role'] == _roleFilter,
          )
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((user) {
        final values = [
          user['display_name'],
          user['username'],
          user['email'],
          user['role'],
          user['approval_status'],
          user['account_status'],
        ].map(
          (v) =>
              v?.toString().toLowerCase() ?? '',
        );

        return values.any(
          (value) =>
              value.contains(_searchQuery),
        );
      }).toList();
    }

    return result;
  }

  // ============================================================
  // APPROVE USER
  // ============================================================

  Future<void> _approveUser(String id) async {
    try {
      await _supabase
          .from('profiles')
          .update({
        'approval_status': 'approved',
        'approved_at':
            DateTime.now().toIso8601String(),
        'approved_by':
            _supabase.auth.currentUser?.id,
      })
          .eq('id', id);

      await _loadUsers();

      if (!mounted) return;

      _showSuccess(
        'User approved successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Could not approve user: $e',
      );
    }
  }

  // ============================================================
  // REJECT USER
  // ============================================================

  Future<void> _rejectUser(String id) async {
    try {
      await _supabase
          .from('profiles')
          .update({
        'approval_status': 'rejected',
        'rejection_reason':
            'Rejected by administrator',
      })
          .eq('id', id);

      await _loadUsers();

      if (!mounted) return;

      _showSuccess(
        'User rejected.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Could not reject user: $e',
      );
    }
  }

  // ============================================================
  // BLOCK / UNBLOCK
  // ============================================================

  Future<void> _toggleBlockUser(
    String id,
    String currentStatus,
  ) async {
    final currentUserId =
        _supabase.auth.currentUser?.id;

    if (id == currentUserId) {
      _showError(
        'For security, you cannot block your own account.',
      );
      return;
    }

    final shouldBlock =
        currentStatus != 'blocked';

    try {
      await _supabase
          .from('profiles')
          .update({
        'account_status':
            shouldBlock ? 'blocked' : 'active',
        'blocked_at': shouldBlock
            ? DateTime.now().toIso8601String()
            : null,
        'blocked_by': shouldBlock
            ? _supabase.auth.currentUser?.id
            : null,
      })
          .eq('id', id);

      await _loadUsers();

      if (!mounted) return;

      _showSuccess(
        shouldBlock
            ? 'User blocked.'
            : 'User unblocked.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Could not update account status: $e',
      );
    }
  }

  // ============================================================
  // SAVE USER EDITS
  // ============================================================

  Future<void> _saveUserEdits({
    required String id,
    required String displayName,
    required String username,
    required String role,
    required String approvalStatus,
    required String accountStatus,
    required int naosLevel,
    required int xp,
  }) async {
    try {
      final currentUserId =
          _supabase.auth.currentUser?.id;

      final isOwnAccount =
          id == currentUserId;

      final safeRole =
          isOwnAccount
              ? 'super_admin'
              : role;

      final safeAccountStatus =
          isOwnAccount
              ? 'active'
              : accountStatus;

      final safeApprovalStatus =
          isOwnAccount
              ? 'approved'
              : approvalStatus;

      await _supabase
          .from('profiles')
          .update({
        'display_name':
            displayName.trim(),
        'username':
            username.trim(),
        'role':
            safeRole,
        'approval_status':
            safeApprovalStatus,
        'account_status':
            safeAccountStatus,
        'naos_level':
            naosLevel,
        'xp':
            xp,
        'updated_at':
            DateTime.now().toIso8601String(),
      })
          .eq('id', id);

      await _loadUsers();

      if (!mounted) return;

      _showSuccess(
        'User updated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Could not update user: $e',
      );
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> _resetUserPassword(
    Map<String, dynamic> user,
  ) async {
    final email =
        user['email']
                ?.toString()
                .trim() ??
            '';

    final name =
        user['display_name']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? user['display_name']
                .toString()
                .trim()
            : user['username']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                    true
                ? user['username']
                    .toString()
                    .trim()
                : 'this user';

    if (email.isEmpty) {
      _showError(
        'This user does not have an email address.',
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _panel,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.lock_reset_rounded,
                color: _primary,
              ),
              SizedBox(width: 10),
              Text(
                'Reset password?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'A secure password reset email will be sent to:\n\n$email\n\n$name will be able to create a new password using the secure Supabase link.\n\nThe current password will never be displayed.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    _primary,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
                  const Text(
                'Send reset email',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _supabase.auth
          .resetPasswordForEmail(email);

      if (!mounted) return;

      _showSuccess(
        'Password reset email sent to $email.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Could not send password reset email: $e',
      );
    }
  }

  // ============================================================
  // DELETE USER
  // ============================================================

  Future<void> _deleteUser(
    String id,
    String displayName,
  ) async {
    final currentUserId =
        _supabase.auth.currentUser?.id;

    if (id == currentUserId) {
      _showError(
        'For security, you cannot permanently delete your own account.',
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _panel,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Text(
            'Permanently delete user?',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: Text(
            'This will permanently remove "$displayName" and cannot be undone.',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(false),
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFFF5C7A,
                ),
              ),
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(true),
              child:
                  const Text(
                'Delete permanently',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _supabase.rpc(
        'delete_user_completely',
        params: {
          'p_user_id': id,
        },
      );

      await _loadUsers();

      if (!mounted) return;

      _showSuccess(
        'User permanently deleted.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Permanent deletion failed: $e',
      );
    }
  }

  // ============================================================
  // USER DETAILS
  // ============================================================

  void _showUserDetails(
    Map<String, dynamic> user,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return _UserDetailsDialog(
          user: user,

          onEdit: () async {
            Navigator.of(context).pop();

            await Future<void>.delayed(
              const Duration(
                milliseconds: 150,
              ),
            );

            if (!mounted) return;

            _showEditUserDialog(user);
          },

          onDelete: () {
            Navigator.of(context).pop();

            _deleteUser(
              user['id'].toString(),
              _displayName(user),
            );
          },

          onBlock: () {
            Navigator.of(context).pop();

            _toggleBlockUser(
              user['id'].toString(),
              user['account_status']
                      ?.toString() ??
                  'active',
            );
          },

          onApprove: () {
            Navigator.of(context).pop();

            _approveUser(
              user['id'].toString(),
            );
          },

          onReject: () {
            Navigator.of(context).pop();

            _rejectUser(
              user['id'].toString(),
            );
          },

          onResetPassword: () {
            Navigator.of(context).pop();

            _resetUserPassword(user);
          },
        );
      },
    );
  }

  // ============================================================
  // EDIT USER
  // ============================================================

  Future<void> _showEditUserDialog(
    Map<String, dynamic> user,
  ) async {
    final displayController =
        TextEditingController(
      text:
          user['display_name']
                  ?.toString() ??
              '',
    );

    final usernameController =
        TextEditingController(
      text:
          user['username']
                  ?.toString() ??
              '',
    );

    final levelController =
        TextEditingController(
      text:
          user['naos_level']
                  ?.toString() ??
              '1',
    );

    final xpController =
        TextEditingController(
      text:
          user['xp']
                  ?.toString() ??
              '0',
    );

    final allowedRoles = [
      'student',
      'teacher',
      'designer',
      'institution_admin',
      'super_admin',
    ];

    final allowedApprovalStatuses = [
      'pending',
      'approved',
      'rejected',
    ];

    final allowedAccountStatuses = [
      'active',
      'blocked',
      'left',
    ];

    String role =
        allowedRoles.contains(
          user['role']?.toString(),
        )
            ? user['role'].toString()
            : 'student';

    String approvalStatus =
        allowedApprovalStatuses.contains(
          user['approval_status']
              ?.toString(),
        )
            ? user['approval_status'].toString()
            : 'pending';

    String accountStatus =
        allowedAccountStatuses.contains(
          user['account_status']
              ?.toString(),
        )
            ? user['account_status'].toString()
            : 'active';

    final currentUserId =
        _supabase.auth.currentUser?.id;

    final userId =
        user['id']?.toString() ?? '';

    final isEditingOwnAccount =
        userId == currentUserId;

    Map<String, dynamic>? editedUser;

    try {
      editedUser =
          await showDialog<
              Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              context,
              setDialogState,
            ) {
              return AlertDialog(
                backgroundColor: _panel,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      color: _primary,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Edit user',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 500,
                  child:
                      SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        _dialogField(
                          controller:
                              displayController,
                          label:
                              'Display name',
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _dialogField(
                          controller:
                              usernameController,
                          label:
                              'Username',
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        DropdownButtonFormField<
                            String>(
                          initialValue: role,
                          dropdownColor:
                              _panel,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),
                          decoration:
                              _inputDecoration(
                            'Role',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value:
                                  'student',
                              child:
                                  Text('Student'),
                            ),
                            DropdownMenuItem(
                              value:
                                  'teacher',
                              child:
                                  Text('Teacher'),
                            ),
                            DropdownMenuItem(
                              value:
                                  'designer',
                              child:
                                  Text('Designer'),
                            ),
                            DropdownMenuItem(
                              value:
                                  'institution_admin',
                              child:
                                  Text(
                                'Institution Admin',
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                                  'super_admin',
                              child:
                                  Text(
                                'Super Admin',
                              ),
                            ),
                          ],
                          onChanged:
                              isEditingOwnAccount
                                  ? null
                                  : (value) {
                                      if (value !=
                                          null) {
                                        setDialogState(
                                          () {
                                            role =
                                                value;
                                          },
                                        );
                                      }
                                    },
                        ),

                        if (isEditingOwnAccount) ...[
                          const SizedBox(
                            height: 8,
                          ),
                          const Align(
                            alignment:
                                Alignment.centerLeft,
                            child: Text(
                              'Your own Super Admin role cannot be changed here.',
                              style:
                                  TextStyle(
                                color:
                                    Colors.orangeAccent,
                                fontSize:
                                    12,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 14,
                        ),

                        DropdownButtonFormField<
                            String>(
                          initialValue:
                              approvalStatus,
                          dropdownColor:
                              _panel,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),
                          decoration:
                              _inputDecoration(
                            'Approval status',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value:
                                  'pending',
                              child:
                                  Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value:
                                  'approved',
                              child:
                                  Text('Approved'),
                            ),
                            DropdownMenuItem(
                              value:
                                  'rejected',
                              child:
                                  Text('Rejected'),
                            ),
                          ],
                          onChanged:
                              isEditingOwnAccount
                                  ? null
                                  : (value) {
                                      if (value !=
                                          null) {
                                        setDialogState(
                                          () {
                                            approvalStatus =
                                                value;
                                          },
                                        );
                                      }
                                    },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        DropdownButtonFormField<
                            String>(
                          initialValue:
                              accountStatus,
                          dropdownColor:
                              _panel,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),
                          decoration:
                              _inputDecoration(
                            'Account status',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value:
                                  'active',
                              child:
                                  Text('Active'),
                            ),
                            DropdownMenuItem(
                              value:
                                  'blocked',
                              child:
                                  Text('Blocked'),
                            ),
                            DropdownMenuItem(
                              value:
                                  'left',
                              child:
                                  Text('Left'),
                            ),
                          ],
                          onChanged:
                              isEditingOwnAccount
                                  ? null
                                  : (value) {
                                      if (value !=
                                          null) {
                                        setDialogState(
                                          () {
                                            accountStatus =
                                                value;
                                          },
                                        );
                                      }
                                    },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        TextField(
                          controller:
                              levelController,
                          keyboardType:
                              TextInputType.number,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),
                          decoration:
                              _inputDecoration(
                            'NAOS Level',
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        TextField(
                          controller:
                              xpController,
                          keyboardType:
                              TextInputType.number,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),
                          decoration:
                              _inputDecoration(
                            'XP',
                          ),
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFF0B1028,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                            border:
                                Border.all(
                              color:
                                  _border,
                            ),
                          ),
                          child:
                              const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color:
                                    Colors.white54,
                                size: 20,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Password is never displayed. Use Reset password from the user details screen to send a secure recovery email.',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white54,
                                    fontSize:
                                        12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        dialogContext,
                      ).pop();
                    },
                    child:
                        const Text('Cancel'),
                  ),

                  FilledButton(
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          _primary,
                    ),
                    onPressed: () {
                      final displayName =
                          displayController
                              .text
                              .trim();

                      final username =
                          usernameController
                              .text
                              .trim();

                      final level =
                          int.tryParse(
                                levelController
                                    .text
                                    .trim(),
                              ) ??
                              1;

                      final xp =
                          int.tryParse(
                                xpController
                                    .text
                                    .trim(),
                              ) ??
                              0;

                      if (displayName.isEmpty) {
                        _showError(
                          'Display name cannot be empty.',
                        );
                        return;
                      }

                      if (username.isEmpty) {
                        _showError(
                          'Username cannot be empty.',
                        );
                        return;
                      }

                      if (level < 1) {
                        _showError(
                          'NAOS Level must be at least 1.',
                        );
                        return;
                      }

                      if (xp < 0) {
                        _showError(
                          'XP cannot be negative.',
                        );
                        return;
                      }

                      Navigator.of(
                        dialogContext,
                      ).pop({
                        'id': userId,
                        'display_name':
                            displayName,
                        'username':
                            username,
                        'role':
                            role,
                        'approval_status':
                            approvalStatus,
                        'account_status':
                            accountStatus,
                        'naos_level':
                            level,
                        'xp':
                            xp,
                      });
                    },
                    child:
                        const Text(
                      'Save changes',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (editedUser == null) {
        return;
      }

      if (!mounted) return;

      await _saveUserEdits(
        id:
            editedUser['id']
                .toString(),
        displayName:
            editedUser['display_name']
                .toString(),
        username:
            editedUser['username']
                .toString(),
        role:
            editedUser['role']
                .toString(),
        approvalStatus:
            editedUser['approval_status']
                .toString(),
        accountStatus:
            editedUser['account_status']
                .toString(),
        naosLevel:
            editedUser['naos_level']
                as int,
        xp:
            editedUser['xp']
                as int,
      );
    } finally {
      displayController.dispose();
      usernameController.dispose();
      levelController.dispose();
      xpController.dispose();
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(
        color: Colors.white60,
      ),
      filled: true,
      fillColor:
          const Color(0xFF0B1028),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: _border,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: _primary,
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG FIELD
  // ============================================================

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style:
          const TextStyle(
        color: Colors.white,
      ),
      decoration:
          _inputDecoration(label),
    );
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  String _displayName(
    Map<String, dynamic> user,
  ) {
    final value =
        user['display_name']
                ?.toString()
                .trim() ??
            '';

    if (value.isNotEmpty) {
      return value;
    }

    final username =
        user['username']
                ?.toString()
                .trim() ??
            '';

    if (username.isNotEmpty) {
      return username;
    }

    return 'Unnamed User';
  }

  // ============================================================
  // ROLE LABEL
  // ============================================================

  String _roleLabel(
    String role,
  ) {
    switch (role) {
      case 'institution_admin':
        return 'Institution Admin';

      case 'super_admin':
        return 'Super Admin';

      case 'student':
        return 'Student';

      case 'teacher':
        return 'Teacher';

      case 'designer':
        return 'Designer';

      default:
        return role.replaceAll(
          '_',
          ' ',
        );
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'approved':
      case 'active':
        return const Color(
          0xFF35D6B5,
        );

      case 'pending':
        return const Color(
          0xFFFFB84D,
        );

      case 'rejected':
      case 'blocked':
        return const Color(
          0xFFFF5C7A,
        );

      default:
        return Colors.white70;
    }
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(
    String text,
  ) {
    final color =
        _statusColor(text);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(
          color:
              color.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style:
            TextStyle(
          color: color,
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget _filterButton(
    String value,
    String label,
  ) {
    final selected =
        _filter == value;

    return OutlinedButton(
      onPressed: () {
        setState(() {
          _filter = value;
        });
      },
      style:
          OutlinedButton.styleFrom(
        foregroundColor:
            selected
                ? Colors.white
                : Colors.white70,
        backgroundColor:
            selected
                ? const Color(
                    0xFF30358A,
                  )
                : null,
        side:
            BorderSide(
          color:
              selected
                  ? _primary
                  : const Color(
                      0xFF303758,
                    ),
        ),
      ),
      child:
          Text(label),
    );
  }

  // ============================================================
  // ROLE BUTTON
  // ============================================================

  Widget _roleButton(
    String value,
    String label,
  ) {
    final selected =
        _roleFilter == value;

    return ChoiceChip(
      label:
          Text(label),
      selected:
          selected,
      onSelected:
          (_) {
        setState(() {
          _roleFilter = value;
        });
      },
      selectedColor:
          const Color(
        0xFF30358A,
      ),
      backgroundColor:
          const Color(
        0xFF10162F,
      ),
      side:
          const BorderSide(
        color:
            Color(
          0xFF303758,
        ),
      ),
      labelStyle:
          TextStyle(
        color:
            selected
                ? Colors.white
                : Colors.white70,
      ),
    );
  }

  // ============================================================
  // USER CARD
  // ============================================================

  Widget _userCard(
    Map<String, dynamic> user,
  ) {
    final role =
        user['role']
                ?.toString() ??
            'unknown';

    final approval =
        user['approval_status']
                ?.toString() ??
            'pending';

    final account =
        user['account_status']
                ?.toString() ??
            'active';

    final name =
        _displayName(user);

    final username =
        user['username']
                ?.toString()
                .trim() ??
            '';

    return InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: () {
        _showUserDetails(user);
      },
      child:
          Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        decoration:
            BoxDecoration(
          color:
              _panel,
          borderRadius:
              BorderRadius.circular(16),
          border:
              Border.all(
            color:
                _border,
          ),
        ),
        child:
            Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor:
                  const Color(
                0xFF252B63,
              ),
              child:
                  Text(
                name.isNotEmpty
                    ? name[0]
                        .toUpperCase()
                    : '?',
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          15,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (username.isNotEmpty) ...[
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      '@$username',
                      style:
                          const TextStyle(
                        color:
                            Colors.white38,
                        fontSize:
                            12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Wrap(
              spacing: 7,
              runSpacing: 7,
              alignment:
                  WrapAlignment.end,
              children: [
                _statusChip(
                  _roleLabel(role),
                ),
                _statusChip(
                  approval,
                ),
                _statusChip(
                  account,
                ),
              ],
            ),

            const SizedBox(
              width: 10,
            ),

            const Icon(
              Icons.chevron_right,
              color:
                  Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showSuccess(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        backgroundColor:
            const Color(
          0xFF3A1420,
        ),
        content:
            Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final users =
        _filteredUsers;

    return Scaffold(
      backgroundColor:
          _background,

      appBar:
          AppBar(
        title:
            const Text('Users'),

        backgroundColor:
            const Color(
          0xFF0B1028,
        ),

        actions: [
          IconButton(
            tooltip:
                'Refresh',
            onPressed:
                _loadUsers,
            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body:
          Padding(
        padding:
            const EdgeInsets.all(24),

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'User Management',

              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize:
                    28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Manage accounts, roles, access and security.',

              style:
                  TextStyle(
                color:
                    Colors.white60,
                fontSize:
                    14,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            TextField(
              controller:
                  _searchController,

              style:
                  const TextStyle(
                color:
                    Colors.white,
              ),

              decoration:
                  InputDecoration(
                hintText:
                    'Search by name, username, email or role...',

                hintStyle:
                    const TextStyle(
                  color:
                      Colors.white38,
                ),

                prefixIcon:
                    const Icon(
                  Icons.search,
                  color:
                      Colors.white60,
                ),

                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed:
                                _searchController
                                    .clear,
                            icon:
                                const Icon(
                              Icons.close,
                              color:
                                  Colors.white60,
                            ),
                          )
                        : null,

                filled:
                    true,

                fillColor:
                    _panel,

                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        _border,
                  ),
                ),

                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        _primary,
                    width:
                        1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterButton(
                  'all',
                  'All',
                ),
                _filterButton(
                  'pending',
                  'Pending',
                ),
                _filterButton(
                  'approved',
                  'Approved',
                ),
                _filterButton(
                  'blocked',
                  'Blocked',
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            SingleChildScrollView(
              scrollDirection:
                  Axis.horizontal,
              child:
                  Row(
                children: [
                  _roleButton(
                    'all',
                    'All roles',
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _roleButton(
                    'student',
                    'Students',
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _roleButton(
                    'teacher',
                    'Teachers',
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _roleButton(
                    'designer',
                    'Designers',
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _roleButton(
                    'institution_admin',
                    'Institution Admins',
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _roleButton(
                    'super_admin',
                    'Super Admins',
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            if (!_isLoading)
              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child:
                    Text(
                  '${users.length} user${users.length == 1 ? '' : 's'} found',
                  style:
                      const TextStyle(
                    color:
                        Colors.white54,
                    fontSize:
                        13,
                  ),
                ),
              ),

            Expanded(
              child:
                  _isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(),
                        )
                      : users.isEmpty
                          ? const Center(
                              child:
                                  Text(
                                'No users found.',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white60,
                                  fontSize:
                                      16,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount:
                                  users.length,

                              separatorBuilder:
                                  (
                                _,
                                __,
                              ) =>
                                  const SizedBox(
                                height: 10,
                              ),

                              itemBuilder:
                                  (
                                _,
                                index,
                              ) =>
                                  _userCard(
                                users[index],
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
// USER DETAILS DIALOG
// ============================================================================

class _UserDetailsDialog
    extends StatelessWidget {
  const _UserDetailsDialog({
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onBlock,
    required this.onApprove,
    required this.onReject,
    required this.onResetPassword,
  });

  final Map<String, dynamic> user;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onBlock;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onResetPassword;

  static const Color _panel =
      Color(0xFF10162F);

  static const Color _border =
      Color(0xFF28335C);

  String _name() {
    final display =
        user['display_name']
                ?.toString()
                .trim() ??
            '';

    if (display.isNotEmpty) {
      return display;
    }

    final username =
        user['username']
                ?.toString()
                .trim() ??
            '';

    if (username.isNotEmpty) {
      return username;
    }

    return 'Unnamed User';
  }

  String _role() {
    return user['role']
            ?.toString() ??
        'unknown';
  }

  String _prettyRole(
    String role,
  ) {
    return role
        .split('_')
        .map(
          (part) {
            if (part.isEmpty) {
              return part;
            }

            return part[0].toUpperCase() +
                part.substring(1);
          },
        )
        .join(' ');
  }

  String _formatCreatedAt(
    dynamic value,
  ) {
    final raw =
        value?.toString().trim() ??
            '';

    if (raw.isEmpty) {
      return '—';
    }

    final date =
        DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    final local =
        date.toLocal();

    final day =
        local.day
            .toString()
            .padLeft(2, '0');

    final month =
        local.month
            .toString()
            .padLeft(2, '0');

    final year =
        local.year.toString();

    final hour =
        local.hour == 0
            ? 12
            : local.hour > 12
                ? local.hour - 12
                : local.hour;

    final minute =
        local.minute
            .toString()
            .padLeft(2, '0');

    final period =
        local.hour >= 12
            ? 'PM'
            : 'AM';

    return '$day/$month/$year, '
        '$hour:$minute $period';
  }

  Widget _info(
    String label,
    String value,
  ) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),

      padding:
          const EdgeInsets.all(12),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF0B1028,
        ),

        borderRadius:
            BorderRadius.circular(10),

        border:
            Border.all(
          color:
              _border,
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            label,

            style:
                const TextStyle(
              color:
                  Colors.white54,
              fontSize:
                  12,
            ),
          ),

          const Spacer(),

          const SizedBox(
            width: 20,
          ),

          Flexible(
            child:
                Text(
              value.isEmpty
                  ? '—'
                  : value,

              textAlign:
                  TextAlign.right,

              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize:
                    12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final role =
        _role();

    final approval =
        user['approval_status']
                ?.toString() ??
            'pending';

    final account =
        user['account_status']
                ?.toString() ??
            'active';

    final email =
        user['email']
                ?.toString() ??
            '';

    final username =
        user['username']
                ?.toString() ??
            '';

    final createdAt =
        user['created_at'];

    final isSuperAdmin =
        role == 'super_admin';

    final name =
        _name();

    return AlertDialog(
      backgroundColor:
          _panel,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),

      title:
          Row(
        children: [
          CircleAvatar(
            backgroundColor:
                const Color(
              0xFF252B63,
            ),

            child:
                Text(
              name.isNotEmpty
                  ? name[0].toUpperCase()
                  : '?',

              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Text(
              name,

              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      content:
          SizedBox(
        width: 500,

        child:
            SingleChildScrollView(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              _info(
                'Email',
                email,
              ),

              _info(
                'Username',
                username,
              ),

              _info(
                'Role',
                _prettyRole(role),
              ),

              _info(
                'Created',
                _formatCreatedAt(
                  createdAt,
                ),
              ),

              _info(
                'Approval',
                approval,
              ),

              _info(
                'Account',
                account,
              ),

              _info(
                'NAOS level',
                user['naos_level']
                        ?.toString() ??
                    '',
              ),

              _info(
                'XP',
                user['xp']
                        ?.toString() ??
                    '',
              ),

              _info(
                'User ID',
                user['id']
                        ?.toString() ??
                    '',
              ),

              const SizedBox(
                height: 10,
              ),

              const Align(
                alignment:
                    Alignment.centerLeft,

                child:
                    Text(
                  'Security',

                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              const Align(
                alignment:
                    Alignment.centerLeft,

                child:
                    Text(
                  'NAOS never displays the current password. Use "Reset password" to send a secure password recovery email through Supabase Auth.',

                  style:
                      TextStyle(
                    color:
                        Colors.white54,
                    fontSize:
                        12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      actions: [
        // ========================================================
        // RESET PASSWORD
        // ========================================================

        TextButton.icon(
          onPressed:
              onResetPassword,

          icon:
              const Icon(
            Icons.lock_reset_rounded,
            size: 18,
          ),

          label:
              const Text(
            'Reset password',
          ),
        ),

        // ========================================================
        // EDIT
        // ========================================================

        TextButton(
          onPressed:
              onEdit,

          child:
              const Text(
            'Edit',
          ),
        ),

        // ========================================================
        // APPROVE
        // ========================================================

        if (approval == 'pending')
          TextButton(
            onPressed:
                onApprove,

            child:
                const Text(
              'Approve',
            ),
          ),

        // ========================================================
        // REJECT
        // ========================================================

        if (approval == 'pending')
          TextButton(
            onPressed:
                onReject,

            child:
                const Text(
              'Reject',
            ),
          ),

        // ========================================================
        // BLOCK / UNBLOCK
        // ========================================================

        if (!isSuperAdmin)
          TextButton(
            onPressed:
                onBlock,

            child:
                Text(
              account == 'blocked'
                  ? 'Unblock'
                  : 'Block',
            ),
          ),

        // ========================================================
        // DELETE
        // ========================================================

        if (!isSuperAdmin)
          TextButton(
            style:
                TextButton.styleFrom(
              foregroundColor:
                  const Color(
                0xFFFF5C7A,
              ),
            ),

            onPressed:
                onDelete,

            child:
                const Text(
              'Delete permanently',
            ),
          ),

        // ========================================================
        // CLOSE
        // ========================================================

        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },

          child:
              const Text(
            'Close',
          ),
        ),
      ],
    );
  }
}