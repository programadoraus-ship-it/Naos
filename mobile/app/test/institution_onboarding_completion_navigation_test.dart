import 'package:app/core/navigation/app_router.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_onboarding_flow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'completion replaces the stack with institution dashboard route',
    (tester) async {
      late BuildContext sourceContext;
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/source',
          routes: {
            '/source': (context) => Builder(
              builder: (context) {
                sourceContext = context;
                return const Text('onboarding');
              },
            ),
            AppRouter.institutionAdmin: (_) =>
                const Text('institution dashboard'),
          },
        ),
      );

      openInstitutionDashboardAfterSetup(sourceContext);
      await tester.pumpAndSettle();

      expect(find.text('institution dashboard'), findsOneWidget);
      expect(find.text('onboarding'), findsNothing);
      expect(
        ModalRoute.of(
          tester.element(find.text('institution dashboard')),
        )?.settings.name,
        AppRouter.institutionAdmin,
      );
    },
  );
}
