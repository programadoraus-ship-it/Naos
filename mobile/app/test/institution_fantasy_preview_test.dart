import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_editor.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_fantasy_scene.dart';
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
  Future<void> show(WidgetTester tester, InstitutionBrandDraft draft) async {
    tester.view.physicalSize = draft.device == PreviewDevice.mobile
        ? const Size(430, 760)
        : const Size(1180, 680);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
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
        InstitutionFantasyAssets.background,
        InstitutionFantasyAssets.castle,
        InstitutionFantasyAssets.book,
        InstitutionFantasyAssets.dragon,
        InstitutionFantasyAssets.fireflies,
        InstitutionFantasyAssets.mushrooms,
        InstitutionFantasyAssets.lantern,
      ]) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await tester.pump();
  }

  for (final variant in FantasyVariant.values) {
    for (final device in PreviewDevice.values) {
      testWidgets('Fantasy scene ${variant.name} ${device.name}', (
        tester,
      ) async {
        final draft = InstitutionBrandDraft()
          ..ambience = InstitutionAmbience.fantasy
          ..fantasyVariant = variant
          ..device = device
          ..elementMotion = 0;
        addTearDown(draft.dispose);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await show(tester, draft);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('ambience-fantasy')), findsOneWidget);
        await expectLater(
          find.byType(InstitutionTemplatePreview),
          matchesGoldenFile(
            'goldens/fantasy-${variant.name}-${device.name}.png',
          ),
        );
      });
    }
  }

  testWidgets(
    'Fantasy scenes render in nine templates, three roles and both sizes',
    (tester) async {
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.fantasy
        ..elementMotion = 0;
      addTearDown(draft.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final variant in FantasyVariant.values) {
        for (final template in InstitutionTemplate.values) {
          for (final role in PreviewRole.values) {
            for (final device in PreviewDevice.values) {
              draft.fantasyVariant = variant;
              draft.template = template;
              draft.role = role;
              draft.device = device;
              await show(tester, draft);
              expect(
                tester.takeException(),
                isNull,
                reason:
                    '${variant.name}/${template.name}/${role.name}/${device.name}',
              );
            }
          }
        }
      }
    },
  );

  test('Fantasy adjustments are separate by scene, template and device', () {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    const key = (
      variant: FantasyVariant.floatingCastle,
      template: InstitutionTemplate.orbit,
      device: PreviewDevice.mobile,
      element: FantasyDecorationId.hero,
    );
    draft.changeFantasyAdjustment(
      key,
      const OceanDecorationAdjustment(scale: 1.5, opacity: .5),
    );
    expect(draft.fantasyAdjustment(key).scale, 1.5);
    expect(
      draft.fantasyAdjustment((
        variant: FantasyVariant.dragonGarden,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
        element: FantasyDecorationId.hero,
      )).scale,
      1,
    );
    expect(
      draft.fantasyAdjustment((
        variant: FantasyVariant.floatingCastle,
        template: InstitutionTemplate.academy,
        device: PreviewDevice.mobile,
        element: FantasyDecorationId.hero,
      )).scale,
      1,
    );
    expect(
      draft.fantasyAdjustment((
        variant: FantasyVariant.floatingCastle,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.desktop,
        element: FantasyDecorationId.hero,
      )).scale,
      1,
    );
  });

  test('Fantasy section mapping is stable across roles', () {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    expect(
      draft.fantasyVariantForSection('Dashboard'),
      FantasyVariant.floatingCastle,
    );
    expect(
      draft.fantasyVariantForSection('Learn'),
      FantasyVariant.enchantedLibrary,
    );
    expect(
      draft.fantasyVariantForSection('My classes'),
      FantasyVariant.enchantedLibrary,
    );
    expect(
      draft.fantasyVariantForSection('Students'),
      FantasyVariant.enchantedLibrary,
    );
    expect(
      draft.fantasyVariantForSection('Games'),
      FantasyVariant.dragonGarden,
    );
    expect(
      draft.fantasyVariantForSection('Access Requests'),
      FantasyVariant.dragonGarden,
    );
  });

  testWidgets('Fantasy background and decorations remain independent', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.fantasy
      ..device = PreviewDevice.mobile
      ..elementMotion = 0;
    addTearDown(draft.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    draft.backgroundIntensity = 0;
    draft.decorationIntensity = 100;
    await show(tester, draft);
    expect(find.byType(InstitutionFantasyBackground), findsNothing);
    expect(find.byType(InstitutionFantasyScene), findsOneWidget);
    draft.backgroundIntensity = 100;
    draft.decorationIntensity = 0;
    await show(tester, draft);
    expect(find.byType(InstitutionFantasyBackground), findsOneWidget);
    expect(find.byType(InstitutionFantasyScene), findsNothing);
  });

  testWidgets('Fantasy element motion respects system reduce motion', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.fantasy
      ..device = PreviewDevice.mobile
      ..elementMotion = 100;
    addTearDown(draft.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester, draft);
    for (final element in FantasyDecorationId.values) {
      final motion = tester.widget<TweenAnimationBuilder<double>>(
        find.byKey(ValueKey('fantasy-motion-${element.name}')),
      );
      expect(motion.duration, Duration.zero);
      expect(motion.tween.end, 0);
    }
  });

  testWidgets(
    'Fantasy decorations drag, scale and become non-interactive outside edit mode',
    (tester) async {
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.fantasy
        ..device = PreviewDevice.mobile
        ..editFantasyDecorations = true
        ..elementMotion = 0;
      addTearDown(draft.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await show(tester, draft);
      const key = (
        variant: FantasyVariant.floatingCastle,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
        element: FantasyDecorationId.hero,
      );
      final original = FantasyDecorationGeometry.recommended(key);
      await tester.drag(
        find.byKey(const ValueKey('fantasy-element-hero')),
        const Offset(-45, 95),
      );
      await tester.pump();
      final moved = FantasyDecorationGeometry.adjustedRect(
        key,
        draft.fantasyAdjustment(key),
      );
      expect((moved.center - original.center).distance, greaterThan(50));
      final beforeScale = moved.center;
      draft.changeFantasyAdjustment(
        key,
        draft.fantasyAdjustment(key).copyWith(scale: 1.5, opacity: .5),
      );
      expect(
        FantasyDecorationGeometry.adjustedRect(
          key,
          draft.fantasyAdjustment(key),
        ).center,
        beforeScale,
      );
      expect(
        find.byKey(const ValueKey('fantasy-protected-zones')),
        findsOneWidget,
      );
      draft.update(() => draft.editFantasyDecorations = false);
      await show(tester, draft);
      final pointer = tester.widget<IgnorePointer>(
        find
            .descendant(
              of: find.byKey(const ValueKey('fantasy-element-hero')),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      expect(pointer.ignoring, isTrue);
    },
  );
  testWidgets(
    'Fantasy editor exposes scenes, controls, selection and expanded preview',
    (tester) async {
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.fantasy
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
      for (final scene in FantasyVariant.values) {
        expect(
          find.byKey(ValueKey('fantasy-variant-${scene.name}')),
          findsOneWidget,
        );
      }
      final enchantedLibrary = find.byKey(
        const ValueKey('fantasy-variant-enchantedLibrary'),
      );
      await tester.ensureVisible(enchantedLibrary);
      await tester.tap(enchantedLibrary);
      await tester.pumpAndSettle();
      expect(draft.fantasyVariant, FantasyVariant.enchantedLibrary);
      await tester.ensureVisible(
        find.byKey(const ValueKey('fantasy-preview-by-section')),
      );
      await tester.tap(
        find.byKey(const ValueKey('fantasy-preview-by-section')),
      );
      await tester.pumpAndSettle();
      expect(draft.fantasyPreviewBySection, isTrue);
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
      draft.update(() => draft.fantasyPreviewBySection = false);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('edit-fantasy-decorations')),
      );
      await tester.tap(find.byKey(const ValueKey('edit-fantasy-decorations')));
      await tester.pumpAndSettle();
      expect(draft.editFantasyDecorations, isTrue);
      expect(
        find.byKey(const ValueKey('fantasy-decoration-editor')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('fantasy-select-mushrooms')),
      );
      await tester.tap(find.byKey(const ValueKey('fantasy-select-mushrooms')));
      await tester.pumpAndSettle();
      expect(draft.selectedFantasyDecoration, FantasyDecorationId.mushrooms);
      await tester.ensureVisible(
        find.byKey(const ValueKey('fantasy-element-size')),
      );
      await tester.drag(
        find.byKey(const ValueKey('fantasy-element-size')),
        const Offset(80, 0),
      );
      await tester.pumpAndSettle();
      final key = (
        variant: FantasyVariant.enchantedLibrary,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
        element: FantasyDecorationId.mushrooms,
      );
      expect(draft.fantasyAdjustment(key).scale, greaterThan(1));
      draft.update(() => draft.template = InstitutionTemplate.academy);
      await tester.pump();
      expect(
        draft.fantasyAdjustment((
          variant: key.variant,
          template: InstitutionTemplate.academy,
          device: key.device,
          element: key.element,
        )).scale,
        1,
      );
      draft.update(() => draft.template = InstitutionTemplate.orbit);
      await tester.pump();
      expect(draft.fantasyAdjustment(key).scale, greaterThan(1));
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
