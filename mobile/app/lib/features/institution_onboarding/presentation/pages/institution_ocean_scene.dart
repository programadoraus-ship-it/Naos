import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'institution_brand_draft.dart';
import 'institution_ocean_ambience.dart';

/// All coordinates belong to the fixed preview canvas, not the app window.
/// The parent FittedBox scales this canvas for normal and expanded previews.
class OceanDecorationGeometry {
  static Size frame(PreviewDevice device) => device == PreviewDevice.mobile
      ? const Size(390, 680)
      : const Size(1080, 600);

  static Rect characterRect(
    InstitutionTemplate template,
    PreviewDevice device,
  ) {
    if (device == PreviewDevice.mobile) {
      return switch (template) {
        InstitutionTemplate.orbit => const Rect.fromLTWH(235, 160, 105, 105),
        InstitutionTemplate.academy => const Rect.fromLTWH(285, 165, 80, 80),
        InstitutionTemplate.pulse => const Rect.fromLTWH(215, 205, 145, 145),
        InstitutionTemplate.littleSteps => const Rect.fromLTWH(38, 250, 84, 84),
        InstitutionTemplate.adventure => const Rect.fromLTWH(160, 215, 90, 90),
        InstitutionTemplate.studio => const Rect.fromLTWH(255, 231, 108, 108),
        InstitutionTemplate.heritage => const Rect.fromLTWH(115, 390, 165, 165),
        InstitutionTemplate.prestige => const Rect.fromLTWH(205, 321, 155, 130),
        InstitutionTemplate.nexus => const Rect.fromLTWH(217, 227, 145, 95),
      };
    }
    return switch (template) {
      InstitutionTemplate.orbit => const Rect.fromLTWH(435, 165, 235, 235),
      InstitutionTemplate.academy => const Rect.fromLTWH(450, 245, 240, 240),
      InstitutionTemplate.pulse => const Rect.fromLTWH(505, 170, 255, 255),
      InstitutionTemplate.littleSteps => const Rect.fromLTWH(
        245,
        200,
        105,
        105,
      ),
      InstitutionTemplate.adventure => const Rect.fromLTWH(115, 295, 120, 120),
      InstitutionTemplate.studio => const Rect.fromLTWH(450, 250, 205, 205),
      InstitutionTemplate.heritage => const Rect.fromLTWH(525, 270, 200, 200),
      InstitutionTemplate.prestige => const Rect.fromLTWH(790, 275, 220, 220),
      InstitutionTemplate.nexus => const Rect.fromLTWH(760, 210, 195, 165),
    };
  }

  static Rect recommended(OceanDecorationKey key) {
    final character = characterRect(key.template, key.device);
    final mobile = key.device == PreviewDevice.mobile;
    final frameSize = frame(key.device);
    return switch (key.element) {
      OceanDecorationId.character => character,
      OceanDecorationId.fishSchool => Rect.fromLTWH(
        character.left + character.width * .06,
        character.top + character.height * .10,
        character.width * .38,
        character.height * .32,
      ),
      OceanDecorationId.coral => _recommendedCoral(key, frameSize),
      OceanDecorationId.plants => Rect.fromLTWH(
        key.variant == OceanVariant.sharkReef
            ? (mobile ? 0 : 8)
            : frameSize.width - (mobile ? 47 : 105),
        mobile
            ? frameSize.height - 200 + (105 - _mobilePlantHeight(key)) / 2
            : frameSize.height - 152,
        mobile && key.variant == OceanVariant.sharkReef
            ? 32
            : (mobile ? 45 : 98),
        mobile ? _mobilePlantHeight(key) : 145,
      ),
    };
  }

  static double _mobilePlantHeight(OceanDecorationKey key) =>
      key.variant == OceanVariant.sharkReef ? 48 : 68;

  static Rect _recommendedCoral(OceanDecorationKey key, Size frameSize) {
    final mobile = key.device == PreviewDevice.mobile;
    final shark = key.variant == OceanVariant.sharkReef;
    if (!mobile) {
      // These compositions have copy in the lower-left corner. Keep the reef
      // in a genuinely free area instead of merely shrinking it over text.
      if (key.template == InstitutionTemplate.studio) {
        return const Rect.fromLTWH(585, 465, 96, 110);
      }
      if (key.template == InstitutionTemplate.prestige) {
        return const Rect.fromLTWH(720, 465, 96, 110);
      }
      if (key.template == InstitutionTemplate.littleSteps) {
        return const Rect.fromLTWH(930, 255, 96, 110);
      }
    }
    final width = mobile ? 34.0 : 116.0;
    final height = mobile ? 51.0 : 150.0;
    return Rect.fromLTWH(
      shark ? frameSize.width - width : 0,
      mobile
          ? frameSize.height - 230 + (105 - height) / 2
          : frameSize.height - 190,
      width,
      height,
    );
  }

  static double minScale(OceanDecorationKey key) => .3;

  static double maxScale(OceanDecorationKey key) => switch (key.element) {
    OceanDecorationId.character => 2.5,
    OceanDecorationId.fishSchool => 3.5,
    OceanDecorationId.coral ||
    OceanDecorationId.plants => key.device == PreviewDevice.mobile ? 6.0 : 3.5,
  };

  /// The only placement constraint is that at least one logical pixel of the
  /// element's box remains on the canvas. Overlap is warned about, not blocked.
  static (OceanDecorationAdjustment, bool) constrain(
    OceanDecorationKey key,
    OceanDecorationAdjustment requested,
  ) {
    final frameSize = frame(key.device);
    final base = recommended(key);
    final scale = requested.scale.clamp(minScale(key), maxScale(key));
    final width = base.width * scale;
    final height = base.height * scale;
    final requestedCenter = Offset(
      base.center.dx + requested.shift.dx * frameSize.width,
      base.center.dy + requested.shift.dy * frameSize.height,
    );
    final center = Offset(
      requestedCenter.dx.clamp(1 - width / 2, frameSize.width + width / 2 - 1),
      requestedCenter.dy.clamp(
        1 - height / 2,
        frameSize.height + height / 2 - 1,
      ),
    );
    final result = requested.copyWith(
      shift: Offset(
        (center.dx - base.center.dx) / frameSize.width,
        (center.dy - base.center.dy) / frameSize.height,
      ),
      scale: scale,
      opacity: requested.opacity.clamp(0, 1),
    );
    final clamped =
        (center - requestedCenter).distance > .01 ||
        (result.scale - requested.scale).abs() > .001 ||
        (result.opacity - requested.opacity).abs() > .001;
    return (result, clamped);
  }

  static Rect adjustedRect(
    OceanDecorationKey key,
    OceanDecorationAdjustment value,
  ) {
    final base = recommended(key);
    final frameSize = frame(key.device);
    final center =
        base.center +
        Offset(
          value.shift.dx * frameSize.width,
          value.shift.dy * frameSize.height,
        );
    return Rect.fromCenter(
      center: center,
      width: base.width * value.scale,
      height: base.height * value.scale,
    );
  }

  /// Alpha bounds measured from the three transparent PNGs. This is used for
  /// the visible-size readout and overlap checks, so empty padding does not
  /// make a decoration appear larger or more obstructive than it really is.
  static Rect visibleRect(
    OceanDecorationKey key,
    OceanDecorationAdjustment value,
  ) {
    final rect = adjustedRect(key, value);
    final (aspect, alpha) = switch (key.element) {
      OceanDecorationId.fishSchool => (
        1.5,
        const Rect.fromLTRB(.108, .133, .838, .819),
      ),
      OceanDecorationId.coral => (
        2 / 3,
        const Rect.fromLTRB(.121, .112, .893, .910),
      ),
      OceanDecorationId.plants => (
        2 / 3,
        const Rect.fromLTRB(.162, .060, .906, .921),
      ),
      OceanDecorationId.character => (
        rect.width / rect.height,
        const Rect.fromLTWH(0, 0, 1, 1),
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

class InstitutionOceanScene extends StatefulWidget {
  const InstitutionOceanScene({
    super.key,
    required this.draft,
    required this.variant,
  });

  final InstitutionBrandDraft draft;
  final OceanVariant variant;

  @override
  State<InstitutionOceanScene> createState() => _InstitutionOceanSceneState();
}

class _InstitutionOceanSceneState extends State<InstitutionOceanScene> {
  Timer? _motionTimer;
  Timer? _motionKickoff;
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
      InstitutionOceanAmbience.turtle,
      InstitutionOceanAmbience.shark,
      InstitutionOceanAmbience.jellyfish,
      InstitutionOceanAmbience.coralCluster,
      InstitutionOceanAmbience.fishSchool,
      InstitutionOceanAmbience.kelp,
    ]) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void didUpdateWidget(covariant InstitutionOceanScene oldWidget) {
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
    _motionTimer?.cancel();
    _motionKickoff?.cancel();
    _motionTimer = null;
    _motionKickoff = null;
    if (reduced || amount == 0) {
      _phase = false;
      return;
    }
    final period = Duration(milliseconds: 11000 - amount * 45);
    _phase = false;
    _motionKickoff = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _phase = true);
    });
    _motionTimer = Timer.periodic(period, (_) {
      if (mounted) setState(() => _phase = !_phase);
    });
  }

  @override
  void dispose() {
    _motionTimer?.cancel();
    _motionKickoff?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanProtectedZones());
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final variant = widget.variant;
    return AnimatedSwitcher(
      key: const ValueKey('ocean-scene-switcher'),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 230),
      child: Stack(
        key: ValueKey('ocean-scene-${variant.name}'),
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          if (widget.draft.editOceanDecorations)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('ocean-protected-zones'),
                  painter: _OceanProtectedZonePainter(_protectedZones),
                ),
              ),
            ),
          for (final element in OceanDecorationId.values)
            _element(variant, element, reduced),
        ],
      ),
    );
  }

  void _scanProtectedZones() {
    if (!mounted) return;
    final root = context.findAncestorRenderObjectOfType<RenderStack>();
    if (root == null || !root.hasSize) return;
    final decorationRender = context.findRenderObject();
    final frameBounds = Offset.zero & root.size;
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
            final topLeft = object.localToGlobal(box.topLeft, ancestor: root);
            final bottomRight = object.localToGlobal(
              box.bottomRight,
              ancestor: root,
            );
            final region = Rect.fromPoints(
              topLeft,
              bottomRight,
            ).inflate(9).intersect(frameBounds);
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
    final collisions = <OceanDecorationId>{};
    for (final element in OceanDecorationId.values) {
      final key = (
        variant: widget.variant,
        template: draft.template,
        device: draft.device,
        element: element,
      );
      final adjustment = OceanDecorationGeometry.constrain(
        key,
        draft.oceanAdjustment(key),
      ).$1;
      if (adjustment.hidden ||
          adjustment.opacity == 0 ||
          draft.decorationIntensity == 0)
        continue;
      final visible = OceanDecorationGeometry.visibleRect(key, adjustment);
      if (zones.any((zone) {
        final overlap = visible.intersect(zone);
        return overlap.width > 2 && overlap.height > 2;
      })) {
        collisions.add(element);
      }
    }
    draft.setOceanOverlaps(collisions);
  }

  bool _sameZones(List<Rect> left, List<Rect> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  Offset _canvasPoint(Offset global) {
    final render = context.findRenderObject();
    return render is RenderBox ? render.globalToLocal(global) : global;
  }

  Widget _element(
    OceanVariant variant,
    OceanDecorationId element,
    bool reduced,
  ) {
    final draft = widget.draft;
    final key = (
      variant: variant,
      template: draft.template,
      device: draft.device,
      element: element,
    );
    final adjustment = OceanDecorationGeometry.constrain(
      key,
      draft.oceanAdjustment(key),
    ).$1;
    if (adjustment.hidden) return const SizedBox.shrink();
    final rect = OceanDecorationGeometry.adjustedRect(key, adjustment);
    final selected =
        draft.editOceanDecorations && draft.selectedOceanDecoration == element;
    final overlapping =
        draft.editOceanDecorations && draft.oceanOverlaps.contains(element);
    final path = switch (element) {
      OceanDecorationId.character => InstitutionOceanAmbience.characterAsset(
        variant,
      ),
      OceanDecorationId.fishSchool => InstitutionOceanAmbience.fishSchool,
      OceanDecorationId.coral => InstitutionOceanAmbience.coralCluster,
      OceanDecorationId.plants => InstitutionOceanAmbience.kelp,
    };
    final amount = reduced ? 0.0 : draft.elementMotion / 100;
    final travel = switch (element) {
      OceanDecorationId.character =>
        variant == OceanVariant.jellyfishGarden ? 6.0 : 4.0,
      OceanDecorationId.fishSchool => 5.0,
      OceanDecorationId.coral => 0.0,
      OceanDecorationId.plants => 0.0,
    };
    final tilt = switch (element) {
      OceanDecorationId.character =>
        variant == OceanVariant.jellyfishGarden ? .010 : .012,
      OceanDecorationId.fishSchool => .008,
      OceanDecorationId.coral => .018,
      OceanDecorationId.plants => .028,
    };
    final opacity = (draft.decorationIntensity / 100 * adjustment.opacity)
        .clamp(0.0, 1.0);
    final period = Duration(milliseconds: 11000 - draft.elementMotion * 45);
    return Positioned.fromRect(
      key: ValueKey('ocean-element-${element.name}'),
      rect: rect,
      child: IgnorePointer(
        ignoring: !draft.editOceanDecorations,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              draft.update(() => draft.selectedOceanDecoration = element),
          onPanDown: (details) {
            _dragStart = _canvasPoint(details.globalPosition);
            _dragAdjustment = draft.oceanAdjustment(key);
          },
          onPanStart: (_) {
            draft.update(() => draft.selectedOceanDecoration = element);
          },
          onPanUpdate: (details) {
            final start = _dragStart;
            final initial = _dragAdjustment;
            if (start == null || initial == null) return;
            final frame = OceanDecorationGeometry.frame(draft.device);
            final delta = _canvasPoint(details.globalPosition) - start;
            final requested = initial.copyWith(
              shift:
                  initial.shift +
                  Offset(delta.dx / frame.width, delta.dy / frame.height),
            );
            final result = OceanDecorationGeometry.constrain(key, requested);
            draft.changeOceanAdjustment(key, result.$1, clamped: result.$2);
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
                key: ValueKey('ocean-motion-${element.name}'),
                tween: Tween(end: amount == 0 ? 0 : (_phase ? 1 : 0)),
                duration: amount == 0 ? Duration.zero : period * .88,
                curve: Curves.easeInOutSine,
                builder: (context, phase, child) {
                  final offset = Offset(
                    element == OceanDecorationId.fishSchool
                        ? phase * travel * amount
                        : 0,
                    -phase * travel * amount,
                  );
                  return Transform.translate(
                    offset: offset,
                    child: Transform.rotate(
                      angle: phase * tilt * amount,
                      alignment:
                          element == OceanDecorationId.coral ||
                              element == OceanDecorationId.plants
                          ? Alignment.bottomCenter
                          : Alignment.center,
                      child: child,
                    ),
                  );
                },
                child: Opacity(
                  opacity: opacity,
                  child: Image.asset(
                    path,
                    key: element == OceanDecorationId.character
                        ? const ValueKey('ocean-character-art')
                        : ValueKey('ocean-${element.name}-art'),
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
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

class _OceanProtectedZonePainter extends CustomPainter {
  const _OceanProtectedZonePainter(this.zones);

  final List<Rect> zones;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0x1FFF6673);
    final outline = Paint()
      ..color = const Color(0x88FF6673)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final zone in zones) {
      final rounded = RRect.fromRectAndRadius(zone, const Radius.circular(5));
      canvas.drawRRect(rounded, fill);
      canvas.drawRRect(rounded, outline);
    }
  }

  @override
  bool shouldRepaint(_OceanProtectedZonePainter oldDelegate) =>
      !_sameRects(zones, oldDelegate.zones);

  bool _sameRects(List<Rect> left, List<Rect> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}
