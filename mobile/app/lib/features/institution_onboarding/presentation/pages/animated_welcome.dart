import 'package:flutter/material.dart';

/// A single, finite introduction; content and Continue remain available throughout.
class AnimatedWelcome extends StatelessWidget {
  const AnimatedWelcome({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 1400),
      builder: (context, value, _) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < children.length; i++)
            Builder(
              builder: (context) {
                final start = i / children.length * .45;
                final progress = reduced
                    ? 1.0
                    : Curves.easeOutCubic.transform(
                        ((value - start) / .55).clamp(0.0, 1.0),
                      );
                return Opacity(
                  opacity: progress,
                  child: Transform.translate(
                    offset: Offset(0, 22 * (1 - progress)),
                    child: Transform.scale(
                      scale: .97 + .03 * progress,
                      child: children[i],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
