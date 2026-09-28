import 'dart:async';

import 'package:flutter/material.dart';

import 'institution_brand_draft.dart';

/// The seascape is painted below the selected template, not over its controls.
class InstitutionOceanBackground extends StatefulWidget {
  const InstitutionOceanBackground({super.key, required this.intensityPercent});

  final int intensityPercent;

  @override
  State<InstitutionOceanBackground> createState() =>
      _InstitutionOceanBackgroundState();
}

/// Reef accents sit below opaque UI surfaces so navigation remains unobscured.
class InstitutionOceanReef extends StatelessWidget {
  const InstitutionOceanReef({
    super.key,
    required this.variant,
    required this.intensityPercent,
  });

  final OceanVariant variant;
  final int intensityPercent;

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final mobile = box.maxWidth < 550;
        final path = switch (variant) {
          OceanVariant.turtleReef => InstitutionOceanAmbience.coral,
          OceanVariant.sharkReef => InstitutionOceanAmbience.sharkCoral,
          OceanVariant.jellyfishGarden => InstitutionOceanAmbience.coral,
        };
        return AnimatedSwitcher(
          key: const ValueKey('ocean-reef-switcher'),
          duration: reduced ? Duration.zero : const Duration(milliseconds: 230),
          child: Stack(
            key: ValueKey('ocean-reef-${variant.name}'),
            fit: StackFit.expand,
            children: [
              Positioned(
                left: variant == OceanVariant.sharkReef
                    ? null
                    : -box.maxWidth * .02,
                right: variant == OceanVariant.sharkReef
                    ? -box.maxWidth * .02
                    : null,
                bottom: mobile ? box.maxHeight * .12 : -box.maxHeight * .06,
                width: mobile ? box.maxWidth * .34 : box.maxWidth * .26,
                child: Opacity(
                  opacity: (intensityPercent / 100).clamp(0.0, .90),
                  child: Image.asset(
                    path,
                    key: const ValueKey('ocean-reef-art'),
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              if (variant == OceanVariant.jellyfishGarden)
                Positioned(
                  right: -box.maxWidth * .025,
                  bottom: mobile ? box.maxHeight * .22 : box.maxHeight * .05,
                  width: mobile ? box.maxWidth * .22 : box.maxWidth * .16,
                  child: Opacity(
                    opacity: (intensityPercent / 135).clamp(0.0, .67),
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        InstitutionOceanAmbience.coral,
                        key: const ValueKey('ocean-garden-plants'),
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _InstitutionOceanBackgroundState
    extends State<InstitutionOceanBackground> {
  static int _activeBackgrounds = 0;

  @override
  void initState() {
    super.initState();
    _activeBackgrounds++;
  }

  @override
  void dispose() {
    _activeBackgrounds--;
    if (_activeBackgrounds == 0) {
      for (final width in [760, 1400]) {
        ResizeImage(
          const AssetImage(InstitutionOceanAmbience.seascape),
          width: width,
        ).evict();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final mobile = box.maxWidth < 550;
      return Opacity(
        key: const ValueKey('ocean-shared-background'),
        opacity: (widget.intensityPercent.clamp(0, 100) / 100).toDouble(),
        child: Image.asset(
          InstitutionOceanAmbience.seascape,
          fit: BoxFit.cover,
          cacheWidth: mobile ? 760 : 1400,
          filterQuality: FilterQuality.medium,
        ),
      );
    },
  );
}

/// Prerendered characters and reef detail, above only unoccupied UI space.
class InstitutionOceanAmbience extends StatefulWidget {
  const InstitutionOceanAmbience({
    super.key,
    required this.intensityPercent,
    required this.variant,
    this.foregroundPlacement = false,
  });

  final int intensityPercent;
  final OceanVariant variant;
  final bool foregroundPlacement;

  static const seascape = 'assets/ambience/ocean/seascape.png';
  static const turtle = 'assets/ambience/ocean/turtle.png';
  static const coral = 'assets/ambience/ocean/coral.png';
  static const shark = 'assets/ambience/ocean/shark.png';
  static const sharkCoral = 'assets/ambience/ocean/shark-coral.png';
  static const jellyfish = 'assets/ambience/ocean/jellyfish.png';
  static const fishSchool = 'assets/ambience/ocean/fish-school.png';
  static const kelp = 'assets/ambience/ocean/kelp.png';
  static const coralCluster = 'assets/ambience/ocean/coral-cluster.png';
  static const thumbnail = 'assets/ambience/ocean/thumbnail.png';

  static String characterAsset(OceanVariant variant) => switch (variant) {
    OceanVariant.turtleReef => turtle,
    OceanVariant.sharkReef => shark,
    OceanVariant.jellyfishGarden => jellyfish,
  };

  @override
  State<InstitutionOceanAmbience> createState() =>
      _InstitutionOceanAmbienceState();
}

class _InstitutionOceanAmbienceState extends State<InstitutionOceanAmbience>
    with SingleTickerProviderStateMixin {
  static int _activePreviews = 0;

  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  bool _started = false;
  bool _preloaded = false;
  bool _reducedMotion = false;
  bool _floatingHigh = false;
  Timer? _floatTimer;

  @override
  void initState() {
    super.initState();
    _activePreviews++;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _reducedMotion = reduced;
    if (reduced) {
      _arrival.value = 1;
      _floatTimer?.cancel();
      _floatTimer = null;
      _floatingHigh = false;
    } else if (!_started) {
      _started = true;
      _arrival.forward();
    }
    if (!reduced) {
      _floatTimer ??= Timer.periodic(const Duration(seconds: 6), (_) {
        if (mounted && widget.variant == OceanVariant.turtleReef) {
          setState(() => _floatingHigh = !_floatingHigh);
        }
      });
    }
    if (!_preloaded) {
      _preloaded = true;
      for (final path in [
        InstitutionOceanAmbience.turtle,
        InstitutionOceanAmbience.coral,
        InstitutionOceanAmbience.shark,
        InstitutionOceanAmbience.sharkCoral,
        InstitutionOceanAmbience.jellyfish,
      ]) {
        precacheImage(AssetImage(path), context);
      }
    }
  }

  @override
  void dispose() {
    _floatTimer?.cancel();
    _arrival.dispose();
    _activePreviews--;
    if (_activePreviews == 0) {
      for (final path in [
        InstitutionOceanAmbience.turtle,
        InstitutionOceanAmbience.coral,
        InstitutionOceanAmbience.shark,
        InstitutionOceanAmbience.sharkCoral,
        InstitutionOceanAmbience.jellyfish,
      ]) {
        AssetImage(path).evict();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final intensity = widget.intensityPercent.clamp(0, 100) / 65;
    final characterOpacity = (.80 * intensity).clamp(0.0, .96);
    final variant = widget.variant;
    return LayoutBuilder(
      builder: (context, box) {
        // These are the preview frame's dimensions, independent of window size.
        final mobile = box.maxWidth < 550;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                key: const ValueKey('ocean-scene-switcher'),
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 230),
                child: AnimatedBuilder(
                  key: ValueKey('ocean-scene-${variant.name}'),
                  animation: _arrival,
                  builder: (context, _) => _scene(
                    box.maxWidth,
                    box.maxHeight,
                    mobile,
                    variant,
                    Curves.easeOutCubic.transform(_arrival.value),
                    characterOpacity,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scene(
    double width,
    double height,
    bool mobile,
    OceanVariant variant,
    double progress,
    double characterOpacity,
  ) {
    final size = width < height ? width : height;
    return Center(
      child: Transform.translate(
        offset: Offset(8 * (1 - progress), -5 * (1 - progress)),
        child: Opacity(
          opacity: characterOpacity,
          child: variant == OceanVariant.turtleReef
              ? TweenAnimationBuilder<double>(
                  key: const ValueKey('turtle-whole-float'),
                  tween: Tween(
                    end: _reducedMotion ? 0 : (_floatingHigh ? 1 : 0),
                  ),
                  duration: _reducedMotion
                      ? Duration.zero
                      : const Duration(seconds: 5),
                  curve: Curves.easeInOutSine,
                  builder: (context, float, child) => Transform.translate(
                    offset: Offset(0, -4 * float),
                    child: Transform.rotate(
                      angle: .012 * float,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.white.withValues(alpha: .025 * float),
                          BlendMode.screen,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                  child: Image.asset(
                    InstitutionOceanAmbience.turtle,
                    key: const ValueKey('ocean-character-art'),
                    width: size * .94,
                    height: size * .94,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                )
              : Image.asset(
                  InstitutionOceanAmbience.characterAsset(variant),
                  key: const ValueKey('ocean-character-art'),
                  width: size * .94,
                  height: size * .94,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
        ),
      ),
    );
  }
}
