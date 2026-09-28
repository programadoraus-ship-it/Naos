import 'package:app/features/institution_onboarding/presentation/pages/courses_editor.dart';
import 'package:app/features/institution_onboarding/presentation/pages/english_levels_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'courses: presets/custom share limit, duplicates, empty, removal; no sorting',
    () {
      final draft = CoursesDraft();
      addTearDown(draft.dispose);
      expect(draft.courses, isEmpty);
      draft.add('Business English');
      draft.add(' general english ');
      expect(draft.courses, ['Business English', 'General English']);
      expect(draft.add(' GENERAL ENGLISH '), isNotNull);
      expect(draft.add(' \t '), isNotNull);
      for (var i = 0; i < 8; i++) {
        expect(draft.add('Course $i'), isNull);
      }
      expect(draft.add('Eleventh'), isNotNull);
      draft.remove('Business English');
      expect(draft.add('Eleventh'), isNull);
      expect(draft.courses.length, 10);
      expect(() => draft.courses.add('Mutate'), throwsUnsupportedError);
    },
  );

  Future<void> show(
    WidgetTester tester,
    Widget child, {
    bool reduced = false,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reduced,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFF14132C),
            body: SingleChildScrollView(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('preset selection, custom add/remove, draft survives remount', (
    tester,
  ) async {
    final draft = CoursesDraft();
    addTearDown(draft.dispose);
    await show(tester, CoursesEditor(draft: draft));
    for (final name in CoursesDraft.suggestions) {
      await tap(tester, find.byKey(ValueKey('course-suggestion-$name')));
    }
    expect(draft.courses, CoursesDraft.suggestions);
    expect(find.text('Local preview · Not saved to Supabase'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('custom-course-name')),
      ' English for Travel ',
    );
    await tap(tester, find.byKey(const ValueKey('add-custom-course')));
    expect(draft.courses.last, 'English for Travel');
    expect(find.byTooltip('Move General English up'), findsNothing);
    await tap(tester, find.byTooltip('Remove General English'));
    await tap(tester, find.byTooltip('Remove English for Travel'));
    expect(draft.courses.length, 4);
    await tester.pumpWidget(const SizedBox());
    await show(tester, CoursesEditor(draft: draft));
    expect(find.text('4 / 10 courses'), findsOneWidget);
  });

  testWidgets(
    'courses errors, button and keyboard limit, selected chip can free slot',
    (tester) async {
      final draft = CoursesDraft();
      addTearDown(draft.dispose);
      await show(tester, CoursesEditor(draft: draft));
      await tap(tester, find.byKey(const ValueKey('add-custom-course')));
      expect(find.text('Enter a course name.'), findsOneWidget);
      draft.add('Academic English');
      await tester.enterText(
        find.byKey(const ValueKey('custom-course-name')),
        'academic english',
      );
      await tap(tester, find.byKey(const ValueKey('add-custom-course')));
      expect(find.text('This course is already selected.'), findsOneWidget);
      for (var i = 0; i < 9; i++) {
        draft.add('Custom $i');
      }
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('add-custom-course')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('course-suggestion-General English')),
            )
            .onSelected,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('custom-course-name')),
        'Eleventh',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(draft.courses.length, 10);
      expect(find.text('You can select up to 10 courses.'), findsOneWidget);
      await tap(
        tester,
        find.byKey(const ValueKey('course-suggestion-Academic English')),
      );
      expect(draft.courses.length, 9);
    },
  );

  for (final reduced in [false, true]) {
    testWidgets('list/chip animations respect reduced motion=$reduced', (
      tester,
    ) async {
      final draft = EnglishLevelsDraft();
      addTearDown(draft.dispose);
      await show(tester, EnglishLevelsEditor(draft: draft), reduced: reduced);
      final chip = tester.widget<FilterChip>(
        find.byKey(const ValueKey('suggestion-A1')),
      );
      expect(
        chip.chipAnimationStyle!.selectAnimation!.duration,
        reduced ? Duration.zero : const Duration(milliseconds: 220),
      );
      draft.add('A1');
      draft.add('B1');
      await tester.pump();
      expect(
        find.byKey(const ValueKey('levels-transition')),
        reduced ? findsNothing : findsOneWidget,
      );
      await tester.pumpAndSettle();
      draft.move(1, -1);
      await tester.pump();
      if (reduced) {
        expect(tester.hasRunningAnimations, isFalse);
      }
      await tester.pumpAndSettle();
      expect(draft.levels, ['B1', 'A1']);
      draft.remove('A1');
      await tester.pump();
      if (reduced) {
        expect(find.byKey(const ValueKey('level-row-A1')), findsNothing);
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('level-row-A1')), findsNothing);
    });
  }

  testWidgets(
    'Courses narrow screen, large text, long names and ten selections',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final draft = CoursesDraft();
      addTearDown(draft.dispose);
      for (final name in CoursesDraft.suggestions) {
        draft.add(name);
      }
      for (var i = 0; i < 5; i++) {
        draft.add('A long custom course name for beginners $i');
      }
      await show(tester, CoursesEditor(draft: draft), scale: 1.5);
      await tester.ensureVisible(
        find.byTooltip('Remove ${draft.courses.last}'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
