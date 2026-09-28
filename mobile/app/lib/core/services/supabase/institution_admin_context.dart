import 'package:supabase_flutter/supabase_flutter.dart';

class InstitutionAdminContext {
  const InstitutionAdminContext({
    required this.userId,
    this.adminLinkId,
    this.institutionId,
    this.activeMembershipId,
  });

  final String userId;
  final String? adminLinkId;
  final String? institutionId;
  final String? activeMembershipId;

  bool get needsInstitution => institutionId == null;
}

class InstitutionAdminContextException implements Exception {
  const InstitutionAdminContextException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Resolves the school-admin context without choosing an arbitrary relation.
///
/// `institution_admins` is the authoritative link. An active administrative
/// membership is optional for a newly approved, not-yet-linked administrator,
/// but when it exists it must point to the same institution.
class InstitutionAdminContextResolver {
  const InstitutionAdminContextResolver(this.client);

  final SupabaseClient client;

  Future<InstitutionAdminContext> resolve(String userId) async {
    final adminResponse = await client
        .from('institution_admins')
        .select('id, institution_id, is_active')
        .eq('user_id', userId);
    final adminLinks = List<Map<String, dynamic>>.from(adminResponse as List);

    if (adminLinks.length > 1) {
      throw const InstitutionAdminContextException(
        'Multiple institution administrator links were found. '
        'An administrator must review them before you can continue.',
      );
    }

    final adminLink = adminLinks.singleOrNull;
    if (adminLink != null && adminLink['is_active'] != true) {
      throw const InstitutionAdminContextException(
        'The institution administrator link is inactive.',
      );
    }

    final membershipResponse = await client
        .from('institution_memberships')
        .select('id, institution_id, status, requested_role')
        .eq('user_id', userId)
        .eq('requested_role', 'institution_admin');
    final memberships = List<Map<String, dynamic>>.from(
      membershipResponse as List,
    );
    final activeMemberships = memberships
        .where((membership) => membership['status'] == 'active')
        .toList();

    if (activeMemberships.length > 1) {
      throw const InstitutionAdminContextException(
        'Multiple active institution administrator memberships were found. '
        'An administrator must review them before you can continue.',
      );
    }

    final institutionId = _text(adminLink?['institution_id']);
    final membership = activeMemberships.singleOrNull;
    final membershipInstitutionId = _text(membership?['institution_id']);

    if (institutionId == null && membershipInstitutionId != null) {
      throw const InstitutionAdminContextException(
        'The administrator link has no institution, but an active '
        'administrative membership points to a school.',
      );
    }

    if (institutionId != null &&
        membershipInstitutionId != null &&
        membershipInstitutionId != institutionId) {
      throw InstitutionAdminContextException(
        'The administrator link and active membership point to different '
        'institutions ($institutionId vs $membershipInstitutionId).',
      );
    }

    return InstitutionAdminContext(
      userId: userId,
      adminLinkId: _text(adminLink?['id']),
      institutionId: institutionId,
      activeMembershipId: _text(membership?['id']),
    );
  }

  String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
