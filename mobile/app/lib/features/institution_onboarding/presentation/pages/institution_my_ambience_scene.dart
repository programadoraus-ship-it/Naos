import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'institution_brand_draft.dart';

class MyDecorationGeometry {
  static Size frame(PreviewDevice device) => device == PreviewDevice.mobile
      ? const Size(390, 680)
      : const Size(1080, 600);

  static Rect recommended(MyDecorationKey key, MyAmbienceFile file) {
    final mobile = key.device == PreviewDevice.mobile;
    final slot = key.id % 5;
    final centers = mobile
        ? const [
            Offset(.82, .29),
            Offset(.14, .47),
            Offset(.85, .67),
            Offset(.14, .82),
            Offset(.50, .91),
          ]
        : const [
            Offset(.83, .25),
            Offset(.10, .50),
            Offset(.87, .67),
            Offset(.25, .84),
            Offset(.58, .88),
          ];
    final frameSize = frame(key.device);
    final maxWidth = mobile ? 84.0 : 150.0;
    final maxHeight = mobile ? 90.0 : 150.0;
    final ratio = file.width / file.height;
    final width = math.min(maxWidth, maxHeight * ratio);
    final height = width / ratio;
    return Rect.fromCenter(
      center: Offset(
        centers[slot].dx * frameSize.width,
        centers[slot].dy * frameSize.height,
      ),
      width: width,
      height: height,
    );
  }

  static Rect adjusted(
    MyDecorationKey key,
    MyAmbienceFile file,
    OceanDecorationAdjustment value,
  ) {
    final base = recommended(key, file);
    final size = frame(key.device);
    return Rect.fromCenter(
      center:
          base.center +
          Offset(value.shift.dx * size.width, value.shift.dy * size.height),
      width: base.width * value.scale,
      height: base.height * value.scale,
    );
  }

  static OceanDecorationAdjustment constrain(
    MyDecorationKey key,
    MyAmbienceFile file,
    OceanDecorationAdjustment value,
  ) {
    final base = recommended(key, file);
    final size = frame(key.device);
    final scale = value.scale.clamp(.25, 4.0);
    final width = base.width * scale;
    final height = base.height * scale;
    final wanted =
        base.center +
        Offset(value.shift.dx * size.width, value.shift.dy * size.height);
    final center = Offset(
      wanted.dx.clamp(1 - width / 2, size.width + width / 2 - 1),
      wanted.dy.clamp(1 - height / 2, size.height + height / 2 - 1),
    );
    return value.copyWith(
      shift: Offset(
        (center.dx - base.center.dx) / size.width,
        (center.dy - base.center.dy) / size.height,
      ),
      scale: scale,
      opacity: value.opacity.clamp(0, 1),
    );
  }
}

class InstitutionMyAmbienceScene extends StatefulWidget {
  const InstitutionMyAmbienceScene({super.key, required this.draft});
  final InstitutionBrandDraft draft;
  @override
  State<InstitutionMyAmbienceScene> createState() =>
      _InstitutionMyAmbienceSceneState();
}

class _InstitutionMyAmbienceSceneState
    extends State<InstitutionMyAmbienceScene> {
  Timer? _timer;
  bool _phase = false;
  List<Rect> _protectedZones = [];
  Offset? _dragStart;
  OceanDecorationAdjustment? _dragAdjustment;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted ||
          widget.draft.elementMotion == 0 ||
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context)) {
        return;
      }
      setState(() => _phase = !_phase);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    if (draft.editMyDecorations) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scanZones());
    }
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (draft.editMyDecorations)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _MyProtectedZonesPainter(_protectedZones),
              ),
            ),
          ),
        for (final entry in draft.myElements.entries)
          _element(entry.key, entry.value, reduced),
      ],
    );
  }

  void _scanZones() {
    if (!mounted) return;
    final root = context.findAncestorRenderObjectOfType<RenderStack>();
    if (root == null || !root.hasSize) return;
    final self = context.findRenderObject();
    final bounds = Offset.zero & root.size;
    final zones = <Rect>[];
    void visit(RenderObject object) {
      if (identical(object, self)) return;
      if (object is RenderParagraph && object.hasSize) {
        final text = object.text.toPlainText();
        if (text.isNotEmpty) {
          for (final box in object.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          )) {
            final a = object.localToGlobal(
              box.toRect().topLeft,
              ancestor: root,
            );
            final b = object.localToGlobal(
              box.toRect().bottomRight,
              ancestor: root,
            );
            final rect = Rect.fromPoints(a, b).inflate(8).intersect(bounds);
            if (rect.width > 2 && rect.height > 2) zones.add(rect);
          }
        }
      }
      object.visitChildren(visit);
    }

    root.visitChildren(visit);
    if (!_sameZones(_protectedZones, zones)) {
      setState(() => _protectedZones = zones);
    }
    final overlaps = <int>{};
    for (final entry in widget.draft.myElements.entries) {
      final key = (
        id: entry.key,
        template: widget.draft.template,
        device: widget.draft.device,
      );
      final value = widget.draft.myAdjustment(key);
      if (value.hidden ||
          value.opacity == 0 ||
          widget.draft.decorationIntensity == 0) {
        continue;
      }
      final rect = MyDecorationGeometry.adjusted(key, entry.value, value);
      if (zones.any((zone) {
        final overlap = rect.intersect(zone);
        return overlap.width > 2 && overlap.height > 2;
      })) {
        overlaps.add(entry.key);
      }
    }
    if (overlaps.length != widget.draft.myOverlaps.length ||
        !widget.draft.myOverlaps.containsAll(overlaps)) {
      widget.draft.update(() => widget.draft.myOverlaps = overlaps);
    }
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

  Widget _element(int id, MyAmbienceFile file, bool reduced) {
    final draft = widget.draft;
    final key = (id: id, template: draft.template, device: draft.device);
    final adjustment = MyDecorationGeometry.constrain(
      key,
      file,
      draft.myAdjustment(key),
    );
    if (adjustment.hidden) return const SizedBox.shrink();
    final rect = MyDecorationGeometry.adjusted(key, file, adjustment);
    final selected = draft.editMyDecorations && draft.selectedMyElementId == id;
    final overlap = draft.editMyDecorations && draft.myOverlaps.contains(id);
    final amount = reduced ? 0.0 : draft.elementMotion / 100;
    final opacity = (draft.decorationIntensity / 100 * adjustment.opacity)
        .clamp(0.0, 1.0);
    return Positioned.fromRect(
      key: ValueKey('my-element-$id'),
      rect: rect,
      child: IgnorePointer(
        ignoring: !draft.editMyDecorations,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => draft.update(() => draft.selectedMyElementId = id),
          onPanDown: (d) {
            _dragStart = _canvasPoint(d.globalPosition);
            _dragAdjustment = draft.myAdjustment(key);
          },
          onPanStart: (_) => draft.update(() => draft.selectedMyElementId = id),
          onPanUpdate: (d) {
            if (_dragStart == null || _dragAdjustment == null) return;
            final delta = _canvasPoint(d.globalPosition) - _dragStart!;
            final size = MyDecorationGeometry.frame(draft.device);
            final requested = _dragAdjustment!.copyWith(
              shift:
                  _dragAdjustment!.shift +
                  Offset(delta.dx / size.width, delta.dy / size.height),
            );
            draft.changeMyAdjustment(
              key,
              MyDecorationGeometry.constrain(key, file, requested),
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: selected
                  ? Border.all(
                      color: overlap ? Colors.redAccent : Colors.cyanAccent,
                      width: 2,
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: amount == 0 ? 0 : (_phase ? 1 : 0)),
              duration: amount == 0
                  ? Duration.zero
                  : const Duration(seconds: 6),
              curve: Curves.easeInOutSine,
              builder: (context, phase, child) => Transform.translate(
                offset: Offset(phase * amount * 3, -phase * amount * 4),
                child: Transform.rotate(
                  angle: phase * amount * .012,
                  child: child,
                ),
              ),
              child: Opacity(
                opacity: opacity,
                child: Image.memory(
                  file.bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyProtectedZonesPainter extends CustomPainter {
  const _MyProtectedZonesPainter(this.zones);
  final List<Rect> zones;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66FF677C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final zone in zones) {
      canvas.drawRect(zone, paint);
    }
  }

  @override
  bool shouldRepaint(_MyProtectedZonesPainter old) => old.zones != zones;
}
