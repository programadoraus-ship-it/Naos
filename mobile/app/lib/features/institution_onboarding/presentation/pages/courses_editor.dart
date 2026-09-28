import 'package:flutter/material.dart';
import 'cosmic_draft_editor.dart';

/// Courses have no academic ranking. Selection order is only a display order.
class CoursesDraft extends ChangeNotifier {
  static const suggestions = [
    'General English',
    'Academic English',
    'IELTS Preparation',
    'Business English',
    'English for Beginners',
  ];
  static const limit = 10;
  final List<String> _courses = [];
  List<String> get courses => List.unmodifiable(_courses);
  void restore(Iterable<String> names) { _courses..clear()..addAll(names); notifyListeners(); }
  String? add(String value) {
    var name = value.trim();
    if (name.isEmpty) return 'Enter a course name.';
    if (_courses.any((course) => course.toLowerCase() == name.toLowerCase())) {
      return 'This course is already selected.';
    }
    if (_courses.length >= limit) return 'You can select up to 10 courses.';
    name = suggestions.firstWhere(
      (course) => course.toLowerCase() == name.toLowerCase(),
      orElse: () => name,
    );
    _courses.add(name);
    notifyListeners();
    return null;
  }

  void remove(String name) {
    if (_courses.remove(name)) notifyListeners();
  }
}

class CoursesEditor extends StatelessWidget {
  const CoursesEditor({super.key, required this.draft, this.connected = false});
  final CoursesDraft draft;
  final bool connected;
  @override
  Widget build(BuildContext context) => CosmicDraftEditor(
    draft: draft,
    items: () => draft.courses,
    suggestions: CoursesDraft.suggestions,
    singular: 'course',
    plural: 'courses',
    add: draft.add,
    remove: draft.remove,
    connected: connected,
  );
}
