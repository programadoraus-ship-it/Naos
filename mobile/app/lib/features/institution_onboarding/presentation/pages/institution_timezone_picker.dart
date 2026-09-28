import 'package:flutter/material.dart';
import 'cosmic_editor_style.dart';
import 'institution_timezones.dart';

String _searchText(String value) {
  var result = value.toLowerCase().replaceAll('_', ' ');
  for (final pair in [
    ('á', 'a'),
    ('é', 'e'),
    ('í', 'i'),
    ('ó', 'o'),
    ('ú', 'u'),
    ('ñ', 'n'),
  ]) {
    result = result.replaceAll(pair.$1, pair.$2);
  }
  return result;
}

const _aliases = <String, String>{
  'Spain': 'España Espana',
  'United States': 'Estados Unidos USA EEUU',
  'United Kingdom': 'Reino Unido Inglaterra',
  'Germany': 'Alemania',
  'France': 'Francia',
  'Italy': 'Italia',
  'Japan': 'Japon Japón',
  'Brazil': 'Brasil',
  'New Zealand': 'Nueva Zelanda',
  'South Africa': 'Sudafrica Sudáfrica',
  'South Korea': 'Corea del Sur',
};

class InstitutionTimezonePicker extends StatelessWidget {
  const InstitutionTimezonePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final matches = institutionTimezones.where((z) => z.$2 == value);
    final country = matches.isEmpty ? null : matches.first.$1;
    return Semantics(
      button: true,
      label: 'Institution timezone',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('institution-timezone'),
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final duration = editorDuration(context);
            final selected = await showDialog<String>(
              context: context,
              animationStyle: AnimationStyle(
                duration: duration,
                reverseDuration: duration,
              ),
              builder: (_) => _TimezoneDialog(current: value),
            );
            if (selected != null && context.mounted && selected != value) {
              onChanged(selected);
            }
          },
          child: Ink(
            decoration: cosmicEditorDecoration(),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(Icons.public_rounded, color: Color(0xFFABDCEB)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Institution timezone',
                        style: TextStyle(
                          color: Color(0xFFC6C2FF),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value.isEmpty ? 'Choose your country and city' : value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (country != null)
                        Text(
                          country,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.search_rounded, color: Color(0xFFC6C2FF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimezoneDialog extends StatefulWidget {
  const _TimezoneDialog({required this.current});
  final String current;
  @override
  State<_TimezoneDialog> createState() => _TimezoneDialogState();
}

class _TimezoneDialogState extends State<_TimezoneDialog> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final options = [
      if (widget.current.isNotEmpty &&
          !institutionTimezones.any((z) => z.$2 == widget.current))
        ('Current saved timezone', widget.current),
      ...institutionTimezones,
    ];
    final terms = _searchText(query).trim().split(RegExp(r'\s+'));
    final results = options.where((z) {
      final text = _searchText('${z.$1} ${z.$2} ${_aliases[z.$1] ?? ''}');
      return terms.every(text.contains);
    }).toList();
    return AlertDialog(
      backgroundColor: const Color(0xFF171B35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x666D67BA)),
      ),
      title: const Text(
        'Find your timezone',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 520,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('timezone-search'),
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: 'Country, city or IANA timezone',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFC6C2FF)),
                filled: true,
                fillColor: const Color(0xFF252641),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose the city for your region. Seasonal clock changes follow the selected timezone.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text(
                        'No matches. Try a nearby city or the IANA name.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final z = results[i];
                        return ListTile(
                          key: ValueKey('timezone-${z.$2}'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          title: Text(
                            '${z.$1} · ${z.$2.split('/').last.replaceAll('_', ' ')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            z.$2,
                            style: const TextStyle(
                              color: Color(0xFFC6C2FF),
                              fontSize: 12,
                            ),
                          ),
                          trailing: z.$2 == widget.current
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF9DE8DB),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, z.$2),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
