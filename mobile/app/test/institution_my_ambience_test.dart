import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_my_ambience_validation.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_template_preview.dart';

Future<Uint8List> png(
  int width,
  int height, {
  required bool transparent,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = transparent ? const Color(0x00FFFFFF) : Colors.blue,
  );
  if (transparent) {
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      width / 4,
      Paint()..color = Colors.blue,
    );
  }
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('validates format, byte limit, dimensions, and real alpha', () async {
    final background = await png(320, 200, transparent: false);
    final element = await png(40, 40, transparent: true);
    expect(
      (await validateMyAmbienceFile(
        'landscape.png',
        background,
        element: false,
      )).width,
      320,
    );
    expect(
      (await validateMyAmbienceFile(
        'sticker.png',
        element,
        element: true,
      )).height,
      40,
    );
    await expectLater(
      validateMyAmbienceFile('fake.webp', background, element: false),
      throwsA(isA<MyAmbienceValidationException>()),
    );
    await expectLater(
      validateMyAmbienceFile('opaque.png', background, element: true),
      throwsA(isA<MyAmbienceValidationException>()),
    );
    await expectLater(
      validateMyAmbienceFile(
        'huge.png',
        Uint8List(5 * 1024 * 1024 + 1),
        element: false,
      ),
      throwsA(isA<MyAmbienceValidationException>()),
    );
    await expectLater(
      validateMyAmbienceFile(
        'small.png',
        await png(8, 8, transparent: true),
        element: true,
      ),
      throwsA(isA<MyAmbienceValidationException>()),
    );
    await expectLater(
      validateMyAmbienceFile('art.svg', element, element: true),
      throwsA(isA<MyAmbienceValidationException>()),
    );
    final animatedPng = Uint8List.fromList([
      ...background.sublist(0, 8),
      0,
      0,
      0,
      0,
      0x61,
      0x63,
      0x54,
      0x4c,
      0,
      0,
      0,
      0,
      ...background.sublist(8),
    ]);
    await expectLater(
      validateMyAmbienceFile('animated.png', animatedPng, element: false),
      throwsA(isA<MyAmbienceValidationException>()),
    );
    final oversizedCanvas = Uint8List.fromList(background);
    oversizedCanvas[16] = 0;
    oversizedCanvas[17] = 0;
    oversizedCanvas[18] = 0x20;
    oversizedCanvas[19] = 0;
    await expectLater(
      validateMyAmbienceFile('too-wide.png', oversizedCanvas, element: false),
      throwsA(isA<MyAmbienceValidationException>()),
    );
  });

  test(
    'five elements, replacement/removal, relative edits and focal points stay independent',
    () async {
      final draft = InstitutionBrandDraft();
      final element = await validateMyAmbienceFile(
        'sticker.png',
        await png(40, 40, transparent: true),
        element: true,
      );
      final ids = [for (var i = 0; i < 5; i++) draft.addMyElement(element)];
      expect(() => draft.addMyElement(element), throwsStateError);
      final mobile = (
        id: ids.first,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
      );
      final desktop = (
        id: ids.first,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.desktop,
      );
      final academy = (
        id: ids.first,
        template: InstitutionTemplate.academy,
        device: PreviewDevice.mobile,
      );
      draft.changeMyAdjustment(
        mobile,
        const OceanDecorationAdjustment(
          shift: Offset(.2, .3),
          scale: 2,
          opacity: .5,
        ),
      );
      expect(draft.myAdjustment(desktop).scale, 1);
      expect(draft.myAdjustment(academy).shift, Offset.zero);
      draft.setMyFocalPoint(PreviewDevice.mobile, const Offset(.8, -.5));
      expect(draft.myFocalPoints[PreviewDevice.desktop], Offset.zero);
      draft.replaceMyElement(ids.first, element);
      expect(draft.myAdjustment(mobile).scale, 2);
      draft.removeMyElement(ids.first);
      expect(draft.myElements.length, 4);
      expect(draft.myAdjustments.containsKey(mobile), isFalse);
      draft.addMyElement(element);
      expect(draft.myElements.length, 5);
      draft.dispose();
    },
  );

  testWidgets(
    'custom background covers without stretching across nine templates, roles and devices',
    (tester) async {
      final draft = InstitutionBrandDraft();
      draft.ambience = InstitutionAmbience.my;
      final files = await tester.runAsync(
        () async => (
          background: await validateMyAmbienceFile(
            'portrait.png',
            await png(200, 320, transparent: false),
            element: false,
          ),
          element: await validateMyAmbienceFile(
            'art.png',
            await png(40, 40, transparent: true),
            element: true,
          ),
        ),
      );
      draft.setMyBackground(files!.background);
      draft.addMyElement(files.element);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1100,
              height: 750,
              child: InstitutionTemplatePreview(
                draft: draft,
                institutionName: 'Demo School',
              ),
            ),
          ),
        ),
      );
      for (final template in InstitutionTemplate.values) {
        for (final role in PreviewRole.values) {
          for (final device in PreviewDevice.values) {
            draft.update(() {
              draft.template = template;
              draft.role = role;
              draft.device = device;
            });
            await tester.pump();
            expect(find.byKey(const ValueKey('ambience-my')), findsOneWidget);
            expect(
              tester.takeException(),
              isNull,
              reason: '$template $role $device',
            );
          }
        }
      }
      final cover = tester
          .widgetList<Image>(find.byType(Image))
          .where((image) => image.fit == BoxFit.cover);
      expect(cover, isNotEmpty);
      draft.dispose();
    },
  );

  testWidgets(
    'editing a custom element drags relatively and reduced motion keeps it static',
    (tester) async {
      tester.view.physicalSize = const Size(430, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final element = await tester.runAsync(
        () async => validateMyAmbienceFile(
          'art.png',
          await png(60, 60, transparent: true),
          element: true,
        ),
      );
      final draft = InstitutionBrandDraft()
        ..ambience = InstitutionAmbience.my
        ..device = PreviewDevice.mobile
        ..editMyDecorations = true
        ..elementMotion = 100;
      addTearDown(draft.dispose);
      final id = draft.addMyElement(element!);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: InstitutionTemplatePreview(
                draft: draft,
                institutionName: 'Demo',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final key = (id: id, template: draft.template, device: draft.device);
      final before = draft.myAdjustment(key).shift;
      await tester.drag(
        find.byKey(ValueKey('my-element-$id')),
        const Offset(-40, 30),
      );
      await tester.pump();
      expect(draft.myAdjustment(key).shift, isNot(before));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'predefined element hides only matching scene, template and device, then restores',
    () {
      final draft = InstitutionBrandDraft();
      const key = (
        variant: OceanVariant.turtleReef,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
        element: OceanDecorationId.character,
      );
      const other = (
        variant: OceanVariant.sharkReef,
        template: InstitutionTemplate.orbit,
        device: PreviewDevice.mobile,
        element: OceanDecorationId.character,
      );
      draft.changeOceanAdjustment(
        key,
        draft.oceanAdjustment(key).copyWith(hidden: true),
      );
      expect(draft.oceanAdjustment(key).hidden, isTrue);
      expect(draft.oceanAdjustment(other).hidden, isFalse);
      draft.resetOceanAdjustment(key);
      expect(draft.oceanAdjustment(key).hidden, isFalse);
      draft.dispose();
    },
  );
}
