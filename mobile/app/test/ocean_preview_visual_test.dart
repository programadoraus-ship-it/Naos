import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_editor.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_ocean_ambience.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_ocean_scene.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_template_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  InstitutionBrandDraft visualDraft({bool motion = false}) =>
      InstitutionBrandDraft()..elementMotion = motion ? 60 : 0;

  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await loader.load();
  });

  for (final pair in [(0, 100), (100, 0), (0, 0), (100, 100)]) {
    testWidgets('Ocean layers ${pair.$1} ${pair.$2}', (tester) async {
      final draft = visualDraft();
      addTearDown(draft.dispose);
      draft.update(() {
        draft.ambience = InstitutionAmbience.ocean;
        draft.device = PreviewDevice.mobile;
        draft.backgroundIntensity = pair.$1;
        draft.decorationIntensity = pair.$2;
      });
      tester.view.physicalSize = const Size(430, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
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
        if (pair.$1 > 0) {
          await precacheImage(
            ResizeImage(
              const AssetImage(InstitutionOceanAmbience.seascape),
              width: 760,
            ),
            context,
          );
        }
        if (pair.$2 > 0) {
          await precacheImage(
            const AssetImage(InstitutionOceanAmbience.turtle),
            context,
          );
          await precacheImage(
            const AssetImage(InstitutionOceanAmbience.coral),
            context,
          );
        }
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(InstitutionTemplatePreview),
        matchesGoldenFile('goldens/ocean-layers-${pair.$1}-${pair.$2}.png'),
      );
    });
  }

  for (final device in PreviewDevice.values) {
    testWidgets('Whole turtle float ${device.name}', (tester) async {
      final draft = visualDraft(motion: true);
      addTearDown(draft.dispose);
      draft.update(() {
        draft.ambience = InstitutionAmbience.ocean;
        draft.device = device;
        draft.oceanVariant = OceanVariant.turtleReef;
      });
      tester.view.physicalSize = device == PreviewDevice.mobile
          ? const Size(430, 760)
          : const Size(1180, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF080D24),
            body: Center(
              child: InstitutionTemplatePreview(
                draft: draft,
                institutionName: 'Aurora Academy',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));
      await tester.runAsync(() async {
        final context = tester.element(find.byType(InstitutionTemplatePreview));
        await precacheImage(
          const AssetImage(InstitutionOceanAmbience.turtle),
          context,
        );
        await precacheImage(
          ResizeImage(
            const AssetImage(InstitutionOceanAmbience.seascape),
            width: device == PreviewDevice.mobile ? 760 : 1400,
          ),
          context,
        );
      });
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 2500));
      expect(find.byKey(const ValueKey('turtle-left-flipper')), findsNothing);
      expect(find.byKey(const ValueKey('turtle-right-flipper')), findsNothing);
      await expectLater(
        find.byType(InstitutionTemplatePreview),
        matchesGoldenFile(
          'goldens/ocean-turtle-whole-float-${device.name}.png',
        ),
      );
    });
  }

  for (final intensity in [0, 50, 100]) {
    testWidgets('Ocean screenshot intensity $intensity', (tester) async {
      final draft = visualDraft();
      addTearDown(draft.dispose);
      draft.update(() {
        draft.ambience = InstitutionAmbience.ocean;
        draft.device = PreviewDevice.mobile;
        draft.decorationIntensity = intensity;
      });
      tester.view.physicalSize = const Size(430, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF080D24),
            body: Center(
              child: InstitutionTemplatePreview(
                draft: draft,
                institutionName: 'Aurora Academy',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (intensity > 0) {
        await tester.runAsync(() async {
          final context = tester.element(
            find.byType(InstitutionTemplatePreview),
          );
          await precacheImage(
            ResizeImage(
              const AssetImage(InstitutionOceanAmbience.seascape),
              width: 760,
            ),
            context,
          );
          await precacheImage(
            const AssetImage(InstitutionOceanAmbience.turtle),
            context,
          );
        });
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(InstitutionTemplatePreview),
        matchesGoldenFile('goldens/ocean-intensity-$intensity.png'),
      );
    });
  }

  for (final template in InstitutionTemplate.values) {
    for (final device in PreviewDevice.values) {
      testWidgets('Ocean template ${template.name} ${device.name}', (
        tester,
      ) async {
        final draft = visualDraft();
        addTearDown(draft.dispose);
        draft.update(() {
          draft.ambience = InstitutionAmbience.ocean;
          draft.template = template;
          draft.device = device;
          draft.oceanVariant = OceanVariant.turtleReef;
        });
        tester.view.physicalSize = device == PreviewDevice.mobile
            ? const Size(430, 760)
            : const Size(1180, 680);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
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
          final context = tester.element(
            find.byType(InstitutionTemplatePreview),
          );
          await precacheImage(
            ResizeImage(
              const AssetImage(InstitutionOceanAmbience.seascape),
              width: device == PreviewDevice.mobile ? 760 : 1400,
            ),
            context,
          );
          await precacheImage(
            const AssetImage(InstitutionOceanAmbience.turtle),
            context,
          );
          await precacheImage(
            const AssetImage(InstitutionOceanAmbience.coral),
            context,
          );
        });
        await tester.pump();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(InstitutionTemplatePreview),
          matchesGoldenFile(
            'goldens/ocean-template-${template.name}-${device.name}.png',
          ),
        );
      });
    }
  }

  for (final variant in [
    OceanVariant.turtleReef,
    OceanVariant.jellyfishGarden,
  ]) {
    for (final template in [
      InstitutionTemplate.orbit,
      InstitutionTemplate.academy,
    ]) {
      for (final device in PreviewDevice.values) {
        testWidgets(
          'Ocean edit sample ${variant.name} ${template.name} ${device.name}',
          (tester) async {
            final draft = visualDraft();
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
                : const Size(1180, 680);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: const MediaQueryData(disableAnimations: true),
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
              final context = tester.element(
                find.byType(InstitutionTemplatePreview),
              );
              await precacheImage(
                ResizeImage(
                  const AssetImage(InstitutionOceanAmbience.seascape),
                  width: device == PreviewDevice.mobile ? 760 : 1400,
                ),
                context,
              );
              for (final path in [
                InstitutionOceanAmbience.characterAsset(variant),
                InstitutionOceanAmbience.fishSchool,
                InstitutionOceanAmbience.coralCluster,
                InstitutionOceanAmbience.kelp,
              ]) {
                await precacheImage(AssetImage(path), context);
              }
            });
            await tester.pump();
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byType(InstitutionTemplatePreview),
              matchesGoldenFile(
                'goldens/ocean-edit-${variant.name}-${template.name}-${device.name}.png',
              ),
            );
          },
        );
      }
    }
  }

  for (final device in PreviewDevice.values) {
    for (final variant in OceanVariant.values) {
      testWidgets('Ocean screenshot ${device.name} ${variant.name}', (
        tester,
      ) async {
        final draft = visualDraft();
        addTearDown(draft.dispose);
        draft.update(() {
          draft.ambience = InstitutionAmbience.ocean;
          draft.device = device;
          draft.role = PreviewRole.student;
          draft.oceanVariant = variant;
          draft.decorationIntensity = 65;
        });
        tester.view.physicalSize = device == PreviewDevice.mobile
            ? const Size(430, 760)
            : const Size(1180, 680);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF080D24),
              body: Center(
                child: InstitutionTemplatePreview(
                  draft: draft,
                  institutionName: 'Aurora Academy',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final context = tester.element(
            find.byType(InstitutionTemplatePreview),
          );
          for (final asset in [
            InstitutionOceanAmbience.characterAsset(variant),
            InstitutionOceanAmbience.coral,
            InstitutionOceanAmbience.sharkCoral,
          ]) {
            await precacheImage(AssetImage(asset), context);
          }
          await precacheImage(
            ResizeImage(
              const AssetImage(InstitutionOceanAmbience.seascape),
              width: device == PreviewDevice.mobile ? 760 : 1400,
            ),
            context,
          );
        });
        await tester.pump();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(InstitutionTemplatePreview),
          matchesGoldenFile('goldens/ocean-${device.name}-${variant.name}.png'),
        );
      });
    }
  }

  testWidgets('Ocean screenshot expanded mobile', (tester) async {
    final draft = visualDraft();
    addTearDown(draft.dispose);
    draft.update(() {
      draft.ambience = InstitutionAmbience.ocean;
      draft.device = PreviewDevice.mobile;
      draft.oceanVariant = OceanVariant.turtleReef;
    });
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
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
    await tester.runAsync(() async {
      final context = tester.element(
        find.byType(InstitutionTemplatePreview).first,
      );
      await precacheImage(
        ResizeImage(
          const AssetImage(InstitutionOceanAmbience.seascape),
          width: 760,
        ),
        context,
      );
      await precacheImage(
        const AssetImage(InstitutionOceanAmbience.turtle),
        context,
      );
      await precacheImage(
        const AssetImage(InstitutionOceanAmbience.coral),
        context,
      );
    });
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('expand-preview')));
    await tester.tap(find.byKey(const ValueKey('expand-preview')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Dialog).first,
      matchesGoldenFile('goldens/ocean-mobile-expanded.png'),
    );
  });

  testWidgets('Ocean screenshot expanded desktop', (tester) async {
    final draft = visualDraft();
    addTearDown(draft.dispose);
    draft.update(() {
      draft.ambience = InstitutionAmbience.ocean;
      draft.device = PreviewDevice.desktop;
      draft.oceanVariant = OceanVariant.sharkReef;
    });
    tester.view.physicalSize = const Size(1240, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
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
    await tester.ensureVisible(find.byKey(const ValueKey('expand-preview')));
    await tester.tap(find.byKey(const ValueKey('expand-preview')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(
        find.byType(InstitutionTemplatePreview).first,
      );
      await precacheImage(
        ResizeImage(
          const AssetImage(InstitutionOceanAmbience.seascape),
          width: 1400,
        ),
        context,
      );
      await precacheImage(
        const AssetImage(InstitutionOceanAmbience.shark),
        context,
      );
      await precacheImage(
        const AssetImage(InstitutionOceanAmbience.sharkCoral),
        context,
      );
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Dialog).first,
      matchesGoldenFile('goldens/ocean-desktop-expanded.png'),
    );
  });

  for (final sample in ['large-coral-corner', 'turtle-moved-left']) {
    testWidgets('Ocean editable composition $sample', (tester) async {
      final coral = sample == 'large-coral-corner';
      final device = coral ? PreviewDevice.desktop : PreviewDevice.mobile;
      final template = coral
          ? InstitutionTemplate.heritage
          : InstitutionTemplate.orbit;
      final element = coral
          ? OceanDecorationId.coral
          : OceanDecorationId.character;
      final draft = visualDraft();
      addTearDown(draft.dispose);
      draft.update(() {
        draft.ambience = InstitutionAmbience.ocean;
        draft.device = device;
        draft.template = template;
        draft.editOceanDecorations = true;
        draft.selectedOceanDecoration = element;
      });
      final key = (
        variant: OceanVariant.turtleReef,
        template: template,
        device: device,
        element: element,
      );
      final frame = OceanDecorationGeometry.frame(device);
      final base = OceanDecorationGeometry.recommended(key);
      final centre = coral ? const Offset(940, 400) : const Offset(35, 245);
      draft.changeOceanAdjustment(
        key,
        OceanDecorationAdjustment(
          shift: Offset(
            (centre.dx - base.center.dx) / frame.width,
            (centre.dy - base.center.dy) / frame.height,
          ),
          scale: coral ? 3 : .7,
        ),
      );
      tester.view.physicalSize = coral
          ? const Size(1180, 680)
          : const Size(430, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
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
        await precacheImage(
          ResizeImage(
            const AssetImage(InstitutionOceanAmbience.seascape),
            width: coral ? 1400 : 760,
          ),
          context,
        );
        for (final path in [
          InstitutionOceanAmbience.turtle,
          InstitutionOceanAmbience.fishSchool,
          InstitutionOceanAmbience.coralCluster,
          InstitutionOceanAmbience.kelp,
        ]) {
          await precacheImage(AssetImage(path), context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(InstitutionTemplatePreview),
        matchesGoldenFile('goldens/ocean-edit-$sample.png'),
      );
    });
  }
}
