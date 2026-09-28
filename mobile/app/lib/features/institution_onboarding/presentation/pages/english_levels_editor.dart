import 'package:flutter/material.dart';
import 'cosmic_draft_editor.dart';

/// In-memory draft only. No institution IDs, storage or backend calls.
class EnglishLevelsDraft extends ChangeNotifier {
  static const suggestions = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const limit = 10;
  final List<String> _levels = [];
  List<String> get levels => List.unmodifiable(_levels);
  void restore(Iterable<String> names) { _levels..clear()..addAll(names); notifyListeners(); }

  String? add(String value) {
    final trimmed = value.trim();
    final name = suggestions.contains(trimmed.toUpperCase())
        ? trimmed.toUpperCase()
        : trimmed;
    if (name.isEmpty) return 'Enter a level name.';
    if (_levels.any((level) => level.toLowerCase() == name.toLowerCase())) {
      return 'This level is already selected.';
    }
    if (_levels.length >= limit) return 'You can select up to 10 levels.';
    // CEFR selections start in ascending order. Explicit moves remain editable.
    final rank = suggestions.indexOf(name);
    final before = rank < 0
        ? -1
        : _levels.indexWhere((level) {
            final other = suggestions.indexOf(level);
            return other >= 0 && other > rank;
          });
    _levels.insert(before < 0 ? _levels.length : before, name);
    notifyListeners();
    return null;
  }

  void remove(String name) {
    if (_levels.remove(name)) notifyListeners();
  }

  void move(int index, int offset) {
    final destination = index + offset;
    if (index < 0 ||
        index >= _levels.length ||
        destination < 0 ||
        destination >= _levels.length) {
      return;
    }
    _levels.insert(destination, _levels.removeAt(index));
    notifyListeners();
  }
}

class EnglishLevelsEditor extends StatelessWidget {
  const EnglishLevelsEditor({super.key, required this.draft, this.connected = false});
  final EnglishLevelsDraft draft;
  final bool connected;
  @override
  Widget build(BuildContext context) => CosmicDraftEditor(
    draft: draft,
    items: () => draft.levels,
    suggestions: EnglishLevelsDraft.suggestions,
    singular: 'level',
    plural: 'levels',
    add: draft.add,
    remove: draft.remove,
    move: draft.move,
    connected: connected,
  );
}
