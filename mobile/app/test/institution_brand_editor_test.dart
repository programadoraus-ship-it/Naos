import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InstitutionBrandDraft draft;

  setUp(() => draft = InstitutionBrandDraft());
  tearDown(() => draft.dispose());

  Future<void> show(
    WidgetTester tester, {
    double width = 1240,
    bool reduced = false,
  }) async {
    tester.view.physicalSize = Size(width, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reduced,
            accessibleNavigation: reduced,
          ),
          child: Scaffold(
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
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  String renderedFamily(WidgetTester tester, Finder textFinder) {
    final richText = find.descendant(
      of: textFinder,
      matching: find.byType(RichText),
    );
    return tester.widget<RichText>(richText.first).text.style!.fontFamily!;
  }

  testWidgets(
    'selected bundled font reaches heading, navigation and preview button',
    (tester) async {
      await show(tester);
      await tap(tester, find.text('Typography').first);
      await tap(tester, find.byKey(const ValueKey('font-Lora Serif')));

      expect(draft.font, InstitutionFont.lora);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('font-sample-lora')))
            .style!
            .fontFamily,
        'Lora',
      );
      expect(
        renderedFamily(tester, find.byKey(const ValueKey('preview-heading'))),
        'Lora',
      );
      expect(renderedFamily(tester, find.text('Dashboard').last), 'Lora');
      expect(
        renderedFamily(
          tester,
          find.byKey(const ValueKey('preview-button-label')),
        ),
        'Lora',
      );
      expect(find.textContaining('áéíóú ñ ¿Qué?'), findsNWidgets(10));
      for (final font in InstitutionFont.values) {
        expect(
          tester
              .widget<Text>(find.byKey(ValueKey('font-sample-${font.name}')))
              .style!
              .fontFamily,
          switch (font) {
            InstitutionFont.inter => 'Inter',
            InstitutionFont.lora => 'Lora',
            InstitutionFont.spaceMono => 'Space Mono',
            InstitutionFont.nunito => 'Nunito',
            InstitutionFont.fredoka => 'Fredoka',
            InstitutionFont.playfairDisplay => 'Playfair Display',
            InstitutionFont.poppins => 'Poppins',
            InstitutionFont.quicksand => 'Quicksand',
            InstitutionFont.montserrat => 'Montserrat',
            InstitutionFont.bitter => 'Bitter',
          },
        );
      }
    },
  );

  testWidgets('all ten bundled fonts reach every role and device', (
    tester,
  ) async {
    await show(tester, width: 1120, reduced: true);
    expect(InstitutionFont.values, hasLength(10));

    for (final font in InstitutionFont.values) {
      for (final role in PreviewRole.values) {
        for (final device in PreviewDevice.values) {
          draft.update(() {
            draft.font = font;
            draft.role = role;
            draft.device = device;
          });
          await tester.pump();
          expect(
            renderedFamily(
              tester,
              find.byKey(const ValueKey('preview-heading')),
            ),
            draft.fontFamily,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$font / $role / $device must not overflow',
          );
        }
      }
    }
  });

  testWidgets(
    'all nine templates render all roles and devices without overflow',
    (tester) async {
      await show(tester, width: 1120, reduced: true);
      expect(InstitutionTemplate.values, hasLength(9));
      for (final template in InstitutionTemplate.values) {
        for (final role in PreviewRole.values) {
          for (final device in PreviewDevice.values) {
            draft.update(() {
              draft.template = template;
              draft.role = role;
              draft.device = device;
            });
            await tester.pump();
            expect(find.textContaining('Demonstration data'), findsOneWidget);
            expect(
              tester.takeException(),
              isNull,
              reason: '$template / $role / $device must not overflow',
            );
          }
        }
      }
    },
  );

  testWidgets('ambiences combine with templates and respect reduced motion', (
    tester,
  ) async {
    await show(tester, width: 1050, reduced: true);
    await tap(tester, find.text('Ambience').first);

    for (final ambience in InstitutionAmbience.values) {
      final label = switch (ambience) {
        InstitutionAmbience.none => 'None',
        InstitutionAmbience.space => 'Space',
        InstitutionAmbience.animals => 'Animals',
        InstitutionAmbience.ocean => 'Ocean',
        InstitutionAmbience.nature => 'Nature',
        InstitutionAmbience.fantasy => 'Fantasy',
        InstitutionAmbience.my => 'My ambience',
      };
      await tap(tester, find.byKey(ValueKey('ambience-$label')));
      expect(draft.ambience, ambience);
      expect(find.byKey(ValueKey('ambience-${ambience.name}')), findsWidgets);
      expect(tester.takeException(), isNull);
    }

    await tap(tester, find.byKey(const ValueKey('intensity-subtle')));
    expect(draft.decorationIntensity, 25);
  });

  testWidgets('Ocean uses final assets only when selected', (tester) async {
    await show(tester, reduced: true);
    expect(find.byKey(const ValueKey('ambience-ocean')), findsNothing);

    draft.update(() => draft.ambience = InstitutionAmbience.ocean);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ambience-ocean')), findsOneWidget);
    expect(find.byKey(const ValueKey('ocean-character-art')), findsOneWidget);
    expect(tester.takeException(), isNull);

    draft.update(() => draft.ambience = InstitutionAmbience.nature);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ocean-character-art')), findsNothing);
  });

  testWidgets('Ocean scenes, section mapping, and intensity keep draft', (
    tester,
  ) async {
    await show(tester, width: 1080, reduced: true);
    await tap(tester, find.text('Ambience').first);
    await tap(tester, find.byKey(const ValueKey('ambience-Ocean')));
    for (final variant in OceanVariant.values) {
      await tap(tester, find.byKey(ValueKey('ocean-variant-${variant.name}')));
      expect(draft.oceanVariant, variant);
      expect(
        find.byKey(ValueKey('ocean-scene-${variant.name}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
    await tap(tester, find.byKey(const ValueKey('ocean-preview-by-section')));
    expect(draft.oceanPreviewBySection, isTrue);
    draft.update(() {
      draft.role = PreviewRole.student;
      draft.previewSectionIndex = 1;
    });
    await tester.pump();
    expect(find.byKey(const ValueKey('ocean-scene-sharkReef')), findsOneWidget);
    draft.update(() => draft.previewSectionIndex = 2);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('ocean-scene-jellyfishGarden')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ocean-shared-background')),
      findsOneWidget,
    );

    draft.update(() => draft.setDecorationIntensity(0));
    await tester.pump();
    expect(draft.decorationIntensity, 0);
    draft.update(() => draft.setDecorationIntensity(50));
    await tester.pump();
    expect(draft.decorationIntensity, 50);
    draft.update(() => draft.setDecorationIntensity(100));
    await tester.pump();
    expect(draft.decorationIntensity, 100);
    draft.setBackgroundIntensity(37);
    await tap(tester, find.text('Typography').first);
    await tap(tester, find.text('Ambience').first);
    expect(draft.decorationIntensity, 100);
    expect(draft.backgroundIntensity, 37);
    expect(draft.oceanPreviewBySection, isTrue);
  });

  testWidgets('all Ocean scenes render at both sizes and all roles', (
    tester,
  ) async {
    await show(tester, width: 1120, reduced: true);
    draft.update(() => draft.ambience = InstitutionAmbience.ocean);
    for (final role in PreviewRole.values) {
      for (final device in PreviewDevice.values) {
        for (final variant in OceanVariant.values) {
          draft.update(() {
            draft.role = role;
            draft.device = device;
            draft.oceanVariant = variant;
            draft.oceanPreviewBySection = false;
          });
          await tester.pump();
          expect(
            find.byKey(ValueKey('ocean-scene-${variant.name}')),
            findsOneWidget,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$role / $device / $variant must not overflow',
          );
        }
      }
    }
  });

  testWidgets(
    'section preview is deterministic for each role and navigation tap',
    (tester) async {
      await show(tester, width: 1120, reduced: true);
      draft.update(() {
        draft.ambience = InstitutionAmbience.ocean;
        draft.oceanPreviewBySection = true;
      });
      for (final role in PreviewRole.values) {
        draft.update(() {
          draft.role = role;
          draft.previewSectionIndex = 0;
        });
        await tester.pump();
        expect(
          find.byKey(const ValueKey('ocean-scene-turtleReef')),
          findsOneWidget,
        );
        await tap(tester, find.byKey(const ValueKey('preview-nav-1')).first);
        expect(draft.previewSectionIndex, 1);
        expect(
          find.byKey(const ValueKey('ocean-scene-sharkReef')),
          findsOneWidget,
        );
        await tap(tester, find.byKey(const ValueKey('preview-nav-2')).first);
        expect(
          find.byKey(const ValueKey('ocean-scene-jellyfishGarden')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('ocean-shared-background')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    '0 percent hides only decoration and reduced motion removes scene fade',
    (tester) async {
      await show(tester, width: 1080, reduced: true);
      draft.update(() => draft.ambience = InstitutionAmbience.ocean);
      final primary = draft.primary;
      draft.setDecorationIntensity(0);
      await tester.pump();
      expect(find.byKey(const ValueKey('ocean-character-art')), findsNothing);
      expect(
        find.byKey(const ValueKey('ocean-shared-background')),
        findsOneWidget,
      );
      expect(draft.primary, primary);
      draft.setDecorationIntensity(50);
      await tester.pump();
      expect(find.byKey(const ValueKey('ambience-ocean')), findsOneWidget);
      draft.setDecorationIntensity(100);
      await tester.pump();
      expect(draft.primary, primary);
      final switcher = tester.widget<AnimatedSwitcher>(
        find.byKey(const ValueKey('ocean-scene-switcher')),
      );
      expect(switcher.duration, Duration.zero);
      expect(find.byKey(const ValueKey('turtle-left-flipper')), findsNothing);
    },
  );

  testWidgets('Ocean background and elements intensities are independent', (
    tester,
  ) async {
    await show(tester, width: 1080, reduced: true);
    draft.update(() => draft.ambience = InstitutionAmbience.ocean);
    final originalColor = draft.primary;
    draft.setBackgroundIntensity(0);
    draft.setDecorationIntensity(100);
    await tester.pump();
    expect(find.byKey(const ValueKey('ocean-shared-background')), findsNothing);
    expect(find.byKey(const ValueKey('ocean-character-art')), findsOneWidget);
    draft.setBackgroundIntensity(50);
    draft.setDecorationIntensity(0);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('ocean-shared-background')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ocean-character-art')), findsNothing);
    draft.setBackgroundIntensity(100);
    draft.setDecorationIntensity(100);
    await tester.pump();
    expect(draft.primary, originalColor);
    final background = tester.element(
      find.byKey(const ValueKey('ocean-shared-background')),
    );
    draft.update(() => draft.oceanVariant = OceanVariant.sharkReef);
    await tester.pump();
    expect(
      tester.element(find.byKey(const ValueKey('ocean-shared-background'))),
      same(background),
    );
    await tap(tester, find.text('Ambience').first);
    expect(
      find.byKey(const ValueKey('background-intensity-slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('decoration-intensity-slider')),
      findsOneWidget,
    );
    tester
        .widget<Slider>(
          find.byKey(const ValueKey('background-intensity-slider')),
        )
        .onChanged!(32);
    await tester.pump();
    expect(draft.backgroundIntensity, 32);
    expect(draft.decorationIntensity, 100);
    tester
        .widget<Slider>(
          find.byKey(const ValueKey('decoration-intensity-slider')),
        )
        .onChanged!(71);
    await tester.pump();
    expect(draft.backgroundIntensity, 32);
    expect(draft.decorationIntensity, 71);
    await tap(tester, find.text('Typography').first);
    await tap(tester, find.text('Ambience').first);
    expect(draft.backgroundIntensity, 32);
    expect(draft.decorationIntensity, 71);
  });

  testWidgets('Ocean keeps nine templates for all roles and sizes', (
    tester,
  ) async {
    await show(tester, width: 1120, reduced: true);
    draft.update(() => draft.ambience = InstitutionAmbience.ocean);
    for (final template in InstitutionTemplate.values) {
      for (final role in PreviewRole.values) {
        for (final device in PreviewDevice.values) {
          draft.update(() {
            draft.template = template;
            draft.role = role;
            draft.device = device;
          });
          await tester.pump();
          expect(
            find.byKey(const ValueKey('ocean-shared-background')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('ocean-character-art')),
            findsOneWidget,
            reason: '$template / $role / $device',
          );
          expect(find.textContaining('Demonstration data'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: '$template / $role / $device',
          );
        }
      }
    }
  });

  testWidgets('turtle stays whole in motion and becomes static when reduced', (
    tester,
  ) async {
    await show(tester, width: 1120);
    draft.update(() => draft.ambience = InstitutionAmbience.ocean);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('ocean-motion-character')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('turtle-left-flipper')), findsNothing);
    expect(find.byKey(const ValueKey('turtle-right-flipper')), findsNothing);
    await show(tester, width: 1120, reduced: true);
    expect(
      find.byKey(const ValueKey('ocean-motion-character')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 8));
    expect(find.byKey(const ValueKey('ocean-character-art')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('colors, typography and buttons remain draft between panels', (
    tester,
  ) async {
    await show(tester, width: 520);
    await tap(tester, find.text('Colors').first);
    await tester.drag(
      find.byKey(const ValueKey('palette-list')),
      const Offset(-1100, 0),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('palette-9')));
    final palette = institutionPalettes[9];
    expect(draft.primary, palette.primary);
    expect(draft.background, palette.background);

    await tap(tester, find.text('Typography').first);
    await tap(tester, find.byKey(const ValueKey('font-Space Mono')));
    await tap(tester, find.text('Buttons').first);
    await tap(tester, find.text('Pill').first);
    await tap(tester, find.text('Gradient').first);
    draft.update(() => draft.motion = InstitutionMotion.playful);

    await tester.pumpWidget(const SizedBox());
    await show(tester, width: 520);
    expect(draft.primary, palette.primary);
    expect(draft.background, palette.background);
    expect(draft.font, InstitutionFont.spaceMono);
    expect(draft.buttonShape, InstitutionButtonShape.pill);
    expect(draft.buttonFinish, InstitutionButtonFinish.gradient);
    expect(draft.motion, InstitutionMotion.playful);
    expect(tester.takeException(), isNull);
  });

  testWidgets('animation packages preview pages, cards and button response', (
    tester,
  ) async {
    await show(tester, width: 920);
    await tap(tester, find.text('Animations').first);

    for (final motion in InstitutionMotion.values) {
      await tap(tester, find.byKey(ValueKey('motion-${motion.name}')));
      expect(draft.motion, motion);
      await tap(tester, find.byKey(const ValueKey('preview-page-transition')));
      expect(find.byKey(const ValueKey('motion-demo')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('test-motion-button'))),
    );
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('all motion packages support every role and device', (
    tester,
  ) async {
    await show(tester, width: 1120, reduced: true);
    for (final motion in InstitutionMotion.values) {
      for (final role in PreviewRole.values) {
        for (final device in PreviewDevice.values) {
          draft.update(() {
            draft.motion = motion;
            draft.role = role;
            draft.device = device;
          });
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '$motion / $role / $device must not overflow',
          );
        }
      }
    }
  });

  testWidgets('reduced motion disables selected package durations', (
    tester,
  ) async {
    await show(tester, width: 920, reduced: true);
    await tap(tester, find.text('Animations').first);
    await tap(tester, find.byKey(const ValueKey('motion-playful')));
    expect(draft.motionDuration(reduced: true), Duration.zero);
    final switcher = tester.widget<AnimatedSwitcher>(
      find.byKey(const ValueKey('motion-page-switcher')),
    );
    expect(switcher.duration, Duration.zero);
    final scale = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byKey(const ValueKey('test-motion-button')),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scale.duration, Duration.zero);
  });

  testWidgets('template changes preserve choices until explicit restore', (
    tester,
  ) async {
    await show(tester);
    draft.update(() {
      draft.primary = const Color(0xFF123456);
      draft.font = InstitutionFont.spaceMono;
      draft.buttonFinish = InstitutionButtonFinish.tonal;
    });
    await tester.pump();
    await tap(tester, find.byKey(const ValueKey('template-Academy')));
    expect(draft.primary, const Color(0xFF123456));
    expect(draft.font, InstitutionFont.spaceMono);
    expect(draft.buttonFinish, InstitutionButtonFinish.tonal);

    await tap(tester, find.byKey(const ValueKey('restore-template-defaults')));
    expect(draft.primary, institutionPalettes[3].primary);
    expect(draft.font, InstitutionFont.lora);
    expect(draft.buttonFinish, InstitutionButtonFinish.solid);
  });

  testWidgets('expanded preview opens and closes without clipping', (
    tester,
  ) async {
    await show(tester, width: 430);
    await tap(tester, find.byKey(const ValueKey('expand-preview')));
    expect(find.text('Expanded local preview'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tap(tester, find.byKey(const ValueKey('close-expanded-preview')));
    expect(find.text('Expanded local preview'), findsNothing);
  });

  testWidgets('expanded Ocean preview renders every scene, role and device', (
    tester,
  ) async {
    await show(tester, width: 1120, reduced: true);
    draft.update(() => draft.ambience = InstitutionAmbience.ocean);
    await tap(tester, find.byKey(const ValueKey('expand-preview')));
    for (final role in PreviewRole.values) {
      for (final device in PreviewDevice.values) {
        for (final variant in OceanVariant.values) {
          draft.update(() {
            draft.role = role;
            draft.device = device;
            draft.oceanVariant = variant;
          });
          await tester.pump();
          expect(
            find.descendant(
              of: find.byType(Dialog).first,
              matching: find.byKey(ValueKey('ocean-scene-${variant.name}')),
            ),
            findsOneWidget,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'expanded $role / $device / $variant',
          );
        }
      }
    }
  });

  testWidgets(
    'Remove element hides only selected built-in decoration and Restore returns it',
    (tester) async {
      await show(tester, width: 1120, reduced: true);
      for (final ambience in [
        InstitutionAmbience.ocean,
        InstitutionAmbience.space,
        InstitutionAmbience.animals,
        InstitutionAmbience.nature,
        InstitutionAmbience.fantasy,
      ]) {
        draft.update(() {
          draft.ambience = ambience;
          switch (ambience) {
            case InstitutionAmbience.ocean:
              draft.editOceanDecorations = true;
            case InstitutionAmbience.space:
              draft.editSpaceDecorations = true;
            case InstitutionAmbience.animals:
              draft.editAnimalsDecorations = true;
            case InstitutionAmbience.nature:
              draft.editNatureDecorations = true;
            case InstitutionAmbience.fantasy:
              draft.editFantasyDecorations = true;
            case InstitutionAmbience.none || InstitutionAmbience.my:
              break;
          }
        });
        await tester.pump();
        final remove = find.byKey(ValueKey('${ambience.name}-remove-element'));
        await tap(tester, remove);
        final hidden = switch (ambience) {
          InstitutionAmbience.ocean => draft.oceanAdjustment((
            variant: draft.oceanVariant,
            template: draft.template,
            device: draft.device,
            element: draft.selectedOceanDecoration,
          )).hidden,
          InstitutionAmbience.space => draft.spaceAdjustment((
            variant: draft.spaceVariant,
            template: draft.template,
            device: draft.device,
            element: draft.selectedSpaceDecoration,
          )).hidden,
          InstitutionAmbience.animals => draft.animalsAdjustment((
            variant: draft.animalsVariant,
            template: draft.template,
            device: draft.device,
            element: draft.selectedAnimalsDecoration,
          )).hidden,
          InstitutionAmbience.nature => draft.natureAdjustment((
            variant: draft.natureVariant,
            template: draft.template,
            device: draft.device,
            element: draft.selectedNatureDecoration,
          )).hidden,
          InstitutionAmbience.fantasy => draft.fantasyAdjustment((
            variant: draft.fantasyVariant,
            template: draft.template,
            device: draft.device,
            element: draft.selectedFantasyDecoration,
          )).hidden,
          InstitutionAmbience.none || InstitutionAmbience.my => false,
        };
        expect(hidden, isTrue, reason: ambience.name);
        await tap(
          tester,
          find.byKey(ValueKey('${ambience.name}-reset-element')),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
