import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'courses_editor.dart';
import 'english_levels_editor.dart';

String structureUuid() {
  final random = Random.secure();
  final b = List.generate(16, (_) => random.nextInt(256));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  final s = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

class SchoolClass {
  SchoolClass({
    String? id,
    required this.name,
    required this.course,
    required this.level,
    required this.shift,
    required List<int> days,
    required this.start,
    required this.end,
  }) : id = id ?? structureUuid(),
       days = List.unmodifiable(days);
  final String id, name, course, level, shift, start, end;
  final List<int> days;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'course': course,
    'level': level,
    'shift': shift,
    'days': days,
    'start': start,
    'end': end,
  };
  String? validate(List<String> courses, List<String> levels) {
    if (name.trim().isEmpty) return 'Enter a class name.';
    if (!courses.contains(course) || !levels.contains(level)) {
      return 'Choose an active course and level for every class.';
    }
    if (!['morning', 'afternoon', 'evening'].contains(shift)) {
      return 'Choose a shift.';
    }
    if (days.isEmpty ||
        days.toSet().length != days.length ||
        days.any((d) => d < 1 || d > 7)) {
      return 'Choose the weekdays.';
    }
    final pattern = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$');
    if (!pattern.hasMatch(start) ||
        !pattern.hasMatch(end) ||
        end.compareTo(start) <= 0) {
      return 'End time must be later on the same day.';
    }
    return null;
  }

  static SchoolClass fromJson(Map<String, dynamic> row) {
    final schedules = (row['schedules'] as List).cast<Map<String, dynamic>>();
    final minuteTime=RegExp(r'^\d{2}:\d{2}(?::00(?:\.0+)?)?$');
    if(schedules.any((s)=>!minuteTime.hasMatch(s['start'] as String)||!minuteTime.hasMatch(s['end'] as String))) {
      throw StateError('Existing sub-minute schedules cannot be rounded silently.');
    }
    if (schedules
                .map((s) => '${s['start']}/${s['end']}/${s['timezone']}')
                .toSet()
                .length >
            1 ||
        schedules.map((s) => s['day']).toSet().length != schedules.length) {
      throw StateError(
        'Class ${row['name']} has multiple time patterns. Its existing schedules were not changed.',
      );
    }
    return SchoolClass(
      id: row['id'] as String,
      name: row['name'] as String,
      course: row['course'] as String,
      level: row['level'] as String? ?? '',
      shift: row['shift'] as String? ?? '',
      days: schedules.map((s) => s['day'] as int).toList(),
      start: schedules.isEmpty
          ? ''
          : (schedules.first['start'] as String).substring(0, 5),
      end: schedules.isEmpty
          ? ''
          : (schedules.first['end'] as String).substring(0, 5),
    );
  }
}

class SchoolStructureDraft extends ChangeNotifier {
  SchoolStructureDraft(this.levels, this.courses) {
    levels.addListener(changed);
    courses.addListener(changed);
  }
  final EnglishLevelsDraft levels;
  final CoursesDraft courses;
  final List<SchoolClass> _classes = [];
  List<SchoolClass> get classes => List.unmodifiable(_classes);
  String timezone = '';
  String? error, _institution, _request;
  int revision = 0;
  int _edits = 0;
  bool loaded = false,
      busy = false,
      dirty = false,
      _hydrating = false,
      _disposed = false;
  void changed() {
    if (_hydrating || _disposed) return;
    _edits++;
    dirty = true;
    _request = null;
    notifyListeners();
  }

  void setTimezone(String value) {
    timezone = value.trim();
    changed();
  }

  String? put(SchoolClass value) {
    final problem = value.validate(courses.courses, levels.levels);
    if (problem != null) return problem;
    final index = _classes.indexWhere((c) => c.id == value.id);
    if (index < 0) {
      _classes.add(value);
    } else {
      _classes[index] = value;
    }
    changed();
    return null;
  }

  void remove(String id) {
    _classes.removeWhere((c) => c.id == id);
    changed();
  }

  Future<void> load(
    SupabaseClient client,
    String institution, {
    bool discardConfirmed = false,
  }) async {
    if (busy || (!discardConfirmed && loaded && _institution == institution)) {
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final raw = Map<String, dynamic>.from(
        await client.rpc(
              'get_school_structure',
              params: {'p_institution_id': institution},
            )
            as Map,
      );
      final parsed = (raw['classes'] as List)
          .map((c) => SchoolClass.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
      if (_disposed) return;
      _hydrating = true;
      levels.restore((raw['levels'] as List).map((l) => l['name'] as String));
      courses.restore((raw['courses'] as List).map((c) => c['name'] as String));
      _classes
        ..clear()
        ..addAll(parsed);
      timezone = raw['timezone'] as String? ?? '';
      revision = raw['revision'] as int;
      _institution = institution;
      loaded = true;
      dirty = false;
      _request = null;
    } catch (e) {
      error = 'Unable to load school structure. Nothing was overwritten. $e';
    } finally {
      _hydrating = false;
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> save(SupabaseClient client, String institution) async {
    if (busy) return false;
    if (!loaded || _institution != institution) {
      error = 'Load the institution structure before saving.';
      notifyListeners();
      return false;
    }
    for (final c in classes) {
      final problem = c.validate(courses.courses, levels.levels);
      if (problem != null) {
        error = '${c.name}: $problem';
        notifyListeners();
        return false;
      }
    }
    if (timezone.isEmpty) {
      error =
          'Confirm the institution timezone (IANA, e.g. Australia/Brisbane).';
      notifyListeners();
      return false;
    }
    final savedEdits = _edits;
    busy = true;
    error = null;
    _request ??= structureUuid();
    notifyListeners();
    try {
      final result = await client.rpc(
        'save_school_structure',
        params: {
          'p_institution_id': institution,
          'p_revision': revision,
          'p_request': _request,
          'p_data': {
            'timezone': timezone,
            'levels': levels.levels,
            'courses': courses.courses,
            'classes': classes.map((c) => c.toJson()).toList(),
          },
        },
      );
      revision = result as int;
      if (_edits != savedEdits) {
        dirty = true;
        _request = null;
        error =
            'The earlier snapshot was saved. Your newer draft is still here; press Continue again.';
        return false;
      }
      dirty = false;
      _request = null;
      return true;
    } catch (e) {
      error =
          'Structure was not confirmed saved. Your draft is still here. Retry or resolve the reported conflict. $e';
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    levels.removeListener(changed);
    courses.removeListener(changed);
    super.dispose();
  }
}
