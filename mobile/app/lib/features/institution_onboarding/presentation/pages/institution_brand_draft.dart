import 'dart:typed_data';

import 'package:flutter/material.dart';

enum InstitutionTemplate {
  orbit,
  academy,
  pulse,
  littleSteps,
  adventure,
  studio,
  heritage,
  prestige,
  nexus,
}

enum PreviewRole { student, teacher, admin }

enum PreviewDevice { desktop, mobile }

enum InstitutionFont {
  inter,
  lora,
  spaceMono,
  nunito,
  fredoka,
  playfairDisplay,
  poppins,
  quicksand,
  montserrat,
  bitter,
}

enum InstitutionAmbience { none, space, animals, ocean, nature, fantasy, my }

enum AmbienceIntensity { subtle, normal }

enum OceanVariant { turtleReef, sharkReef, jellyfishGarden }

enum OceanDecorationId { character, fishSchool, coral, plants }

enum SpaceVariant { planetExploration, orbitalStation, asteroidExpedition }

enum SpaceDecorationId { hero, craft, probe, stardust }

enum AnimalsVariant { foxGrove, deerMeadow, owlCanopy }

enum AnimalsDecorationId { hero, butterflies, foliage, pawprints }

enum NatureVariant { ancientGrove, alpineVista, waterfallHaven }

enum NatureDecorationId { hero, songbirds, wildflowers, leaves }

enum FantasyVariant { floatingCastle, enchantedLibrary, dragonGarden }

enum FantasyDecorationId { hero, fireflies, mushrooms, lantern }

typedef FantasyDecorationKey = ({
  FantasyVariant variant,
  InstitutionTemplate template,
  PreviewDevice device,
  FantasyDecorationId element,
});

typedef NatureDecorationKey = ({
  NatureVariant variant,
  InstitutionTemplate template,
  PreviewDevice device,
  NatureDecorationId element,
});

enum InstitutionColorSlot { primary, secondary, accent, background }

typedef AnimalsDecorationKey = ({
  AnimalsVariant variant,
  InstitutionTemplate template,
  PreviewDevice device,
  AnimalsDecorationId element,
});

typedef SpaceDecorationKey = ({
  SpaceVariant variant,
  InstitutionTemplate template,
  PreviewDevice device,
  SpaceDecorationId element,
});

typedef OceanDecorationKey = ({
  OceanVariant variant,
  InstitutionTemplate template,
  PreviewDevice device,
  OceanDecorationId element,
});

class OceanDecorationAdjustment {
  const OceanDecorationAdjustment({
    this.shift = Offset.zero,
    this.scale = 1,
    this.opacity = 1,
    this.hidden = false,
  });

  final Offset shift;
  final double scale;
  final double opacity;
  final bool hidden;

  OceanDecorationAdjustment copyWith({
    Offset? shift,
    double? scale,
    double? opacity,
    bool? hidden,
  }) => OceanDecorationAdjustment(
    shift: shift ?? this.shift,
    scale: scale ?? this.scale,
    opacity: opacity ?? this.opacity,
    hidden: hidden ?? this.hidden,
  );
}

class MyAmbienceFile {
  const MyAmbienceFile({
    required this.name,
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
  });

  final String name;
  final Uint8List bytes;
  final int width;
  final int height;
  final String format;

  int get approximateMemoryBytes => bytes.length + width * height * 4;
}

typedef MyDecorationKey = ({
  int id,
  InstitutionTemplate template,
  PreviewDevice device,
});

enum InstitutionMotion { none, soft, slide, spring, depth, playful }

enum InstitutionButtonShape { square, soft, rounded, pill }

enum InstitutionButtonFinish { solid, outlined, tonal, gradient, elevated }

class InstitutionPalette {
  const InstitutionPalette(
    this.name,
    this.primary,
    this.secondary,
    this.accent,
    this.background,
  );

  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
}

const institutionPalettes = <InstitutionPalette>[
  InstitutionPalette(
    'Cosmic violet',
    Color(0xFF675CFF),
    Color(0xFF22B8CF),
    Color(0xFFFFC857),
    Color(0xFF080D24),
  ),
  InstitutionPalette(
    'Midnight blue',
    Color(0xFF4169E1),
    Color(0xFF22D3A7),
    Color(0xFFFFB84D),
    Color(0xFF071426),
  ),
  InstitutionPalette(
    'Graphite',
    Color(0xFF3B5CCC),
    Color(0xFF68778F),
    Color(0xFFE9A23B),
    Color(0xFF161B24),
  ),
  InstitutionPalette(
    'Clean slate',
    Color(0xFF2457D6),
    Color(0xFF49647E),
    Color(0xFFDE7C2D),
    Color(0xFFF3F6FA),
  ),
  InstitutionPalette(
    'Mint paper',
    Color(0xFF176B5B),
    Color(0xFF3B82A0),
    Color(0xFFEAA638),
    Color(0xFFF2FBF7),
  ),
  InstitutionPalette(
    'Rose notebook',
    Color(0xFF9E3D62),
    Color(0xFF5C6EB5),
    Color(0xFFE18B42),
    Color(0xFFFFF6F8),
  ),
  InstitutionPalette(
    'Pastel cloud',
    Color(0xFF7768C8),
    Color(0xFF5DA6A8),
    Color(0xFFE88E9B),
    Color(0xFFF8F5FF),
  ),
  InstitutionPalette(
    'Peach garden',
    Color(0xFFE56F5D),
    Color(0xFF4FA78B),
    Color(0xFF8A65C7),
    Color(0xFFFFF5E9),
  ),
  InstitutionPalette(
    'Electric lime',
    Color(0xFF6554E8),
    Color(0xFF16B5A8),
    Color(0xFFB7EF3A),
    Color(0xFF11152D),
  ),
  InstitutionPalette(
    'Coral pop',
    Color(0xFFFF526E),
    Color(0xFF246BFD),
    Color(0xFFFFCE38),
    Color(0xFF15142B),
  ),
  InstitutionPalette(
    'Ocean bright',
    Color(0xFF0077C8),
    Color(0xFF00A99D),
    Color(0xFFFFB703),
    Color(0xFFEFFAFF),
  ),
  InstitutionPalette(
    'Forest sun',
    Color(0xFF2E6D45),
    Color(0xFF687F3E),
    Color(0xFFE29B25),
    Color(0xFFF5F7EC),
  ),
];

class InstitutionBrandDraft extends ChangeNotifier {
  MyAmbienceFile? myBackground;
  final Map<int, MyAmbienceFile> myElements = {};
  final Map<MyDecorationKey, OceanDecorationAdjustment> myAdjustments = {};
  final Map<PreviewDevice, Offset> myFocalPoints = {
    PreviewDevice.mobile: Offset.zero,
    PreviewDevice.desktop: Offset.zero,
  };
  int? selectedMyElementId;
  bool editMyDecorations = false;
  Set<int> myOverlaps = {};

  bool get hasUnrecoverableFiles =>
      ambience == InstitutionAmbience.my &&
      (myBackground != null || myElements.isNotEmpty);

  int get myApproximateMemoryBytes =>
      (myBackground?.approximateMemoryBytes ?? 0) +
      myElements.values.fold<int>(
        0,
        (sum, file) => sum + file.approximateMemoryBytes,
      );

  void setMyBackground(MyAmbienceFile? file) => update(() {
    myBackground = file;
  });

  int addMyElement(MyAmbienceFile file) {
    if (myElements.length >= 5) throw StateError('Maximum 5 elements.');
    final id = List.generate(
      5,
      (index) => index,
    ).firstWhere((candidate) => !myElements.containsKey(candidate));
    update(() {
      myElements[id] = file;
      selectedMyElementId = id;
    });
    return id;
  }

  void replaceMyElement(int id, MyAmbienceFile file) {
    if (!myElements.containsKey(id)) throw StateError('Element not found.');
    update(() => myElements[id] = file);
  }

  void removeMyElement(int id) => update(() {
    myElements.remove(id);
    myAdjustments.removeWhere((key, _) => key.id == id);
    if (selectedMyElementId == id) {
      selectedMyElementId = myElements.keys.firstOrNull;
    }
    myOverlaps.remove(id);
  });

  OceanDecorationAdjustment myAdjustment(MyDecorationKey key) =>
      myAdjustments[key] ?? const OceanDecorationAdjustment();

  void changeMyAdjustment(
    MyDecorationKey key,
    OceanDecorationAdjustment adjustment,
  ) => update(() => myAdjustments[key] = adjustment);

  void resetMyAdjustment(MyDecorationKey key) =>
      update(() => myAdjustments.remove(key));

  void setMyFocalPoint(PreviewDevice device, Offset focal) => update(() {
    myFocalPoints[device] = Offset(
      focal.dx.clamp(-1, 1),
      focal.dy.clamp(-1, 1),
    );
  });
  InstitutionTemplate template = InstitutionTemplate.orbit;
  PreviewRole role = PreviewRole.student;
  PreviewDevice device = PreviewDevice.desktop;
  InstitutionFont font = InstitutionFont.inter;
  InstitutionAmbience ambience = InstitutionAmbience.space;
  int backgroundIntensity = 65;
  int decorationIntensity = 65;
  int elementMotion = 35;
  OceanVariant oceanVariant = OceanVariant.turtleReef;
  bool oceanPreviewBySection = false;
  bool editOceanDecorations = false;
  OceanDecorationId selectedOceanDecoration = OceanDecorationId.character;
  bool oceanPlacementClamped = false;
  Set<OceanDecorationId> oceanOverlaps = {};
  final Map<OceanDecorationKey, OceanDecorationAdjustment>
  oceanDecorationAdjustments = {};
  SpaceVariant spaceVariant = SpaceVariant.planetExploration;
  bool spacePreviewBySection = false;
  bool editSpaceDecorations = false;
  SpaceDecorationId selectedSpaceDecoration = SpaceDecorationId.hero;
  Set<SpaceDecorationId> spaceOverlaps = {};
  final Map<SpaceDecorationKey, OceanDecorationAdjustment>
  spaceDecorationAdjustments = {};
  AnimalsVariant animalsVariant = AnimalsVariant.foxGrove;
  bool animalsPreviewBySection = false;
  bool editAnimalsDecorations = false;
  AnimalsDecorationId selectedAnimalsDecoration = AnimalsDecorationId.hero;
  Set<AnimalsDecorationId> animalsOverlaps = {};
  final Map<AnimalsDecorationKey, OceanDecorationAdjustment>
  animalsDecorationAdjustments = {};
  NatureVariant natureVariant = NatureVariant.ancientGrove;
  bool naturePreviewBySection = false;
  bool editNatureDecorations = false;
  NatureDecorationId selectedNatureDecoration = NatureDecorationId.hero;
  Set<NatureDecorationId> natureOverlaps = {};
  final Map<NatureDecorationKey, OceanDecorationAdjustment>
  natureDecorationAdjustments = {};
  FantasyVariant fantasyVariant = FantasyVariant.floatingCastle;
  bool fantasyPreviewBySection = false;
  bool editFantasyDecorations = false;
  FantasyDecorationId selectedFantasyDecoration = FantasyDecorationId.hero;
  Set<FantasyDecorationId> fantasyOverlaps = {};
  final Map<FantasyDecorationKey, OceanDecorationAdjustment>
  fantasyDecorationAdjustments = {};
  int previewSectionIndex = 0;
  InstitutionMotion motion = InstitutionMotion.soft;
  InstitutionButtonShape buttonShape = InstitutionButtonShape.rounded;
  InstitutionButtonFinish buttonFinish = InstitutionButtonFinish.solid;
  Color primary = institutionPalettes.first.primary;
  Color secondary = institutionPalettes.first.secondary;
  Color accent = institutionPalettes.first.accent;
  Color background = institutionPalettes.first.background;
  final Map<InstitutionColorSlot, int> _transparency = {
    for (final slot in InstitutionColorSlot.values) slot: 0,
  };
  final Map<InstitutionColorSlot, double> _lastChromaticHue = {};

  static const success = Color(0xFF169B62);
  static const warning = Color(0xFFE49A22);
  static const error = Color(0xFFD9435F);

  void update(void Function() change) {
    change();
    notifyListeners();
  }

  void applyPalette(InstitutionPalette palette) => update(() {
    primary = palette.primary;
    secondary = palette.secondary;
    accent = palette.accent;
    background = palette.background;
    _lastChromaticHue.clear();
    for (final slot in InstitutionColorSlot.values) {
      _transparency[slot] = 0;
    }
  });

  int transparencyFor(InstitutionColorSlot slot) => _transparency[slot] ?? 0;

  void setTransparency(InstitutionColorSlot slot, double value) => update(() {
    _transparency[slot] = value.round().clamp(0, 100);
  });

  Color surfaceColor(InstitutionColorSlot slot) =>
      colorFor(slot).withValues(alpha: 1 - transparencyFor(slot) / 100);

  Color colorFor(InstitutionColorSlot slot) => switch (slot) {
    InstitutionColorSlot.primary => primary,
    InstitutionColorSlot.secondary => secondary,
    InstitutionColorSlot.accent => accent,
    InstitutionColorSlot.background => background,
  };

  HSLColor hslFor(InstitutionColorSlot slot) {
    final hsl = HSLColor.fromColor(colorFor(slot));
    return hsl.withHue(
      hsl.saturation > .001 ? hsl.hue : (_lastChromaticHue[slot] ?? hsl.hue),
    );
  }

  void setColor(InstitutionColorSlot slot, Color value) => update(() {
    final hsl = HSLColor.fromColor(value);
    if (hsl.saturation > .001 && hsl.lightness > .001 && hsl.lightness < .999) {
      _lastChromaticHue[slot] = hsl.hue;
    }
    switch (slot) {
      case InstitutionColorSlot.primary:
        primary = value;
      case InstitutionColorSlot.secondary:
        secondary = value;
      case InstitutionColorSlot.accent:
        accent = value;
      case InstitutionColorSlot.background:
        background = value;
    }
  });

  void setColorSaturation(InstitutionColorSlot slot, double value) {
    final hsl = hslFor(slot);
    _lastChromaticHue[slot] = hsl.hue;
    setColor(slot, hsl.withSaturation(value.clamp(0, 1)).toColor());
  }

  void setColorLightness(InstitutionColorSlot slot, double value) {
    final hsl = hslFor(slot);
    _lastChromaticHue[slot] = hsl.hue;
    setColor(slot, hsl.withLightness(value.clamp(0, 1)).toColor());
  }

  void setDecorationIntensity(double value) => update(() {
    decorationIntensity = value.round().clamp(0, 100);
  });

  void setBackgroundIntensity(double value) => update(() {
    backgroundIntensity = value.round().clamp(0, 100);
  });

  void setElementMotion(double value) => update(() {
    elementMotion = value.round().clamp(0, 100);
  });

  OceanDecorationAdjustment oceanAdjustment(OceanDecorationKey key) =>
      oceanDecorationAdjustments[key] ?? const OceanDecorationAdjustment();

  void changeOceanAdjustment(
    OceanDecorationKey key,
    OceanDecorationAdjustment adjustment, {
    bool clamped = false,
  }) => update(() {
    oceanDecorationAdjustments[key] = adjustment;
    oceanPlacementClamped = clamped;
  });

  void resetOceanAdjustment(OceanDecorationKey key) => update(() {
    oceanDecorationAdjustments.remove(key);
    oceanPlacementClamped = false;
  });

  void setOceanOverlaps(Set<OceanDecorationId> value) {
    if (oceanOverlaps.length == value.length &&
        oceanOverlaps.containsAll(value)) {
      return;
    }
    update(() => oceanOverlaps = value);
  }

  OceanDecorationAdjustment spaceAdjustment(SpaceDecorationKey key) =>
      spaceDecorationAdjustments[key] ?? const OceanDecorationAdjustment();

  void changeSpaceAdjustment(
    SpaceDecorationKey key,
    OceanDecorationAdjustment adjustment,
  ) => update(() => spaceDecorationAdjustments[key] = adjustment);

  void resetSpaceAdjustment(SpaceDecorationKey key) =>
      update(() => spaceDecorationAdjustments.remove(key));

  void setSpaceOverlaps(Set<SpaceDecorationId> value) {
    if (spaceOverlaps.length == value.length &&
        spaceOverlaps.containsAll(value)) {
      return;
    }
    update(() => spaceOverlaps = value);
  }

  OceanDecorationAdjustment animalsAdjustment(AnimalsDecorationKey key) =>
      animalsDecorationAdjustments[key] ?? const OceanDecorationAdjustment();

  void changeAnimalsAdjustment(
    AnimalsDecorationKey key,
    OceanDecorationAdjustment adjustment,
  ) => update(() => animalsDecorationAdjustments[key] = adjustment);

  void resetAnimalsAdjustment(AnimalsDecorationKey key) =>
      update(() => animalsDecorationAdjustments.remove(key));

  void setAnimalsOverlaps(Set<AnimalsDecorationId> value) {
    if (animalsOverlaps.length == value.length &&
        animalsOverlaps.containsAll(value)) {
      return;
    }
    update(() => animalsOverlaps = value);
  }

  OceanDecorationAdjustment natureAdjustment(NatureDecorationKey key) =>
      natureDecorationAdjustments[key] ?? const OceanDecorationAdjustment();

  void changeNatureAdjustment(
    NatureDecorationKey key,
    OceanDecorationAdjustment adjustment,
  ) => update(() => natureDecorationAdjustments[key] = adjustment);

  void resetNatureAdjustment(NatureDecorationKey key) =>
      update(() => natureDecorationAdjustments.remove(key));

  void setNatureOverlaps(Set<NatureDecorationId> value) {
    if (natureOverlaps.length == value.length &&
        natureOverlaps.containsAll(value)) {
      return;
    }
    update(() => natureOverlaps = value);
  }

  OceanDecorationAdjustment fantasyAdjustment(FantasyDecorationKey key) =>
      fantasyDecorationAdjustments[key] ?? const OceanDecorationAdjustment();

  void changeFantasyAdjustment(
    FantasyDecorationKey key,
    OceanDecorationAdjustment adjustment,
  ) => update(() => fantasyDecorationAdjustments[key] = adjustment);

  void resetFantasyAdjustment(FantasyDecorationKey key) =>
      update(() => fantasyDecorationAdjustments.remove(key));

  void setFantasyOverlaps(Set<FantasyDecorationId> value) {
    if (fantasyOverlaps.length == value.length &&
        fantasyOverlaps.containsAll(value)) {
      return;
    }
    update(() => fantasyOverlaps = value);
  }

  void applyIntensityPreset(AmbienceIntensity preset) => update(() {
    final value = switch (preset) {
      AmbienceIntensity.subtle => 25,
      AmbienceIntensity.normal => 65,
    };
    backgroundIntensity = value;
    decorationIntensity = value;
  });

  OceanVariant oceanVariantForSection(String section) => switch (section) {
    'Learn' ||
    'Students' ||
    'My classes' ||
    'Assessments' ||
    'Teachers' ||
    'Classes' ||
    'Progress' => OceanVariant.sharkReef,
    'Games' ||
    'Lessons & activities' ||
    'Access Requests' ||
    'Rankings' ||
    'Schedule' ||
    'English Levels' => OceanVariant.jellyfishGarden,
    _ => OceanVariant.turtleReef,
  };

  SpaceVariant spaceVariantForSection(String section) => switch (section) {
    'Learn' ||
    'Students' ||
    'My classes' ||
    'Teachers' ||
    'Classes' ||
    'Schedule' => SpaceVariant.orbitalStation,
    'Games' ||
    'Lessons & activities' ||
    'Assessments' ||
    'Access Requests' ||
    'Rankings' ||
    'English Levels' => SpaceVariant.asteroidExpedition,
    _ => SpaceVariant.planetExploration,
  };

  AnimalsVariant animalsVariantForSection(String section) => switch (section) {
    'Learn' ||
    'Students' ||
    'My classes' ||
    'Teachers' ||
    'Classes' ||
    'Schedule' => AnimalsVariant.deerMeadow,
    'Games' ||
    'Lessons & activities' ||
    'Assessments' ||
    'Access Requests' ||
    'Rankings' ||
    'English Levels' => AnimalsVariant.owlCanopy,
    _ => AnimalsVariant.foxGrove,
  };

  NatureVariant natureVariantForSection(String section) => switch (section) {
    'Learn' ||
    'Students' ||
    'My classes' ||
    'Teachers' ||
    'Classes' ||
    'Schedule' => NatureVariant.alpineVista,
    'Games' ||
    'Lessons & activities' ||
    'Assessments' ||
    'Access Requests' ||
    'Rankings' ||
    'English Levels' => NatureVariant.waterfallHaven,
    _ => NatureVariant.ancientGrove,
  };

  FantasyVariant fantasyVariantForSection(String section) => switch (section) {
    'Learn' ||
    'Students' ||
    'My classes' ||
    'Teachers' ||
    'Classes' ||
    'Schedule' => FantasyVariant.enchantedLibrary,
    'Games' ||
    'Lessons & activities' ||
    'Assessments' ||
    'Access Requests' ||
    'Rankings' ||
    'English Levels' => FantasyVariant.dragonGarden,
    _ => FantasyVariant.floatingCastle,
  };

  void restoreTemplateDefaults() => update(() {
    final defaults = switch (template) {
      InstitutionTemplate.orbit => (
        institutionPalettes[0],
        InstitutionFont.inter,
        InstitutionButtonShape.rounded,
        InstitutionButtonFinish.gradient,
      ),
      InstitutionTemplate.academy => (
        institutionPalettes[3],
        InstitutionFont.lora,
        InstitutionButtonShape.soft,
        InstitutionButtonFinish.solid,
      ),
      InstitutionTemplate.pulse => (
        institutionPalettes[9],
        InstitutionFont.inter,
        InstitutionButtonShape.pill,
        InstitutionButtonFinish.elevated,
      ),
      InstitutionTemplate.littleSteps => (
        institutionPalettes[7],
        InstitutionFont.inter,
        InstitutionButtonShape.pill,
        InstitutionButtonFinish.tonal,
      ),
      InstitutionTemplate.adventure => (
        institutionPalettes[11],
        InstitutionFont.inter,
        InstitutionButtonShape.rounded,
        InstitutionButtonFinish.elevated,
      ),
      InstitutionTemplate.studio => (
        institutionPalettes[2],
        InstitutionFont.spaceMono,
        InstitutionButtonShape.square,
        InstitutionButtonFinish.outlined,
      ),
      InstitutionTemplate.heritage => (
        institutionPalettes[5],
        InstitutionFont.bitter,
        InstitutionButtonShape.square,
        InstitutionButtonFinish.outlined,
      ),
      InstitutionTemplate.prestige => (
        institutionPalettes[3],
        InstitutionFont.playfairDisplay,
        InstitutionButtonShape.soft,
        InstitutionButtonFinish.solid,
      ),
      InstitutionTemplate.nexus => (
        institutionPalettes[1],
        InstitutionFont.spaceMono,
        InstitutionButtonShape.soft,
        InstitutionButtonFinish.tonal,
      ),
    };
    primary = defaults.$1.primary;
    secondary = defaults.$1.secondary;
    accent = defaults.$1.accent;
    background = defaults.$1.background;
    _lastChromaticHue.clear();
    for (final slot in InstitutionColorSlot.values) {
      _transparency[slot] = 0;
    }
    font = defaults.$2;
    buttonShape = defaults.$3;
    buttonFinish = defaults.$4;
  });

  String get fontFamily => switch (font) {
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
  };

  String get fontLabel => switch (font) {
    InstitutionFont.inter => 'Inter Sans',
    InstitutionFont.lora => 'Lora Serif',
    InstitutionFont.spaceMono => 'Space Mono',
    InstitutionFont.nunito => 'Nunito Rounded',
    InstitutionFont.fredoka => 'Fredoka Playful',
    InstitutionFont.playfairDisplay => 'Playfair Display',
    InstitutionFont.poppins => 'Poppins Modern',
    InstitutionFont.quicksand => 'Quicksand Friendly',
    InstitutionFont.montserrat => 'Montserrat Professional',
    InstitutionFont.bitter => 'Bitter Editorial',
  };

  Duration motionDuration({bool reduced = false}) {
    if (reduced || motion == InstitutionMotion.none) return Duration.zero;
    return switch (motion) {
      InstitutionMotion.none => Duration.zero,
      InstitutionMotion.soft => const Duration(milliseconds: 280),
      InstitutionMotion.slide => const Duration(milliseconds: 320),
      InstitutionMotion.spring => const Duration(milliseconds: 430),
      InstitutionMotion.depth => const Duration(milliseconds: 360),
      InstitutionMotion.playful => const Duration(milliseconds: 380),
    };
  }

  Curve motionCurve({bool entering = true}) => switch (motion) {
    InstitutionMotion.none => Curves.linear,
    InstitutionMotion.soft => entering ? Curves.easeOutCubic : Curves.easeIn,
    InstitutionMotion.slide => Curves.easeOutCubic,
    InstitutionMotion.spring => Curves.easeOutBack,
    InstitutionMotion.depth => Curves.easeOutQuart,
    InstitutionMotion.playful => Curves.easeOutBack,
  };

  double get buttonRadius => switch (buttonShape) {
    InstitutionButtonShape.square => 0,
    InstitutionButtonShape.soft => 8,
    InstitutionButtonShape.rounded => 18,
    InstitutionButtonShape.pill => 999,
  };

  bool get backgroundIsDark => background.computeLuminance() < .38;

  @override
  void dispose() {
    final background = myBackground;
    if (background != null) MemoryImage(background.bytes).evict();
    for (final file in myElements.values) {
      MemoryImage(file.bytes).evict();
    }
    myElements.clear();
    myBackground = null;
    super.dispose();
  }
}
