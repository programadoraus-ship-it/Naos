import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_editor.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_nature_scene.dart';
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
        InstitutionNatureAssets.background,
        InstitutionNatureAssets.oak,
        InstitutionNatureAssets.summit,
        InstitutionNatureAssets.waterfall,
        InstitutionNatureAssets.songbirds,
        InstitutionNatureAssets.wildflowers,
        InstitutionNatureAssets.leaves,
      ]) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await tester.pump();
  }

  for (final variant in NatureVariant.values) {
    for (final device in PreviewDevice.values) {
      testWidgets('Nature scene capture ${variant.name} ${device.name}', (
        tester,
      ) async {
        final draft = InstitutionBrandDraft()
          ..ambience = InstitutionAmbience.nature
          ..template = InstitutionTemplate.orbit
          ..natureVariant = variant
          ..device = device
          ..elementMotion = 0;
        addTearDown(draft.dispose);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await show(tester, draft);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('ambience-nature')), findsOneWidget);
        await expectLater(
          find.byType(InstitutionTemplatePreview),
          matchesGoldenFile(
            'goldens/nature-${variant.name}-${device.name}.png',
          ),
        );
      });
    }
  }

  for (final template in InstitutionTemplate.values) {
    for (final device in PreviewDevice.values) {
      testWidgets('Nature template capture ${template.name} ${device.name}', (
        tester,
      ) async {
        final draft = InstitutionBrandDraft()
          ..ambience = InstitutionAmbience.nature
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
            'goldens/nature-template-${template.name}-${device.name}.png',
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
        'Nature role capture ${sample.$1.name} ${sample.$2.name} ${device.name}',
        (tester) async {
          final draft = InstitutionBrandDraft()
            ..ambience = InstitutionAmbience.nature
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
              'goldens/nature-role-${sample.$1.name}-${sample.$2.name}-${device.name}.png',
            ),
          );
        },
      );
    }
  }

  testWidgets(
    'Three Nature scenes render across nine templates, three roles, two devices',
    (tester) async {
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.nature
        ..elementMotion = 0;
      addTearDown(draft.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final variant in NatureVariant.values) {
        for (final template in InstitutionTemplate.values) {
          for (final role in PreviewRole.values) {
            for (final device in PreviewDevice.values) {
              draft.natureVariant = variant;
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
                find.byKey(const ValueKey('ambience-nature')),
                findsOneWidget,
              );
            }
          }
        }
      }
    },
  );

  testWidgets('Nature drag can overlap reading zones without snapping back', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.nature
      ..template = InstitutionTemplate.orbit
      ..device = PreviewDevice.mobile
      ..natureVariant = NatureVariant.ancientGrove
      ..editNatureDecorations = true
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
      variant: NatureVariant.ancientGrove,
      template: InstitutionTemplate.orbit,
      device: PreviewDevice.mobile,
      element: NatureDecorationId.hero,
    );
    final base = NatureDecorationGeometry.recommended(key);
    const drag = Offset(-60, 140);
    await tester.drag(find.byKey(const ValueKey('nature-element-hero')), drag);
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('nature-protected-zones')),
      findsOneWidget,
    );
    final placed = NatureDecorationGeometry.adjustedRect(
      key,
      draft.natureAdjustment(key),
    );
    expect((placed.center - (base.center + drag)).distance, lessThan(1));
    expect(draft.natureOverlaps, contains(NatureDecorationId.hero));
    draft.update(() => draft.editNatureDecorations = false);
    await tester.pump();
    final target = tester.widget<IgnorePointer>(
      find
          .descendant(
            of: find.byKey(const ValueKey('nature-element-hero')),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(target.ignoring, isTrue);
  });

  test('Nature section mapping is fixed for all three roles', () {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    expect(
      draft.natureVariantForSection('Dashboard'),
      NatureVariant.ancientGrove,
    );
    expect(draft.natureVariantForSection('Learn'), NatureVariant.alpineVista);
    expect(
      draft.natureVariantForSection('Games'),
      NatureVariant.waterfallHaven,
    );
    expect(
      draft.natureVariantForSection('Students'),
      NatureVariant.alpineVista,
    );
    expect(
      draft.natureVariantForSection('Access Requests'),
      NatureVariant.waterfallHaven,
    );
    expect(
      draft.natureVariantForSection('My classes'),
      NatureVariant.alpineVista,
    );
  });

  test(
    'Nature edits stay independent by scene/template/device; scaling stays centered',
    () {
      final draft = InstitutionBrandDraft();
      addTearDown(draft.dispose);
      const key = (
        variant: NatureVariant.ancientGrove,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
        element: NatureDecorationId.hero,
      );
      final original = NatureDecorationGeometry.adjustedRect(
        key,
        draft.natureAdjustment(key),
      );
      draft.changeNatureAdjustment(
        key,
        const OceanDecorationAdjustment(
          shift: Offset(-.35, .2),
          scale: 1.7,
          opacity: .42,
        ),
      );
      expect(draft.natureAdjustment(key).scale, 1.7);
      expect(
        draft.natureAdjustment((
          variant: NatureVariant.alpineVista,
          template: key.template,
          device: key.device,
          element: key.element,
        )).scale,
        1,
      );
      expect(
        draft.natureAdjustment((
          variant: key.variant,
          template: InstitutionTemplate.academy,
          device: key.device,
          element: key.element,
        )).scale,
        1,
      );
      expect(
        draft.natureAdjustment((
          variant: key.variant,
          template: key.template,
          device: PreviewDevice.desktop,
          element: key.element,
        )).scale,
        1,
      );
      final centerBefore = NatureDecorationGeometry.adjustedRect(
        key,
        const OceanDecorationAdjustment(shift: Offset(-.35, .2)),
      ).center;
      final centerAfter = NatureDecorationGeometry.adjustedRect(
        key,
        draft.natureAdjustment(key),
      ).center;
      expect(centerAfter, centerBefore);
      expect(original.center, isNot(centerAfter));
      final constrained = NatureDecorationGeometry.constrain(
        key,
        const OceanDecorationAdjustment(shift: Offset(9, -9), scale: 2),
      );
      expect(constrained.$2, isTrue);
      expect(
        NatureDecorationGeometry.adjustedRect(
          key,
          constrained.$1,
        ).overlaps(Offset.zero & NatureDecorationGeometry.frame(key.device)),
        isTrue,
      );
      draft.resetNatureAdjustment(key);
      expect(draft.natureAdjustment(key).scale, 1);
    },
  );

  test(
    'Every Nature element reaches canvas edges and visible size uses alpha',
    () {
      for (final variant in NatureVariant.values) {
        for (final template in InstitutionTemplate.values) {
          for (final device in PreviewDevice.values) {
            for (final element in NatureDecorationId.values) {
              final key = (
                variant: variant,
                template: template,
                device: device,
                element: element,
              );
              final result = NatureDecorationGeometry.constrain(
                key,
                const OceanDecorationAdjustment(
                  shift: Offset(5, -5),
                  scale: 4,
                  opacity: -1,
                ),
              );
              final canvas =
                  Offset.zero & NatureDecorationGeometry.frame(device);
              final intersection = NatureDecorationGeometry.adjustedRect(
                key,
                result.$1,
              ).intersect(canvas);
              expect(intersection.width, greaterThan(.99), reason: '$key');
              expect(intersection.height, greaterThan(.99), reason: '$key');
              expect(result.$1.opacity, inInclusiveRange(0, 1));
              expect(
                result.$1.scale,
                inInclusiveRange(
                  NatureDecorationGeometry.minScale(key),
                  NatureDecorationGeometry.maxScale(key),
                ),
              );
              final visible = NatureDecorationGeometry.visibleRect(
                key,
                const OceanDecorationAdjustment(),
              );
              final layout = NatureDecorationGeometry.recommended(key);
              expect(visible.width, lessThan(layout.width));
              expect(visible.height, lessThan(layout.height));
            }
          }
        }
      }
    },
  );

  testWidgets('Nature sliders independently affect background and foreground', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.nature
      ..device = PreviewDevice.mobile
      ..elementMotion = 0;
    addTearDown(draft.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    draft.backgroundIntensity = 0;
    draft.decorationIntensity = 100;
    await show(tester, draft);
    expect(find.byType(InstitutionNatureBackground), findsNothing);
    expect(find.byType(InstitutionNatureScene), findsOneWidget);
    draft.backgroundIntensity = 100;
    draft.decorationIntensity = 0;
    await show(tester, draft);
    expect(find.byType(InstitutionNatureBackground), findsOneWidget);
    expect(find.byType(InstitutionNatureScene), findsNothing);
  });

  testWidgets('System reduced motion keeps Nature layers static', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.nature
      ..device = PreviewDevice.mobile
      ..elementMotion = 100;
    addTearDown(draft.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester, draft, reduced: true);
    final motion = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('nature-motion-hero')),
    );
    expect(motion.duration, Duration.zero);
    expect(motion.tween.end, 0);
  });

  testWidgets('Nature details respond to Element motion only', (tester) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.nature
      ..device = PreviewDevice.mobile
      ..elementMotion = 100;
    addTearDown(draft.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester, draft, reduced: false);
    await tester.pump(const Duration(milliseconds: 350));
    for (final element in NatureDecorationId.values) {
      final motion = tester.widget<TweenAnimationBuilder<double>>(
        find.byKey(ValueKey('nature-motion-${element.name}')),
      );
      expect(motion.duration, greaterThan(Duration.zero));
    }
    draft.update(() => draft.elementMotion = 0);
    await show(tester, draft, reduced: false);
    for (final element in NatureDecorationId.values) {
      final motion = tester.widget<TweenAnimationBuilder<double>>(
        find.byKey(ValueKey('nature-motion-${element.name}')),
      );
      expect(motion.duration, Duration.zero);
      expect(motion.tween.end, 0);
    }
  });

  testWidgets(
    'Nature editor exposes scenes, controls, selection and expanded preview',
    (tester) async {
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.nature
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
      for (final scene in NatureVariant.values) {
        expect(
          find.byKey(ValueKey('nature-variant-${scene.name}')),
          findsOneWidget,
        );
      }
      final alpineVista = find.byKey(
        const ValueKey('nature-variant-alpineVista'),
      );
      await tester.ensureVisible(alpineVista);
      await tester.tap(alpineVista);
      await tester.pumpAndSettle();
      expect(draft.natureVariant, NatureVariant.alpineVista);
      await tester.ensureVisible(
        find.byKey(const ValueKey('nature-preview-by-section')),
      );
      await tester.tap(find.byKey(const ValueKey('nature-preview-by-section')));
      await tester.pumpAndSettle();
      expect(draft.naturePreviewBySection, isTrue);
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
      draft.update(() => draft.naturePreviewBySection = false);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('edit-nature-decorations')),
      );
      await tester.tap(find.byKey(const ValueKey('edit-nature-decorations')));
      await tester.pumpAndSettle();
      expect(draft.editNatureDecorations, isTrue);
      expect(
        find.byKey(const ValueKey('nature-decoration-editor')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('nature-select-wildflowers')),
      );
      await tester.tap(find.byKey(const ValueKey('nature-select-wildflowers')));
      await tester.pumpAndSettle();
      expect(draft.selectedNatureDecoration, NatureDecorationId.wildflowers);
      await tester.ensureVisible(
        find.byKey(const ValueKey('nature-element-size')),
      );
      await tester.drag(
        find.byKey(const ValueKey('nature-element-size')),
        const Offset(80, 0),
      );
      await tester.pumpAndSettle();
      final key = (
        variant: NatureVariant.alpineVista,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
        element: NatureDecorationId.wildflowers,
      );
      expect(draft.natureAdjustment(key).scale, greaterThan(1));
      draft.update(() => draft.template = InstitutionTemplate.academy);
      await tester.pump();
      expect(
        draft.natureAdjustment((
          variant: key.variant,
          template: InstitutionTemplate.academy,
          device: key.device,
          element: key.element,
        )).scale,
        1,
      );
      draft.update(() => draft.template = InstitutionTemplate.orbit);
      await tester.pump();
      expect(draft.natureAdjustment(key).scale, greaterThan(1));
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
