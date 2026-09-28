import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_config_mapper.dart';
import 'package:app/features/institution_onboarding/presentation/pages/institution_brand_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'round-trips approved appearance choices and independent adjustments',
    () {
      final source = InstitutionBrandDraft()
        ..template = InstitutionTemplate.heritage
        ..font = InstitutionFont.bitter
        ..motion = InstitutionMotion.depth
        ..buttonShape = InstitutionButtonShape.pill
        ..buttonFinish = InstitutionButtonFinish.tonal
        ..ambience = InstitutionAmbience.ocean
        ..oceanVariant = OceanVariant.jellyfishGarden
        ..oceanPreviewBySection = true
        ..backgroundIntensity = 41
        ..decorationIntensity = 72
        ..elementMotion = 18;
      source.setColor(InstitutionColorSlot.primary, const Color(0xFF123456));
      source.setTransparency(InstitutionColorSlot.primary, 37);
      source.oceanDecorationAdjustments[(
        variant: OceanVariant.turtleReef,
        template: InstitutionTemplate.heritage,
        device: PreviewDevice.mobile,
        element: OceanDecorationId.coral,
      )] = const OceanDecorationAdjustment(
        shift: Offset(.8, -.7),
        scale: 2.4,
        opacity: .55,
        hidden: true,
      );

      final config = InstitutionBrandConfigMapper.encode(source);
      final restored = InstitutionBrandDraft();
      InstitutionBrandConfigMapper.restore(restored, config);

      expect(restored.template, InstitutionTemplate.heritage);
      expect(restored.font, InstitutionFont.bitter);
      expect(restored.motion, InstitutionMotion.depth);
      expect(restored.oceanVariant, OceanVariant.jellyfishGarden);
      expect(restored.oceanPreviewBySection, isTrue);
      expect(restored.backgroundIntensity, 41);
      expect(restored.decorationIntensity, 72);
      expect(restored.elementMotion, 18);
      expect(restored.primary.toARGB32(), const Color(0xFF123456).toARGB32());
      expect(restored.transparencyFor(InstitutionColorSlot.primary), 37);
      final adjustment = restored.oceanAdjustment((
        variant: OceanVariant.turtleReef,
        template: InstitutionTemplate.heritage,
        device: PreviewDevice.mobile,
        element: OceanDecorationId.coral,
      ));
      expect(adjustment.shift, const Offset(.8, -.7));
      expect(adjustment.scale, 2.4);
      expect(adjustment.opacity, .55);
      expect(adjustment.hidden, isTrue);
    },
  );

  test('preserves custom asset slots and independent focal points', () {
    final source = InstitutionBrandDraft()
      ..ambience = InstitutionAmbience.my
      ..myFocalPoints[PreviewDevice.mobile] = const Offset(.7, -.2)
      ..myFocalPoints[PreviewDevice.desktop] = const Offset(-.4, .5);
    final config = InstitutionBrandConfigMapper.encode(
      source,
      customBackgroundAssetId: '10000000-0000-4000-8000-000000000001',
      customElementAssetIds: const {
        1: '10000000-0000-4000-8000-000000000002',
        4: '10000000-0000-4000-8000-000000000003',
      },
    );
    final target = InstitutionBrandDraft();
    final recovered = InstitutionBrandConfigMapper.restore(target, config);
    expect(recovered.backgroundAssetId, '10000000-0000-4000-8000-000000000001');
    expect(recovered.elementAssetIds.keys, {1, 4});
    expect(target.myFocalPoints[PreviewDevice.mobile], const Offset(.7, -.2));
    expect(target.myFocalPoints[PreviewDevice.desktop], const Offset(-.4, .5));
  });
}
