import 'dart:convert';

const institutionAppearanceSchemaVersion = 1;
const institutionAppearanceMaxConfigBytes = 256 * 1024;

class InstitutionAppearanceConfigException implements Exception {
  const InstitutionAppearanceConfigException(this.message);
  final String message;
  @override
  String toString() => message;
}

class InstitutionAppearanceAsset {
  const InstitutionAppearanceAsset({
    required this.id,
    required this.kind,
    required this.slot,
    required this.storagePath,
    required this.mimeType,
    required this.width,
    required this.height,
    this.signedUrl,
  });

  final String id;
  final String kind;
  final int slot;
  final String storagePath;
  final String mimeType;
  final int width;
  final int height;
  final String? signedUrl;

  factory InstitutionAppearanceAsset.fromJson(Map<String, dynamic> json) =>
      InstitutionAppearanceAsset(
        id: json['id'] as String,
        kind: json['kind'] as String,
        slot: (json['slot'] as num).toInt(),
        storagePath: json['storage_path'] as String,
        mimeType: json['mime_type'] as String,
        width: (json['width'] as num).toInt(),
        height: (json['height'] as num).toInt(),
        signedUrl: json['signed_url'] as String?,
      );

  InstitutionAppearanceAsset withSignedUrl(String value) =>
      InstitutionAppearanceAsset(
        id: id,
        kind: kind,
        slot: slot,
        storagePath: storagePath,
        mimeType: mimeType,
        width: width,
        height: height,
        signedUrl: value,
      );
}

class InstitutionAppearanceConfig {
  InstitutionAppearanceConfig._(Map<String, dynamic> value)
    : json = _deepCopy(value) {
    validate();
  }

  final Map<String, dynamic> json;

  int get schemaVersion => json['schema_version'] as int;
  String get template => json['template'] as String;
  String get typography => json['typography'] as String;
  String get motion => json['motion'] as String;
  Map<String, dynamic> get ambience =>
      Map<String, dynamic>.from(json['ambience'] as Map);
  Map<String, dynamic> get colors =>
      Map<String, dynamic>.from(json['colors'] as Map);
  Map<String, dynamic> get buttons =>
      Map<String, dynamic>.from(json['buttons'] as Map);

  factory InstitutionAppearanceConfig.fromJson(Map<String, dynamic> json) =>
      InstitutionAppearanceConfig._(json);

  factory InstitutionAppearanceConfig.safeDefault({
    String? legacyTemplate,
    String? legacyPrimary,
    String? legacyFont,
    String? legacyButtonStyle,
  }) {
    const templates = {
      'orbit',
      'academy',
      'pulse',
      'littleSteps',
      'adventure',
      'studio',
      'heritage',
      'prestige',
      'nexus',
    };
    const fonts = {
      'inter',
      'lora',
      'spaceMono',
      'nunito',
      'fredoka',
      'playfairDisplay',
      'poppins',
      'quicksand',
      'montserrat',
      'bitter',
    };
    final buttonParts = (legacyButtonStyle ?? '').split(':');
    final shape =
        const {
          'square',
          'soft',
          'rounded',
          'pill',
        }.contains(buttonParts.firstOrNull)
        ? buttonParts.first
        : 'rounded';
    final finish =
        buttonParts.length > 1 &&
            const {
              'solid',
              'outlined',
              'tonal',
              'gradient',
              'elevated',
            }.contains(buttonParts[1])
        ? buttonParts[1]
        : 'solid';
    final primary = RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(legacyPrimary ?? '')
        ? legacyPrimary!.toUpperCase()
        : '#675CFF';
    return InstitutionAppearanceConfig._({
      'schema_version': institutionAppearanceSchemaVersion,
      'template': templates.contains(legacyTemplate) ? legacyTemplate : 'orbit',
      'typography': fonts.contains(legacyFont) ? legacyFont : 'inter',
      'motion': 'none',
      'buttons': {'shape': shape, 'finish': finish},
      'colors': {
        'primary': _color(primary, .52, .68),
        'secondary': _color('#22B8CF', .71, .47),
        'accent': _color('#FFC857', 1, .67),
        'background': _color('#080D24', .64, .09),
      },
      'ambience': {
        'kind': 'none',
        'selected_scene': null,
        'preview_by_section': false,
        'section_scenes': {
          'student': <String, dynamic>{},
          'teacher': <String, dynamic>{},
          'admin': <String, dynamic>{},
        },
        'background_intensity': 0,
        'decorative_elements_intensity': 0,
        'element_motion': 0,
        'custom_background_asset_id': null,
        'custom_element_asset_ids': <String>[],
        'custom_element_slots': <String, String>{},
        'focal_points': {
          'mobile': {'x': 0.0, 'y': 0.0},
          'desktop': {'x': 0.0, 'y': 0.0},
        },
      },
      'decoration_overrides': <String, dynamic>{},
    });
  }

  static Map<String, dynamic> _color(
    String hex,
    double saturation,
    double lightness,
  ) => {
    'hex': hex,
    'saturation': saturation,
    'lightness': lightness,
    'transparency': 0,
  };

  Map<String, dynamic> toJson() => _deepCopy(json);

  void validate() {
    final encodedSize = utf8.encode(jsonEncode(json)).length;
    if (encodedSize > institutionAppearanceMaxConfigBytes) {
      throw const InstitutionAppearanceConfigException(
        'Appearance configuration exceeds 256 KiB.',
      );
    }
    if (schemaVersion != institutionAppearanceSchemaVersion) {
      throw const InstitutionAppearanceConfigException(
        'Unsupported appearance schema version.',
      );
    }
    _oneOf('template', template, const {
      'orbit',
      'academy',
      'pulse',
      'littleSteps',
      'adventure',
      'studio',
      'heritage',
      'prestige',
      'nexus',
    });
    _oneOf('typography', typography, const {
      'inter',
      'lora',
      'spaceMono',
      'nunito',
      'fredoka',
      'playfairDisplay',
      'poppins',
      'quicksand',
      'montserrat',
      'bitter',
    });
    _oneOf('motion', motion, const {
      'none',
      'soft',
      'slide',
      'spring',
      'depth',
      'playful',
    });
    _oneOf('button shape', buttons['shape'], const {
      'square',
      'soft',
      'rounded',
      'pill',
    });
    _oneOf('button finish', buttons['finish'], const {
      'solid',
      'outlined',
      'tonal',
      'gradient',
      'elevated',
    });
    for (final slot in const ['primary', 'secondary', 'accent', 'background']) {
      final value = Map<String, dynamic>.from(colors[slot] as Map? ?? {});
      if (!RegExp(
        r'^#[0-9A-Fa-f]{6}$',
      ).hasMatch(value['hex'] as String? ?? '')) {
        throw InstitutionAppearanceConfigException('Invalid $slot HEX color.');
      }
      _range('$slot saturation', value['saturation'], 0, 1);
      _range('$slot lightness', value['lightness'], 0, 1);
      _range('$slot transparency', value['transparency'], 0, 100);
    }
    _oneOf('ambience', ambience['kind'], const {
      'none',
      'space',
      'animals',
      'ocean',
      'nature',
      'fantasy',
      'my',
    });
    _range('background intensity', ambience['background_intensity'], 0, 100);
    _range(
      'decorative elements intensity',
      ambience['decorative_elements_intensity'],
      0,
      100,
    );
    _range('element motion', ambience['element_motion'], 0, 100);
    final elements = ambience['custom_element_asset_ids'];
    if (elements is! List || elements.length > 5) {
      throw const InstitutionAppearanceConfigException(
        'Custom ambience supports at most five elements.',
      );
    }
    if (ambience['section_scenes'] is! Map ||
        ambience['focal_points'] is! Map ||
        ambience['custom_element_slots'] is! Map ||
        json['decoration_overrides'] is! Map) {
      throw const InstitutionAppearanceConfigException(
        'Appearance maps are missing or malformed.',
      );
    }
    final sections = ambience['section_scenes'] as Map;
    for (final role in const ['student', 'teacher', 'admin']) {
      if (sections[role] is! Map) {
        throw InstitutionAppearanceConfigException(
          'Missing $role section-to-scene map.',
        );
      }
    }
    const scenesByAmbience = <String, Set<String>>{
      'ocean': {'turtleReef', 'sharkReef', 'jellyfishGarden'},
      'space': {'planetExploration', 'orbitalStation', 'asteroidExpedition'},
      'animals': {'foxGrove', 'deerMeadow', 'owlCanopy'},
      'nature': {'ancientGrove', 'alpineVista', 'waterfallHaven'},
      'fantasy': {'floatingCastle', 'enchantedLibrary', 'dragonGarden'},
    };
    final selectedScene = ambience['selected_scene'];
    final allowedScenes = scenesByAmbience[ambience['kind']];
    if (allowedScenes == null
        ? selectedScene != null
        : selectedScene is! String || !allowedScenes.contains(selectedScene)) {
      throw const InstitutionAppearanceConfigException(
        'Invalid selected ambience scene.',
      );
    }
    for (final device in const ['mobile', 'desktop']) {
      final focal = Map<String, dynamic>.from(
        (ambience['focal_points'] as Map)[device] as Map? ?? {},
      );
      _range('$device focal x', focal['x'], -1, 1);
      _range('$device focal y', focal['y'], -1, 1);
    }
    if (ambience['kind'] != 'my' &&
        (ambience['custom_background_asset_id'] != null ||
            elements.isNotEmpty ||
            (ambience['custom_element_slots'] as Map).isNotEmpty)) {
      throw const InstitutionAppearanceConfigException(
        'Built-in ambience cannot reference custom files.',
      );
    }
    if (ambience['kind'] == 'my') {
      final slots = Map<String, dynamic>.from(
        ambience['custom_element_slots'] as Map,
      );
      if (slots.length != elements.length ||
          slots.entries.any(
            (entry) =>
                int.tryParse(entry.key) == null ||
                int.parse(entry.key) < 0 ||
                int.parse(entry.key) > 4 ||
                entry.value is! String ||
                !elements.contains(entry.value),
          )) {
        throw const InstitutionAppearanceConfigException(
          'Custom element slots do not match custom element assets.',
        );
      }
    }
  }

  static void _oneOf(String name, Object? value, Set<String> allowed) {
    if (value is! String || !allowed.contains(value)) {
      throw InstitutionAppearanceConfigException('Invalid $name.');
    }
  }

  static void _range(String name, Object? value, num min, num max) {
    if (value is! num || value < min || value > max) {
      throw InstitutionAppearanceConfigException('$name is outside its range.');
    }
  }

  static Map<String, dynamic> _deepCopy(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
}

class LoadedInstitutionAppearance {
  const LoadedInstitutionAppearance({
    required this.institutionId,
    required this.config,
    required this.revision,
    required this.assets,
    required this.usesFallback,
  });

  final String institutionId;
  final InstitutionAppearanceConfig config;
  final int revision;
  final List<InstitutionAppearanceAsset> assets;
  final bool usesFallback;
}
