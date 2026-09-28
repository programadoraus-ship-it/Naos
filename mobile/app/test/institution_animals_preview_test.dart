import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_editor.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_animals_scene.dart';
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
        InstitutionAnimalsAssets.background,
        InstitutionAnimalsAssets.fox,
        InstitutionAnimalsAssets.deer,
        InstitutionAnimalsAssets.owl,
        InstitutionAnimalsAssets.butterflies,
        InstitutionAnimalsAssets.foliage,
        InstitutionAnimalsAssets.pawprints,
      ]) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await tester.pump();
  }

  for (final variant in AnimalsVariant.values) {
    for (final device in PreviewDevice.values) {
      testWidgets('Animals scene capture ${variant.name} ${device.name}', (
        tester,
      ) async {
        final draft = InstitutionBrandDraft()
          ..ambience = InstitutionAmbience.animals
          ..template = InstitutionTemplate.orbit
          ..animalsVariant = variant
          ..device = device
          ..elementMotion = 0;
        addTearDown(draft.dispose);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await show(tester, draft);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('ambience-animals')), findsOneWidget);
        await expectLater(
          find.byType(InstitutionTemplatePreview),
          matchesGoldenFile(
            'goldens/animals-${variant.name}-${device.name}.png',
          ),
        );
      });
    }
  }

  for (final template in InstitutionTemplate.values) {
    for (final device in PreviewDevice.values) {
      testWidgets('Animals template capture ${template.name} ${device.name}', (
        tester,
      ) async {
        final draft = InstitutionBrandDraft()
          ..ambience = InstitutionAmbience.animals
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
            'goldens/animals-template-${template.name}-${device.name}.png',
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
        'Animals role capture ${sample.$1.name} ${sample.$2.name} ${device.name}',
        (tester) async {
          final draft = InstitutionBrandDraft()
            ..ambience = InstitutionAmbience.animals
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
              'goldens/animals-role-${sample.$1.name}-${sample.$2.name}-${device.name}.png',
            ),
          );
        },
      );
    }
  }

  testWidgets(
    'Three Animals scenes render across nine templates, three roles, two devices',
    (tester) async {
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.animals
        ..elementMotion = 0;
      addTearDown(draft.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final variant in AnimalsVariant.values) {
        for (final template in InstitutionTemplate.values) {
          for (final role in PreviewRole.values) {
            for (final device in PreviewDevice.values) {
              draft.animalsVariant = variant;
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
                find.byKey(const ValueKey('ambience-animals')),
                findsOneWidget,
              );
            }
          }
        }
      }
    },
  );

  testWidgets('Animals drag can overlap reading zones without snapping back', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.animals
      ..template = InstitutionTemplate.orbit
      ..device = PreviewDevice.mobile
      ..animalsVariant = AnimalsVariant.foxGrove
      ..editAnimalsDecorations = true
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
      variant: AnimalsVariant.foxGrove,
      template: InstitutionTemplate.orbit,
      device: PreviewDevice.mobile,
      element: AnimalsDecorationId.hero,
    );
    final base = AnimalsDecorationGeometry.recommended(key);
    const drag = Offset(-60, 140);
    await tester.drag(find.byKey(const ValueKey('animals-element-hero')), drag);
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('animals-protected-zones')),
      findsOneWidget,
    );
    final placed = AnimalsDecorationGeometry.adjustedRect(
      key,
      draft.animalsAdjustment(key),
    );
    expect((placed.center - (base.center + drag)).distance, lessThan(1));
    expect(draft.animalsOverlaps, contains(AnimalsDecorationId.hero));
    draft.update(() => draft.editAnimalsDecorations = false);
    await tester.pump();
    final target = tester.widget<IgnorePointer>(
      find
          .descendant(
            of: find.byKey(const ValueKey('animals-element-hero')),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(target.ignoring, isTrue);
  });

  test('Animals section mapping is fixed for all three roles', () {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    expect(
      draft.animalsVariantForSection('Dashboard'),
      AnimalsVariant.foxGrove,
    );
    expect(draft.animalsVariantForSection('Learn'), AnimalsVariant.deerMeadow);
    expect(draft.animalsVariantForSection('Games'), AnimalsVariant.owlCanopy);
    expect(
      draft.animalsVariantForSection('Students'),
      AnimalsVariant.deerMeadow,
    );
    expect(
      draft.animalsVariantForSection('Access Requests'),
      AnimalsVariant.owlCanopy,
    );
    expect(
      draft.animalsVariantForSection('My classes'),
      AnimalsVariant.deerMeadow,
    );
  });

  test(
    'Animals edits stay independent by scene/template/device; scaling stays centered',
    () {
      final draft = InstitutionBrandDraft();
      addTearDown(draft.dispose);
      const key = (
        variant: AnimalsVariant.foxGrove,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
        element: AnimalsDecorationId.hero,
      );
      final original = AnimalsDecorationGeometry.adjustedRect(
        key,
        draft.animalsAdjustment(key),
      );
      draft.changeAnimalsAdjustment(
        key,
        const OceanDecorationAdjustment(
          shift: Offset(-.35, .2),
          scale: 1.7,
          opacity: .42,
        ),
      );
      expect(draft.animalsAdjustment(key).scale, 1.7);
      expect(
        draft.animalsAdjustment((
          variant: AnimalsVariant.deerMeadow,
          template: key.template,
          device: key.device,
          element: key.element,
        )).scale,
        1,
      );
      expect(
        draft.animalsAdjustment((
          variant: key.variant,
          template: InstitutionTemplate.academy,
          device: key.device,
          element: key.element,
        )).scale,
        1,
      );
      expect(
        draft.animalsAdjustment((
          variant: key.variant,
          template: key.template,
          device: PreviewDevice.desktop,
          element: key.element,
        )).scale,
        1,
      );
      final centerBefore = AnimalsDecorationGeometry.adjustedRect(
        key,
        const OceanDecorationAdjustment(shift: Offset(-.35, .2)),
      ).center;
      final centerAfter = AnimalsDecorationGeometry.adjustedRect(
        key,
        draft.animalsAdjustment(key),
      ).center;
      expect(centerAfter, centerBefore);
      expect(original.center, isNot(centerAfter));
      final constrained = AnimalsDecorationGeometry.constrain(
        key,
        const OceanDecorationAdjustment(shift: Offset(9, -9), scale: 2),
      );
      expect(constrained.$2, isTrue);
      expect(
        AnimalsDecorationGeometry.adjustedRect(
          key,
          constrained.$1,
        ).overlaps(Offset.zero & AnimalsDecorationGeometry.frame(key.device)),
        isTrue,
      );
      draft.resetAnimalsAdjustment(key);
      expect(draft.animalsAdjustment(key).scale, 1);
    },
  );

  test(
    'Every Animals element reaches canvas edges and visible size uses alpha',
    () {
      for (final variant in AnimalsVariant.values) {
        for (final template in InstitutionTemplate.values) {
          for (final device in PreviewDevice.values) {
            for (final element in AnimalsDecorationId.values) {
              final key = (
                variant: variant,
                template: template,
                device: device,
                element: element,
              );
              final result = AnimalsDecorationGeometry.constrain(
                key,
                const OceanDecorationAdjustment(
                  shift: Offset(5, -5),
                  scale: 4,
                  opacity: -1,
                ),
              );
              final canvas =
                  Offset.zero & AnimalsDecorationGeometry.frame(device);
              final intersection = AnimalsDecorationGeometry.adjustedRect(
                key,
                result.$1,
              ).intersect(canvas);
              expect(intersection.width, greaterThan(.99), reason: '$key');
              expect(intersection.height, greaterThan(.99), reason: '$key');
              expect(result.$1.opacity, inInclusiveRange(0, 1));
              expect(
                result.$1.scale,
                inInclusiveRange(
                  AnimalsDecorationGeometry.minScale(key),
                  AnimalsDecorationGeometry.maxScale(key),
                ),
              );
              final visible = AnimalsDecorationGeometry.visibleRect(
                key,
                const OceanDecorationAdjustment(),
              );
              final layout = AnimalsDecorationGeometry.recommended(key);
              expect(visible.width, lessThan(layout.width));
              expect(visible.height, lessThan(layout.height));
            }
          }
        }
      }
    },
  );

  testWidgets(
    'Animals sliders independently affect background and foreground',
    (tester) async {
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.animals
        ..device = PreviewDevice.mobile
        ..elementMotion = 0;
      addTearDown(draft.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      draft.backgroundIntensity = 0;
      draft.decorationIntensity = 100;
      await show(tester, draft);
      expect(find.byType(InstitutionAnimalsBackground), findsNothing);
      expect(find.byType(InstitutionAnimalsScene), findsOneWidget);
      draft.backgroundIntensity = 100;
      draft.decorationIntensity = 0;
      await show(tester, draft);
      expect(find.byType(InstitutionAnimalsBackground), findsOneWidget);
      expect(find.byType(InstitutionAnimalsScene), findsNothing);
    },
  );

  testWidgets('System reduced motion keeps Animals layers static', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.animals
      ..device = PreviewDevice.mobile
      ..elementMotion = 100;
    addTearDown(draft.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester, draft, reduced: true);
    final motion = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('animals-motion-hero')),
    );
    expect(motion.duration, Duration.zero);
    expect(motion.tween.end, 0);
  });

  testWidgets('Animal and habitat motion responds to Element motion only', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.animals
      ..device = PreviewDevice.mobile
      ..elementMotion = 100;
    addTearDown(draft.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester, draft, reduced: false);
    await tester.pump(const Duration(milliseconds: 350));
    for (final element in AnimalsDecorationId.values) {
      final motion = tester.widget<TweenAnimationBuilder<double>>(
        find.byKey(ValueKey('animals-motion-${element.name}')),
      );
      expect(motion.duration, greaterThan(Duration.zero));
    }
    draft.update(() => draft.elementMotion = 0);
    await show(tester, draft, reduced: false);
    for (final element in AnimalsDecorationId.values) {
      final motion = tester.widget<TweenAnimationBuilder<double>>(
        find.byKey(ValueKey('animals-motion-${element.name}')),
      );
      expect(motion.duration, Duration.zero);
      expect(motion.tween.end, 0);
    }
  });

  testWidgets(
    'Animals editor exposes scenes, controls, selection and expanded preview',
    (tester) async {
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.animals
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
      for (final scene in AnimalsVariant.values) {
        expect(
          find.byKey(ValueKey('animals-variant-${scene.name}')),
          findsOneWidget,
        );
      }
      final deerMeadow = find.byKey(
        const ValueKey('animals-variant-deerMeadow'),
      );
      await tester.ensureVisible(deerMeadow);
      await tester.tap(deerMeadow);
      await tester.pumpAndSettle();
      expect(draft.animalsVariant, AnimalsVariant.deerMeadow);
      await tester.ensureVisible(
        find.byKey(const ValueKey('animals-preview-by-section')),
      );
      await tester.tap(
        find.byKey(const ValueKey('animals-preview-by-section')),
      );
      await tester.pumpAndSettle();
      expect(draft.animalsPreviewBySection, isTrue);
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
      draft.update(() => draft.animalsPreviewBySection = false);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('edit-animals-decorations')),
      );
      await tester.tap(find.byKey(const ValueKey('edit-animals-decorations')));
      await tester.pumpAndSettle();
      expect(draft.editAnimalsDecorations, isTrue);
      expect(
        find.byKey(const ValueKey('animals-decoration-editor')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('animals-select-foliage')),
      );
      await tester.tap(find.byKey(const ValueKey('animals-select-foliage')));
      await tester.pumpAndSettle();
      expect(draft.selectedAnimalsDecoration, AnimalsDecorationId.foliage);
      await tester.ensureVisible(
        find.byKey(const ValueKey('animals-element-size')),
      );
      await tester.drag(
        find.byKey(const ValueKey('animals-element-size')),
        const Offset(80, 0),
      );
      await tester.pumpAndSettle();
      final key = (
        variant: AnimalsVariant.deerMeadow,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
        element: AnimalsDecorationId.foliage,
      );
      expect(draft.animalsAdjustment(key).scale, greaterThan(1));
      draft.update(() => draft.template = InstitutionTemplate.academy);
      await tester.pump();
      expect(
        draft.animalsAdjustment((
          variant: key.variant,
          template: InstitutionTemplate.academy,
          device: key.device,
          element: key.element,
        )).scale,
        1,
      );
      draft.update(() => draft.template = InstitutionTemplate.orbit);
      await tester.pump();
      expect(draft.animalsAdjustment(key).scale, greaterThan(1));
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
