import 'package:flutter/material.dart';

import '../../../institution_onboarding/presentation/pages/institution_animals_scene.dart';
import '../../../institution_onboarding/presentation/pages/institution_brand_draft.dart';
import '../../../institution_onboarding/presentation/pages/institution_fantasy_scene.dart';
import '../../../institution_onboarding/presentation/pages/institution_my_ambience_scene.dart';
import '../../../institution_onboarding/presentation/pages/institution_nature_scene.dart';
import '../../../institution_onboarding/presentation/pages/institution_ocean_ambience.dart';
import '../../../institution_onboarding/presentation/pages/institution_ocean_scene.dart';
import '../../../institution_onboarding/presentation/pages/institution_space_scene.dart';

class InstitutionAdminDestination {
  const InstitutionAdminDestination({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
}

class InstitutionAdminAppearanceShell extends StatelessWidget {
  const InstitutionAdminAppearanceShell({
    super.key,
    required this.draft,
    required this.institutionName,
    required this.destinations,
    required this.body,
    required this.onRefresh,
    required this.onSignOut,
    this.logoUrl,
  });

  final InstitutionBrandDraft draft;
  final String institutionName;
  final String? logoUrl;
  final List<InstitutionAdminDestination> destinations;
  final Widget body;
  final VoidCallback onRefresh;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 760;
      draft.device = mobile ? PreviewDevice.mobile : PreviewDevice.desktop;
      final dark = draft.backgroundIsDark;
      final foreground = dark ? Colors.white : const Color(0xFF172033);
      final base = dark ? ThemeData.dark() : ThemeData.light();
      final theme = base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: draft.fontFamily,
          bodyColor: foreground,
          displayColor: foreground,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: draft.primary,
          brightness: dark ? Brightness.dark : Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.transparent,
      );
      return Theme(
        data: theme,
        child: DefaultTextStyle(
          style: TextStyle(fontFamily: draft.fontFamily, color: foreground),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: draft.backgroundIsDark
                    ? const Color(0xFF080D24)
                    : const Color(0xFFF4F6FA),
              ),
              _background(),
              _templateSurface(context, mobile, foreground),
              _decorations(),
            ],
          ),
        ),
      );
    },
  );

  Widget _background() {
    if (draft.backgroundIntensity <= 0) return const SizedBox.shrink();
    return switch (draft.ambience) {
      InstitutionAmbience.ocean => InstitutionOceanBackground(
        intensityPercent: draft.backgroundIntensity,
      ),
      InstitutionAmbience.space => InstitutionSpaceBackground(
        intensityPercent: draft.backgroundIntensity,
      ),
      InstitutionAmbience.animals => InstitutionAnimalsBackground(
        intensityPercent: draft.backgroundIntensity,
      ),
      InstitutionAmbience.nature => InstitutionNatureBackground(
        intensityPercent: draft.backgroundIntensity,
      ),
      InstitutionAmbience.fantasy => InstitutionFantasyBackground(
        intensityPercent: draft.backgroundIntensity,
      ),
      InstitutionAmbience.my when draft.myBackground != null => Opacity(
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
      _ => const SizedBox.shrink(),
    };
  }

  Widget _templateSurface(BuildContext context, bool mobile, Color foreground) {
    final topNavigation = {
      InstitutionTemplate.academy,
      InstitutionTemplate.heritage,
      InstitutionTemplate.prestige,
      InstitutionTemplate.studio,
    }.contains(draft.template);
    final angular = draft.template == InstitutionTemplate.nexus;
    final generous = draft.template == InstitutionTemplate.prestige;
    final playful = {
      InstitutionTemplate.pulse,
      InstitutionTemplate.littleSteps,
      InstitutionTemplate.adventure,
    }.contains(draft.template);
    final backgroundAlpha =
        1 - draft.transparencyFor(InstitutionColorSlot.background) / 100;
    final overlay = draft.background.withValues(
      alpha: (draft.backgroundIsDark ? .82 : .90) * backgroundAlpha,
    );
    final mobileNavigationHeight = _mobileNavigationHeight(context);
    final content = Column(
      children: [
        _topBar(context, foreground, mobile),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              mobile
                  ? 12
                  : generous
                  ? 42
                  : 22,
              mobile ? 10 : 18,
              mobile
                  ? 12
                  : generous
                  ? 42
                  : 22,
              mobile ? mobileNavigationHeight + 10 : 24,
            ),
            child: body,
          ),
        ),
      ],
    );
    if (mobile) {
      return ColoredBox(
        color: overlay,
        child: Stack(
          children: [
            content,
            Align(
              alignment: Alignment.bottomCenter,
              child: _mobileNavigation(context, foreground, angular, playful),
            ),
          ],
        ),
      );
    }
    if (topNavigation) {
      return Padding(
        padding: EdgeInsets.all(generous ? 26 : 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            draft.template == InstitutionTemplate.heritage ? 3 : 18,
          ),
          child: ColoredBox(
            color: overlay,
            child: Column(
              children: [
                _desktopTopNavigation(foreground),
                Expanded(child: content),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(
        draft.template == InstitutionTemplate.orbit ? 14 : 0,
      ),
      child: Row(
        children: [
          _sideNavigation(foreground, angular, playful),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                draft.template == InstitutionTemplate.orbit
                    ? 28
                    : angular
                    ? 4
                    : 0,
              ),
              child: ColoredBox(color: overlay, child: content),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, Color foreground, bool mobile) =>
      Container(
        height: mobile ? 64 : 76,
        padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 24),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: draft.primary.withValues(alpha: .20)),
          ),
        ),
        child: Row(
          children: [
            if (mobile) ...[_brandMark(), const SizedBox(width: 10)],
            Expanded(
              child: Text(
                institutionName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: mobile ? 16 : 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh dashboard',
              onPressed: onRefresh,
              icon: Icon(Icons.refresh_rounded, color: foreground),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: onSignOut,
              icon: Icon(Icons.logout_rounded, color: foreground),
            ),
          ],
        ),
      );

  Widget _brandMark() => Container(
    width: 42,
    height: 42,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: draft.primary,
      borderRadius: BorderRadius.circular(draft.buttonRadius.clamp(8, 21)),
    ),
    child: logoUrl == null || logoUrl!.isEmpty
        ? const Icon(Icons.auto_awesome, color: Colors.white)
        : Image.network(
            logoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.auto_awesome, color: Colors.white),
          ),
  );

  Widget _sideNavigation(Color foreground, bool angular, bool playful) =>
      Container(
        width: playful ? 220 : 236,
        margin: draft.template == InstitutionTemplate.orbit
            ? const EdgeInsets.only(right: 14)
            : EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
        decoration: BoxDecoration(
          color: draft.primary.withValues(alpha: .22),
          borderRadius: BorderRadius.circular(
            draft.template == InstitutionTemplate.orbit
                ? 28
                : angular
                ? 4
                : 0,
          ),
          border: Border.all(color: draft.primary.withValues(alpha: .42)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _brandMark(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'NAOS',
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView(
                children: [
                  for (final item in destinations)
                    _navItem(item, foreground, compact: false),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _desktopTopNavigation(Color foreground) => Container(
    height: 76,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: draft.primary.withValues(alpha: .13),
      border: Border(
        bottom: BorderSide(color: draft.primary.withValues(alpha: .28)),
      ),
    ),
    child: Row(
      children: [
        _brandMark(),
        const SizedBox(width: 10),
        Text(
          'NAOS',
          style: TextStyle(color: foreground, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final item in destinations)
                _navItem(item, foreground, compact: true),
            ],
          ),
        ),
      ],
    ),
  );

  double _mobileNavigationHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    return 72 + ((scale - 1).clamp(0, 2) * 24);
  }

  Widget _mobileNavigation(
    BuildContext context,
    Color foreground,
    bool angular,
    bool playful,
  ) {
    final visible = destinations
        .where((item) => item.label != 'Sign out')
        .toList();
    return Container(
      height: _mobileNavigationHeight(context),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: draft.background.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(
          angular
              ? 5
              : playful
              ? 28
              : 18,
        ),
        border: Border.all(color: draft.primary.withValues(alpha: .45)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18)],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        children: [
          for (final item in visible) _navItem(item, foreground, compact: true),
        ],
      ),
    );
  }

  Widget _navItem(
    InstitutionAdminDestination item,
    Color foreground, {
    required bool compact,
  }) => Padding(
    padding: EdgeInsets.symmetric(horizontal: compact ? 3 : 0, vertical: 3),
    child: Material(
      color: item.selected
          ? draft.primary.withValues(alpha: .72)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(draft.buttonRadius.clamp(4, 24)),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(draft.buttonRadius.clamp(4, 24)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 13,
            vertical: 11,
          ),
          child: compact
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 18, color: foreground),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(item.icon, size: 19, color: foreground),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: item.selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );

  Widget _decorations() {
    if (draft.decorationIntensity <= 0) return const SizedBox.shrink();
    final section = 'Dashboard';
    return IgnorePointer(
      child: switch (draft.ambience) {
        InstitutionAmbience.ocean => InstitutionOceanScene(
          draft: draft,
          variant: draft.oceanPreviewBySection
              ? draft.oceanVariantForSection(section)
              : draft.oceanVariant,
        ),
        InstitutionAmbience.space => InstitutionSpaceScene(
          draft: draft,
          variant: draft.spacePreviewBySection
              ? draft.spaceVariantForSection(section)
              : draft.spaceVariant,
        ),
        InstitutionAmbience.animals => InstitutionAnimalsScene(
          draft: draft,
          variant: draft.animalsPreviewBySection
              ? draft.animalsVariantForSection(section)
              : draft.animalsVariant,
        ),
        InstitutionAmbience.nature => InstitutionNatureScene(
          draft: draft,
          variant: draft.naturePreviewBySection
              ? draft.natureVariantForSection(section)
              : draft.natureVariant,
        ),
        InstitutionAmbience.fantasy => InstitutionFantasyScene(
          draft: draft,
          variant: draft.fantasyPreviewBySection
              ? draft.fantasyVariantForSection(section)
              : draft.fantasyVariant,
        ),
        InstitutionAmbience.my => InstitutionMyAmbienceScene(draft: draft),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
