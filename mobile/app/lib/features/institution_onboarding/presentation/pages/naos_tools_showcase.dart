import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// Informational only: no provisioning, selection or persistence.
class NaosToolsShowcase extends StatefulWidget {
  const NaosToolsShowcase({super.key});

  static const tools = <(IconData, String)>[
    (Icons.people_alt_rounded, 'Students'),
    (Icons.school_rounded, 'Teachers'),
    (Icons.menu_book_rounded, 'Courses'),
    (Icons.class_rounded, 'Classes'),
    (Icons.emoji_events_rounded, 'Rankings'),
    (Icons.payments_rounded, 'Finance'),
    (Icons.analytics_rounded, 'Analytics'),
    (Icons.verified_user_rounded, 'Access Requests'),
    (Icons.public_rounded, 'Virtual School'),
    (Icons.sports_esports_rounded, 'Games'),
  ];

  @override
  State<NaosToolsShowcase> createState() => _NaosToolsShowcaseState();
}

class _NaosToolsShowcaseState extends State<NaosToolsShowcase>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 11000),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 740
            ? 4
            : width >= 440
            ? 2
            : 1;
        const gap = 12.0;
        // Allow large accessibility text without truncating tool names.
        final rowHeight =
            76.0 +
            (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0, 60) * 3;
        final cardWidth = (width - gap * (columns - 1)) / columns;
        final height =
            ((NaosToolsShowcase.tools.length / columns).ceil()) *
                (rowHeight + gap) -
            gap;
        final progress = _controller.value * NaosToolsShowcase.tools.length;
        final index = progress.floor();
        final finished = index >= NaosToolsShowcase.tools.length;
        final phase = progress - index;
        Rect target(int i) => Rect.fromLTWH(
          (i % columns) * (cardWidth + gap),
          (i ~/ columns) * (rowHeight + gap),
          cardWidth,
          rowHeight,
        );
        final heroWidth = width.clamp(0.0, 430.0);
        final hero = Rect.fromLTWH(
          (width - heroWidth) / 2,
          12,
          heroWidth,
          rowHeight + 84,
        );
        final origin = Rect.fromCenter(
          center: hero.center,
          width: hero.width * .18,
          height: hero.height * .18,
        );
        final docking = ((phase - .55) / .45).clamp(0.0, 1.0);
        final arrival = (phase / .3).clamp(0.0, 1.0);
        final flyingRect = finished
            ? Rect.zero
            : phase < .55
            ? Rect.lerp(origin, hero, Curves.easeOutCubic.transform(arrival))!
            : Rect.lerp(
                hero,
                target(index),
                Curves.easeInOutCubic.transform(docking),
              )!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('skip-tools-intro'),
                onPressed: finished ? null : () => _controller.value = 1,
                icon: Icon(
                  finished ? Icons.check_rounded : Icons.skip_next_rounded,
                  size: 18,
                ),
                label: Text(finished ? 'Your toolkit' : 'Show all tools'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC6C2FF),
                ),
              ),
            ),
            SizedBox(
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < NaosToolsShowcase.tools.length; i++)
                    Positioned.fromRect(
                      rect: target(i),
                      child: Semantics(
                        label: NaosToolsShowcase.tools[i].$2,
                        child: ExcludeSemantics(
                          child: Opacity(
                            opacity: finished || i < index ? 1 : .12,
                            child: _toolCard(i, 0),
                          ),
                        ),
                      ),
                    ),
                  if (!finished)
                    Positioned.fromRect(
                      rect: flyingRect,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: Opacity(
                            opacity: arrival,
                            child: _toolCard(
                              index,
                              (phase < .55 ? arrival : 1 - docking),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _toolCard(int index, double emphasis) {
    final tool = NaosToolsShowcase.tools[index];
    return Container(
      key: ValueKey('tool-card-${tool.$2}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF262453), Color(0xFF101832)],
        ),
        borderRadius: BorderRadius.circular(lerpDouble(18, 28, emphasis)!),
        border: Border.all(
          color: Color.lerp(
            const Color(0xFF393666),
            const Color(0xFFB9B2FF),
            emphasis,
          )!,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A65FF).withValues(alpha: emphasis * .3),
            blurRadius: 36 * emphasis,
            spreadRadius: 3 * emphasis,
          ),
        ],
      ),
      // The enlarged presentation scales its contents with the flying card;
      // this avoids layout overflow during the tiny arrival from the background.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 160 + 150 * emphasis,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10 + 6 * emphasis),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF34316C),
                  border: Border.all(color: const Color(0xFF655AAE)),
                ),
                child: Icon(
                  tool.$1,
                  size: 20 + 24 * emphasis,
                  color: const Color(0xFFC6C2FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tool.$2,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 + 12 * emphasis,
                    fontWeight: FontWeight.w700,
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
