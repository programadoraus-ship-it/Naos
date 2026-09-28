import 'dart:convert';

import 'package:app/core/navigation/app_router.dart';
import 'package:app/features/auth/presentation/pages/login_page.dart';
import 'package:app/features/onboarding/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// HTTP is already locked as a Supabase dependency; used only by the offline fake.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const userId = '22222222-2222-4222-8222-222222222222';
const institutionId = '11111111-1111-4111-8111-111111111111';

String token() {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'sub': userId, 'exp': 4102444800})}.fake';
}

Future<void> initialize() async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (call) async => call.method == 'getAll' ? <String, Object>{} : true,
      );
  await Supabase.initialize(
    url: 'http://localhost:54321',
    publishableKey: 'fake-key',
    httpClient: MockClient((request) async {
      Object body;
      if (request.url.path.contains('/auth/v1/token')) {
        body = {
          'access_token': token(),
          'refresh_token': 'fake',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': userId,
            'aud': 'authenticated',
            'role': 'authenticated',
            'email': 'synthetic@example.invalid',
            'app_metadata': {},
            'user_metadata': {},
            'created_at': '2026-01-01T00:00:00Z',
          },
        };
      } else if (request.url.path.endsWith('/profiles')) {
        body = {'id': userId, 'role': 'institution_admin'};
      } else if (request.url.path.endsWith('/institution_admins')) {
        body = [
          {
            'id': '33333333-3333-4333-8333-333333333333',
            'institution_id': institutionId,
            'is_active': true,
          },
        ];
      } else if (request.url.path.endsWith('/institution_memberships')) {
        body = [
          {
            'id': '44444444-4444-4444-8444-444444444444',
            'institution_id': institutionId,
            'status': 'active',
            'requested_role': 'institution_admin',
          },
        ];
      } else if (request.url.path.endsWith('/institutions')) {
        body = {
          'id': institutionId,
          'name': 'Test School 2',
          'onboarding_completed': false,
          'onboarding_step': 8,
        };
      } else {
        throw StateError(
          'Unexpected request: ${request.method} ${request.url}',
        );
      }
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }),
    authOptions: const FlutterAuthClientOptions(
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUri: false,
    ),
  );
}

Widget app(Widget home) => MaterialApp(
  home: home,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(0.7)),
    child: child!,
  ),
  routes: {
    AppRouter.institutionOnboardingWelcome: (_) =>
        const Scaffold(body: Text('ONBOARDING ROUTE')),
    AppRouter.institutionAdmin: (_) =>
        const Scaffold(body: Text('DASHBOARD ROUTE')),
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initialize();
  });

  tearDown(() async {
    await Supabase.instance.dispose();
  });

  testWidgets('login resumes pending institution onboarding', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const LoginPage()));
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'synthetic@example.invalid',
      password: 'fake',
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ONBOARDING ROUTE'), findsOneWidget);
    expect(find.text('DASHBOARD ROUTE'), findsNothing);
  });

  testWidgets('restored session resumes the same pending onboarding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'synthetic@example.invalid',
      password: 'fake',
    );
    await tester.pumpWidget(app(const SplashPage()));
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ONBOARDING ROUTE'), findsOneWidget);
    expect(find.text('DASHBOARD ROUTE'), findsNothing);
  });
}
