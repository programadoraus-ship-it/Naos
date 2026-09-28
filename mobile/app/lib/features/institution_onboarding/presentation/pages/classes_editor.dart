import 'package:flutter/material.dart';
import 'school_structure_draft.dart';
import 'cosmic_editor_style.dart';
import 'institution_timezone_picker.dart';

class ClassesEditor extends StatelessWidget {
  const ClassesEditor({super.key, required this.draft});
  final SchoolStructureDraft draft;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: draft,
    builder: (context, _) {
      final reduced =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context);
      final duration = reduced
          ? Duration.zero
          : const Duration(milliseconds: 220);
      return AnimatedSize(
        duration: duration,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CosmicEditorNotice(
              'Draft · Save your structure with Continue',
            ),
            const SizedBox(height: 16),
            InstitutionTimezonePicker(
              value: draft.timezone,
              onChanged: draft.setTimezone,
            ),
            const SizedBox(height: 16),
            Text(
              '${draft.classes.length} ${draft.classes.length == 1 ? 'class' : 'classes'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            CosmicEditorTransition(
              child: Column(
                key: ValueKey(
                  draft.classes.map((c) => c.toJson().toString()).join('|'),
                ),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (draft.classes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: cosmicEditorDecoration(),
                      child: const Text(
                        'No classes yet. Add only the classes you need.',
                        style: TextStyle(color: Colors.white60, height: 1.5),
                      ),
                    ),
                  for (final c in draft.classes)
                    AnimatedContainer(
                      duration: duration,
                      key: ValueKey('class-${c.id}'),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: cosmicEditorDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                c.shift == 'morning'
                                    ? Icons.wb_sunny_outlined
                                    : c.shift == 'afternoon'
                                    ? Icons.wb_twilight
                                    : Icons.nights_stay_outlined,
                                color: const Color(0xFFABDCEB),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${c.name} · ${_shiftLabel(c.shift)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${c.course} · ${c.level}\n${c.days.map((d) => _days[d - 1]).join(', ')} · ${c.start}–${c.end}',
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.6,
                            ),
                          ),
                          if (c.validate(
                                draft.courses.courses,
                                draft.levels.levels,
                              ) !=
                              null)
                            const Text(
                              'Update this class before saving.',
                              style: TextStyle(color: Colors.amberAccent),
                            ),
                          Wrap(
                            alignment: WrapAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _edit(context, c),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                              TextButton.icon(
                                onPressed: () => draft.remove(c.id),
                                icon: const Icon(Icons.remove_circle_outline),
                                label: const Text('Remove'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            TextButton.icon(
              key: const ValueKey('add-class'),
              onPressed:
                  draft.courses.courses.isEmpty || draft.levels.levels.isEmpty
                  ? null
                  : () => _edit(context, null),
              icon: const Icon(Icons.add_rounded),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC6C2FF),
                backgroundColor: const Color(0x226F63FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              label: const Text('Add class'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose at least one course and level. Removed saved classes are archived, not deleted.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      );
    },
  );
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static String _shiftLabel(String shift) => switch (shift) {
    'morning' => 'Morning',
    'afternoon' => 'Afternoon',
    'evening' => 'Evening',
    _ => shift,
  };

  Future<void> _edit(BuildContext context, SchoolClass? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final start = TextEditingController(text: existing?.start ?? '09:00');
    final end = TextEditingController(text: existing?.end ?? '10:00');
    String? course = draft.courses.courses.contains(existing?.course)
        ? existing?.course
        : null;
    String? level = draft.levels.levels.contains(existing?.level)
        ? existing?.level
        : null;
    String? shift =
        ['morning', 'afternoon', 'evening'].contains(existing?.shift)
        ? existing?.shift
        : null;
    final days = existing?.days.toSet() ?? <int>{};
    String? error;
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    await showDialog<void>(
      context: context,
      animationStyle: AnimationStyle(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
        reverseDuration: reduced
            ? Duration.zero
            : const Duration(milliseconds: 180),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Theme(
          data: ThemeData.dark().copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF252641),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x665E5B91)),
              ),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8B82FF),
              brightness: Brightness.dark,
            ),
          ),
          child: AlertDialog(
            backgroundColor: const Color(0xFF171B35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0x666D67BA)),
            ),
            title: Text(existing == null ? 'New class' : 'Edit class'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const ValueKey('class-name'),
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Class name',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('class-course'),
                      initialValue: course,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Course'),
                      items: [
                        for (final c in draft.courses.courses)
                          DropdownMenuItem(value: c, child: Text(c)),
                      ],
                      onChanged: (v) => course = v,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('class-level'),
                      initialValue: level,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Level'),
                      items: [
                        for (final l in draft.levels.levels)
                          DropdownMenuItem(value: l, child: Text(l)),
                      ],
                      onChanged: (v) => level = v,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('class-shift'),
                      initialValue: shift,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Shift'),
                      items: const [
                        DropdownMenuItem(
                          value: 'morning',
                          child: Text('Morning'),
                        ),
                        DropdownMenuItem(
                          value: 'afternoon',
                          child: Text('Afternoon'),
                        ),
                        DropdownMenuItem(
                          value: 'evening',
                          child: Text('Evening'),
                        ),
                      ],
                      onChanged: (v) => shift = v,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (var d = 1; d <= 7; d++)
                          FilterChip(
                            chipAnimationStyle: ChipAnimationStyle(
                              selectAnimation: AnimationStyle(
                                duration: reduced
                                    ? Duration.zero
                                    : const Duration(milliseconds: 180),
                              ),
                              enableAnimation: AnimationStyle(
                                duration: reduced
                                    ? Duration.zero
                                    : const Duration(milliseconds: 180),
                              ),
                            ),
                            label: Text(_days[d - 1]),
                            selected: days.contains(d),
                            onSelected: (value) => setDialogState(
                              () => value ? days.add(d) : days.remove(d),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const ValueKey('class-start'),
                      controller: start,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Start (HH:mm, 24-hour)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const ValueKey('class-end'),
                      controller: end,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'End (HH:mm, 24-hour)',
                      ),
                    ),
                    if (error != null)
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.amberAccent),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                key: const ValueKey('confirm-class'),
                onPressed: () {
                  final value = SchoolClass(
                    id: existing?.id,
                    name: name.text.trim(),
                    course: course ?? '',
                    level: level ?? '',
                    shift: shift ?? '',
                    days: days.toList()..sort(),
                    start: start.text.trim(),
                    end: end.text.trim(),
                  );
                  final problem = draft.put(value);
                  if (problem != null) {
                    setDialogState(() => error = problem);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Keep class'),
              ),
            ],
          ),
        ),
      ),
    );
    // The route can still animate out after showDialog completes.
    await Future<void>.delayed(
      reduced ? Duration.zero : const Duration(milliseconds: 220),
    );
    name.dispose();
    start.dispose();
    end.dispose();
  }
}
