import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'institution_brand_draft.dart';
import 'institution_ocean_scene.dart' show OceanDecorationGeometry;

class InstitutionNatureAssets {
  static const background = 'assets/ambience/nature/valley.png';
  static const oak = 'assets/ambience/nature/oak.png';
  static const summit = 'assets/ambience/nature/summit.png';
  static const waterfall = 'assets/ambience/nature/waterfall.png';
  static const songbirds = 'assets/ambience/nature/songbirds.png';
  static const wildflowers = 'assets/ambience/nature/wildflowers.png';
  static const leaves = 'assets/ambience/nature/leaves.png';

  static String hero(NatureVariant variant) => switch (variant) {
    NatureVariant.ancientGrove => oak,
    NatureVariant.alpineVista => summit,
    NatureVariant.waterfallHaven => waterfall,
  };
}

class InstitutionNatureBackground extends StatelessWidget {
  const InstitutionNatureBackground({
    super.key,
    required this.intensityPercent,
  });
  final int intensityPercent;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Opacity(
      opacity: (intensityPercent / 100).clamp(0, 1),
      child: Image.asset(
        InstitutionNatureAssets.background,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
      ),
    ),
  );
}

/// Relative shifts make a composition survive a normal/expanded preview.
/// Only complete disappearance is prevented; overlaps are warnings.
class NatureDecorationGeometry {
  static Size frame(PreviewDevice device) =>
      OceanDecorationGeometry.frame(device);

  static Rect recommended(NatureDecorationKey key) {
    final size = frame(key.device);
    final mobile = key.device == PreviewDevice.mobile;
    final hero = mobile
        ? switch (key.template) {
            InstitutionTemplate.orbit => const Rect.fromLTWH(
              160,
              135,
              165,
              135,
            ),
            InstitutionTemplate.academy => const Rect.fromLTWH(
              265,
              180,
              115,
              105,
            ),
            InstitutionTemplate.pulse => const Rect.fromLTWH(
              200,
              195,
              170,
              145,
            ),
            InstitutionTemplate.littleSteps => const Rect.fromLTWH(
              35,
              245,
              100,
              90,
            ),
            InstitutionTemplate.adventure => const Rect.fromLTWH(
              145,
              225,
              145,
              105,
            ),
            InstitutionTemplate.studio => const Rect.fromLTWH(
              245,
              245,
              135,
              120,
            ),
            InstitutionTemplate.heritage => const Rect.fromLTWH(
              105,
              380,
              175,
              165,
            ),
            InstitutionTemplate.prestige => const Rect.fromLTWH(
              205,
              285,
              165,
              135,
            ),
            InstitutionTemplate.nexus => const Rect.fromLTWH(
              220,
              160,
              160,
              125,
            ),
          }
        : OceanDecorationGeometry.characterRect(key.template, key.device);
    if (!mobile && key.template == InstitutionTemplate.littleSteps) {
      return switch (key.element) {
        NatureDecorationId.hero => hero,
        NatureDecorationId.songbirds => const Rect.fromLTWH(765, 245, 138, 102),
        NatureDecorationId.wildflowers => const Rect.fromLTWH(
          850,
          320,
          120,
          100,
        ),
        NatureDecorationId.leaves => const Rect.fromLTWH(920, 145, 125, 95),
      };
    }
    if (mobile) {
      return switch (key.element) {
        NatureDecorationId.hero => hero,
        NatureDecorationId.songbirds => switch (key.template) {
          InstitutionTemplate.academy => const Rect.fromLTWH(300, 540, 70, 55),
          InstitutionTemplate.littleSteps => const Rect.fromLTWH(
            20,
            185,
            70,
            55,
          ),
          InstitutionTemplate.studio => const Rect.fromLTWH(300, 375, 75, 60),
          InstitutionTemplate.heritage => const Rect.fromLTWH(35, 510, 80, 65),
          InstitutionTemplate.prestige => const Rect.fromLTWH(285, 490, 85, 65),
          InstitutionTemplate.nexus => const Rect.fromLTWH(25, 190, 75, 60),
          _ => const Rect.fromLTWH(10, 220, 78, 65),
        },
        NatureDecorationId.wildflowers => switch (key.template) {
          InstitutionTemplate.adventure => const Rect.fromLTWH(
            305,
            245,
            70,
            62,
          ),
          InstitutionTemplate.heritage => const Rect.fromLTWH(305, 360, 70, 62),
          _ => const Rect.fromLTWH(314, 310, 70, 62),
        },
        NatureDecorationId.leaves => switch (key.template) {
          InstitutionTemplate.orbit => const Rect.fromLTWH(10, 380, 60, 50),
          InstitutionTemplate.academy => const Rect.fromLTWH(305, 485, 65, 50),
          InstitutionTemplate.pulse => const Rect.fromLTWH(305, 210, 65, 50),
          InstitutionTemplate.adventure => const Rect.fromLTWH(
            305,
            230,
            65,
            50,
          ),
          InstitutionTemplate.studio => const Rect.fromLTWH(310, 340, 65, 50),
          InstitutionTemplate.heritage => const Rect.fromLTWH(305, 420, 65, 50),
          InstitutionTemplate.prestige => const Rect.fromLTWH(305, 380, 65, 50),
          InstitutionTemplate.nexus => const Rect.fromLTWH(305, 380, 65, 50),
          _ => const Rect.fromLTWH(310, 397, 65, 50),
        },
      };
    }
    return switch (key.element) {
      NatureDecorationId.hero => hero,
      NatureDecorationId.songbirds =>
        key.template == InstitutionTemplate.pulse
            ? const Rect.fromLTWH(880, 310, 125, 90)
            : Rect.fromLTWH(size.width - 188, size.height - 162, 158, 116),
      NatureDecorationId.wildflowers => Rect.fromLTWH(
        switch (key.template) {
          InstitutionTemplate.orbit => 310,
          InstitutionTemplate.academy => 340,
          InstitutionTemplate.pulse => 330,
          InstitutionTemplate.adventure => 365,
          InstitutionTemplate.studio => 140,
          InstitutionTemplate.heritage => 330,
          InstitutionTemplate.prestige => 520,
          InstitutionTemplate.nexus => 650,
          InstitutionTemplate.littleSteps => 850,
        },
        switch (key.template) {
          InstitutionTemplate.orbit => 220,
          InstitutionTemplate.academy => 300,
          InstitutionTemplate.pulse => 250,
          InstitutionTemplate.adventure => 300,
          InstitutionTemplate.studio => 280,
          InstitutionTemplate.heritage => 390,
          InstitutionTemplate.prestige => 280,
          InstitutionTemplate.nexus => 235,
          InstitutionTemplate.littleSteps => 320,
        },
        122,
        105,
      ),
      NatureDecorationId.leaves => Rect.fromLTWH(
        key.template == InstitutionTemplate.adventure ||
                key.template == InstitutionTemplate.studio
            ? 780
            : size.width - 195,
        key.template == InstitutionTemplate.adventure ||
                key.template == InstitutionTemplate.studio
            ? 105
            : 45,
        155,
        112,
      ),
    };
  }

  static double minScale(NatureDecorationKey key) => .3;
  static double maxScale(NatureDecorationKey key) => switch (key.element) {
    NatureDecorationId.hero => 2.6,
    NatureDecorationId.songbirds || NatureDecorationId.wildflowers => 4.0,
    NatureDecorationId.leaves => 5.0,
  };

  static (OceanDecorationAdjustment, bool) constrain(
    NatureDecorationKey key,
    OceanDecorationAdjustment requested,
  ) {
    final canvas = frame(key.device);
    final base = recommended(key);
    final scale = requested.scale.clamp(minScale(key), maxScale(key));
    final width = base.width * scale;
    final height = base.height * scale;
    final desired =
        base.center +
        Offset(
          requested.shift.dx * canvas.width,
          requested.shift.dy * canvas.height,
        );
    final center = Offset(
      desired.dx.clamp(1 - width / 2, canvas.width + width / 2 - 1),
      desired.dy.clamp(1 - height / 2, canvas.height + height / 2 - 1),
    );
    final adjusted = requested.copyWith(
      shift: Offset(
        (center.dx - base.center.dx) / canvas.width,
        (center.dy - base.center.dy) / canvas.height,
      ),
      scale: scale,
      opacity: requested.opacity.clamp(0, 1),
    );
    return (
      adjusted,
      (center - desired).distance > .01 ||
          (scale - requested.scale).abs() > .001 ||
          (adjusted.opacity - requested.opacity).abs() > .001,
    );
  }

  static Rect adjustedRect(
    NatureDecorationKey key,
    OceanDecorationAdjustment value,
  ) {
    final base = recommended(key);
    final canvas = frame(key.device);
    return Rect.fromCenter(
      center:
          base.center +
          Offset(value.shift.dx * canvas.width, value.shift.dy * canvas.height),
      width: base.width * value.scale,
      height: base.height * value.scale,
    );
  }

  /// Bounds measured from PNG alpha, rather than the transparent file canvas.
  static Rect visibleRect(
    NatureDecorationKey key,
    OceanDecorationAdjustment value,
  ) {
    final rect = adjustedRect(key, value);
    final (aspect, alpha) = switch (key.element) {
      NatureDecorationId.hero => switch (key.variant) {
        NatureVariant.ancientGrove => (
          1145 / 1374,
          const Rect.fromLTRB(.007, 0, .999, .996),
        ),
        NatureVariant.alpineVista => (
          1.5,
          const Rect.fromLTRB(.005, .008, .995, .984),
        ),
        NatureVariant.waterfallHaven => (
          1207 / 1303,
          const Rect.fromLTRB(0, 0, .995, .995),
        ),
      },
      NatureDecorationId.songbirds => (
        1.5,
        const Rect.fromLTRB(.010, .016, .990, .984),
      ),
      NatureDecorationId.wildflowers => (
        1374 / 1145,
        const Rect.fromLTRB(.029, .014, .996, .986),
      ),
      NatureDecorationId.leaves => (
        1.5,
        const Rect.fromLTRB(.042, .063, .953, .906),
      ),
    };
    final imageWidth = math.min(rect.width, rect.height * aspect);
    final imageHeight = imageWidth / aspect;
    final image = Rect.fromCenter(
      center: rect.center,
      width: imageWidth,
      height: imageHeight,
    );
    return Rect.fromLTRB(
      image.left + image.width * alpha.left,
      image.top + image.height * alpha.top,
      image.left + image.width * alpha.right,
      image.top + image.height * alpha.bottom,
    );
  }
}

class InstitutionNatureScene extends StatefulWidget {
  const InstitutionNatureScene({
    super.key,
    required this.draft,
    required this.variant,
  });
  final InstitutionBrandDraft draft;
  final NatureVariant variant;

  @override
  State<InstitutionNatureScene> createState() => _InstitutionNatureSceneState();
}

class _InstitutionNatureSceneState extends State<InstitutionNatureScene> {
  Timer? _timer;
  Timer? _kickoff;
  bool _phase = false;
  int _lastMotion = -1;
  bool _lastReduced = false;
  List<Rect> _protectedZones = const [];
  Offset? _dragStart;
  OceanDecorationAdjustment? _dragAdjustment;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    for (final path in [
      InstitutionNatureAssets.oak,
      InstitutionNatureAssets.summit,
      InstitutionNatureAssets.waterfall,
      InstitutionNatureAssets.songbirds,
      InstitutionNatureAssets.wildflowers,
      InstitutionNatureAssets.leaves,
    ]) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void didUpdateWidget(covariant InstitutionNatureScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final amount = widget.draft.elementMotion;
    if (amount == _lastMotion && reduced == _lastReduced) return;
    _lastMotion = amount;
    _lastReduced = reduced;
    _timer?.cancel();
    _kickoff?.cancel();
    _timer = null;
    _kickoff = null;
    if (reduced || amount == 0) {
      _phase = false;
      return;
    }
    final period = Duration(milliseconds: 12000 - amount * 45);
    _phase = false;
    _kickoff = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _phase = true);
    });
    _timer = Timer.periodic(period, (_) {
      if (mounted) setState(() => _phase = !_phase);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _kickoff?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanProtectedZones());
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 230),
      child: Stack(
        key: ValueKey('nature-scene-${widget.variant.name}'),
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          if (widget.draft.editNatureDecorations)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('nature-protected-zones'),
                  painter: _NatureProtectedZonePainter(_protectedZones),
                ),
              ),
            ),
          for (final element in NatureDecorationId.values)
            _element(element, reduced),
        ],
      ),
    );
  }

  void _scanProtectedZones() {
    if (!mounted) return;
    final root = context.findAncestorRenderObjectOfType<RenderStack>();
    if (root == null || !root.hasSize) return;
    final decorationRender = context.findRenderObject();
    final bounds = Offset.zero & root.size;
    final zones = <Rect>[];
    void visit(RenderObject object) {
      if (identical(object, decorationRender)) return;
      if (object is RenderParagraph && object.hasSize) {
        final text = object.text.toPlainText();
        if (text.isNotEmpty) {
          for (final glyphs in object.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          )) {
            final box = glyphs.toRect();
            final region = Rect.fromPoints(
              object.localToGlobal(box.topLeft, ancestor: root),
              object.localToGlobal(box.bottomRight, ancestor: root),
            ).inflate(9).intersect(bounds);
            if (region.width > 2 && region.height > 2) zones.add(region);
          }
        }
      }
      object.visitChildren(visit);
    }

    root.visitChildren(visit);
    if (!_sameZones(_protectedZones, zones)) {
      setState(() => _protectedZones = zones);
    }
    final draft = widget.draft;
    final overlaps = <NatureDecorationId>{};
    for (final element in NatureDecorationId.values) {
      final key = (
        variant: widget.variant,
        template: draft.template,
        device: draft.device,
        element: element,
      );
      final adjustment = NatureDecorationGeometry.constrain(
        key,
        draft.natureAdjustment(key),
      ).$1;
      if (adjustment.hidden ||
          adjustment.opacity == 0 ||
          draft.decorationIntensity == 0)
        continue;
      final visible = NatureDecorationGeometry.visibleRect(key, adjustment);
      if (zones.any((zone) {
        final intersection = visible.intersect(zone);
        return intersection.width > 2 && intersection.height > 2;
      })) {
        overlaps.add(element);
      }
    }
    draft.setNatureOverlaps(overlaps);
  }

  bool _sameZones(List<Rect> a, List<Rect> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Offset _canvasPoint(Offset global) {
    final render = context.findRenderObject();
    return render is RenderBox ? render.globalToLocal(global) : global;
  }

  Widget _element(NatureDecorationId element, bool reduced) {
    final draft = widget.draft;
    final key = (
      variant: widget.variant,
      template: draft.template,
      device: draft.device,
      element: element,
    );
    final adjustment = NatureDecorationGeometry.constrain(
      key,
      draft.natureAdjustment(key),
    ).$1;
    if (adjustment.hidden) return const SizedBox.shrink();
    final rect = NatureDecorationGeometry.adjustedRect(key, adjustment);
    final selected =
        draft.editNatureDecorations &&
        draft.selectedNatureDecoration == element;
    final overlapping =
        draft.editNatureDecorations && draft.natureOverlaps.contains(element);
    final path = switch (element) {
      NatureDecorationId.hero => InstitutionNatureAssets.hero(widget.variant),
      NatureDecorationId.songbirds => InstitutionNatureAssets.songbirds,
      NatureDecorationId.wildflowers => InstitutionNatureAssets.wildflowers,
      NatureDecorationId.leaves => InstitutionNatureAssets.leaves,
    };
    final amount = reduced ? 0.0 : draft.elementMotion / 100;
    final travel = switch (element) {
      NatureDecorationId.hero => 0.0,
      NatureDecorationId.songbirds => 8.0,
      NatureDecorationId.wildflowers => 0.0,
      NatureDecorationId.leaves => 5.0,
    };
    final tilt = switch (element) {
      NatureDecorationId.hero => 0.0,
      NatureDecorationId.songbirds => .012,
      NatureDecorationId.wildflowers => .020,
      NatureDecorationId.leaves => .025,
    };
    final opacity = (draft.decorationIntensity / 100 * adjustment.opacity)
        .clamp(0.0, 1.0);
    final period = Duration(milliseconds: 12000 - draft.elementMotion * 45);
    return Positioned.fromRect(
      key: ValueKey('nature-element-${element.name}'),
      rect: rect,
      child: IgnorePointer(
        ignoring: !draft.editNatureDecorations,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              draft.update(() => draft.selectedNatureDecoration = element),
          onPanDown: (details) {
            _dragStart = _canvasPoint(details.globalPosition);
            _dragAdjustment = draft.natureAdjustment(key);
          },
          onPanStart: (_) =>
              draft.update(() => draft.selectedNatureDecoration = element),
          onPanUpdate: (details) {
            if (_dragStart == null || _dragAdjustment == null) return;
            final frame = NatureDecorationGeometry.frame(draft.device);
            final delta = _canvasPoint(details.globalPosition) - _dragStart!;
            final requested = _dragAdjustment!.copyWith(
              shift:
                  _dragAdjustment!.shift +
                  Offset(delta.dx / frame.width, delta.dy / frame.height),
            );
            draft.changeNatureAdjustment(
              key,
              NatureDecorationGeometry.constrain(key, requested).$1,
            );
          },
          onPanEnd: (_) {
            _dragStart = null;
            _dragAdjustment = null;
          },
          onPanCancel: () {
            _dragStart = null;
            _dragAdjustment = null;
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey('nature-motion-${element.name}'),
                tween: Tween(end: amount == 0 ? 0 : (_phase ? 1 : 0)),
                duration: amount == 0 ? Duration.zero : period * .88,
                curve: Curves.easeInOutSine,
                builder: (context, phase, child) => Transform.translate(
                  offset: Offset(
                    (element == NatureDecorationId.songbirds ||
                            element == NatureDecorationId.leaves)
                        ? phase * travel * amount
                        : 0,
                    -phase * travel * amount,
                  ),
                  child: Transform.rotate(
                    angle: phase * tilt * amount,
                    alignment: element == NatureDecorationId.wildflowers
                        ? Alignment.bottomCenter
                        : Alignment.center,
                    child: child,
                  ),
                ),
                child: Opacity(
                  opacity: opacity,
                  child: Image.asset(
                    path,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              if (selected || overlapping)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: overlapping
                          ? const Color(0xFFFF6673)
                          : Colors.amberAccent,
                      width: selected ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Icon(
                      overlapping
                          ? Icons.warning_amber_rounded
                          : Icons.open_with_rounded,
                      size: 16,
                      color: overlapping
                          ? const Color(0xFFFF6673)
                          : Colors.amberAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NatureProtectedZonePainter extends CustomPainter {
  const _NatureProtectedZonePainter(this.zones);
  final List<Rect> zones;
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0x1FFF6673);
    final line = Paint()
      ..color = const Color(0x88FF6673)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final zone in zones) {
      final shape = RRect.fromRectAndRadius(zone, const Radius.circular(5));
      canvas.drawRRect(shape, fill);
      canvas.drawRRect(shape, line);
    }
  }

  @override
  bool shouldRepaint(_NatureProtectedZonePainter oldDelegate) {
    if (zones.length != oldDelegate.zones.length) return true;
    for (var i = 0; i < zones.length; i++) {
      if (zones[i] != oldDelegate.zones[i]) return true;
    }
    return false;
  }
}
