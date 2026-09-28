import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_editor.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_space_scene.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_template_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await loader.load();
  });

  Future<void> show(
    WidgetTester tester,
    InstitutionBrandDraft draft, {
    bool reduced = true,
  }) async {
    tester.view.physicalSize = draft.device == PreviewDevice.mobile
        ? const Size(430, 760)
        : const Size(1180, 680);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            backgroundColor: const Color(0xFF080D24),
            body: Center(
              child: InstitutionTemplatePreview(
                draft: draft,
                institutionName: 'Aurora Academy',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(InstitutionTemplatePreview));
      for (final path in [
        InstitutionSpaceAssets.background,
        InstitutionSpaceAssets.planet,
        InstitutionSpaceAssets.station,
        InstitutionSpaceAssets.asteroids,
        InstitutionSpaceAssets.ship,
        InstitutionSpaceAssets.probe,
        InstitutionSpaceAssets.stardust,
      ]) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await tester.pump();
  }

  for (final variant in SpaceVariant.values) {
    for (final device in PreviewDevice.values) {
      testWidgets('Space scene capture ${variant.name} ${device.name}', (
        tester,
      ) async {
        final draft = InstitutionBrandDraft()
          ..ambience = InstitutionAmbience.space
          ..template = InstitutionTemplate.orbit
          ..spaceVariant = variant
          ..device = device
          ..elementMotion = 0;
        addTearDown(draft.dispose);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await show(tester, draft);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('ambience-space')), findsOneWidget);
        await expectLater(
          find.byType(InstitutionTemplatePreview),
          matchesGoldenFile('goldens/space-${variant.name}-${device.name}.png'),
        );
      });
    }
  }

  for (final template in InstitutionTemplate.values) {
    for (final device in PreviewDevice.values) {
      testWidgets('Space template capture ${template.name} ${device.name}', (
        tester,
      ) async {
        final draft = InstitutionBrandDraft()
          ..ambience = InstitutionAmbience.space
          ..template = template
          ..device = device
          ..elementMotion = 0;
        addTearDown(draft.dispose);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await show(tester, draft);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(InstitutionTemplatePreview),
          matchesGoldenFile(
            'goldens/space-template-${template.name}-${device.name}.png',
          ),
        );
      });
    }
  }

  for (final sample in [
    (InstitutionTemplate.orbit, PreviewRole.admin),
    (InstitutionTemplate.academy, PreviewRole.teacher),
  ]) {
    for (final device in PreviewDevice.values) {
      testWidgets(
        'Space role capture ${sample.$1.name} ${sample.$2.name} ${device.name}',
        (tester) async {
          final draft = InstitutionBrandDraft()
            ..ambience = InstitutionAmbience.space
            ..template = sample.$1
            ..role = sample.$2
            ..device = device
            ..elementMotion = 0;
          addTearDown(draft.dispose);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await show(tester, draft);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(InstitutionTemplatePreview),
            matchesGoldenFile(
              'goldens/space-role-${sample.$1.name}-${sample.$2.name}-${device.name}.png',
            ),
          );
        },
      );
    }
  }

  testWidgets(
    'Three Space scenes render across nine templates, three roles, two devices',
    (tester) async {
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.space
        ..elementMotion = 0;
      addTearDown(draft.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final variant in SpaceVariant.values) {
        for (final template in InstitutionTemplate.values) {
          for (final role in PreviewRole.values) {
            for (final device in PreviewDevice.values) {
              draft.spaceVariant = variant;
              draft.template = template;
              draft.role = role;
              draft.device = device;
              draft.previewSectionIndex = 0;
              await show(tester, draft);
              expect(
                tester.takeException(),
                isNull,
                reason:
                    '${variant.name}/${template.name}/${role.name}/${device.name}',
              );
              expect(
                find.byKey(const ValueKey('ambience-space')),
                findsOneWidget,
              );
            }
          }
        }
      }
    },
  );

  testWidgets('Space drag can overlap reading zones without snapping back', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.space
      ..template = InstitutionTemplate.orbit
      ..device = PreviewDevice.mobile
      ..spaceVariant = SpaceVariant.planetExploration
      ..editSpaceDecorations = true
      ..elementMotion = 0;
    addTearDown(draft.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(430, 760);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: draft,
            builder: (context, _) => InstitutionTemplatePreview(
              draft: draft,
              institutionName: 'Aurora Academy',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    const key = (
      variant: SpaceVariant.planetExploration,
      template: InstitutionTemplate.orbit,
      device: PreviewDevice.mobile,
      element: SpaceDecorationId.hero,
    );
    final base = SpaceDecorationGeometry.recommended(key);
    const drag = Offset(-60, 140);
    await tester.drag(find.byKey(const ValueKey('space-element-hero')), drag);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('space-protected-zones')), findsOneWidget);
    final placed = SpaceDecorationGeometry.adjustedRect(
      key,
      draft.spaceAdjustment(key),
    );
    expect((placed.center - (base.center + drag)).distance, lessThan(1));
    expect(draft.spaceOverlaps, contains(SpaceDecorationId.hero));
    draft.update(() => draft.editSpaceDecorations = false);
    await tester.pump();
    final target = tester.widget<IgnorePointer>(
      find
          .descendant(
            of: find.byKey(const ValueKey('space-element-hero')),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(target.ignoring, isTrue);
  });

  test('Space section mapping is fixed for all three roles', () {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    expect(
      draft.spaceVariantForSection('Dashboard'),
      SpaceVariant.planetExploration,
    );
    expect(draft.spaceVariantForSection('Learn'), SpaceVariant.orbitalStation);
    expect(
      draft.spaceVariantForSection('Games'),
      SpaceVariant.asteroidExpedition,
    );
    expect(
      draft.spaceVariantForSection('Students'),
      SpaceVariant.orbitalStation,
    );
    expect(
      draft.spaceVariantForSection('Access Requests'),
      SpaceVariant.asteroidExpedition,
    );
    expect(
      draft.spaceVariantForSection('My classes'),
      SpaceVariant.orbitalStation,
    );
  });

  test(
    'Space edits stay independent by scene/template/device; scaling stays centered',
    () {
      final draft = InstitutionBrandDraft();
      addTearDown(draft.dispose);
      const key = (
        variant: SpaceVariant.planetExploration,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
        element: SpaceDecorationId.hero,
      );
      final original = SpaceDecorationGeometry.adjustedRect(
        key,
        draft.spaceAdjustment(key),
      );
      draft.changeSpaceAdjustment(
        key,
        const OceanDecorationAdjustment(
          shift: Offset(-.35, .2),
          scale: 1.7,
          opacity: .42,
        ),
      );
      expect(draft.spaceAdjustment(key).scale, 1.7);
      expect(
        draft.spaceAdjustment((
          variant: SpaceVariant.orbitalStation,
          template: key.template,
          device: key.device,
          element: key.element,
        )).scale,
        1,
      );
      expect(
        draft.spaceAdjustment((
          variant: key.variant,
          template: InstitutionTemplate.academy,
          device: key.device,
          element: key.element,
        )).scale,
        1,
      );
      expect(
        draft.spaceAdjustment((
          variant: key.variant,
          template: key.template,
          device: PreviewDevice.desktop,
          element: key.element,
        )).scale,
        1,
      );
      final centerBefore = SpaceDecorationGeometry.adjustedRect(
        key,
        const OceanDecorationAdjustment(shift: Offset(-.35, .2)),
      ).center;
      final centerAfter = SpaceDecorationGeometry.adjustedRect(
        key,
        draft.spaceAdjustment(key),
      ).center;
      expect(centerAfter, centerBefore);
      expect(original.center, isNot(centerAfter));
      final constrained = SpaceDecorationGeometry.constrain(
        key,
        const OceanDecorationAdjustment(shift: Offset(9, -9), scale: 2),
      );
      expect(constrained.$2, isTrue);
      expect(
        SpaceDecorationGeometry.adjustedRect(
          key,
          constrained.$1,
        ).overlaps(Offset.zero & SpaceDecorationGeometry.frame(key.device)),
        isTrue,
      );
      draft.resetSpaceAdjustment(key);
      expect(draft.spaceAdjustment(key).scale, 1);
    },
  );

  test(
    'Every Space element reaches canvas edges and visible size uses alpha',
    () {
      for (final variant in SpaceVariant.values) {
        for (final template in InstitutionTemplate.values) {
          for (final device in PreviewDevice.values) {
            for (final element in SpaceDecorationId.values) {
              final key = (
                variant: variant,
                template: template,
                device: device,
                element: element,
              );
              final result = SpaceDecorationGeometry.constrain(
                key,
                const OceanDecorationAdjustment(
                  shift: Offset(5, -5),
                  scale: 4,
                  opacity: -1,
                ),
              );
              final canvas =
                  Offset.zero & SpaceDecorationGeometry.frame(device);
              final intersection = SpaceDecorationGeometry.adjustedRect(
                key,
                result.$1,
              ).intersect(canvas);
              expect(intersection.width, greaterThan(.99), reason: '$key');
              expect(intersection.height, greaterThan(.99), reason: '$key');
              expect(result.$1.opacity, inInclusiveRange(0, 1));
              expect(
                result.$1.scale,
                inInclusiveRange(
                  SpaceDecorationGeometry.minScale(key),
                  SpaceDecorationGeometry.maxScale(key),
                ),
              );
              final visible = SpaceDecorationGeometry.visibleRect(
                key,
                const OceanDecorationAdjustment(),
              );
              final layout = SpaceDecorationGeometry.recommended(key);
              expect(visible.width, lessThan(layout.width));
              expect(visible.height, lessThan(layout.height));
            }
          }
        }
      }
    },
  );

  testWidgets('Space sliders independently affect background and foreground', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.space
      ..device = PreviewDevice.mobile
      ..elementMotion = 0;
    addTearDown(draft.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    draft.backgroundIntensity = 0;
    draft.decorationIntensity = 100;
    await show(tester, draft);
    expect(find.byType(InstitutionSpaceBackground), findsNothing);
    expect(find.byType(InstitutionSpaceScene), findsOneWidget);
    draft.backgroundIntensity = 100;
    draft.decorationIntensity = 0;
    await show(tester, draft);
    expect(find.byType(InstitutionSpaceBackground), findsOneWidget);
    expect(find.byType(InstitutionSpaceScene), findsNothing);
  });

  testWidgets('System reduced motion keeps Space layers static', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.space
      ..device = PreviewDevice.mobile
      ..elementMotion = 100;
    addTearDown(draft.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester, draft, reduced: true);
    final motion = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('space-motion-hero')),
    );
    expect(motion.duration, Duration.zero);
    expect(motion.tween.end, 0);
  });

  testWidgets(
    'Space editor exposes scenes, controls, selection and expanded preview',
    (tester) async {
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.space
        ..device = PreviewDevice.mobile
        ..elementMotion = 0;
      addTearDown(draft.dispose);
      tester.view.physicalSize = const Size(1240, 1900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF080D24),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: InstitutionBrandEditor(
                draft: draft,
                institutionName: 'Aurora Academy',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ambience').first);
      await tester.pumpAndSettle();
      for (final scene in SpaceVariant.values) {
        expect(
          find.byKey(ValueKey('space-variant-${scene.name}')),
          findsOneWidget,
        );
      }
      final orbitalStation = find.byKey(
        const ValueKey('space-variant-orbitalStation'),
      );
      await tester.ensureVisible(orbitalStation);
      await tester.tap(orbitalStation);
      await tester.pumpAndSettle();
      expect(draft.spaceVariant, SpaceVariant.orbitalStation);
      await tester.ensureVisible(
        find.byKey(const ValueKey('space-preview-by-section')),
      );
      await tester.tap(find.byKey(const ValueKey('space-preview-by-section')));
      await tester.pumpAndSettle();
      expect(draft.spacePreviewBySection, isTrue);
      expect(
        find.byKey(const ValueKey('background-intensity-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('decoration-intensity-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('element-motion-intensity-slider')),
        findsOneWidget,
      );
      draft.update(() => draft.spacePreviewBySection = false);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('edit-space-decorations')),
      );
      await tester.tap(find.byKey(const ValueKey('edit-space-decorations')));
      await tester.pumpAndSettle();
      expect(draft.editSpaceDecorations, isTrue);
      expect(
        find.byKey(const ValueKey('space-decoration-editor')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('space-select-probe')),
      );
      await tester.tap(find.byKey(const ValueKey('space-select-probe')));
      await tester.pumpAndSettle();
      expect(draft.selectedSpaceDecoration, SpaceDecorationId.probe);
      await tester.ensureVisible(
        find.byKey(const ValueKey('space-element-size')),
      );
      await tester.drag(
        find.byKey(const ValueKey('space-element-size')),
        const Offset(80, 0),
      );
      await tester.pumpAndSettle();
      final key = (
        variant: SpaceVariant.orbitalStation,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
        element: SpaceDecorationId.probe,
      );
      expect(draft.spaceAdjustment(key).scale, greaterThan(1));
      draft.update(() => draft.template = InstitutionTemplate.academy);
      await tester.pump();
      expect(
        draft.spaceAdjustment((
          variant: key.variant,
          template: InstitutionTemplate.academy,
          device: key.device,
          element: key.element,
        )).scale,
        1,
      );
      draft.update(() => draft.template = InstitutionTemplate.orbit);
      await tester.pump();
      expect(draft.spaceAdjustment(key).scale, greaterThan(1));
      await tester.ensureVisible(find.byKey(const ValueKey('expand-preview')));
      await tester.tap(find.byKey(const ValueKey('expand-preview')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('close-expanded-preview')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
