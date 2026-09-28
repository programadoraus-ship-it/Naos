import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:app/features/institution_onboarding/presentation/pages/courses_editor.dart';
import 'package:app/features/institution_onboarding/presentation/pages/english_levels_editor.dart';
import 'package:app/features/institution_onboarding/presentation/pages/school_structure_draft.dart';
import 'package:app/features/institution_onboarding/presentation/pages/classes_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EnglishLevelsDraft levels;
  late CoursesDraft courses;
  late SchoolStructureDraft draft;
  setUp(() {
    levels = EnglishLevelsDraft();
    courses = CoursesDraft();
    draft = SchoolStructureDraft(levels, courses);
  });
  tearDown(() {
    draft.dispose();
    levels.dispose();
    courses.dispose();
  });
  SchoolClass sample({String shift = 'morning'}) => SchoolClass(
    name: 'Class A',
    course: 'General English',
    level: 'A1',
    shift: shift,
    days: [1, 3],
    start: '09:00',
    end: '10:00',
  );

  test(
    'classes allow repeated names/shifts and >10; orphan references block save',
    () {
      levels.add('A1');
      courses.add('General English');
      for (var i = 0; i < 12; i++) {
        expect(
          draft.put(sample(shift: i.isEven ? 'morning' : 'afternoon')),
          isNull,
        );
      }
      expect(draft.classes.length, 12);
      final original = draft.classes.first;
      expect(
        draft.put(
          SchoolClass(
            id: original.id,
            name: 'Edited',
            course: original.course,
            level: original.level,
            shift: original.shift,
            days: [2],
            start: '12:00',
            end: '13:00',
          ),
        ),
        isNull,
      );
      expect(draft.classes.length, 12);
      expect(draft.classes.first.name, 'Edited');
      levels.remove('A1');
      expect(
        draft.classes.first.validate(courses.courses, levels.levels),
        isNotNull,
      );
      draft.remove(original.id);
      expect(draft.classes.length, 11);
    },
  );

  test(
    'save failure retains draft/request; retry and fresh-controller reload roundtrip',
    () async {
      var stored = <String, dynamic>{
        'revision': 0,
        'timezone': 'Australia/Brisbane',
        'levels': [],
        'courses': [],
        'classes': [],
      };
      final requests = <Map<String, dynamic>>[];
      var fail = true;
      final client = SupabaseClient(
        'http://localhost:9999',
        'test',
        httpClient: MockClient((request) async {
          expect(request.url.host, 'localhost');
          if (request.url.path.endsWith('get_school_structure')) {
            return http.Response(
              jsonEncode(stored),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          final body = Map<String, dynamic>.from(
            jsonDecode(request.body) as Map,
          );
          requests.add(body);
          if (fail) {
            return http.Response(
              '{"message":"temporary failure","code":"XX000"}',
              500,
              request: request,
            );
          }
          final data = body['p_data'] as Map;
          stored = {
            'revision': 1,
            'timezone': data['timezone'],
            'levels': (data['levels'] as List).map((n) => {'name': n}).toList(),
            'courses': (data['courses'] as List)
                .map((n) => {'name': n})
                .toList(),
            'classes': (data['classes'] as List)
                .map(
                  (c) => {
                    ...c,
                    'schedules': (c['days'] as List)
                        .map(
                          (d) => {
                            'day': d,
                            'start': c['start'],
                            'end': c['end'],
                            'timezone': data['timezone'],
                          },
                        )
                        .toList(),
                  },
                )
                .toList(),
          };
          return http.Response(
            '1',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await draft.load(client, 'institution-A');
      expect(draft.loaded, isTrue, reason: draft.error);
      levels.add('A1');
      courses.add('General English');
      draft.put(sample());
      draft.setTimezone('Europe/Madrid');
      expect(await draft.save(client, 'institution-A'), isFalse);
      expect(draft.classes.length, 1);
      expect(draft.dirty, isTrue);
      expect(draft.error, isNotNull);
      fail = false;
      expect(
        await draft.save(client, 'institution-A'),
        isTrue,
        reason: draft.error,
      );
      expect(requests[0], requests[1]);
      expect(draft.revision, 1);
      final l = EnglishLevelsDraft(), c = CoursesDraft();
      final reloaded = SchoolStructureDraft(l, c);
      await reloaded.load(client, 'institution-A');
      expect(l.levels, ['A1']);
      expect(c.courses, ['General English']);
      expect(reloaded.classes.single.toJson(), draft.classes.single.toJson());
      expect(reloaded.timezone, 'Europe/Madrid');
      reloaded.dispose();
      l.dispose();
      c.dispose();
    },
  );

  test(
    'failed load never becomes empty writable snapshot; unsupported schedules preserved',
    () async {
      final client = SupabaseClient(
        'http://localhost:9999',
        'test',
        httpClient: MockClient(
          (request) async =>
              http.Response('{"message":"RPC missing","code":"PGRST202"}', 404),
        ),
      );
      addTearDown(client.dispose);
      await draft.load(client, 'A');
      expect(draft.loaded, isFalse);
      expect(await draft.save(client, 'A'), isFalse);
      expect(
        () => SchoolClass.fromJson({
          'id': 'x',
          'name': 'Legacy',
          'course': 'Course',
          'schedules': [
            {'day': 1, 'start': '09:00', 'end': '10:00', 'timezone': 'UTC'},
            {'day': 2, 'start': '11:00', 'end': '12:00', 'timezone': 'UTC'},
          ],
        }),
        throwsStateError,
      );
    },
  );

  testWidgets(
    'class dialog creates, edits, removes and validates without defaults',
    (tester) async {
      levels.add('A1');
      courses.add('General English');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ClassesEditor(draft: draft)),
          ),
        ),
      );
      expect(draft.classes, isEmpty);
      await tester.tap(find.byKey(const ValueKey('add-class')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-class')));
      await tester.pump();
      expect(find.text('Enter a class name.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('class-name')),
        'Class A',
      );
      for (final entry in {
        'class-course': 'General English',
        'class-level': 'A1',
        'class-shift': 'Morning',
      }.entries) {
        await tester.tap(find.byKey(ValueKey(entry.key)));
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.value).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Mon'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm-class')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      expect(draft.classes.length, 1);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('class-name')),
        'Class A updated',
      );
      await tester.tap(find.byKey(const ValueKey('confirm-class')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      expect(draft.classes.single.name, 'Class A updated');
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(draft.classes, isEmpty);
    },
  );
}
