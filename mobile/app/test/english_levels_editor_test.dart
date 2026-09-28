import 'package:app/features/institution_onboarding/presentation/pages/english_levels_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'draft starts empty; CEFR ascending, custom trimmed, duplicates rejected',
    () {
      final draft = EnglishLevelsDraft();
      addTearDown(draft.dispose);
      expect(draft.levels, isEmpty);
      draft.add('B1');
      draft.add(' a1 ');
      draft.add('Foundation');
      expect(draft.levels, ['A1', 'B1', 'Foundation']);
      expect(draft.add(' foundation '), isNotNull);
      expect(draft.add('  '), isNotNull);
      draft.move(2, -1);
      expect(draft.levels, ['A1', 'Foundation', 'B1']);
      draft.move(0, -1);
      draft.move(2, 1);
      expect(draft.levels, ['A1', 'Foundation', 'B1']);
      expect(
        () => draft.levels.add('illegal mutation'),
        throwsUnsupportedError,
      );
    },
  );

  test('suggested and custom levels share limit; removal frees a slot', () {
    final draft = EnglishLevelsDraft();
    addTearDown(draft.dispose);
    for (final name in EnglishLevelsDraft.suggestions) {
      draft.add(name);
    }
    for (var i = 0; i < 4; i++) {
      draft.add('Custom $i');
    }
    expect(draft.levels, hasLength(10));
    expect(draft.add('Eleventh'), isNotNull);
    draft.remove('A1');
    expect(draft.add('Eleventh'), isNull);
    expect(draft.levels, hasLength(10));
  });

  Future<void> show(WidgetTester tester, EnglishLevelsDraft draft) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF14132C),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: EnglishLevelsEditor(draft: draft),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'select, create, reorder, remove; draft survives editor remount',
    (tester) async {
      final draft = EnglishLevelsDraft();
      addTearDown(draft.dispose);
      await show(tester, draft);
      expect(
        find.text('Local preview · Not saved to Supabase'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('suggestion-B1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('suggestion-A1')));
      await tester.enterText(
        find.byKey(const ValueKey('custom-level-name')),
        ' Foundation ',
      );
      await tester.tap(find.byKey(const ValueKey('add-custom-level')));
      await tester.pumpAndSettle();
      expect(draft.levels, ['A1', 'B1', 'Foundation']);
      await tester.ensureVisible(find.byTooltip('Move Foundation up'));
      await tester.tap(find.byTooltip('Move Foundation up'));
      await tester.pumpAndSettle();
      expect(draft.levels, ['A1', 'Foundation', 'B1']);
      await tester.tap(find.byTooltip('Remove Foundation'));
      await tester.pumpAndSettle();
      expect(draft.levels, ['A1', 'B1']);
      await tester.pumpWidget(const SizedBox());
      await show(tester, draft);
      expect(find.text('2 / 10 levels'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      final fresh = EnglishLevelsDraft();
      addTearDown(fresh.dispose);
      await show(tester, fresh);
      expect(find.text('0 / 10 levels'), findsOneWidget);
    },
  );

  testWidgets(
    'empty/duplicate errors; limit blocks button and keyboard submit',
    (tester) async {
      final draft = EnglishLevelsDraft();
      addTearDown(draft.dispose);
      await show(tester, draft);
      await tester.tap(find.byKey(const ValueKey('add-custom-level')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a level name.'), findsOneWidget);
      draft.add('A1');
      await tester.enterText(
        find.byKey(const ValueKey('custom-level-name')),
        'a1',
      );
      await tester.tap(find.byKey(const ValueKey('add-custom-level')));
      await tester.pumpAndSettle();
      expect(find.text('This level is already selected.'), findsOneWidget);
      for (var i = 0; i < 9; i++) {
        draft.add('Custom $i');
      }
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('add-custom-level')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilterChip>(find.byKey(const ValueKey('suggestion-A2')))
            .onSelected,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('custom-level-name')),
        'Eleventh',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(draft.levels, hasLength(10));
      expect(find.text('You can select up to 10 levels.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('suggestion-A1')));
      await tester.tap(find.byKey(const ValueKey('suggestion-A1')));
      await tester.pumpAndSettle();
      expect(draft.levels, hasLength(9));
    },
  );

  testWidgets(
    'small screen with ten levels and long custom name scrolls without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final draft = EnglishLevelsDraft();
      addTearDown(draft.dispose);
      for (var i = 0; i < 10; i++) {
        draft.add('Custom foundation level with a long name $i');
      }
      await show(tester, draft);
      await tester.ensureVisible(find.byTooltip('Remove ${draft.levels.last}'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Remove ${draft.levels.last}'));
      await tester.pumpAndSettle();
      expect(draft.levels, hasLength(9));
    },
  );
}
