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
  test(
    'Transparency is independent, preserves RGB and resets with palettes',
    () {
      final draft = InstitutionBrandDraft();
      addTearDown(draft.dispose);
      final rgb = {
        for (final slot in InstitutionColorSlot.values)
          slot: draft.colorFor(slot),
      };
      for (final slot in InstitutionColorSlot.values) {
        draft.setTransparency(slot, 50);
        expect(draft.transparencyFor(slot), 50);
        expect(draft.colorFor(slot), rgb[slot]);
        for (final other in InstitutionColorSlot.values.where(
          (item) => item != slot,
        )) {
          if (InstitutionColorSlot.values.indexOf(other) >
              InstitutionColorSlot.values.indexOf(slot)) {
            expect(draft.transparencyFor(other), 0);
          }
        }
      }
      draft.setTransparency(InstitutionColorSlot.primary, 0);
      draft.setTransparency(InstitutionColorSlot.secondary, 100);
      expect(draft.surfaceColor(InstitutionColorSlot.primary).a, 1);
      expect(draft.surfaceColor(InstitutionColorSlot.secondary).a, 0);
      expect(
        draft.surfaceColor(InstitutionColorSlot.accent).a,
        closeTo(.5, .01),
      );
      draft.setColor(InstitutionColorSlot.accent, const Color(0xFFAA22BB));
      expect(draft.transparencyFor(InstitutionColorSlot.accent), 50);
      draft.applyPalette(institutionPalettes[2]);
      for (final slot in InstitutionColorSlot.values) {
        expect(draft.transparencyFor(slot), 0);
      }
      draft.setTransparency(InstitutionColorSlot.background, 75);
      draft.restoreTemplateDefaults();
      expect(draft.transparencyFor(InstitutionColorSlot.background), 0);
    },
  );
  for (final percent in [0, 50, 100]) {
    testWidgets('Fantasy preview composited transparency $percent%', (
      tester,
    ) async {
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.fantasy
        ..device = PreviewDevice.mobile
        ..elementMotion = 0;
      addTearDown(draft.dispose);
      tester.view.physicalSize = const Size(430, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final slot in InstitutionColorSlot.values) {
        draft.setTransparency(slot, percent.toDouble());
      }
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
          InstitutionFantasyAssets.fireflies,
          InstitutionFantasyAssets.mushrooms,
          InstitutionFantasyAssets.lantern,
        ]) {
          await precacheImage(AssetImage(path), context);
        }
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(InstitutionTemplatePreview),
        matchesGoldenFile('goldens/colors-transparency-$percent.png'),
      );
    });
  }

  test('saturation and lightness preserve hue and other color channels', () {
    final draft = InstitutionBrandDraft();
    addTearDown(draft.dispose);
    for (final slot in InstitutionColorSlot.values) {
      draft.applyPalette(institutionPalettes.first);
      final before = {
        for (final item in InstitutionColorSlot.values)
          item: draft.colorFor(item),
      };
      final hue = draft.hslFor(slot).hue;
      draft.setColorSaturation(slot, 0);
      expect(draft.hslFor(slot).saturation, lessThan(.01));
      draft.setColorSaturation(slot, .8);
      expect(draft.hslFor(slot).hue, closeTo(hue, 1.5));
      draft.setColorLightness(slot, .72);
      expect(draft.hslFor(slot).lightness, closeTo(.72, .01));
      expect(draft.hslFor(slot).hue, closeTo(hue, 1.5));
      for (final other in InstitutionColorSlot.values.where((e) => e != slot)) {
        expect(draft.colorFor(other), before[other]);
      }
    }
    draft.applyPalette(institutionPalettes[3]);
    expect(draft.primary, institutionPalettes[3].primary);
    expect(draft.secondary, institutionPalettes[3].secondary);
  });

  testWidgets('HEX, color axes, contrast warning and live preview stay in sync', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()..ambience = InstitutionAmbience.none;
    addTearDown(draft.dispose);
    tester.view.physicalSize = const Size(1240, 1480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Inter'),
        home: Scaffold(
          backgroundColor: const Color(0xFF080D24),
          body: SingleChildScrollView(
            child: InstitutionBrandEditor(
              draft: draft,
              institutionName: 'Aurora Academy',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colors').first);
    await tester.pumpAndSettle();
    final baseline = {
      InstitutionColorSlot.secondary: draft.secondary,
      InstitutionColorSlot.accent: draft.accent,
      InstitutionColorSlot.background: draft.background,
    };
    await expectLater(
      find.byKey(const ValueKey('colors-editor')),
      matchesGoldenFile('goldens/colors-primary-default.png'),
    );
    draft.setColorSaturation(InstitutionColorSlot.primary, .12);
    draft.setColorLightness(InstitutionColorSlot.primary, .72);
    await tester.pumpAndSettle();
    for (final entry in baseline.entries) {
      expect(draft.colorFor(entry.key), entry.value);
    }
    final saturation = tester.widget<Slider>(
      find.byKey(const ValueKey('color-saturation-Primary')),
    );
    final lightness = tester.widget<Slider>(
      find.byKey(const ValueKey('color-lightness-Primary')),
    );
    expect(saturation.value, closeTo(.12, .01));
    expect(lightness.value, closeTo(.72, .01));
    expect(
      find.text(
        '#${draft.primary.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      ),
      findsOneWidget,
    );
    await expectLater(
      find.byKey(const ValueKey('colors-editor')),
      matchesGoldenFile('goldens/colors-primary-adjusted.png'),
    );

    final beforeDrag = draft.primary;
    final hueBeforeDrag = draft.hslFor(InstitutionColorSlot.primary).hue;
    await tester.drag(
      find.byKey(const ValueKey('color-saturation-Primary')),
      const Offset(45, 0),
    );
    await tester.pumpAndSettle();
    expect(draft.primary, isNot(beforeDrag));
    expect(
      draft.hslFor(InstitutionColorSlot.primary).hue,
      closeTo(hueBeforeDrag, 1.5),
    );
    for (final entry in baseline.entries) {
      expect(draft.colorFor(entry.key), entry.value);
    }

    final hexField = find.byKey(
      ValueKey('hex-Primary-${draft.primary.toARGB32()}'),
    );
    await tester.enterText(hexField, '#12AABB');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(draft.primary, const Color(0xFF12AABB));
    expect(
      tester
          .widget<Slider>(
            find.byKey(const ValueKey('color-saturation-Primary')),
          )
          .value,
      closeTo(HSLColor.fromColor(draft.primary).saturation, .001),
    );
    expect(
      tester
          .widget<Slider>(find.byKey(const ValueKey('color-lightness-Primary')))
          .value,
      closeTo(HSLColor.fromColor(draft.primary).lightness, .001),
    );
    draft.setColor(InstitutionColorSlot.primary, draft.background);
    await tester.pumpAndSettle();
    expect(find.textContaining('Low contrast:'), findsOneWidget);
    expect(draft.primary, draft.background);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all four color controls remain usable at mobile width', (
    tester,
  ) async {
    final draft = InstitutionBrandDraft()..ambience = InstitutionAmbience.none;
    addTearDown(draft.dispose);
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Inter'),
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colors').first);
    await tester.pumpAndSettle();
    for (final name in ['Primary', 'Secondary', 'Accent', 'Background']) {
      final slider = find.byKey(ValueKey('color-lightness-$name'));
      expect(slider, findsOneWidget);
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      final transparency = find.byKey(ValueKey('color-transparency-$name'));
      expect(transparency, findsOneWidget);
      await tester.ensureVisible(transparency);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
