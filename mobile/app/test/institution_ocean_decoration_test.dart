import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_editor.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_ocean_ambience.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_ocean_scene.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_template_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  OceanDecorationKey key(
    OceanVariant variant,
    InstitutionTemplate template,
    PreviewDevice device,
    OceanDecorationId element,
  ) => (variant: variant, template: template, device: device, element: element);

  test('all scene elements can reach canvas edges without vanishing', () {
    for (final variant in OceanVariant.values) {
      for (final template in InstitutionTemplate.values) {
        for (final device in PreviewDevice.values) {
          for (final element in OceanDecorationId.values) {
            final item = key(variant, template, device, element);
            final result = OceanDecorationGeometry.constrain(
              item,
              const OceanDecorationAdjustment(
                shift: Offset(5, -5),
                scale: 4,
                opacity: -1,
              ),
            );
            final rect = OceanDecorationGeometry.adjustedRect(item, result.$1);
            final canvas = Offset.zero & OceanDecorationGeometry.frame(device);
            final intersection = rect.intersect(canvas);
            expect(result.$2, isTrue);
            expect(intersection.width, greaterThan(.99), reason: '$item');
            expect(intersection.height, greaterThan(.99), reason: '$item');
            expect(result.$1.opacity, inInclusiveRange(0, 1));
            expect(
              result.$1.scale,
              inInclusiveRange(
                OceanDecorationGeometry.minScale(item),
                OceanDecorationGeometry.maxScale(item),
              ),
            );
          }
        }
      }
    }
  });

  test('draft keeps independent scene, template and device adjustments', () {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    final turtleOrbitMobile = key(
      OceanVariant.turtleReef,
      InstitutionTemplate.orbit,
      PreviewDevice.mobile,
      OceanDecorationId.character,
    );
    final jellyOrbitMobile = key(
      OceanVariant.jellyfishGarden,
      InstitutionTemplate.orbit,
      PreviewDevice.mobile,
      OceanDecorationId.character,
    );
    final turtleAcademyMobile = key(
      OceanVariant.turtleReef,
      InstitutionTemplate.academy,
      PreviewDevice.mobile,
      OceanDecorationId.character,
    );
    final turtleOrbitDesktop = key(
      OceanVariant.turtleReef,
      InstitutionTemplate.orbit,
      PreviewDevice.desktop,
      OceanDecorationId.character,
    );
    draft.changeOceanAdjustment(
      turtleOrbitMobile,
      const OceanDecorationAdjustment(scale: .8, opacity: .45),
    );
    for (final other in [
      jellyOrbitMobile,
      turtleAcademyMobile,
      turtleOrbitDesktop,
    ]) {
      expect(draft.oceanAdjustment(other).scale, 1);
      expect(draft.oceanAdjustment(other).opacity, 1);
    }
    draft.changeOceanAdjustment(
      jellyOrbitMobile,
      const OceanDecorationAdjustment(scale: 1.1),
    );
    expect(draft.oceanAdjustment(turtleOrbitMobile).scale, .8);
    draft.resetOceanAdjustment(turtleOrbitMobile);
    expect(draft.oceanAdjustment(turtleOrbitMobile).scale, 1);
    expect(draft.oceanAdjustment(jellyOrbitMobile).scale, 1.1);
  });

  test('Coral and Plants have large scales without shifting their centre', () {
    for (final variant in OceanVariant.values) {
      for (final template in [
        InstitutionTemplate.orbit,
        InstitutionTemplate.academy,
        InstitutionTemplate.heritage,
        InstitutionTemplate.nexus,
      ]) {
        for (final device in PreviewDevice.values) {
          for (final element in [
            OceanDecorationId.coral,
            OceanDecorationId.plants,
          ]) {
            final item = key(variant, template, device, element);
            final frame = OceanDecorationGeometry.frame(device);
            final base = OceanDecorationGeometry.recommended(item);
            final shift = Offset(
              (frame.width / 2 - base.center.dx) / frame.width,
              (frame.height / 2 - base.center.dy) / frame.height,
            );
            final small = OceanDecorationGeometry.constrain(
              item,
              OceanDecorationAdjustment(shift: shift, scale: .5),
            ).$1;
            final large = OceanDecorationGeometry.constrain(
              item,
              OceanDecorationAdjustment(
                shift: shift,
                scale: OceanDecorationGeometry.maxScale(item),
              ),
            ).$1;
            expect(
              (OceanDecorationGeometry.adjustedRect(item, small).center -
                      OceanDecorationGeometry.adjustedRect(item, large).center)
                  .distance,
              lessThan(.001),
            );
            expect(
              OceanDecorationGeometry.visibleRect(item, large).width,
              greaterThan(
                OceanDecorationGeometry.visibleRect(item, small).width * 2,
              ),
            );
          }
        }
      }
    }
  });

  testWidgets('overlap warns without pushing an element away', (tester) async {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    draft.update(() {
      draft.ambience = InstitutionAmbience.ocean;
      draft.template = InstitutionTemplate.orbit;
      draft.device = PreviewDevice.mobile;
      draft.editOceanDecorations = true;
      draft.elementMotion = 0;
    });
    tester.view.physicalSize = const Size(430, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    final item = key(
      OceanVariant.turtleReef,
      InstitutionTemplate.orbit,
      PreviewDevice.mobile,
      OceanDecorationId.character,
    );
    final base = OceanDecorationGeometry.recommended(item);
    const drag = Offset(-82, 88);
    await tester.drag(
      find.byKey(const ValueKey('ocean-element-character')),
      drag,
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('ocean-protected-zones')), findsOneWidget);
    expect(draft.oceanOverlaps, contains(OceanDecorationId.character));
    final placed = OceanDecorationGeometry.adjustedRect(
      item,
      draft.oceanAdjustment(item),
    );
    expect((placed.center - (base.center + drag)).distance, lessThan(1));
  });

  for (final variant in [
    OceanVariant.turtleReef,
    OceanVariant.sharkReef,
    OceanVariant.jellyfishGarden,
  ]) {
    for (final template in [
      InstitutionTemplate.orbit,
      InstitutionTemplate.academy,
      InstitutionTemplate.heritage,
      InstitutionTemplate.nexus,
    ]) {
      for (final device in PreviewDevice.values) {
        testWidgets(
          'editable ${variant.name} ${template.name} ${device.name}',
          (tester) async {
            final draft = InstitutionBrandDraft();
            addTearDown(draft.dispose);
            draft.update(() {
              draft.ambience = InstitutionAmbience.ocean;
              draft.oceanVariant = variant;
              draft.template = template;
              draft.device = device;
              draft.editOceanDecorations = true;
              draft.elementMotion = 0;
            });
            tester.view.physicalSize = device == PreviewDevice.mobile
                ? const Size(430, 760)
                : const Size(1180, 700);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
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
            for (final element in OceanDecorationId.values) {
              expect(
                find.byKey(ValueKey('ocean-element-${element.name}')),
                findsOneWidget,
              );
            }
            final character = key(
              variant,
              template,
              device,
              OceanDecorationId.character,
            );
            await tester.drag(
              find.byKey(const ValueKey('ocean-element-character')),
              const Offset(2000, 0),
            );
            await tester.pump();
            expect(draft.oceanPlacementClamped, isTrue);
            final moved = OceanDecorationGeometry.adjustedRect(
              character,
              draft.oceanAdjustment(character),
            );
            final canvas = Offset.zero & OceanDecorationGeometry.frame(device);
            expect(moved.intersect(canvas).width, greaterThanOrEqualTo(1));
            expect(moved.intersect(canvas).height, greaterThanOrEqualTo(1));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('normal mode passes clicks through decorations', (tester) async {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    draft.update(() => draft.ambience = InstitutionAmbience.ocean);
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
    final element = find.byKey(const ValueKey('ocean-element-character'));
    final pointer = find
        .descendant(of: element, matching: find.byType(IgnorePointer))
        .first;
    expect(tester.widget<IgnorePointer>(pointer).ignoring, isTrue);
  });

  testWidgets('motion control is independent and reduced motion is static', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    draft.update(() {
      draft.ambience = InstitutionAmbience.ocean;
      draft.elementMotion = 100;
      draft.backgroundIntensity = 26;
      draft.decorationIntensity = 71;
    });
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: InstitutionTemplatePreview(
              draft: draft,
              institutionName: 'Aurora Academy',
            ),
          ),
        ),
      ),
    );
    for (final element in OceanDecorationId.values) {
      final tween = tester.widget<TweenAnimationBuilder<double>>(
        find.byKey(ValueKey('ocean-motion-${element.name}')),
      );
      expect(tween.duration, Duration.zero);
    }
    draft.setElementMotion(0);
    expect(draft.backgroundIntensity, 26);
    expect(draft.decorationIntensity, 71);
  });

  testWidgets(
    'all decorations animate while the shared background stays still',
    (tester) async {
      final draft = InstitutionBrandDraft();
      addTearDown(draft.dispose);
      draft.update(() {
        draft.ambience = InstitutionAmbience.ocean;
        draft.oceanVariant = OceanVariant.sharkReef;
        draft.elementMotion = 100;
      });
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
      final background = tester.widget<InstitutionOceanBackground>(
        find.byType(InstitutionOceanBackground),
      );
      await tester.pump(const Duration(milliseconds: 301));
      for (final element in OceanDecorationId.values) {
        final tween = tester.widget<TweenAnimationBuilder<double>>(
          find.byKey(ValueKey('ocean-motion-${element.name}')),
        );
        expect(tween.tween.end, 1, reason: element.name);
      }
      expect(
        tester
            .widget<InstitutionOceanBackground>(
              find.byType(InstitutionOceanBackground),
            )
            .intensityPercent,
        background.intensityPercent,
      );
      draft.setElementMotion(0);
      await tester.pump();
      for (final element in OceanDecorationId.values) {
        final tween = tester.widget<TweenAnimationBuilder<double>>(
          find.byKey(ValueKey('ocean-motion-${element.name}')),
        );
        expect(tween.duration, Duration.zero);
      }
    },
  );

  testWidgets('Shark Reef elements can all be selected and safely dragged', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    draft.update(() {
      draft.ambience = InstitutionAmbience.ocean;
      draft.oceanVariant = OceanVariant.sharkReef;
      draft.template = InstitutionTemplate.nexus;
      draft.device = PreviewDevice.desktop;
      draft.editOceanDecorations = true;
      draft.elementMotion = 0;
    });
    tester.view.physicalSize = const Size(1180, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    for (final element in OceanDecorationId.values) {
      final item = key(
        OceanVariant.sharkReef,
        InstitutionTemplate.nexus,
        PreviewDevice.desktop,
        element,
      );
      await tester.drag(
        find.byKey(ValueKey('ocean-element-${element.name}')),
        const Offset(2000, -2000),
      );
      await tester.pump();
      final rect = OceanDecorationGeometry.adjustedRect(
        item,
        draft.oceanAdjustment(item),
      );
      final canvas = Offset.zero & OceanDecorationGeometry.frame(draft.device);
      expect(rect.intersect(canvas).width, greaterThanOrEqualTo(1));
      expect(rect.intersect(canvas).height, greaterThanOrEqualTo(1));
      expect(draft.selectedOceanDecoration, element);
    }
  });

  testWidgets('editor exposes motion, selection, size, opacity and reset', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    draft.update(() => draft.ambience = InstitutionAmbience.ocean);
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InstitutionBrandEditor(
              draft: draft,
              institutionName: 'Aurora Academy',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('edit-ocean-decorations')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('ocean-decoration-editor')),
      findsOneWidget,
    );
    final fish = find.byKey(const ValueKey('ocean-select-fishSchool'));
    await tester.ensureVisible(fish);
    await tester.tap(fish);
    await tester.pump();
    expect(draft.selectedOceanDecoration, OceanDecorationId.fishSchool);
    tester
        .widget<Slider>(find.byKey(const ValueKey('ocean-element-size')))
        .onChanged!(.8);
    tester
        .widget<Slider>(find.byKey(const ValueKey('ocean-element-opacity')))
        .onChanged!(.4);
    await tester.pump();
    final selected = key(
      draft.oceanVariant,
      draft.template,
      draft.device,
      OceanDecorationId.fishSchool,
    );
    expect(draft.oceanAdjustment(selected).scale, closeTo(.8, .001));
    expect(draft.oceanAdjustment(selected).opacity, closeTo(.4, .001));
    await tester.ensureVisible(
      find.byKey(const ValueKey('ocean-reset-element')),
    );
    await tester.tap(find.byKey(const ValueKey('ocean-reset-element')));
    await tester.pump();
    expect(draft.oceanAdjustment(selected).scale, 1);
    expect(draft.oceanAdjustment(selected).opacity, 1);
    await tester.ensureVisible(find.text('Ambience').first);
    await tester.tap(find.text('Ambience').first);
    await tester.pumpAndSettle();
    tester
        .widget<Slider>(
          find.byKey(const ValueKey('element-motion-intensity-slider')),
        )
        .onChanged!(89);
    expect(draft.elementMotion, 89);
  });
}
