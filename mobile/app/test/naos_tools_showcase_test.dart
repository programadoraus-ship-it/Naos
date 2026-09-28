import 'package:app/features/institution_onboarding/presentation/pages/naos_tools_showcase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(
    WidgetTester tester, {
    bool reduced = false,
    double width = 820,
  }) => tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: width, child: const NaosToolsShowcase()),
          ),
        ),
      ),
    ),
  );

  testWidgets('sequential spotlight settles all ten informational tools', (
    tester,
  ) async {
    await show(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Students'), findsNWidgets(2));
    expect(find.text('Teachers'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Teachers'), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.text('Virtual School'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Your toolkit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skip and early disposal safely stop the sequence', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.byKey(const ValueKey('skip-tools-intro')));
    await tester.pump();
    expect(find.text('Your toolkit'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await show(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows every tool immediately on narrow layouts', (
    tester,
  ) async {
    await show(tester, reduced: true, width: 280);
    await tester.pump();
    expect(find.text('Your toolkit'), findsOneWidget);
    expect(find.text('Virtual School'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
