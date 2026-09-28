import 'package:flutter/material.dart';
import 'cosmic_editor_style.dart';

/// Shared local-only presentation. Persistence is deliberately not a dependency.
class CosmicDraftEditor extends StatefulWidget {
  const CosmicDraftEditor({
    super.key,
    required this.draft,
    required this.items,
    required this.suggestions,
    required this.singular,
    required this.plural,
    required this.add,
    required this.remove,
    this.move,
    this.connected = false,
  });
  final Listenable draft;
  final List<String> Function() items;
  final List<String> suggestions;
  final String singular;
  final String plural;
  final String? Function(String) add;
  final void Function(String) remove;
  final void Function(int, int)? move;
  final bool connected;

  @override
  State<CosmicDraftEditor> createState() => _CosmicDraftEditorState();
}

class _CosmicDraftEditorState extends State<CosmicDraftEditor> {
  static const accent = Color(0xFFC6C2FF);
  final _name = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _add() {
    final error = widget.add(_name.text);
    setState(() => _error = error);
    if (error == null) _name.clear();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.draft,
    builder: (context, _) {
      final items = widget.items();
      final full = items.length >= 10;
      final reduced =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context);
      final duration = reduced
          ? Duration.zero
          : const Duration(milliseconds: 220);
      final animation = AnimationStyle(
        duration: duration,
        reverseDuration: duration,
      );
      final list = Column(
        key: ValueKey(items.join('\n')),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x335E5B91)),
              ),
              child: Text(
                'Choose suggested ${widget.plural} or add your own to begin.',
                style: const TextStyle(color: Colors.white60, height: 1.5),
              ),
            ),
          for (var i = 0; i < items.length; i++)
            Container(
              key: ValueKey('${widget.singular}-row-${items[i]}'),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: cosmicEditorDecoration(),
              child: Row(
                children: [
                  if (widget.move != null) ...[
                    Text(
                      '${i + 1}'.padLeft(2, '0'),
                      style: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      items[i],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (widget.move != null) ...[
                    _action(
                      Icons.arrow_upward_rounded,
                      'Move ${items[i]} up',
                      i == 0 ? null : () => widget.move!(i, -1),
                    ),
                    _action(
                      Icons.arrow_downward_rounded,
                      'Move ${items[i]} down',
                      i == items.length - 1 ? null : () => widget.move!(i, 1),
                    ),
                  ],
                  _action(Icons.close_rounded, 'Remove ${items[i]}', () {
                    widget.remove(items[i]);
                    setState(() => _error = null);
                  }),
                ],
              ),
            ),
        ],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CosmicEditorNotice(
            widget.connected
                ? 'Draft · Save your structure with Continue'
                : 'Local preview · Not saved to Supabase',
          ),
          const SizedBox(height: 20),
          Text(
            '${items.length} / 10 ${widget.plural}',
            key: ValueKey('${widget.plural}-count'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your ${widget.plural}',
            style: const TextStyle(color: accent, fontSize: 13),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [
                for (final name in widget.suggestions)
                  Builder(
                    builder: (context) {
                      final selected = items.any(
                        (item) => item.toLowerCase() == name.toLowerCase(),
                      );
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: AnimatedContainer(
                          duration: duration,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: selected
                                ? const [
                                    BoxShadow(
                                      color: Color(0x406F63FF),
                                      blurRadius: 14,
                                    ),
                                  ]
                                : [],
                          ),
                          child: FilterChip(
                            key: ValueKey(
                              widget.singular == 'level'
                                  ? 'suggestion-$name'
                                  : 'course-suggestion-$name',
                            ),
                            label: Text(name, softWrap: true),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : accent,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            selected: selected,
                            showCheckmark: true,
                            checkmarkColor: const Color(0xFFBDF5FF),
                            backgroundColor: const Color(0xFF201F3C),
                            selectedColor: const Color(0xFF5145A0),
                            disabledColor: const Color(0xFF242238),
                            side: BorderSide(
                              color: selected
                                  ? const Color(0xFFB9B2FF)
                                  : const Color(0xFF555178),
                              width: selected ? 1.5 : 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            chipAnimationStyle: ChipAnimationStyle(
                              enableAnimation: animation,
                              selectAnimation: animation,
                              avatarDrawerAnimation: animation,
                              deleteDrawerAnimation: animation,
                            ),
                            onSelected: full && !selected
                                ? null
                                : (value) {
                                    setState(() => _error = null);
                                    if (value) {
                                      final error = widget.add(name);
                                      if (error != null) {
                                        setState(() => _error = error);
                                      }
                                    } else {
                                      widget.remove(
                                        items.firstWhere(
                                          (item) =>
                                              item.toLowerCase() ==
                                              name.toLowerCase(),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            key: ValueKey('custom-${widget.singular}-name'),
            controller: _name,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: 'Custom ${widget.singular}',
              hintText: widget.singular == 'level'
                  ? 'e.g. Foundation'
                  : 'e.g. English for Travel',
              labelStyle: const TextStyle(color: accent),
              hintStyle: const TextStyle(color: Colors.white54),
              errorText: _error,
              errorMaxLines: 2,
              filled: true,
              fillColor: const Color(0xFF201F3C),
              contentPadding: const EdgeInsets.all(18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF555178)),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: ValueKey('add-custom-${widget.singular}'),
              onPressed: full ? null : _add,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                backgroundColor: const Color(0x226F63FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text('Add ${widget.singular}'),
            ),
          ),
          if (full)
            Text(
              'Maximum 10 ${widget.plural}. Remove one to add another.',
              style: const TextStyle(color: accent, fontSize: 12),
            ),
          const SizedBox(height: 20),
          Text(
            widget.move != null
                ? 'Ascending order · lowest to highest'
                : 'Selected courses · no academic order',
            style: const TextStyle(color: accent, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (reduced)
            list
          else
            AnimatedSize(
              duration: duration,
              alignment: Alignment.topCenter,
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                key: ValueKey('${widget.plural}-transition'),
                duration: duration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
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
                    position: Tween(
                      begin: const Offset(0, 0.025),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: list,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            widget.connected
                ? 'Removing saved items archives them. Changes are saved together with Continue.'
                : 'Changes stay here while you navigate the steps. '
                      'Leaving onboarding or restarting the app clears this preview.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
        ],
      );
    },
  );

  Widget _action(IconData icon, String tooltip, VoidCallback? onPressed) =>
      IconButton(
        tooltip: tooltip,
        color: accent,
        disabledColor: Colors.white24,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
      );
}
