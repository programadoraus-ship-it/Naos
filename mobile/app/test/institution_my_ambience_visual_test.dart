import 'dart:ui' as ui;

import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_template_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> sampleImage(
  int width,
  int height, {
  required bool background,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (background) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()
        ..shader =
            const LinearGradient(
              colors: [Color(0xFF7B9CD6), Color(0xFFDFC29D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(
              Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
            ),
    );
    canvas.drawCircle(
      Offset(width * .7, height * .35),
      width * .14,
      Paint()..color = const Color(0xFFF9E4A9),
    );
  } else {
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      width * .38,
      Paint()..color = const Color(0xFFE2A450),
    );
    canvas.drawCircle(
      Offset(width * .62, height * .40),
      width * .06,
      Paint()..color = Colors.white,
    );
  }
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await loader.load();
  });

  for (final device in PreviewDevice.values) {
    for (final portrait in [false, true]) {
      testWidgets(
        'My ambience sample ${device.name} ${portrait ? 'portrait' : 'landscape'}',
        (tester) async {
          final bgWidth = portrait ? 440 : 700;
          final bgHeight = portrait ? 700 : 440;
          tester.view.physicalSize = device == PreviewDevice.mobile
              ? const Size(430, 760)
              : const Size(1180, 680);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final files = await tester.runAsync(
            () async => (
              background: await sampleImage(
                bgWidth,
                bgHeight,
                background: true,
              ),
              element: await sampleImage(140, 140, background: false),
            ),
          );
          final draft = InstitutionBrandDraft()
            ..ambience = InstitutionAmbience.my
            ..device = device
            ..elementMotion = 0;
          addTearDown(draft.dispose);
          draft.setMyBackground(
            MyAmbienceFile(
              name: 'sample.png',
              bytes: files!.background,
              width: bgWidth,
              height: bgHeight,
              format: 'PNG',
            ),
          );
          draft.addMyElement(
            MyAmbienceFile(
              name: 'element.png',
              bytes: files.element,
              width: 140,
              height: 140,
              format: 'PNG',
            ),
          );
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
            final context = tester.element(
              find.byType(InstitutionTemplatePreview),
            );
            await precacheImage(MemoryImage(files.background), context);
            await precacheImage(MemoryImage(files.element), context);
          });
          await tester.pump();
          await expectLater(
            find.byType(InstitutionTemplatePreview),
            matchesGoldenFile(
              'goldens/my-ambience-${device.name}-${portrait ? 'portrait' : 'landscape'}.png',
            ),
          );
        },
      );
    }
  }
}
