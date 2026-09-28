import 'package:flutter/material.dart';

Duration editorDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 240);

BoxDecoration cosmicEditorDecoration() => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF29274E), Color(0xFF141A34)],
  ),
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: const Color(0x666D67BA)),
);

class CosmicEditorNotice extends StatelessWidget {
  const CosmicEditorNotice(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0x182CDAE8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x302CDAE8)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.cloud_done_outlined,
          size: 18,
          color: Color(0xFFABDCEB),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFABDCEB),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Finite transitions only. Outgoing content is neither interactive nor announced.
class CosmicEditorTransition extends StatelessWidget {
  const CosmicEditorTransition({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final duration = editorDuration(context);
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final old in previous)
              ExcludeSemantics(child: IgnorePointer(child: old)),
            ?current,
          ],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .025), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
        child: child,
      ),
    );
  }
}
