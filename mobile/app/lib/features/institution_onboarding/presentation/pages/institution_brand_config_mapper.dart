import 'package:flutter/material.dart';

import '../../../../core/appearance/institution_appearance_config.dart';
import 'institution_brand_draft.dart';

typedef RecoveredCustomAssetSelection = ({
  String? backgroundAssetId,
  Map<int, String> elementAssetIds,
});

class InstitutionBrandConfigMapper {
  const InstitutionBrandConfigMapper._();

  static const _sections = <String, List<String>>{
    'student': [
      'Home',
      'Learn',
      'Games',
      'My classes',
      'Progress',
      'Rankings',
      'Profile',
    ],
    'teacher': [
      'Dashboard',
      'My classes',
      'Lessons & activities',
      'Assessments',
      'Attendance',
      'Schedule',
      'Profile',
    ],
    'admin': [
      'Dashboard',
      'Students',
      'Teachers',
      'Courses',
      'Classes',
      'English Levels',
      'Rankings',
      'Access Requests',
    ],
  };

  static InstitutionAppearanceConfig encode(
    InstitutionBrandDraft draft, {
    String? customBackgroundAssetId,
    Map<int, String> customElementAssetIds = const {},
  }) {
    final colors = <String, dynamic>{};
    for (final slot in InstitutionColorSlot.values) {
      final hsl = draft.hslFor(slot);
      colors[slot.name] = {
        'hex': _hex(draft.colorFor(slot)),
        'saturation': _round(hsl.saturation),
        'lightness': _round(hsl.lightness),
        'transparency': draft.transparencyFor(slot),
      };
    }
    return InstitutionAppearanceConfig.fromJson({
      'schema_version': institutionAppearanceSchemaVersion,
      'template': draft.template.name,
      'typography': draft.font.name,
      'motion': draft.motion.name,
      'buttons': {
        'shape': draft.buttonShape.name,
        'finish': draft.buttonFinish.name,
      },
      'colors': colors,
      'ambience': {
        'kind': draft.ambience.name,
        'selected_scene': _selectedScene(draft),
        'preview_by_section': _previewBySection(draft),
        'section_scenes': _sectionScenes(draft),
        'background_intensity': draft.backgroundIntensity,
        'decorative_elements_intensity': draft.decorationIntensity,
        'element_motion': draft.elementMotion,
        'custom_background_asset_id': draft.ambience == InstitutionAmbience.my
            ? customBackgroundAssetId
            : null,
        'custom_element_asset_ids': draft.ambience == InstitutionAmbience.my
            ? [
                for (final entry
                    in customElementAssetIds.entries.toList()
                      ..sort((a, b) => a.key.compareTo(b.key)))
                  entry.value,
              ]
            : <String>[],
        'custom_element_slots': draft.ambience == InstitutionAmbience.my
            ? {
                for (final entry in customElementAssetIds.entries)
                  '${entry.key}': entry.value,
              }
            : <String, String>{},
        'focal_points': {
          for (final device in PreviewDevice.values)
            device.name: {
              'x': _round(draft.myFocalPoints[device]?.dx ?? 0),
              'y': _round(draft.myFocalPoints[device]?.dy ?? 0),
            },
        },
      },
      'decoration_overrides': {
        'ocean': [
          for (final entry in draft.oceanDecorationAdjustments.entries)
            _adjustment(
              scene: entry.key.variant.name,
              template: entry.key.template.name,
              device: entry.key.device.name,
              element: entry.key.element.name,
              value: entry.value,
            ),
        ],
        'space': [
          for (final entry in draft.spaceDecorationAdjustments.entries)
            _adjustment(
              scene: entry.key.variant.name,
              template: entry.key.template.name,
              device: entry.key.device.name,
              element: entry.key.element.name,
              value: entry.value,
            ),
        ],
        'animals': [
          for (final entry in draft.animalsDecorationAdjustments.entries)
            _adjustment(
              scene: entry.key.variant.name,
              template: entry.key.template.name,
              device: entry.key.device.name,
              element: entry.key.element.name,
              value: entry.value,
            ),
        ],
        'nature': [
          for (final entry in draft.natureDecorationAdjustments.entries)
            _adjustment(
              scene: entry.key.variant.name,
              template: entry.key.template.name,
              device: entry.key.device.name,
              element: entry.key.element.name,
              value: entry.value,
            ),
        ],
        'fantasy': [
          for (final entry in draft.fantasyDecorationAdjustments.entries)
            _adjustment(
              scene: entry.key.variant.name,
              template: entry.key.template.name,
              device: entry.key.device.name,
              element: entry.key.element.name,
              value: entry.value,
            ),
        ],
        'my': [
          for (final entry in draft.myAdjustments.entries)
            _adjustment(
              scene: 'custom',
              template: entry.key.template.name,
              device: entry.key.device.name,
              element: '${entry.key.id}',
              value: entry.value,
            ),
        ],
      },
    });
  }

  static RecoveredCustomAssetSelection restore(
    InstitutionBrandDraft draft,
    InstitutionAppearanceConfig config,
  ) {
    final data = config.toJson();
    final ambience = Map<String, dynamic>.from(data['ambience'] as Map);
    final colorData = Map<String, dynamic>.from(data['colors'] as Map);
    draft.update(() {
      draft.template = _enum(
        InstitutionTemplate.values,
        data['template'],
        InstitutionTemplate.orbit,
      );
      draft.font = _enum(
        InstitutionFont.values,
        data['typography'],
        InstitutionFont.inter,
      );
      draft.motion = _enum(
        InstitutionMotion.values,
        data['motion'],
        InstitutionMotion.none,
      );
      final buttons = Map<String, dynamic>.from(data['buttons'] as Map);
      draft.buttonShape = _enum(
        InstitutionButtonShape.values,
        buttons['shape'],
        InstitutionButtonShape.rounded,
      );
      draft.buttonFinish = _enum(
        InstitutionButtonFinish.values,
        buttons['finish'],
        InstitutionButtonFinish.solid,
      );
      draft.ambience = _enum(
        InstitutionAmbience.values,
        ambience['kind'],
        InstitutionAmbience.none,
      );
      draft.backgroundIntensity = (ambience['background_intensity'] as num)
          .round();
      draft.decorationIntensity =
          (ambience['decorative_elements_intensity'] as num).round();
      draft.elementMotion = (ambience['element_motion'] as num).round();
      final selected = ambience['selected_scene'];
      switch (draft.ambience) {
        case InstitutionAmbience.ocean:
          draft.oceanVariant = _enum(
            OceanVariant.values,
            selected,
            OceanVariant.turtleReef,
          );
          draft.oceanPreviewBySection = ambience['preview_by_section'] == true;
        case InstitutionAmbience.space:
          draft.spaceVariant = _enum(
            SpaceVariant.values,
            selected,
            SpaceVariant.planetExploration,
          );
          draft.spacePreviewBySection = ambience['preview_by_section'] == true;
        case InstitutionAmbience.animals:
          draft.animalsVariant = _enum(
            AnimalsVariant.values,
            selected,
            AnimalsVariant.foxGrove,
          );
          draft.animalsPreviewBySection =
              ambience['preview_by_section'] == true;
        case InstitutionAmbience.nature:
          draft.natureVariant = _enum(
            NatureVariant.values,
            selected,
            NatureVariant.ancientGrove,
          );
          draft.naturePreviewBySection = ambience['preview_by_section'] == true;
        case InstitutionAmbience.fantasy:
          draft.fantasyVariant = _enum(
            FantasyVariant.values,
            selected,
            FantasyVariant.floatingCastle,
          );
          draft.fantasyPreviewBySection =
              ambience['preview_by_section'] == true;
        case InstitutionAmbience.none || InstitutionAmbience.my:
          break;
      }
      draft.oceanDecorationAdjustments.clear();
      draft.spaceDecorationAdjustments.clear();
      draft.animalsDecorationAdjustments.clear();
      draft.natureDecorationAdjustments.clear();
      draft.fantasyDecorationAdjustments.clear();
      draft.myAdjustments.clear();
      _restoreAdjustments(draft, data['decoration_overrides'] as Map);
      final focals = Map<String, dynamic>.from(ambience['focal_points'] as Map);
      for (final device in PreviewDevice.values) {
        final focal = Map<String, dynamic>.from(focals[device.name] as Map);
        draft.myFocalPoints[device] = Offset(
          (focal['x'] as num).toDouble(),
          (focal['y'] as num).toDouble(),
        );
      }
    });
    for (final slot in InstitutionColorSlot.values) {
      final value = Map<String, dynamic>.from(colorData[slot.name] as Map);
      draft.setColor(slot, _color(value['hex'] as String));
      draft.setTransparency(slot, (value['transparency'] as num).toDouble());
    }
    final slots = Map<String, dynamic>.from(
      ambience['custom_element_slots'] as Map? ?? const {},
    );
    return (
      backgroundAssetId: ambience['custom_background_asset_id'] as String?,
      elementAssetIds: {
        for (final entry in slots.entries)
          int.parse(entry.key): entry.value as String,
      },
    );
  }

  static void _restoreAdjustments(InstitutionBrandDraft draft, Map raw) {
    for (final item in _list(raw['ocean'])) {
      draft.oceanDecorationAdjustments[(
        variant: _enum(
          OceanVariant.values,
          item['scene'],
          OceanVariant.turtleReef,
        ),
        template: _enum(
          InstitutionTemplate.values,
          item['template'],
          InstitutionTemplate.orbit,
        ),
        device: _enum(
          PreviewDevice.values,
          item['device'],
          PreviewDevice.desktop,
        ),
        element: _enum(
          OceanDecorationId.values,
          item['element'],
          OceanDecorationId.character,
        ),
      )] = _value(
        item,
      );
    }
    for (final item in _list(raw['space'])) {
      draft.spaceDecorationAdjustments[(
        variant: _enum(
          SpaceVariant.values,
          item['scene'],
          SpaceVariant.planetExploration,
        ),
        template: _enum(
          InstitutionTemplate.values,
          item['template'],
          InstitutionTemplate.orbit,
        ),
        device: _enum(
          PreviewDevice.values,
          item['device'],
          PreviewDevice.desktop,
        ),
        element: _enum(
          SpaceDecorationId.values,
          item['element'],
          SpaceDecorationId.hero,
        ),
      )] = _value(
        item,
      );
    }
    for (final item in _list(raw['animals'])) {
      draft.animalsDecorationAdjustments[(
        variant: _enum(
          AnimalsVariant.values,
          item['scene'],
          AnimalsVariant.foxGrove,
        ),
        template: _enum(
          InstitutionTemplate.values,
          item['template'],
          InstitutionTemplate.orbit,
        ),
        device: _enum(
          PreviewDevice.values,
          item['device'],
          PreviewDevice.desktop,
        ),
        element: _enum(
          AnimalsDecorationId.values,
          item['element'],
          AnimalsDecorationId.hero,
        ),
      )] = _value(
        item,
      );
    }
    for (final item in _list(raw['nature'])) {
      draft.natureDecorationAdjustments[(
        variant: _enum(
          NatureVariant.values,
          item['scene'],
          NatureVariant.ancientGrove,
        ),
        template: _enum(
          InstitutionTemplate.values,
          item['template'],
          InstitutionTemplate.orbit,
        ),
        device: _enum(
          PreviewDevice.values,
          item['device'],
          PreviewDevice.desktop,
        ),
        element: _enum(
          NatureDecorationId.values,
          item['element'],
          NatureDecorationId.hero,
        ),
      )] = _value(
        item,
      );
    }
    for (final item in _list(raw['fantasy'])) {
      draft.fantasyDecorationAdjustments[(
        variant: _enum(
          FantasyVariant.values,
          item['scene'],
          FantasyVariant.floatingCastle,
        ),
        template: _enum(
          InstitutionTemplate.values,
          item['template'],
          InstitutionTemplate.orbit,
        ),
        device: _enum(
          PreviewDevice.values,
          item['device'],
          PreviewDevice.desktop,
        ),
        element: _enum(
          FantasyDecorationId.values,
          item['element'],
          FantasyDecorationId.hero,
        ),
      )] = _value(
        item,
      );
    }
    for (final item in _list(raw['my'])) {
      draft.myAdjustments[(
        id: int.parse(item['element'] as String),
        template: _enum(
          InstitutionTemplate.values,
          item['template'],
          InstitutionTemplate.orbit,
        ),
        device: _enum(
          PreviewDevice.values,
          item['device'],
          PreviewDevice.desktop,
        ),
      )] = _value(
        item,
      );
    }
  }

  static List<Map<String, dynamic>> _list(Object? value) => [
    for (final item in value as List? ?? const [])
      Map<String, dynamic>.from(item as Map),
  ];

  static OceanDecorationAdjustment _value(Map<String, dynamic> item) =>
      OceanDecorationAdjustment(
        shift: Offset(
          (item['x'] as num).toDouble(),
          (item['y'] as num).toDouble(),
        ),
        scale: (item['scale'] as num).toDouble(),
        opacity: (item['opacity'] as num).toDouble(),
        hidden: item['hidden'] == true,
      );

  static Map<String, dynamic> _adjustment({
    required String scene,
    required String template,
    required String device,
    required String element,
    required OceanDecorationAdjustment value,
  }) => {
    'scene': scene,
    'template': template,
    'device': device,
    'element': element,
    'x': _round(value.shift.dx),
    'y': _round(value.shift.dy),
    'scale': _round(value.scale),
    'opacity': _round(value.opacity),
    'hidden': value.hidden,
  };

  static Map<String, dynamic> _sectionScenes(InstitutionBrandDraft draft) => {
    for (final role in _sections.entries)
      role.key: {
        for (final section in role.value) section: _sceneFor(draft, section),
      },
  };

  static String? _sceneFor(
    InstitutionBrandDraft draft,
    String section,
  ) => switch (draft.ambience) {
    InstitutionAmbience.ocean => draft.oceanVariantForSection(section).name,
    InstitutionAmbience.space => draft.spaceVariantForSection(section).name,
    InstitutionAmbience.animals => draft.animalsVariantForSection(section).name,
    InstitutionAmbience.nature => draft.natureVariantForSection(section).name,
    InstitutionAmbience.fantasy => draft.fantasyVariantForSection(section).name,
    InstitutionAmbience.none || InstitutionAmbience.my => null,
  };

  static String? _selectedScene(InstitutionBrandDraft draft) =>
      switch (draft.ambience) {
        InstitutionAmbience.ocean => draft.oceanVariant.name,
        InstitutionAmbience.space => draft.spaceVariant.name,
        InstitutionAmbience.animals => draft.animalsVariant.name,
        InstitutionAmbience.nature => draft.natureVariant.name,
        InstitutionAmbience.fantasy => draft.fantasyVariant.name,
        InstitutionAmbience.none || InstitutionAmbience.my => null,
      };

  static bool _previewBySection(InstitutionBrandDraft draft) =>
      switch (draft.ambience) {
        InstitutionAmbience.ocean => draft.oceanPreviewBySection,
        InstitutionAmbience.space => draft.spacePreviewBySection,
        InstitutionAmbience.animals => draft.animalsPreviewBySection,
        InstitutionAmbience.nature => draft.naturePreviewBySection,
        InstitutionAmbience.fantasy => draft.fantasyPreviewBySection,
        InstitutionAmbience.none || InstitutionAmbience.my => false,
      };

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((value) => value.name == name).firstOrNull ?? fallback;

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  static Color _color(String hex) =>
      Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
  static double _round(double value) => double.parse(value.toStringAsFixed(6));
}
