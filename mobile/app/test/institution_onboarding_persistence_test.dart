import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// HTTP is already locked as a Supabase dependency; used only by the offline fake.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_onboarding_flow_page.dart';

const institutionId = '11111111-1111-4111-8111-111111111111';
const userId = '22222222-2222-4222-8222-222222222222';

class Backend {
  final data = <String, dynamic>{};
  bool linked = false;
  bool failName = false;
  bool failProgress = false;
  int bootstraps = 0;
  Completer<void>? gate;
  final writes = <Map<String, dynamic>>[];
  Map<String, dynamic> structure = {
    'revision': 0,
    'timezone': 'Australia/Brisbane',
    'levels': [],
    'courses': [],
    'classes': [],
  };
  int structureSaves = 0;
  bool failStructure = false;
  final structureRequests = <Map<String, dynamic>>[];
  Future<http.Response> handle(http.Request request) async {
    // Every request goes through this fake, never the project URL.
    expect(request.url.host, 'localhost');
    if (request.url.path.contains('/auth/v1/token')) {
      String part(Object value) =>
          base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      final token =
          '${part({'alg': 'HS256'})}.${part({'sub': userId, 'exp': 4102444800})}.fake';
      return http.Response(
        jsonEncode({
          'access_token': token,
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
        }),
        200,
      );
    }
    if (request.url.path.endsWith('/rpc/bootstrap_institution')) {
      bootstraps++;
      await gate?.future;
      if (failName) {
        return http.Response('{"message":"denied","code":"42501"}', 403);
      }
      linked = true;
      data['name'] = (jsonDecode(request.body) as Map)['p_name'];
      return http.Response(jsonEncode(institutionId), 200);
    }
    if (request.url.path.endsWith('/rpc/get_school_structure')) {
      return http.Response(jsonEncode(structure), 200);
    }
    if (request.url.path.endsWith(
      '/rpc/list_pending_institution_appearance_assets',
    )) {
      return http.Response('[]', 200);
    }
    if (request.url.path.endsWith('/rpc/get_institution_appearance')) {
      return http.Response(
        jsonEncode({
          'appearance': null,
          'assets': <Object>[],
          'template': data['template'],
          'theme_color': data['theme_color'],
          'font_style': data['font_style'],
          'button_style': data['button_style'],
        }),
        200,
      );
    }
    if (request.url.path.endsWith('/rpc/save_school_structure')) {
      final body = jsonDecode(request.body) as Map;
      structureRequests.add(Map<String, dynamic>.from(body));
      if (failStructure) {
        return http.Response(
          '{"message":"structure denied","code":"42501"}',
          403,
        );
      }
      structureSaves++;
      final data = body['p_data'] as Map;
      structure = {
        'revision': structureSaves,
        'timezone': data['timezone'],
        'levels': (data['levels'] as List).map((n) => {'name': n}).toList(),
        'courses': (data['courses'] as List).map((n) => {'name': n}).toList(),
        'classes': [],
      };
      return http.Response(jsonEncode(structureSaves), 200);
    }
    if (request.url.path.endsWith('/institution_admins')) {
      expect(request.method, 'GET'); // No client-side relation writes.
      final relation = {
        'id': '33333333-3333-4333-8333-333333333333',
        'institution_id': institutionId,
        'is_active': true,
      };
      final single =
          request.headers['accept']?.contains('vnd.pgrst.object') == true;
      return http.Response(
        jsonEncode(single ? relation : (linked ? [relation] : [])),
        200,
      );
    }
    if (request.url.path.endsWith('/institution_memberships')) {
      expect(request.method, 'GET');
      return http.Response('[]', 200);
    }
    if (request.url.path.endsWith('/institutions')) {
      if (request.method == 'PATCH') {
        final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        if (failName && body.containsKey('name')) {
          return http.Response('{"message":"denied","code":"42501"}', 403);
        }
        if (failProgress && body.containsKey('onboarding_step')) {
          return http.Response(
            '{"message":"progress denied","code":"42501"}',
            403,
          );
        }
        writes.add(body);
        data.addAll(body);
      }
      final row = {'id': institutionId, ...data};
      return http.Response(
        jsonEncode(request.method == 'PATCH' ? row : [row]),
        200,
      );
    }
    throw StateError('Unexpected request: ${request.method} ${request.url}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Backend backend;
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
        final response = await backend.handle(request);
        return http.Response(
          response.body,
          response.statusCode,
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
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'synthetic@example.invalid',
      password: 'fake',
    );
  }

  setUp(() async {
    backend = Backend();
    await initialize();
  });
  tearDown(() async {
    await Supabase.instance.dispose();
  });

  Future<void> click(WidgetTester tester, String label) async {
    final target = find.text(label).last;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> openName(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // The test engine's Ahem font is wider than the app font. These are persistence
    // tests, not golden/layout tests; keep the existing fixed-width buttons usable.
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.85)),
          child: child!,
        ),
        home: const InstitutionOnboardingFlowPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await click(tester, 'Begin the journey');
    expect(find.text('Step 2 of 9'), findsOneWidget);
    expect(find.text('Welcome, Administrator.'), findsNothing);
    await click(tester, 'Back');
    expect(find.text('Begin the journey'), findsOneWidget);
    await click(tester, 'Begin the journey');
    expect(find.text('Step 2 of 9'), findsOneWidget);
    await click(tester, "Let's build it");
  }

  String value(WidgetTester tester, int index) => tester
      .widget<TextField>(find.byType(TextField).at(index))
      .controller!
      .text;

  testWidgets(
    'Continue waits for pending bootstrap; latest name persists once',
    (tester) async {
      backend.gate = Completer<void>();
      await openName(tester);
      await tester.enterText(find.byType(TextField).first, 'First name');
      await tester.pump(const Duration(milliseconds: 750));
      expect(backend.bootstraps, 1);
      await tester.enterText(find.byType(TextField).first, 'Latest name');
      await click(tester, 'Continue');
      expect(find.text('School name'), findsOneWidget);
      await click(tester, 'Continue');
      expect(backend.bootstraps, 1);
      backend.gate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(backend.data['name'], 'Latest name');
      expect(find.text('Slogan'), findsOneWidget);
      expect(backend.bootstraps, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Failed bootstrap and failed existing update cannot advance', (
    tester,
  ) async {
    backend.failName = true;
    backend.gate = Completer<void>();
    await openName(tester);
    await tester.enterText(find.byType(TextField).first, 'Retry school');
    await tester.pump(const Duration(milliseconds: 750));
    await click(tester, 'Continue');
    expect(backend.bootstraps, 1);
    backend.gate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('School name'), findsOneWidget);
    expect(backend.data['onboarding_step'], isNull);
    backend.failName = false;
    backend.gate = null;
    await click(tester, 'Continue');
    expect(find.text('Slogan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    backend.failName = true;
    backend.data['onboarding_step'] = 0;
    await openName(tester);
    await tester.enterText(find.byType(TextField).first, 'Denied change');
    await click(tester, 'Continue');
    expect(find.text('School name'), findsOneWidget);
    expect(backend.data['name'], 'Retry school');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Levels and Courses save together on Continue and survive back/forward steps',
    (tester) async {
      backend.linked = true;
      backend.data['name'] = 'Existing school';
      await openName(tester);
      await click(tester, 'Continue');
      await click(tester, 'Continue');
      await click(tester, 'Build my school');
      final writesBefore = backend.writes.length;
      await tester.tap(find.byKey(const ValueKey('suggestion-A1')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(
        find.byKey(const ValueKey('custom-level-name')),
        'Foundation',
      );
      await tester.tap(find.byKey(const ValueKey('add-custom-level')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('2 / 10 levels'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('course-suggestion-General English')),
      );
      await tester.tap(
        find.byKey(const ValueKey('course-suggestion-General English')),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.ensureVisible(
        find.byKey(const ValueKey('custom-course-name')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('custom-course-name')),
        'Travel English',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('add-custom-course')),
      );
      await tester.tap(find.byKey(const ValueKey('add-custom-course')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('2 / 10 courses'), findsOneWidget);
      expect(backend.writes.length, writesBefore);
      await tester.ensureVisible(find.text('Continue').last);
      await click(tester, 'Continue');
      await click(tester, 'Back');
      expect(backend.structureSaves, 1);
      expect(find.text('2 / 10 levels'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('level-row-Foundation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('course-row-Travel English')),
        findsOneWidget,
      );
      // Navigation only writes progress fields; levels never enter that payload.
      expect(
        backend.writes
            .skip(writesBefore)
            .every(
              (body) => body.keys.every(
                (key) =>
                    key == 'onboarding_step' || key == 'onboarding_completed',
              ),
            ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Existing name, Identity and Location save and reload', (
    tester,
  ) async {
    backend.linked = true;
    backend.data.addAll({
      'name': 'Existing school',
      'logo_url': 'http://localhost/logo.png?v=42',
    });
    await openName(tester);
    expect(value(tester, 0), 'Existing school');
    await tester.enterText(find.byType(TextField).first, 'Renamed school');
    await click(tester, 'Continue');
    await tester.enterText(find.byType(TextField).at(0), 'Our slogan');
    await tester.enterText(find.byType(TextField).at(1), 'Our description');
    await click(tester, 'Continue');
    await tester.enterText(find.byType(TextField).at(0), 'Australia');
    await tester.enterText(find.byType(TextField).at(1), 'Brisbane');
    await tester.enterText(find.byType(TextField).at(2), 'Test address');
    await click(tester, 'Build my school');
    expect(backend.bootstraps, 0);
    expect(backend.data['logo_url'], 'http://localhost/logo.png?v=42');
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await Supabase.instance.dispose();
      await initialize(); // New session for the same synthetic user.
    });
    backend.data['onboarding_step'] = 0;
    await openName(tester);
    expect(value(tester, 0), 'Renamed school');
    await click(tester, 'Continue');
    expect(value(tester, 0), 'Our slogan');
    expect(value(tester, 1), 'Our description');
    await click(tester, 'Continue');
    expect(value(tester, 0), 'Australia');
    expect(value(tester, 1), 'Brisbane');
    expect(value(tester, 2), 'Test address');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Failed structure save keeps draft and does not advance; retry reuses request',
    (tester) async {
      backend.linked = true;
      backend.data['name'] = 'Existing school';
      await openName(tester);
      await click(tester, 'Continue');
      await click(tester, 'Continue');
      await click(tester, 'Build my school');
      await tester.tap(find.byKey(const ValueKey('suggestion-A1')));
      await tester.pump(const Duration(milliseconds: 600));
      backend.failStructure = true;
      await tester.ensureVisible(find.text('Continue').last);
      await click(tester, 'Continue');
      expect(find.text('BUILD YOUR SCHOOL'), findsOneWidget);
      expect(find.text('1 / 10 levels'), findsOneWidget);
      expect(backend.structureSaves, 0);
      backend.failStructure = false;
      await tester.ensureVisible(find.text('Continue').last);
      await click(tester, 'Continue');
      expect(find.text('YOUR NAOS TOOLS'), findsOneWidget);
      expect(backend.structureRequests.length, 2);
      expect(backend.structureRequests[0], backend.structureRequests[1]);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('saved step resumes and a failed progress write cannot advance', (
    tester,
  ) async {
    backend.linked = true;
    backend.data.addAll({
      'name': 'Test School 2',
      'onboarding_step': 8,
      'onboarding_completed': false,
    });
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.85)),
          child: child!,
        ),
        home: const InstitutionOnboardingFlowPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('MAKE IT YOURS'), findsOneWidget);
    expect(find.text('Step 8 of 9'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    backend.data['onboarding_step'] = 2;
    backend.failProgress = true;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.85)),
          child: child!,
        ),
        home: const InstitutionOnboardingFlowPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await click(tester, "Let's build it");
    expect(find.text('WHAT IS NAOS?'), findsOneWidget);
    expect(
      find.text('Could not save your onboarding progress. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'legacy step maps to Welcome and completed setup is not downgraded',
    (tester) async {
      backend.linked = true;
      backend.data.addAll({
        'name': 'Test School 2',
        'onboarding_step': 1,
        'onboarding_completed': false,
      });
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(0.85)),
            child: child!,
          ),
          home: const InstitutionOnboardingFlowPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Begin the journey'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      backend.data['onboarding_step'] = 9;
      backend.data['onboarding_completed'] = true;
      final writesBefore = backend.writes.length;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(0.85)),
            child: child!,
          ),
          home: const InstitutionOnboardingFlowPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Enter NAOS'), findsOneWidget);
      await click(tester, 'Back');
      await click(tester, 'Finish setup');
      expect(backend.writes.length, writesBefore);
      expect(backend.data['onboarding_completed'], true);
      expect(backend.data['onboarding_step'], 9);
    },
  );
}
