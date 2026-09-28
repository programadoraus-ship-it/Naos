import 'package:app/features/institution_onboarding/presentation/pages/institution_timezone_picker.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_timezones.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalogue has distinct IANA identifiers and regional choices', () {
    expect(
      institutionTimezones.map((z) => z.$2).toSet().length,
      institutionTimezones.length,
    );
    expect(
      institutionTimezones.where((z) => z.$1 == 'Australia').length,
      greaterThan(5),
    );
    expect(institutionTimezones.where((z) => z.$1 == 'Ecuador').length, 2);
  });

  testWidgets(
    'search country/city, cancel preserves value, selection returns IANA only',
    (tester) async {
      var value = 'Australia/Brisbane';
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => InstitutionTimezonePicker(
                value: value,
                onChanged: (v) => setState(() {
                  value = v;
                  changes++;
                }),
              ),
            ),
          ),
        ),
      );
      Future<void> open() async {
        await tester.tap(find.byKey(const ValueKey('institution-timezone')));
        await tester.pumpAndSettle();
      }

      await open();
      await tester.enterText(
        find.byKey(const ValueKey('timezone-search')),
        'Ecuador',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('timezone-America/Guayaquil')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('timezone-Pacific/Galapagos')),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(value, 'Australia/Brisbane');
      expect(changes, 0);
      await open();
      await tester.enterText(
        find.byKey(const ValueKey('timezone-search')),
        'España Madrid',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('timezone-Europe/Madrid')));
      await tester.pumpAndSettle();
      expect(value, 'Europe/Madrid');
      expect(changes, 1);
      expect(find.text('Europe/Madrid'), findsOneWidget);
    },
  );

  testWidgets(
    'narrow reduced-motion picker keeps legacy saved zone and handles no matches',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: InstitutionTimezonePicker(value: 'UTC', onChanged: (_) {}),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('institution-timezone')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('timezone-UTC')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('timezone-search')),
        'not-a-zone',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No matches. Try a nearby city or the IANA name.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
