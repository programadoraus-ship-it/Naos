import 'package:app/features/institution_admin/presentation/pages/institution_dashboard_page.dart';
import 'package:app/features/institution_admin/presentation/widgets/institution_admin_appearance_shell.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> showDashboard(
    WidgetTester tester, {
    required InstitutionTemplate template,
    required InstitutionFont font,
    required Size size,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    final draft = InstitutionBrandDraft()
      ..template = template
      ..font = font
      ..ambience = InstitutionAmbience.none;
    addTearDown(draft.dispose);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
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
            body: InstitutionAdminDashboardContent(
              draft: draft,
              institutionName: 'A long institutional academy name',
              institutionId: 'c8fdcd63-5115-499b-a838-9c1763d1aedc',
              counts: const [1200, 80, 14, 10],
              requests: const [],
              warning: null,
              open: (_) {},
              retry: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('all templates and fonts render on mobile and desktop', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final template in InstitutionTemplate.values) {
      for (final font in InstitutionFont.values) {
        for (final size in const [Size(390, 844), Size(1280, 800)]) {
          await showDashboard(
            tester,
            template: template,
            font: font,
            size: size,
          );
          expect(
            tester.takeException(),
            isNull,
            reason:
                '${template.name}/${font.name}/${size.width.toInt()}px overflowed',
          );
        }
      }
    }
  });

  testWidgets('long labels and scaled text grow cards without overflow', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final template in InstitutionTemplate.values) {
      for (final font in const [
        InstitutionFont.playfairDisplay,
        InstitutionFont.lora,
        InstitutionFont.fredoka,
        InstitutionFont.spaceMono,
      ]) {
        for (final size in const [Size(390, 844), Size(1280, 800)]) {
          await showDashboard(
            tester,
            template: template,
            font: font,
            size: size,
            textScale: 1.6,
          );
          expect(find.text('Pending requests'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason:
                '${template.name}/${font.name}/${size.width.toInt()}px at 160% overflowed',
          );
        }
      }
    }
  });

  testWidgets('cards share row height and Institution remains scrollable', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showDashboard(
      tester,
      template: InstitutionTemplate.orbit,
      font: InstitutionFont.playfairDisplay,
      size: const Size(1280, 640),
      textScale: 1.6,
    );

    final cards = List.generate(
      4,
      (index) => find.byKey(ValueKey('institution-stat-card-$index')),
    );
    final heights = cards
        .map(tester.getSize)
        .map((size) => size.height)
        .toList();
    expect(heights.toSet(), hasLength(1));
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Institution'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    expect(find.text('A long institutional academy name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
