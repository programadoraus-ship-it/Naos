import 'package:app/features/institution_admin/presentation/widgets/institution_admin_appearance_shell.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final template in InstitutionTemplate.values) {
    for (final size in const [Size(390, 760), Size(1280, 800)]) {
      testWidgets('${template.name} renders at ${size.width.toInt()} px', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final draft = InstitutionBrandDraft()
          ..template = template
          ..ambience = InstitutionAmbience.none;
        addTearDown(draft.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InstitutionAdminAppearanceShell(
                draft: draft,
                institutionName: 'Test School 2',
                destinations: [
                  InstitutionAdminDestination(
                    label: 'Dashboard',
                    icon: Icons.dashboard,
                    selected: true,
                    onTap: () {},
                  ),
                  InstitutionAdminDestination(
                    label: 'Appearance',
                    icon: Icons.palette,
                    onTap: () {},
                  ),
                ],
                onRefresh: () {},
                onSignOut: () {},
                body: const SingleChildScrollView(
                  child: SizedBox(
                    height: 500,
                    child: Text('Real dashboard content'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Test School 2'), findsOneWidget);
        expect(find.text('Real dashboard content'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
