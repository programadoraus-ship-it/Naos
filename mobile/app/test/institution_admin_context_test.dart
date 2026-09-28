import 'dart:convert';

import 'package:app/core/services/supabase/institution_admin_context.dart';
import 'package:app/features/institution_onboarding/domain/institution_onboarding_progress.dart';
import 'package:flutter_test/flutter_test.dart';
// HTTP is already locked as a Supabase dependency; used only by the offline fake.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const userId = '22222222-2222-4222-8222-222222222222';
const testSchoolId = '11111111-1111-4111-8111-111111111111';
const otherSchoolId = '99999999-9999-4999-8999-999999999999';

SupabaseClient clientFor({
  required List<Map<String, dynamic>> adminLinks,
  required List<Map<String, dynamic>> memberships,
}) {
  return SupabaseClient(
    'http://localhost:54321',
    'fake-key',
    httpClient: MockClient((request) async {
      final body = switch (request.url.pathSegments.last) {
        'institution_admins' => adminLinks,
        'institution_memberships' => memberships,
        _ => throw StateError('Unexpected request: ${request.url}'),
      };
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }),
  );
}

Map<String, dynamic> admin(String? institutionId) => {
  'id': '33333333-3333-4333-8333-333333333333',
  'institution_id': institutionId,
  'is_active': true,
};

Map<String, dynamic> membership(String institutionId, {String? id}) => {
  'id': id ?? '44444444-4444-4444-8444-444444444444',
  'institution_id': institutionId,
  'status': 'active',
  'requested_role': 'institution_admin',
};

void main() {
  test(
    'uses the active institution_admin link when membership agrees',
    () async {
      final context = await InstitutionAdminContextResolver(
        clientFor(
          adminLinks: [admin(testSchoolId)],
          memberships: [membership(testSchoolId)],
        ),
      ).resolve(userId);

      expect(context.institutionId, testSchoolId);
      expect(context.activeMembershipId, isNotNull);
    },
  );

  test(
    'allows an approved administrator before initial institution link',
    () async {
      final context = await InstitutionAdminContextResolver(
        clientFor(adminLinks: const [], memberships: const []),
      ).resolve(userId);

      expect(context.needsInstitution, isTrue);
    },
  );

  test('rejects contradictory institutions instead of choosing one', () async {
    await expectLater(
      InstitutionAdminContextResolver(
        clientFor(
          adminLinks: [admin(testSchoolId)],
          memberships: [membership(otherSchoolId)],
        ),
      ).resolve(userId),
      throwsA(
        isA<InstitutionAdminContextException>().having(
          (error) => error.message,
          'message',
          contains('different institutions'),
        ),
      ),
    );
  });

  test('rejects multiple links and multiple active memberships', () async {
    await expectLater(
      InstitutionAdminContextResolver(
        clientFor(
          adminLinks: [admin(testSchoolId), admin(testSchoolId)],
          memberships: const [],
        ),
      ).resolve(userId),
      throwsA(isA<InstitutionAdminContextException>()),
    );

    await expectLater(
      InstitutionAdminContextResolver(
        clientFor(
          adminLinks: [admin(testSchoolId)],
          memberships: [
            membership(testSchoolId),
            membership(
              testSchoolId,
              id: '55555555-5555-4555-8555-555555555555',
            ),
          ],
        ),
      ).resolve(userId),
      throwsA(isA<InstitutionAdminContextException>()),
    );
  });

  test('normalizes legacy and inconsistent onboarding progress explicitly', () {
    final legacy = InstitutionOnboardingProgress.fromValues(
      step: 1,
      completed: false,
    );
    expect(legacy.resumeStep, 0);
    expect(legacy.isCompleted, isFalse);

    final inconsistent = InstitutionOnboardingProgress.fromValues(
      step: 6,
      completed: true,
    );
    expect(inconsistent.resumeStep, 6);
    expect(inconsistent.isCompleted, isFalse);
    expect(inconsistent.isInconsistent, isTrue);

    final pendingMakeItYours = InstitutionOnboardingProgress.fromValues(
      step: 8,
      completed: false,
    );
    expect(pendingMakeItYours.resumeStep, 8);
    expect(pendingMakeItYours.isCompleted, isFalse);

    final completed = InstitutionOnboardingProgress.fromValues(
      step: 9,
      completed: true,
    );
    expect(completed.isCompleted, isTrue);
  });
}
