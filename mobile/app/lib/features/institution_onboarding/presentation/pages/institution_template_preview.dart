import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'institution_ambience_layer.dart';
import 'institution_brand_draft.dart';
import 'institution_ocean_ambience.dart';
import 'institution_ocean_scene.dart';
import 'institution_space_scene.dart';
import 'institution_animals_scene.dart';
import 'institution_nature_scene.dart';
import 'institution_fantasy_scene.dart';
import 'institution_my_ambience_scene.dart';

class InstitutionTemplatePreview extends StatelessWidget {
  const InstitutionTemplatePreview({
    super.key,
    required this.draft,
    required this.institutionName,
    this.logoBytes,
    this.logoUrl,
  });

  final InstitutionBrandDraft draft;
  final String institutionName;
  final Uint8List? logoBytes;
  final String? logoUrl;

  static const studentNavigation = [
    'Dashboard',
    'Learn',
    'Games',
    'My classes',
    'Progress',
    'Rankings',
    'Profile',
  ];
  static const teacherNavigation = [
    'Dashboard',
    'My classes',
    'Lessons & activities',
    'Assessments',
    'Attendance',
    'Schedule',
    'Profile',
  ];
  static const adminNavigation = [
    'Dashboard',
    'Students',
    'Access Requests',
    'Teachers',
    'Courses',
    'Classes',
    'English Levels',
    'Rankings',
    'Institution',
    'Settings',
  ];

  List<String> get navigation => switch (draft.role) {
    PreviewRole.student => studentNavigation,
    PreviewRole.teacher => teacherNavigation,
    PreviewRole.admin => adminNavigation,
  };

  String get activeSection =>
      navigation[draft.previewSectionIndex.clamp(0, navigation.length - 1)];

  OceanVariant get activeOceanVariant => draft.oceanPreviewBySection
      ? draft.oceanVariantForSection(activeSection)
      : draft.oceanVariant;

  SpaceVariant get activeSpaceVariant => draft.spacePreviewBySection
      ? draft.spaceVariantForSection(activeSection)
      : draft.spaceVariant;

  AnimalsVariant get activeAnimalsVariant => draft.animalsPreviewBySection
      ? draft.animalsVariantForSection(activeSection)
      : draft.animalsVariant;

  NatureVariant get activeNatureVariant => draft.naturePreviewBySection
      ? draft.natureVariantForSection(activeSection)
      : draft.natureVariant;

  FantasyVariant get activeFantasyVariant => draft.fantasyPreviewBySection
      ? draft.fantasyVariantForSection(activeSection)
      : draft.fantasyVariant;

  bool get hasIllustratedAmbience =>
      draft.ambience == InstitutionAmbience.ocean ||
      draft.ambience == InstitutionAmbience.space ||
      draft.ambience == InstitutionAmbience.animals ||
      draft.ambience == InstitutionAmbience.nature ||
      draft.ambience == InstitutionAmbience.fantasy ||
      draft.ambience == InstitutionAmbience.my;

  void _selectSection(int index) => draft.update(() {
    draft.previewSectionIndex = index;
  });

  String get roleLabel => switch (draft.role) {
    PreviewRole.student => 'Student demo',
    PreviewRole.teacher => 'Teacher demo',
    PreviewRole.admin => 'School admin demo',
  };

  String get mainAction => switch (draft.role) {
    PreviewRole.student => 'Continue lesson',
    PreviewRole.teacher => 'Open today’s class',
    PreviewRole.admin => 'Review school activity',
  };

  String get mainDetail => switch (draft.role) {
    PreviewRole.student => 'B1 · Academic English · Unit 4',
    PreviewRole.teacher => 'Class A · Attendance and lesson plan',
    PreviewRole.admin => 'Students, staff and access requests',
  };

  String get upcoming => switch (draft.role) {
    PreviewRole.student => 'Next class · 10:00',
    PreviewRole.teacher => 'Class A · 10:00',
    PreviewRole.admin => '3 access requests',
  };

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final mobile = draft.device == PreviewDevice.mobile;
    final width = mobile ? 390.0 : 1080.0;
    final height = mobile ? 680.0 : 600.0;
    final ocean = draft.ambience == InstitutionAmbience.ocean;
    final space = draft.ambience == InstitutionAmbience.space;
    final animals = draft.ambience == InstitutionAmbience.animals;
    final nature = draft.ambience == InstitutionAmbience.nature;
    final fantasy = draft.ambience == InstitutionAmbience.fantasy;
    final my = draft.ambience == InstitutionAmbience.my;
    final dark = draft.backgroundIsDark;
    final foreground = dark ? Colors.white : const Color(0xFF172033);
    final baseTheme = ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      fontFamily: draft.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: draft.primary,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      textTheme: (dark ? ThemeData.dark() : ThemeData.light()).textTheme.apply(
        fontFamily: draft.fontFamily,
      ),
    );

    final frame = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: draft.transparencyFor(InstitutionColorSlot.background) == 0
            ? draft.background
            : (dark ? const Color(0xFF111327) : const Color(0xFFF3F0E9)),
        borderRadius: BorderRadius.circular(mobile ? 32 : 24),
        border: Border.all(
          color: draft.primary.withValues(alpha: .72),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: draft.primary.withValues(alpha: .20),
            blurRadius: 36,
          ),
        ],
      ),
      child: Theme(
        data: baseTheme,
        child: DefaultTextStyle(
          key: const ValueKey('preview-default-text-style'),
          style: TextStyle(
            fontFamily: draft.fontFamily,
            color: foreground,
            fontSize: 14,
          ),
          child: Stack(
            children: [
              if (draft.transparencyFor(InstitutionColorSlot.background) > 0)
                Positioned.fill(
                  child: ColoredBox(
                    color: draft.surfaceColor(InstitutionColorSlot.background),
                  ),
                ),
              if (ocean && draft.backgroundIntensity > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: InstitutionOceanBackground(
                      intensityPercent: draft.backgroundIntensity,
                    ),
                  ),
                ),
              if (space && draft.backgroundIntensity > 0)
                Positioned.fill(
                  child: InstitutionSpaceBackground(
                    intensityPercent: draft.backgroundIntensity,
                  ),
                ),
              if (animals && draft.backgroundIntensity > 0)
                Positioned.fill(
                  child: InstitutionAnimalsBackground(
                    intensityPercent: draft.backgroundIntensity,
                  ),
                ),
              if (nature && draft.backgroundIntensity > 0)
                Positioned.fill(
                  child: InstitutionNatureBackground(
                    intensityPercent: draft.backgroundIntensity,
                  ),
                ),
              if (fantasy && draft.backgroundIntensity > 0)
                Positioned.fill(
                  child: InstitutionFantasyBackground(
                    intensityPercent: draft.backgroundIntensity,
                  ),
                ),
              if (my &&
                  draft.myBackground != null &&
                  draft.backgroundIntensity > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: draft.backgroundIntensity / 100,
                      child: Image.memory(
                        draft.myBackground!.bytes,
                        fit: BoxFit.cover,
                        alignment: Alignment(
                          draft.myFocalPoints[draft.device]!.dx,
                          draft.myFocalPoints[draft.device]!.dy,
                        ),
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              if (ocean)
                Positioned.fill(
                  child: ColoredBox(
                    color: draft
                        .surfaceColor(InstitutionColorSlot.background)
                        .withValues(
                          alpha:
                              (dark ? .52 : .80) *
                              (1 -
                                  draft.transparencyFor(
                                        InstitutionColorSlot.background,
                                      ) /
                                      100),
                        ),
                  ),
                ),
              if (space)
                Positioned.fill(
                  child: ColoredBox(
                    color: draft
                        .surfaceColor(InstitutionColorSlot.background)
                        .withValues(
                          alpha:
                              (dark ? .48 : .76) *
                              (1 -
                                  draft.transparencyFor(
                                        InstitutionColorSlot.background,
                                      ) /
                                      100),
                        ),
                  ),
                ),
              if (animals)
                Positioned.fill(
                  child: ColoredBox(
                    color: draft
                        .surfaceColor(InstitutionColorSlot.background)
                        .withValues(
                          alpha:
                              (dark ? .38 : .67) *
                              (1 -
                                  draft.transparencyFor(
                                        InstitutionColorSlot.background,
                                      ) /
                                      100),
                        ),
                  ),
                ),
              if (nature)
                Positioned.fill(
                  child: ColoredBox(
                    color: draft
                        .surfaceColor(InstitutionColorSlot.background)
                        .withValues(
                          alpha:
                              (dark ? .48 : .70) *
                              (1 -
                                  draft.transparencyFor(
                                        InstitutionColorSlot.background,
                                      ) /
                                      100),
                        ),
                  ),
                ),
              if (fantasy)
                Positioned.fill(
                  child: ColoredBox(
                    color: draft.background.withValues(
                      alpha:
                          (dark ? .48 : .70) *
                          (1 -
                              draft.transparencyFor(
                                    InstitutionColorSlot.background,
                                  ) /
                                  100),
                    ),
                  ),
                ),
              if (my)
                Positioned.fill(
                  child: ColoredBox(
                    color: draft.background.withValues(
                      alpha:
                          (dark ? .40 : .64) *
                          (1 -
                              draft.transparencyFor(
                                    InstitutionColorSlot.background,
                                  ) /
                                  100),
                    ),
                  ),
                ),
              Positioned.fill(child: _template(mobile, reduced, dark)),
              if (my)
                Positioned.fill(
                  child: InstitutionMyAmbienceScene(
                    key: const ValueKey('ambience-my'),
                    draft: draft,
                  ),
                ),
              if (ocean && draft.decorationIntensity > 0)
                Positioned.fill(
                  child: InstitutionOceanScene(
                    key: const ValueKey('ambience-ocean'),
                    draft: draft,
                    variant: activeOceanVariant,
                  ),
                ),
              if (space && draft.decorationIntensity > 0)
                Positioned.fill(
                  child: InstitutionSpaceScene(
                    key: const ValueKey('ambience-space'),
                    draft: draft,
                    variant: activeSpaceVariant,
                  ),
                ),
              if (animals && draft.decorationIntensity > 0)
                Positioned.fill(
                  child: InstitutionAnimalsScene(
                    key: const ValueKey('ambience-animals'),
                    draft: draft,
                    variant: activeAnimalsVariant,
                  ),
                ),
              if (nature && draft.decorationIntensity > 0)
                Positioned.fill(
                  child: InstitutionNatureScene(
                    key: const ValueKey('ambience-nature'),
                    draft: draft,
                    variant: activeNatureVariant,
                  ),
                ),
              if (fantasy && draft.decorationIntensity > 0)
                Positioned.fill(
                  child: InstitutionFantasyScene(
                    key: const ValueKey('ambience-fantasy'),
                    draft: draft,
                    variant: activeFantasyVariant,
                  ),
                ),
              if (!ocean && !space && !animals && !nature && !fantasy && !my)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: .58,
                      child: AnimatedSwitcher(
                        duration: reduced
                            ? Duration.zero
                            : const Duration(milliseconds: 320),
                        child: InstitutionAmbienceLayer(
                          key: ValueKey(draft.ambience.name),
                          ambience: draft.ambience,
                          intensityPercent: draft.decorationIntensity,
                          oceanVariant: activeOceanVariant,
                          primary: draft.primary,
                          secondary: draft.secondary,
                          accent: draft.accent,
                          dark: dark,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : width;
        final scale = (available / width).clamp(0.0, 1.0);
        return Center(
          child: SizedBox(
            width: width * scale,
            height: height * scale,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(width: width, height: height, child: frame),
            ),
          ),
        );
      },
    );
  }

  Widget _template(bool mobile, bool reduced, bool dark) =>
      switch (draft.template) {
        InstitutionTemplate.orbit => _orbit(mobile, dark),
        InstitutionTemplate.academy => _academy(mobile, dark),
        InstitutionTemplate.pulse => _pulse(mobile, dark),
        InstitutionTemplate.littleSteps => _littleSteps(mobile, dark),
        InstitutionTemplate.adventure => _adventure(mobile, dark),
        InstitutionTemplate.studio => _studio(mobile, dark),
        InstitutionTemplate.heritage => _heritage(mobile),
        InstitutionTemplate.prestige => _prestige(mobile, dark),
        InstitutionTemplate.nexus => _nexus(mobile),
      };

  Widget _orbit(bool mobile, bool dark) => _sideShell(
    mobile,
    dark,
    railWidth: 190,
    railOpacity: .78,
    navRadius: 12,
    body: Padding(
      padding: EdgeInsets.all(mobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _welcome(dark),
          SizedBox(height: mobile ? 12 : 18),
          Expanded(
            child: mobile
                ? Column(
                    children: [
                      Expanded(flex: 3, child: _orbitHero(dark, compact: true)),
                      const SizedBox(height: 12),
                      Expanded(flex: 2, child: _twoCards(dark)),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(flex: 3, child: _orbitHero(dark)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _twoCards(dark)),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _academy(bool mobile, bool dark) => _sideShell(
    mobile,
    dark,
    railWidth: 220,
    railOpacity: .95,
    navRadius: 6,
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _welcome(dark),
          const SizedBox(height: 20),
          Expanded(
            child: mobile
                ? ListView(
                    children: [
                      _academicPanel(
                        'Overview',
                        mainDetail,
                        dark,
                        compact: true,
                      ),
                      const SizedBox(height: 12),
                      _academicPanel('Schedule', upcoming, dark, compact: true),
                      const SizedBox(height: 12),
                      _academicPanel(
                        'Tasks',
                        '3 items need attention',
                        dark,
                        compact: true,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _academicPanel(
                          'Today at a glance',
                          mainDetail,
                          dark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _academicPanel('Schedule', upcoming, dark),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _academicPanel(
                                'Tasks',
                                '3 items need attention',
                                dark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _pulse(bool mobile, bool dark) => _sideShell(
    mobile,
    dark,
    railWidth: 170,
    railOpacity: .82,
    navRadius: 22,
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _welcome(dark),
          const SizedBox(height: 15),
          Expanded(
            child: mobile
                ? Column(
                    children: [
                      Expanded(flex: 2, child: _pulseProgress(dark)),
                      const SizedBox(height: 12),
                      Expanded(child: _pulseTiles(dark, horizontal: true)),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(flex: 2, child: _pulseProgress(dark)),
                      const SizedBox(width: 15),
                      Expanded(child: _pulseTiles(dark)),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _littleSteps(bool mobile, bool dark) {
    final student = draft.role == PreviewRole.student;
    final cards = student
        ? const [
            ('Learn', Icons.menu_book_rounded),
            ('Play', Icons.sports_esports_rounded),
            ('My class', Icons.groups_rounded),
          ]
        : [
            (
              draft.role == PreviewRole.teacher ? 'My classes' : 'Students',
              Icons.groups_rounded,
            ),
            (
              draft.role == PreviewRole.teacher ? 'Attendance' : 'Teachers',
              Icons.fact_check_rounded,
            ),
            (
              draft.role == PreviewRole.teacher ? 'Activities' : 'Requests',
              Icons.assignment_rounded,
            ),
          ];
    return _bubbleShell(
      mobile,
      dark,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _welcome(dark),
            const SizedBox(height: 18),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: draft.primary.withValues(alpha: dark ? .82 : .92),
                  borderRadius: BorderRadius.circular(42),
                ),
                child: Row(
                  children: [
                    Container(
                      width: mobile ? 84 : 120,
                      height: mobile ? 84 : 120,
                      decoration: BoxDecoration(
                        color: draft.accent,
                        shape: BoxShape.circle,
                      ),
                      child:
                          hasIllustratedAmbience &&
                              draft.decorationIntensity > 0
                          ? null
                          : Icon(
                              student
                                  ? Icons.waving_hand_rounded
                                  : Icons.workspaces_rounded,
                              size: mobile ? 42 : 58,
                              color: _onColor(draft.accent),
                            ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mainAction,
                            style: TextStyle(
                              color: _onColor(draft.primary),
                              fontSize: mobile ? 22 : 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mainDetail,
                            maxLines: 2,
                            style: TextStyle(
                              color: _onColor(
                                draft.primary,
                              ).withValues(alpha: .75),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _button('Open', compact: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(
                      child: _largeIconCard(cards[i].$1, cards[i].$2, dark),
                    ),
                    if (i != cards.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adventure(bool mobile, bool dark) {
    final stages = draft.role == PreviewRole.student
        ? const ['Warm-up', 'Lesson 4', 'Challenge', 'Reward']
        : draft.role == PreviewRole.teacher
        ? const ['Prepare', 'Teach', 'Attendance', 'Review']
        : const ['Overview', 'Requests', 'Staff', 'Reports'];
    return _adventureShell(
      mobile,
      dark,
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _welcome(dark),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.role == PreviewRole.student
                        ? 'Your learning trail'
                        : 'Today’s workflow',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _badge('Level B1', Icons.workspace_premium_rounded),
              ],
            ),
            const SizedBox(height: 18),
            if (mobile &&
                hasIllustratedAmbience &&
                draft.decorationIntensity > 0)
              const SizedBox(height: 105),
            Expanded(
              child: mobile
                  ? ListView.separated(
                      itemCount: stages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _missionCard(stages[i], i, dark, horizontal: true),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < stages.length; i++) ...[
                          Expanded(child: _missionCard(stages[i], i, dark)),
                          if (i != stages.length - 1)
                            SizedBox(
                              width: 34,
                              child: Center(
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: draft.accent,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studio(bool mobile, bool dark) {
    final ink = dark ? Colors.white : const Color(0xFF151515);
    return _studioShell(
      mobile,
      dark,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _welcome(dark),
            const SizedBox(height: 18),
            Expanded(
              child: mobile
                  ? Column(
                      children: [
                        Expanded(flex: 3, child: _studioFeature(ink, dark)),
                        const SizedBox(height: 12),
                        Expanded(
                          flex: 2,
                          child: _studioStrip(ink, dark, horizontal: true),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 5, child: _studioFeature(ink, dark)),
                        const SizedBox(width: 14),
                        Expanded(flex: 3, child: _studioStrip(ink, dark)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heritage(bool mobile) {
    final paper = Color.lerp(draft.background, const Color(0xFFF7EDD9), .82)!;
    const ink = Color(0xFF302A25);
    final rule = draft.primary.withValues(alpha: .62);
    return ColoredBox(
      color: hasIllustratedAmbience ? paper.withValues(alpha: .62) : paper,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PaperTexture())),
          Column(
            children: [
              Container(
                height: mobile ? 78 : 104,
                padding: EdgeInsets.symmetric(horizontal: mobile ? 17 : 30),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: rule, width: 1.4)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'THE SCHOOL EDITION  ·  ${roleLabel.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: draft.primary,
                        fontSize: mobile ? 8 : 10,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: Divider(color: rule)),
                        const SizedBox(width: 12),
                        Flexible(
                          flex: 3,
                          child: Text(
                            institutionName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Divider(color: rule)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: mobile
                    ? Column(
                        children: [
                          SizedBox(height: 54, child: _heritageIndex(true)),
                          Expanded(child: _heritageArticle(true, paper, ink)),
                        ],
                      )
                    : Row(
                        children: [
                          SizedBox(width: 190, child: _heritageIndex(false)),
                          Expanded(child: _heritageArticle(false, paper, ink)),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heritageIndex(bool mobile) {
    final entries = [
      for (var i = 0; i < navigation.length; i++) (i, navigation[i]),
    ];
    final list = ListView(
      scrollDirection: mobile ? Axis.horizontal : Axis.vertical,
      children: [
        for (final entry in entries)
          InkWell(
            key: ValueKey('preview-nav-${entry.$1}'),
            onTap: () => _selectSection(entry.$1),
            child: Container(
              margin: EdgeInsets.only(
                right: mobile ? 8 : 0,
                bottom: mobile ? 0 : 5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: entry.$1 == draft.previewSectionIndex
                    ? _tintedSurface(InstitutionColorSlot.primary, .12)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: draft.primary.withValues(
                      alpha: entry.$1 == draft.previewSectionIndex ? .7 : .22,
                    ),
                  ),
                ),
              ),
              child: Text(
                '${(entry.$1 + 1).toString().padLeft(2, '0')}  ${entry.$2}',
                maxLines: 1,
                style: TextStyle(
                  color: const Color(0xFF302A25),
                  fontSize: mobile ? 10 : 11,
                  fontWeight: entry.$1 == draft.previewSectionIndex
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          right: mobile
              ? BorderSide.none
              : BorderSide(color: draft.primary.withValues(alpha: .4)),
          bottom: mobile
              ? BorderSide(color: draft.primary.withValues(alpha: .4))
              : BorderSide.none,
        ),
      ),
      child: list,
    );
  }

  Widget _heritageArticle(bool mobile, Color paper, Color ink) => Padding(
    padding: EdgeInsets.all(mobile ? 13 : 25),
    child: Container(
      padding: EdgeInsets.all(mobile ? 15 : 25),
      decoration: BoxDecoration(
        color: paper.withValues(alpha: hasIllustratedAmbience ? .78 : .92),
        border: Border.all(color: draft.primary.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: .10),
            offset: const Offset(4, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOL. 01  /  TODAY  /  Demonstration data',
            style: TextStyle(
              color: draft.primary,
              fontSize: 9,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome to $institutionName',
            key: const ValueKey('preview-heading'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: mobile ? 20 : 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Divider(color: draft.primary.withValues(alpha: .65), thickness: 2),
          const SizedBox(height: 10),
          Text(
            mainAction,
            maxLines: 2,
            style: TextStyle(
              color: ink,
              fontSize: mobile ? 19 : 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(mainDetail, style: TextStyle(color: ink.withValues(alpha: .76))),
          const SizedBox(height: 16),
          _button('Open profile', compact: true),
          const Spacer(),
          Divider(color: draft.primary.withValues(alpha: .4)),
          Row(
            children: [
              Expanded(child: _heritageNote('UP NEXT', upcoming, ink)),
              const SizedBox(width: 12),
              Expanded(child: _heritageNote('TO REVIEW', '3 tasks', ink)),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _heritageNote(String heading, String body, Color ink) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        heading,
        style: TextStyle(color: draft.primary, fontSize: 9, letterSpacing: 1.4),
      ),
      const SizedBox(height: 4),
      Text(
        body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ],
  );

  Widget _prestige(bool mobile, bool dark) {
    final ink = _text(dark);
    return Column(
      children: [
        Container(
          height: mobile ? 76 : 88,
          padding: EdgeInsets.symmetric(horizontal: mobile ? 18 : 32),
          decoration: BoxDecoration(
            color: _surface(dark, .96),
            border: Border(
              bottom: BorderSide(color: draft.secondary.withValues(alpha: .25)),
            ),
          ),
          child: Row(
            children: [
              Expanded(flex: mobile ? 2 : 1, child: _brand(dark)),
              if (!mobile)
                Expanded(
                  flex: 3,
                  child: Center(child: _prestigeNavigation(dark)),
                ),
              Text(
                roleLabel.toUpperCase(),
                maxLines: 1,
                style: TextStyle(
                  color: _muted(dark),
                  fontSize: 9,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (mobile) SizedBox(height: 49, child: _prestigeNavigation(dark)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              mobile ? 18 : 45,
              mobile ? 18 : 30,
              mobile ? 18 : 45,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'A CONSIDERED VIEW OF TODAY · Demonstration data',
                  style: TextStyle(
                    color: draft.secondary,
                    letterSpacing: 2.5,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Welcome to $institutionName',
                  key: const ValueKey('preview-heading'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: mobile ? 23 : 38,
                    fontWeight: FontWeight.w600,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  height: 1,
                  color: draft.accent.withValues(alpha: .65),
                ),
                const SizedBox(height: 21),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.all(mobile ? 19 : 34),
                    decoration: BoxDecoration(
                      color: _surface(dark, .97),
                      border: Border.all(
                        color: draft.secondary.withValues(alpha: .25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .06),
                          blurRadius: 24,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '01 / FEATURE',
                          style: TextStyle(
                            color: draft.secondary,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          mainAction,
                          maxLines: 2,
                          style: TextStyle(
                            color: ink,
                            fontSize: mobile ? 22 : 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          mainDetail,
                          maxLines: 2,
                          style: TextStyle(color: _muted(dark), fontSize: 12),
                        ),
                        const SizedBox(height: 17),
                        _button('Open profile', compact: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: _prestigeDetail('COMING UP', upcoming, dark),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _prestigeDetail(
                          'YOUR FOCUS',
                          '3 tasks need attention',
                          dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _prestigeNavigation(bool dark) => ListView(
    scrollDirection: Axis.horizontal,
    shrinkWrap: true,
    children: [
      for (var i = 0; i < navigation.length; i++)
        InkWell(
          key: ValueKey('preview-nav-$i'),
          onTap: () => _selectSection(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                navigation[i],
                style: TextStyle(
                  color: i == draft.previewSectionIndex
                      ? _text(dark)
                      : _muted(dark),
                  fontSize: 10,
                  fontWeight: i == draft.previewSectionIndex
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _prestigeDetail(String label, String value, bool dark) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: _surface(dark, .95),
      border: Border(top: BorderSide(color: draft.accent, width: 2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: draft.secondary,
            fontSize: 9,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _text(dark),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _nexus(bool mobile) {
    const ink = Colors.white;
    final shell = Color.lerp(draft.background, const Color(0xFF061626), .75)!;
    return ColoredBox(
      color: hasIllustratedAmbience ? shell.withValues(alpha: .84) : shell,
      child: Column(
        children: [
          Container(
            height: 69,
            padding: const EdgeInsets.symmetric(horizontal: 19),
            decoration: BoxDecoration(
              color: const Color(0xDD071422),
              border: Border(
                bottom: BorderSide(color: draft.accent.withValues(alpha: .65)),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _brand(true)),
                Text(
                  'NODE / ${roleLabel.toUpperCase()}',
                  style: TextStyle(
                    color: draft.accent,
                    fontSize: 9,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (!mobile) SizedBox(width: 187, child: _nexusRail()),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(mobile ? 15 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'LIVE WORKSPACE  /  Demonstration data',
                          style: TextStyle(
                            color: draft.accent,
                            fontSize: 9,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Welcome to $institutionName',
                          key: const ValueKey('preview-heading'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Expanded(
                          flex: 3,
                          child: _nexusPanel(
                            label: '01  //  ACTIVE MODULE',
                            title: mainAction,
                            detail: mainDetail,
                            primary: true,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Expanded(
                                child: _nexusPanel(
                                  label: '02  //  SCHEDULE',
                                  title: upcoming,
                                  detail: 'Next signal in your workspace',
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: _nexusPanel(
                                  label: '03  //  QUEUE',
                                  title: '3 tasks',
                                  detail: 'Ready for review',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (mobile) SizedBox(height: 61, child: _nexusMobileNavigation()),
        ],
      ),
    );
  }

  Widget _nexusRail() => Container(
    padding: const EdgeInsets.fromLTRB(9, 19, 9, 12),
    decoration: BoxDecoration(
      color: const Color(0xDD081D2D),
      border: Border(
        right: BorderSide(color: draft.secondary.withValues(alpha: .4)),
      ),
    ),
    child: ListView(
      children: [
        for (var i = 0; i < navigation.length; i++)
          InkWell(
            key: ValueKey('preview-nav-$i'),
            onTap: () => _selectSection(i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              color: i == draft.previewSectionIndex
                  ? _tintedSurface(InstitutionColorSlot.primary, .34)
                  : Colors.transparent,
              child: Row(
                children: [
                  Text(
                    '${(i + 1).toString().padLeft(2, '0')} /',
                    style: TextStyle(color: draft.accent, fontSize: 9),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      navigation[i].toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _nexusMobileNavigation() => Container(
    color: const Color(0xED081D2D),
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (var i = 0; i < navigation.length; i++)
          InkWell(
            key: ValueKey('preview-nav-$i'),
            onTap: () => _selectSection(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _navIcon(navigation[i]),
                    color: i == draft.previewSectionIndex
                        ? draft.accent
                        : Colors.white60,
                    size: 18,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    navigation[i],
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _nexusPanel({
    required String label,
    required String title,
    required String detail,
    bool primary = false,
  }) => ClipPath(
    clipper: const _ChamferClipper(19),
    child: Container(
      padding: EdgeInsets.all(primary ? 19 : 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: primary
              ? [
                  _tintedSurface(InstitutionColorSlot.primary, .53),
                  const Color(0xFF0A2536),
                ]
              : [const Color(0xFF173044), const Color(0xFF0A1D2D)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: draft.accent,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: primary ? 24 : 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          if (primary) ...[
            const SizedBox(height: 12),
            _button('Open profile', compact: true),
          ],
          Container(
            height: 2,
            margin: const EdgeInsets.only(top: 10),
            color: draft.accent.withValues(alpha: .65),
          ),
        ],
      ),
    ),
  );

  Widget _sideShell(
    bool mobile,
    bool dark, {
    required double railWidth,
    required double railOpacity,
    required double navRadius,
    required Widget body,
  }) {
    if (mobile) {
      return Column(
        children: [
          _mobileHeader(dark),
          Expanded(child: body),
          _mobileNavigation(dark, radius: navRadius),
        ],
      );
    }
    return Row(
      children: [
        Container(
          width: railWidth,
          padding: const EdgeInsets.fromLTRB(15, 19, 13, 14),
          color: (dark ? const Color(0xFF090F29) : Colors.white).withValues(
            alpha: railOpacity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _brand(dark),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < navigation.length; i++)
                      _navItem(
                        navigation[i],
                        i == draft.previewSectionIndex,
                        dark,
                        navRadius,
                      ),
                  ],
                ),
              ),
              Text(
                roleLabel,
                style: TextStyle(color: _muted(dark), fontSize: 10),
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _bubbleShell(bool mobile, bool dark, {required Widget body}) {
    if (mobile) {
      return Column(
        children: [
          _mobileHeader(dark),
          Expanded(child: body),
          _mobileNavigation(dark, radius: 28),
        ],
      );
    }
    return Row(
      children: [
        Container(
          width: 155,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: _surface(dark, .94),
            borderRadius: BorderRadius.circular(36),
          ),
          child: Column(
            children: [
              _logo(46),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < navigation.length; i++)
                      InkWell(
                        key: ValueKey('preview-nav-$i'),
                        onTap: () => _selectSection(i),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: i == draft.previewSectionIndex
                                    ? draft.surfaceColor(
                                        InstitutionColorSlot.primary,
                                      )
                                    : _tintedSurface(
                                        InstitutionColorSlot.secondary,
                                        .16,
                                      ),
                                child: Icon(
                                  _navIcon(navigation[i]),
                                  color: i == draft.previewSectionIndex
                                      ? _onColor(draft.primary)
                                      : draft.secondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                navigation[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _adventureShell(bool mobile, bool dark, {required Widget body}) {
    if (mobile) {
      return Column(
        children: [
          _mobileHeader(dark),
          Expanded(child: body),
          _mobileNavigation(dark, radius: 12),
        ],
      );
    }
    return Column(
      children: [
        Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          color: _surface(dark, .93),
          child: Row(
            children: [
              SizedBox(width: 220, child: _brand(dark)),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < 5 && i < navigation.length; i++)
                      Expanded(
                        child: InkWell(
                          key: ValueKey('preview-nav-$i'),
                          onTap: () => _selectSection(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              navigation[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _badge('Trail 04', Icons.explore_rounded),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _studioShell(bool mobile, bool dark, {required Widget body}) {
    if (mobile) {
      return Column(
        children: [
          _mobileHeader(dark),
          Expanded(child: body),
          _mobileNavigation(dark, radius: 0),
        ],
      );
    }
    return Column(
      children: [
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: _surface(dark, .96),
            border: Border(bottom: BorderSide(color: draft.accent, width: 3)),
          ),
          child: Row(
            children: [
              SizedBox(width: 235, child: _brand(dark)),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < 6 && i < navigation.length; i++)
                      Expanded(
                        child: InkWell(
                          key: ValueKey('preview-nav-$i'),
                          onTap: () => _selectSection(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Text(
                              navigation[i].toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _button('PROFILE', compact: true),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _mobileHeader(bool dark) => Container(
    height: 66,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    color: _surface(dark, .88),
    child: Row(
      children: [
        Expanded(child: _brand(dark)),
        _badge(roleLabel.split(' ').first, Icons.person_outline),
      ],
    ),
  );

  Widget _mobileNavigation(bool dark, {required double radius}) => Container(
    height: 70,
    color: _surface(dark, .96),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (var index = 0; index < 4 && index < navigation.length; index++)
          Expanded(
            child: InkWell(
              key: ValueKey('preview-nav-$index'),
              onTap: () => _selectSection(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                decoration: BoxDecoration(
                  color: index == draft.previewSectionIndex
                      ? _tintedSurface(InstitutionColorSlot.primary, .18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _navIcon(navigation[index]),
                      size: 19,
                      color: index == draft.previewSectionIndex
                          ? draft.accent
                          : _muted(dark),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      navigation[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        color: index == draft.previewSectionIndex
                            ? _text(dark)
                            : _muted(dark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _brand(bool dark) => Row(
    children: [
      _logo(36),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          institutionName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: _text(dark), fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );

  Widget _logo(double size) {
    ImageProvider? provider;
    if (logoBytes != null) provider = MemoryImage(logoBytes!);
    if (provider == null && logoUrl != null && logoUrl!.isNotEmpty) {
      provider = NetworkImage(logoUrl!);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: draft.surfaceColor(InstitutionColorSlot.primary),
        borderRadius: BorderRadius.circular(size * .31),
        image: provider == null
            ? null
            : DecorationImage(image: provider, fit: BoxFit.cover),
      ),
      child: provider == null
          ? Icon(
              Icons.auto_awesome,
              color: _onColor(draft.primary),
              size: size * .52,
            )
          : null,
    );
  }

  Widget _navItem(String label, bool selected, bool dark, double radius) =>
      InkWell(
        key: ValueKey('preview-nav-${navigation.indexOf(label)}'),
        onTap: () => _selectSection(navigation.indexOf(label)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _tintedSurface(InstitutionColorSlot.primary, dark ? .30 : .13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            children: [
              Icon(
                _navIcon(label),
                size: 17,
                color: selected ? draft.accent : _muted(dark),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? _text(dark) : _muted(dark),
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _welcome(bool dark) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to $institutionName',
              key: const ValueKey('preview-heading'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _text(dark),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '$roleLabel · Demonstration data',
              style: TextStyle(color: _muted(dark), fontSize: 11),
            ),
          ],
        ),
      ),
      _button('Open profile', compact: true),
    ],
  );

  Widget _orbitHero(bool dark, {bool compact = false}) => Container(
    padding: EdgeInsets.all(compact ? 18 : 24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          draft.surfaceColor(InstitutionColorSlot.primary),
          draft.surfaceColor(InstitutionColorSlot.secondary),
        ],
      ),
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: draft.primary.withValues(alpha: .32),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.rocket_launch_rounded,
          color: _onColor(draft.primary),
          size: compact ? 31 : 38,
        ),
        const Spacer(),
        Text(
          mainAction,
          style: TextStyle(
            color: _onColor(draft.primary),
            fontSize: compact ? 21 : 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          mainDetail,
          style: TextStyle(
            color: _onColor(draft.primary).withValues(alpha: .74),
            fontSize: 12,
          ),
        ),
        SizedBox(height: compact ? 10 : 15),
        _button('Continue', compact: true),
      ],
    ),
  );

  Widget _twoCards(bool dark) => Column(
    children: [
      Expanded(child: _infoCard('Next', upcoming, Icons.event_rounded, dark)),
      const SizedBox(height: 12),
      Expanded(
        child: _infoCard(
          'Pending tasks',
          '3 items need attention',
          Icons.notifications_active_rounded,
          dark,
        ),
      ),
    ],
  );

  Widget _infoCard(String title, String subtitle, IconData icon, bool dark) =>
      Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: _surface(dark, .88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: draft.secondary.withValues(alpha: .32)),
        ),
        child: Row(
          children: [
            Icon(icon, color: draft.accent, size: 27),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: _muted(dark), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _academicPanel(
    String title,
    String subtitle,
    bool dark, {
    bool compact = false,
  }) => Container(
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      color: _surface(dark, .96),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: dark ? Colors.white12 : const Color(0xFFD8DEE8),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 42, height: 4, color: draft.primary),
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        Text(subtitle, style: TextStyle(color: _muted(dark), fontSize: 11)),
        if (compact) const SizedBox(height: 20) else const Spacer(),
        LinearProgressIndicator(
          value: .68,
          color: draft.primary,
          backgroundColor: draft.secondary.withValues(alpha: .14),
        ),
      ],
    ),
  );

  Widget _pulseProgress(bool dark) => Container(
    padding: const EdgeInsets.all(23),
    decoration: BoxDecoration(
      color: draft.surfaceColor(InstitutionColorSlot.primary),
      borderRadius: BorderRadius.circular(36),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft.role == PreviewRole.student ? 'THIS WEEK' : 'TODAY',
          style: TextStyle(
            color: _onColor(draft.primary).withValues(alpha: .72),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Text(
          draft.role == PreviewRole.student ? '78%' : '12',
          style: TextStyle(
            color: _onColor(draft.primary),
            fontSize: 52,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          mainAction,
          style: TextStyle(
            color: _onColor(draft.primary),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: .78,
            color: draft.accent,
            backgroundColor: _onColor(draft.primary).withValues(alpha: .18),
          ),
        ),
      ],
    ),
  );

  Widget _pulseTiles(bool dark, {bool horizontal = false}) {
    final cards = [
      Expanded(child: _largeIconCard(upcoming, Icons.event_rounded, dark)),
      SizedBox(width: horizontal ? 13 : 0, height: horizontal ? 0 : 13),
      Expanded(child: _largeIconCard('3 tasks', Icons.bolt_rounded, dark)),
    ];
    return horizontal ? Row(children: cards) : Column(children: cards);
  }

  Widget _largeIconCard(String label, IconData icon, bool dark) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _surface(dark, .92),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: draft.secondary.withValues(alpha: .38)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: draft.accent, size: 31),
        const SizedBox(height: 9),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );

  Widget _missionCard(
    String title,
    int index,
    bool dark, {
    bool horizontal = false,
  }) {
    final completed = index < 1;
    final content = [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: completed
              ? draft.surfaceColor(InstitutionColorSlot.primary)
              : draft.secondary.withValues(
                  alpha:
                      .18 *
                      (1 -
                          draft.transparencyFor(
                                InstitutionColorSlot.secondary,
                              ) /
                              100),
                ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: completed
              ? Icon(Icons.check_rounded, color: _onColor(draft.primary))
              : Text(
                  '${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
        ),
      ),
      SizedBox(width: horizontal ? 14 : 0, height: horizontal ? 0 : 15),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: horizontal
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: horizontal ? TextAlign.start : TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              index == 0 ? 'Completed' : 'Ready when you are',
              textAlign: horizontal ? TextAlign.start : TextAlign.center,
              style: TextStyle(color: _muted(dark), fontSize: 10),
            ),
          ],
        ),
      ),
      if (horizontal) Icon(Icons.chevron_right_rounded, color: draft.accent),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface(dark, .92),
        borderRadius: BorderRadius.circular(index.isEven ? 24 : 12),
        border: Border.all(
          color: completed
              ? draft.primary
              : draft.secondary.withValues(alpha: .28),
          width: completed ? 2 : 1,
        ),
      ),
      child: horizontal ? Row(children: content) : Column(children: content),
    );
  }

  Widget _studioFeature(Color ink, bool dark) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: draft.surfaceColor(InstitutionColorSlot.primary),
      borderRadius: const BorderRadius.only(topRight: Radius.circular(64)),
    ),
    child: Stack(
      children: [
        Positioned(
          right: 0,
          top: 0,
          child: Transform.rotate(
            angle: .10,
            child: _badge('NEW', Icons.auto_awesome_rounded),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FEATURE / 04',
              style: TextStyle(
                color: _onColor(draft.primary).withValues(alpha: .65),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const Spacer(),
            Text(
              mainAction.toUpperCase(),
              maxLines: 2,
              style: TextStyle(
                color: _onColor(draft.primary),
                fontSize: 31,
                height: .96,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mainDetail,
              style: TextStyle(
                color: _onColor(draft.primary).withValues(alpha: .75),
              ),
            ),
            const SizedBox(height: 16),
            _button('OPEN / START', compact: true),
          ],
        ),
      ],
    ),
  );

  Widget _studioStrip(Color ink, bool dark, {bool horizontal = false}) {
    final panels = [
      Expanded(
        flex: 3,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: _surface(dark, .94),
            border: Border.all(color: ink.withValues(alpha: .20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROGRESS',
                style: TextStyle(
                  color: _muted(dark),
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '78%',
                style: TextStyle(
                  color: draft.accent,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                ),
              ),
              LinearProgressIndicator(
                value: .78,
                color: draft.accent,
                backgroundColor: draft.secondary.withValues(alpha: .18),
              ),
            ],
          ),
        ),
      ),
      SizedBox(width: horizontal ? 13 : 0, height: horizontal ? 0 : 13),
      Expanded(
        flex: 2,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          color: draft.surfaceColor(InstitutionColorSlot.secondary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_outward_rounded,
                color: _onColor(draft.secondary),
              ),
              const SizedBox(height: 8),
              Text(
                upcoming.toUpperCase(),
                style: TextStyle(
                  color: _onColor(draft.secondary),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
    return horizontal ? Row(children: panels) : Column(children: panels);
  }

  Widget _badge(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: draft.surfaceColor(InstitutionColorSlot.accent),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: _onColor(draft.accent)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: _onColor(draft.accent),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  Widget _button(
    String label, {
    bool compact = false,
    bool disabled = false,
    bool pressed = false,
  }) {
    final finish = draft.buttonFinish;
    final foreground = finish == InstitutionButtonFinish.outlined
        ? draft.primary
        : finish == InstitutionButtonFinish.tonal
        ? _text(draft.backgroundIsDark)
        : _onColor(draft.primary);
    Color background = switch (finish) {
      InstitutionButtonFinish.outlined => Colors.transparent,
      InstitutionButtonFinish.tonal => draft.primary.withValues(
        alpha:
            .18 *
            (1 - draft.transparencyFor(InstitutionColorSlot.primary) / 100),
      ),
      _ => draft.surfaceColor(InstitutionColorSlot.primary),
    };
    if (disabled) background = background.withValues(alpha: .35);
    return Transform.translate(
      offset: pressed && finish == InstitutionButtonFinish.elevated
          ? const Offset(0, 3)
          : Offset.zero,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 20,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: finish == InstitutionButtonFinish.gradient ? null : background,
          gradient: finish == InstitutionButtonFinish.gradient
              ? LinearGradient(
                  colors: [
                    draft.surfaceColor(InstitutionColorSlot.primary),
                    draft.surfaceColor(InstitutionColorSlot.secondary),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(draft.buttonRadius),
          border: finish == InstitutionButtonFinish.outlined
              ? Border.all(color: draft.primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: finish == InstitutionButtonFinish.elevated && !pressed
              ? [
                  BoxShadow(
                    color: draft.primary.withValues(alpha: .35),
                    blurRadius: 0,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          key: label == 'Open profile'
              ? const ValueKey('preview-button-label')
              : null,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: draft.fontFamily,
            color: disabled ? foreground.withValues(alpha: .50) : foreground,
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  IconData _navIcon(String label) {
    if (label.contains('class')) return Icons.groups_outlined;
    if (label.contains('Game')) return Icons.sports_esports_outlined;
    if (label.contains('Progress') || label.contains('Rank')) {
      return Icons.trending_up_rounded;
    }
    if (label.contains('Profile') || label.contains('Student')) {
      return Icons.person_outline_rounded;
    }
    if (label.contains('Teacher')) return Icons.school_outlined;
    if (label.contains('Request')) return Icons.mark_email_unread_outlined;
    return Icons.grid_view_rounded;
  }

  Color _surface(bool dark, double opacity) =>
      (dark ? const Color(0xFF10172E) : Colors.white).withValues(
        alpha: opacity,
      );
  Color _tintedSurface(InstitutionColorSlot slot, double opacity) => draft
      .colorFor(slot)
      .withValues(alpha: opacity * (1 - draft.transparencyFor(slot) / 100));
  Color _text(bool dark) => dark ? Colors.white : const Color(0xFF172033);
  Color _muted(bool dark) => dark ? Colors.white60 : const Color(0xFF667085);

  Color _onColor(Color color) {
    final slot = color == draft.primary
        ? InstitutionColorSlot.primary
        : color == draft.secondary
        ? InstitutionColorSlot.secondary
        : color == draft.accent
        ? InstitutionColorSlot.accent
        : null;
    final fallback = draft.backgroundIsDark
        ? const Color(0xFF111327)
        : const Color(0xFFF3F0E9);
    final backdrop = Color.alphaBlend(
      draft.surfaceColor(InstitutionColorSlot.background),
      fallback,
    );
    final visible = slot == null
        ? color
        : Color.alphaBlend(draft.surfaceColor(slot), backdrop);
    return visible.computeLuminance() > .42 ? Colors.black : Colors.white;
  }
}

class _PaperTexture extends CustomPainter {
  const _PaperTexture();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x153E3022)
      ..strokeWidth = .6;
    for (var i = 0; i < 210; i++) {
      final x = ((i * 127.7) % size.width);
      final y = ((i * 83.9) % size.height);
      canvas.drawLine(Offset(x, y), Offset(x + 3.5, y + .7), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexture oldDelegate) => false;
}

class _ChamferClipper extends CustomClipper<Path> {
  const _ChamferClipper(this.corner);

  final double corner;

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width - corner, 0)
    ..lineTo(size.width, corner)
    ..lineTo(size.width, size.height)
    ..lineTo(corner, size.height)
    ..lineTo(0, size.height - corner)
    ..close();

  @override
  bool shouldReclip(covariant _ChamferClipper oldClipper) =>
      corner != oldClipper.corner;
}
