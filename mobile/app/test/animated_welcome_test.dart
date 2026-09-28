import 'package:app/features/institution_onboarding/presentation/pages/animated_welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets('welcome settles safely; reduced motion = $reduced', (tester) async {
      await tester.pumpWidget(MaterialApp(home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: const Scaffold(body: AnimatedWelcome(children: [Text('NAOS'), Text('Welcome')])),
      )));
      await tester.pump();
      if (reduced) {
        expect(tester.widgetList<Opacity>(find.byType(Opacity)).every((w) => w.opacity == 1), isTrue);
      }
      await tester.pumpAndSettle();
      expect(find.text('Welcome'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
