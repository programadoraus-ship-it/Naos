import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'institution_ambience_layer.dart';
import 'institution_brand_draft.dart';
import 'institution_ocean_ambience.dart';
import 'institution_ocean_scene.dart';
import 'institution_space_scene.dart';
import 'institution_animals_scene.dart';
import 'institution_nature_scene.dart';
import 'institution_fantasy_scene.dart';
import 'institution_my_ambience_scene.dart';
import 'institution_my_ambience_validation.dart';
import 'institution_template_preview.dart';

class InstitutionBrandEditor extends StatefulWidget {
  const InstitutionBrandEditor({
    super.key,
    required this.draft,
    required this.institutionName,
    this.logoBytes,
    this.logoUrl,
  });

  final InstitutionBrandDraft draft;
  final String institutionName;
  final Uint8List? logoBytes;
  final String? logoUrl;

  @override
  State<InstitutionBrandEditor> createState() => _InstitutionBrandEditorState();
}

class _InstitutionBrandEditorState extends State<InstitutionBrandEditor>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 6, vsync: this);
  int _motionDemoPage = 0;
  bool _motionDemoPressed = false;
  String? _myFileError;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.draft,
    builder: (context, _) {
      final reduced =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context);
      final duration = reduced
          ? Duration.zero
          : const Duration(milliseconds: 280);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _notice(),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xB3121835),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x3D8B82FF)),
            ),
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: widget.draft.primary,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  text: 'Template',
                  icon: Icon(Icons.dashboard_customize_rounded),
                ),
                Tab(text: 'Ambience', icon: Icon(Icons.landscape_outlined)),
                Tab(text: 'Colors', icon: Icon(Icons.palette_outlined)),
                Tab(text: 'Typography', icon: Icon(Icons.text_fields_rounded)),
                Tab(text: 'Buttons', icon: Icon(Icons.smart_button_outlined)),
                Tab(text: 'Animations', icon: Icon(Icons.animation_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 390,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x70101633),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: TabBarView(
              controller: _tabs,
              children: [
                _templates(duration),
                _ambiences(duration),
                _colors(),
                _typography(duration),
                _buttons(duration),
                _animations(duration, reduced),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _previewControls(),
          if (widget.draft.ambience == InstitutionAmbience.ocean &&
              widget.draft.editOceanDecorations) ...[
            const SizedBox(height: 12),
            _oceanEditControls(),
          ],
          if (widget.draft.ambience == InstitutionAmbience.space &&
              widget.draft.editSpaceDecorations) ...[
            const SizedBox(height: 12),
            _spaceEditControls(),
          ],
          if (widget.draft.ambience == InstitutionAmbience.animals &&
              widget.draft.editAnimalsDecorations) ...[
            const SizedBox(height: 12),
            _animalsEditControls(),
          ],
          if (widget.draft.ambience == InstitutionAmbience.nature &&
              widget.draft.editNatureDecorations) ...[
            const SizedBox(height: 12),
            _natureEditControls(),
          ],
          if (widget.draft.ambience == InstitutionAmbience.fantasy &&
              widget.draft.editFantasyDecorations) ...[
            const SizedBox(height: 12),
            _fantasyEditControls(),
          ],
          if (widget.draft.ambience == InstitutionAmbience.my &&
              widget.draft.editMyDecorations) ...[
            const SizedBox(height: 12),
            _myEditControls(),
          ],
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: widget.draft.motionDuration(reduced: reduced),
            switchInCurve: widget.draft.motionCurve(),
            switchOutCurve: widget.draft.motionCurve(entering: false),
            transitionBuilder: (child, animation) => _motionTransition(
              child,
              animation,
              widget.draft.motion,
              reduced,
            ),
            child: InstitutionTemplatePreview(
              key: ValueKey(
                '${widget.draft.template}-${widget.draft.role}-${widget.draft.device}-${widget.draft.motion}',
              ),
              draft: widget.draft,
              institutionName: _institutionName,
              logoBytes: widget.logoBytes,
              logoUrl: widget.logoUrl,
            ),
          ),
        ],
      );
    },
  );

  String get _institutionName => widget.institutionName.trim().isEmpty
      ? 'Your institution'
      : widget.institutionName.trim();

  Widget _notice() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0x182CDAE8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x302CDAE8)),
    ),
    child: const Row(
      children: [
        Icon(Icons.visibility_outlined, color: Color(0xFFABDCEB), size: 19),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Interactive visual demo · This draft is not saved to Supabase and does not change any live dashboard.',
            style: TextStyle(
              color: Color(0xFFABDCEB),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _templates(Duration duration) => SingleChildScrollView(
    child: LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 920
            ? 3
            : box.maxWidth >= 560
            ? 2
            : 1;
        const gap = 12.0;
        final width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final template in InstitutionTemplate.values)
              SizedBox(width: width, child: _templateCard(template, duration)),
          ],
        );
      },
    ),
  );

  Widget _templateCard(InstitutionTemplate template, Duration duration) {
    final selected = widget.draft.template == template;
    final meta = _templateMeta(template);
    return Semantics(
      selected: selected,
      button: true,
      label: '${meta.$1} template',
      child: InkWell(
        key: ValueKey('template-${meta.$1}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () =>
            widget.draft.update(() => widget.draft.template = template),
        child: AnimatedContainer(
          duration: duration,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? widget.draft.primary.withValues(alpha: .22)
                : const Color(0xFF171C38),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? widget.draft.primary : const Color(0x445E5B91),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _templateMiniature(template),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meta.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? widget.draft.accent : Colors.white30,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                meta.$2,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, String) _templateMeta(InstitutionTemplate template) =>
      switch (template) {
        InstitutionTemplate.orbit => (
          'Orbit',
          'Floating depth and immersive cards',
        ),
        InstitutionTemplate.academy => (
          'Academy',
          'Structured panels and precise navigation',
        ),
        InstitutionTemplate.pulse => (
          'Pulse',
          'Bold progress and energetic modules',
        ),
        InstitutionTemplate.littleSteps => (
          'Little Steps',
          'Large friendly shapes and simple choices',
        ),
        InstitutionTemplate.adventure => (
          'Adventure',
          'A staged learning trail with missions',
        ),
        InstitutionTemplate.studio => (
          'Studio',
          'Asymmetric editorial blocks for teens',
        ),
        InstitutionTemplate.heritage => (
          'Heritage',
          'Paper, classic frames and an editorial index',
        ),
        InstitutionTemplate.prestige => (
          'Prestige',
          'Airy hierarchy and quiet premium detail',
        ),
        InstitutionTemplate.nexus => (
          'Nexus',
          'Angular work panels and luminous telemetry',
        ),
      };

  Widget _templateMiniature(InstitutionTemplate template) {
    final light =
        template == InstitutionTemplate.academy ||
        template == InstitutionTemplate.littleSteps;
    final child = switch (template) {
      InstitutionTemplate.orbit => Stack(
        children: [
          Positioned(
            left: 2,
            top: 3,
            bottom: 3,
            child: _block(22, widget.draft.primary, 9),
          ),
          Positioned(
            left: 32,
            right: 4,
            top: 4,
            child: Row(
              children: [
                Expanded(child: _line(widget.draft.secondary)),
                const SizedBox(width: 5),
                Expanded(child: _line(widget.draft.accent)),
              ],
            ),
          ),
          Positioned(
            left: 32,
            right: 15,
            bottom: 6,
            child: _line(Colors.white30),
          ),
        ],
      ),
      InstitutionTemplate.academy => Row(
        children: [
          _block(25, widget.draft.primary, 2),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              children: [
                _line(const Color(0xFFCBD1DC)),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _line(widget.draft.secondary)),
                      const SizedBox(width: 5),
                      Expanded(child: _line(const Color(0xFFDDE1E8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      InstitutionTemplate.pulse => Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 2, child: _line(widget.draft.primary, 20)),
                const SizedBox(width: 6),
                Expanded(child: _line(widget.draft.accent, 20)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _line(widget.draft.secondary, 20),
        ],
      ),
      InstitutionTemplate.littleSteps => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final color in [
            widget.draft.primary,
            widget.draft.accent,
            widget.draft.secondary,
          ])
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
      InstitutionTemplate.adventure => Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            Container(
              width: 30,
              height: 42 + i * 6,
              decoration: BoxDecoration(
                color: i == 0
                    ? widget.draft.primary
                    : widget.draft.secondary.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(i.isEven ? 12 : 4),
              ),
            ),
            if (i != 3)
              Expanded(child: Container(height: 2, color: widget.draft.accent)),
          ],
        ],
      ),
      InstitutionTemplate.studio => Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: widget.draft.primary,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                Expanded(child: Container(color: widget.draft.accent)),
                const SizedBox(height: 6),
                Expanded(child: Container(color: widget.draft.secondary)),
              ],
            ),
          ),
        ],
      ),
      InstitutionTemplate.heritage => Container(
        decoration: BoxDecoration(
          border: Border.all(color: widget.draft.accent, width: 2),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            _line(widget.draft.secondary, 1),
            const SizedBox(height: 5),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 2, child: _line(widget.draft.primary, 0)),
                  const SizedBox(width: 5),
                  Expanded(child: _line(widget.draft.accent, 0)),
                ],
              ),
            ),
          ],
        ),
      ),
      InstitutionTemplate.prestige => Column(
        children: [
          Align(
            alignment: Alignment.center,
            child: SizedBox(width: 52, child: _line(widget.draft.primary, 0)),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(flex: 3, child: _line(widget.draft.secondary, 2)),
              const SizedBox(width: 13),
              Expanded(child: _line(widget.draft.accent, 2)),
            ],
          ),
          const Spacer(),
        ],
      ),
      InstitutionTemplate.nexus => Row(
        children: [
          Container(width: 20, color: widget.draft.secondary),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              children: [
                _line(widget.draft.accent, 0),
                const SizedBox(height: 5),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _line(widget.draft.primary, 0)),
                      const SizedBox(width: 5),
                      Expanded(child: _line(widget.draft.secondary, 0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    };
    return Container(
      height: 72,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: template == InstitutionTemplate.heritage
            ? const Color(0xFFF3E9D7)
            : template == InstitutionTemplate.prestige
            ? const Color(0xFFF9F8F5)
            : light
            ? const Color(0xFFF3F5F8)
            : const Color(0xFF090E26),
        borderRadius: BorderRadius.circular(
          template == InstitutionTemplate.pulse ? 24 : 12,
        ),
      ),
      child: child,
    );
  }

  Widget _block(double width, Color color, double radius) => Container(
    width: width,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
  Widget _line(Color color, [double radius = 7]) => Container(
    height: 13,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );

  Widget _ambiences(Duration duration) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= 840
                ? 3
                : box.maxWidth >= 520
                ? 2
                : 1;
            const gap = 12.0;
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final ambience in InstitutionAmbience.values)
                  SizedBox(
                    width: width,
                    child: _ambienceCard(ambience, duration),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        if (widget.draft.ambience == InstitutionAmbience.ocean) ...[
          const Text(
            'Ocean scenes',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 610 ? 3 : 1;
              const gap = 10.0;
              final cardWidth = (box.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final variant in OceanVariant.values)
                    SizedBox(
                      width: cardWidth,
                      child: _oceanVariantCard(variant),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              key: const ValueKey('ocean-preview-by-section'),
              value: widget.draft.oceanPreviewBySection,
              onChanged: (value) => widget.draft.update(
                () => widget.draft.oceanPreviewBySection = value,
              ),
              title: const Text(
                'Preview by section',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: const Text(
                'Fixed scene for each demo section; the same sea background remains.',
              ),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: widget.draft.accent,
            ),
          ),
          if (widget.draft.oceanPreviewBySection) _oceanSectionChoices(),
          const SizedBox(height: 12),
        ],
        if (widget.draft.ambience == InstitutionAmbience.space) ...[
          const Text(
            'Space scenes',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 610 ? 3 : 1;
              const gap = 10.0;
              final width = (box.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final variant in SpaceVariant.values)
                    SizedBox(width: width, child: _spaceVariantCard(variant)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              key: const ValueKey('space-preview-by-section'),
              value: widget.draft.spacePreviewBySection,
              onChanged: (value) => widget.draft.update(
                () => widget.draft.spacePreviewBySection = value,
              ),
              title: const Text(
                'Preview by section',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: const Text(
                'Fixed scene for each demo section; the same starfield remains.',
              ),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: widget.draft.accent,
            ),
          ),
          if (widget.draft.spacePreviewBySection) _spaceSectionChoices(),
          const SizedBox(height: 12),
        ],
        if (widget.draft.ambience == InstitutionAmbience.animals) ...[
          const Text(
            'Animals scenes',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 610 ? 3 : 1;
              const gap = 10.0;
              final width = (box.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final variant in AnimalsVariant.values)
                    SizedBox(width: width, child: _animalsVariantCard(variant)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              key: const ValueKey('animals-preview-by-section'),
              value: widget.draft.animalsPreviewBySection,
              onChanged: (value) => widget.draft.update(
                () => widget.draft.animalsPreviewBySection = value,
              ),
              title: const Text(
                'Preview by section',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: const Text(
                'Fixed woodland scene for each demo section; the same landscape remains.',
              ),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: widget.draft.accent,
            ),
          ),
          if (widget.draft.animalsPreviewBySection) _animalsSectionChoices(),
          const SizedBox(height: 12),
        ],
        if (widget.draft.ambience == InstitutionAmbience.nature) ...[
          const Text(
            'Nature scenes',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 610 ? 3 : 1;
              const gap = 10.0;
              final width = (box.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final variant in NatureVariant.values)
                    SizedBox(width: width, child: _natureVariantCard(variant)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              key: const ValueKey('nature-preview-by-section'),
              value: widget.draft.naturePreviewBySection,
              onChanged: (value) => widget.draft.update(
                () => widget.draft.naturePreviewBySection = value,
              ),
              title: const Text(
                'Preview by section',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: const Text(
                'Fixed nature scene for each demo section; the same valley remains.',
              ),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: widget.draft.accent,
            ),
          ),
          if (widget.draft.naturePreviewBySection) _natureSectionChoices(),
          const SizedBox(height: 12),
        ],
        if (widget.draft.ambience == InstitutionAmbience.fantasy) ...[
          const Text(
            'Fantasy scenes',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 610 ? 3 : 1;
              const gap = 10.0;
              final width = (box.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final variant in FantasyVariant.values)
                    SizedBox(width: width, child: _fantasyVariantCard(variant)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              key: const ValueKey('fantasy-preview-by-section'),
              value: widget.draft.fantasyPreviewBySection,
              onChanged: (value) => widget.draft.update(
                () => widget.draft.fantasyPreviewBySection = value,
              ),
              title: const Text(
                'Preview by section',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: const Text(
                'Stable fantasy scene per demo section; the same valley remains.',
              ),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: widget.draft.accent,
            ),
          ),
          if (widget.draft.fantasyPreviewBySection) _fantasySectionChoices(),
          const SizedBox(height: 12),
        ],
        if (widget.draft.ambience == InstitutionAmbience.my) ...[
          _myFilesControls(),
          const SizedBox(height: 12),
        ],
        if (widget.draft.ambience == InstitutionAmbience.ocean ||
            widget.draft.ambience == InstitutionAmbience.space ||
            widget.draft.ambience == InstitutionAmbience.animals ||
            widget.draft.ambience == InstitutionAmbience.nature ||
            widget.draft.ambience == InstitutionAmbience.fantasy ||
            widget.draft.ambience == InstitutionAmbience.my)
          _intensityControl(
            'Background intensity',
            'background',
            widget.draft.backgroundIntensity,
            widget.draft.setBackgroundIntensity,
          ),
        _intensityControl(
          'Decorative elements intensity',
          'decoration',
          widget.draft.decorationIntensity,
          widget.draft.setDecorationIntensity,
        ),
        if (widget.draft.ambience == InstitutionAmbience.ocean ||
            widget.draft.ambience == InstitutionAmbience.space ||
            widget.draft.ambience == InstitutionAmbience.animals ||
            widget.draft.ambience == InstitutionAmbience.nature ||
            widget.draft.ambience == InstitutionAmbience.fantasy ||
            widget.draft.ambience == InstitutionAmbience.my)
          _intensityControl(
            'Element motion',
            'element-motion',
            widget.draft.elementMotion,
            widget.draft.setElementMotion,
          ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              key: const ValueKey('intensity-subtle'),
              label: const Text('Subtle · 25%'),
              onPressed: () =>
                  widget.draft.applyIntensityPreset(AmbienceIntensity.subtle),
            ),
            ActionChip(
              key: const ValueKey('intensity-normal'),
              label: const Text('Normal · 65%'),
              onPressed: () =>
                  widget.draft.applyIntensityPreset(AmbienceIntensity.normal),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'The landscape stays still behind the interface. Decorations only respond to dragging in Edit decorations mode; academic data never changes.',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    ),
  );

  Future<MyAmbienceFile?> _pickMyFile({required bool element}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (picked == null) return null;
      final bytes = await picked.readAsBytes();
      final file = await validateMyAmbienceFile(
        picked.name,
        bytes,
        element: element,
      );
      if (mounted) setState(() => _myFileError = null);
      return file;
    } on MyAmbienceValidationException catch (error) {
      if (mounted) setState(() => _myFileError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _myFileError =
              'Could not open this image. Choose a local PNG, JPG or WebP file.',
        );
      }
    }
    return null;
  }

  Future<void> _chooseMyBackground() async {
    final file = await _pickMyFile(element: false);
    if (file == null || !mounted) return;
    var mobileFocal =
        widget.draft.myFocalPoints[PreviewDevice.mobile] ?? Offset.zero;
    var desktopFocal =
        widget.draft.myFocalPoints[PreviewDevice.desktop] ?? Offset.zero;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) => AlertDialog(
          title: const Text('Check background crop'),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${file.name} · ${file.width} × ${file.height} · ${(file.bytes.length / 1048576).toStringAsFixed(2)} MB',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These are the actual Mobile and Desktop crops. Move the focal point before accepting.',
                  ),
                  const SizedBox(height: 12),
                  for (final device in PreviewDevice.values) ...[
                    Text(
                      device == PreviewDevice.mobile ? 'Mobile' : 'Desktop',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: SizedBox(
                        width: device == PreviewDevice.mobile ? 156 : 324,
                        height: device == PreviewDevice.mobile ? 272 : 180,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            file.bytes,
                            fit: BoxFit.cover,
                            alignment: Alignment(
                              (device == PreviewDevice.mobile
                                      ? mobileFocal
                                      : desktopFocal)
                                  .dx,
                              (device == PreviewDevice.mobile
                                      ? mobileFocal
                                      : desktopFocal)
                                  .dy,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_cropFraction(file, device) < .60)
                      const Text(
                        'Large crop: check that your main subject remains visible.',
                        style: TextStyle(color: Color(0xFFB95420)),
                      ),
                    for (final horizontal in [true, false])
                      Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(horizontal ? 'Horizontal' : 'Vertical'),
                          ),
                          Expanded(
                            child: Slider(
                              value: horizontal
                                  ? (device == PreviewDevice.mobile
                                        ? mobileFocal.dx
                                        : desktopFocal.dx)
                                  : (device == PreviewDevice.mobile
                                        ? mobileFocal.dy
                                        : desktopFocal.dy),
                              min: -1,
                              max: 1,
                              onChanged: (v) => refresh(() {
                                if (device == PreviewDevice.mobile) {
                                  mobileFocal = horizontal
                                      ? Offset(v, mobileFocal.dy)
                                      : Offset(mobileFocal.dx, v);
                                } else {
                                  desktopFocal = horizontal
                                      ? Offset(v, desktopFocal.dy)
                                      : Offset(desktopFocal.dx, v);
                                }
                              }),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Use background'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !mounted) return;
    final old = widget.draft.myBackground;
    widget.draft.setMyBackground(file);
    widget.draft.setMyFocalPoint(PreviewDevice.mobile, mobileFocal);
    widget.draft.setMyFocalPoint(PreviewDevice.desktop, desktopFocal);
    if (old != null) MemoryImage(old.bytes).evict();
  }

  double _cropFraction(MyAmbienceFile file, PreviewDevice device) {
    final size = MyDecorationGeometry.frame(device);
    final imageRatio = file.width / file.height;
    final frameRatio = size.width / size.height;
    return imageRatio > frameRatio
        ? frameRatio / imageRatio
        : imageRatio / frameRatio;
  }

  Widget _myFilesControls() {
    final draft = widget.draft;
    final background = draft.myBackground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Local-only draft: your own files disappear when you close the app. They are not uploaded to Supabase, and onboarding cannot be completed with them yet.',
          style: TextStyle(
            color: Color(0xFFFFD27C),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              key: const ValueKey('my-upload-background'),
              onPressed: _chooseMyBackground,
              icon: const Icon(Icons.wallpaper_rounded),
              label: Text(
                background == null ? 'Add background' : 'Replace background',
              ),
            ),
            if (background != null)
              OutlinedButton.icon(
                key: const ValueKey('my-remove-background'),
                onPressed: () {
                  draft.setMyBackground(null);
                  MemoryImage(background.bytes).evict();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove background'),
              ),
          ],
        ),
        if (background != null) ...[
          const SizedBox(height: 8),
          Text(
            '${background.name} · ${background.width} × ${background.height}',
            style: const TextStyle(color: Colors.white70),
          ),
          const Text(
            'Focal point for each view (actual crop shown in the preview below):',
            style: TextStyle(color: Colors.white70),
          ),
          for (final device in PreviewDevice.values) ...[
            Text(
              device.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            for (final horizontal in [true, false])
              Row(
                children: [
                  SizedBox(
                    width: 68,
                    child: Text(
                      horizontal ? 'Horizontal' : 'Vertical',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      key: ValueKey(
                        'my-focal-${device.name}-${horizontal ? 'x' : 'y'}',
                      ),
                      value: horizontal
                          ? draft.myFocalPoints[device]!.dx
                          : draft.myFocalPoints[device]!.dy,
                      min: -1,
                      max: 1,
                      onChanged: (v) {
                        final point = draft.myFocalPoints[device]!;
                        draft.setMyFocalPoint(
                          device,
                          horizontal
                              ? Offset(v, point.dy)
                              : Offset(point.dx, v),
                        );
                      },
                    ),
                  ),
                ],
              ),
            if (_cropFraction(background, device) < .60)
              const Text(
                'Large crop — inspect this view before continuing.',
                style: TextStyle(color: Color(0xFFFFD27C)),
              ),
          ],
        ],
        const SizedBox(height: 12),
        Text(
          'Decorative elements · ${draft.myElements.length}/5',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'PNG or WebP with transparent pixels, up to 2 MB and 2048 px per side.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          key: const ValueKey('my-add-element'),
          onPressed: draft.myElements.length >= 5
              ? null
              : () async {
                  final file = await _pickMyFile(element: true);
                  if (file != null) draft.addMyElement(file);
                },
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add element'),
        ),
        for (final entry in draft.myElements.entries)
          Card(
            child: ListTile(
              leading: Image.memory(
                entry.value.bytes,
                width: 42,
                height: 42,
                fit: BoxFit.contain,
              ),
              title: Text(
                entry.value.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${entry.value.width} × ${entry.value.height}'),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Replace element',
                    onPressed: () async {
                      final file = await _pickMyFile(element: true);
                      if (file != null) {
                        draft.replaceMyElement(entry.key, file);
                        MemoryImage(entry.value.bytes).evict();
                      }
                    },
                    icon: const Icon(Icons.swap_horiz_rounded),
                  ),
                  IconButton(
                    tooltip: 'Remove element',
                    onPressed: () {
                      draft.removeMyElement(entry.key);
                      MemoryImage(entry.value.bytes).evict();
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        if (_myFileError != null)
          Text(
            _myFileError!,
            key: const ValueKey('my-file-error'),
            style: const TextStyle(
              color: Color(0xFFFF8B95),
              fontWeight: FontWeight.bold,
            ),
          ),
        Text(
          'Approximate loaded image memory: ${(draft.myApproximateMemoryBytes / 1048576).toStringAsFixed(1)} MB (compressed + decoded; cache may add more).',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const Text(
          'Background: PNG, JPG or WebP · 5 MB · 180–4096 px per side. Static images only.',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _intensityControl(
    String label,
    String key,
    int value,
    ValueChanged<double> onChanged,
  ) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$value%',
            key: ValueKey('$key-intensity-value'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      Slider(
        key: ValueKey('$key-intensity-slider'),
        value: value.toDouble(),
        min: 0,
        max: 100,
        divisions: 100,
        label: '$value%',
        onChanged: onChanged,
      ),
    ],
  );

  Widget _ambienceCard(InstitutionAmbience ambience, Duration duration) {
    final selected = widget.draft.ambience == ambience;
    final label = switch (ambience) {
      InstitutionAmbience.none => 'None',
      InstitutionAmbience.space => 'Space',
      InstitutionAmbience.animals => 'Animals',
      InstitutionAmbience.ocean => 'Ocean',
      InstitutionAmbience.nature => 'Nature',
      InstitutionAmbience.fantasy => 'Fantasy',
      InstitutionAmbience.my => 'My ambience',
    };
    return InkWell(
      key: ValueKey('ambience-$label'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => widget.draft.update(() => widget.draft.ambience = ambience),
      child: AnimatedContainer(
        duration: duration,
        height: 112,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF171C38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? widget.draft.primary : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ambience == InstitutionAmbience.ocean
                    ? Image.asset(
                        InstitutionOceanAmbience.thumbnail,
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                      )
                    : ambience == InstitutionAmbience.space
                    ? Image.asset(
                        InstitutionSpaceAssets.background,
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                      )
                    : ambience == InstitutionAmbience.animals
                    ? Image.asset(
                        InstitutionAnimalsAssets.background,
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                      )
                    : ambience == InstitutionAmbience.nature
                    ? Image.asset(
                        InstitutionNatureAssets.background,
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                      )
                    : ambience == InstitutionAmbience.fantasy
                    ? Image.asset(
                        InstitutionFantasyAssets.background,
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                      )
                    : ambience == InstitutionAmbience.my &&
                          widget.draft.myBackground != null
                    ? Image.memory(
                        widget.draft.myBackground!.bytes,
                        fit: BoxFit.cover,
                      )
                    : InstitutionAmbienceLayer(
                        ambience: ambience,
                        intensityPercent: 65,
                        primary: widget.draft.primary,
                        secondary: widget.draft.secondary,
                        accent: widget.draft.accent,
                        dark: true,
                      ),
              ),
            ),
            if (ambience == InstitutionAmbience.ocean ||
                ambience == InstitutionAmbience.space ||
                ambience == InstitutionAmbience.animals ||
                ambience == InstitutionAmbience.nature ||
                ambience == InstitutionAmbience.fantasy)
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xBB06172A)],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? widget.draft.accent : Colors.white38,
                    size: 19,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _oceanVariantCard(OceanVariant variant) {
    final selected =
        widget.draft.oceanVariant == variant &&
        !widget.draft.oceanPreviewBySection;
    final label = switch (variant) {
      OceanVariant.turtleReef => 'Turtle Reef',
      OceanVariant.sharkReef => 'Shark Reef',
      OceanVariant.jellyfishGarden => 'Jellyfish Garden',
    };
    return InkWell(
      key: ValueKey('ocean-variant-${variant.name}'),
      onTap: () => widget.draft.update(() {
        widget.draft.oceanVariant = variant;
        widget.draft.oceanPreviewBySection = false;
      }),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 94,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF08324E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? widget.draft.accent : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                InstitutionOceanAmbience.seascape,
                fit: BoxFit.cover,
                cacheWidth: 420,
              ),
            ),
            Positioned(
              left: variant == OceanVariant.sharkReef ? null : -9,
              right: variant == OceanVariant.sharkReef ? -9 : null,
              bottom: -12,
              width: 85,
              child: Image.asset(
                variant == OceanVariant.sharkReef
                    ? InstitutionOceanAmbience.sharkCoral
                    : InstitutionOceanAmbience.coral,
                cacheWidth: 130,
              ),
            ),
            Positioned(
              right: 8,
              top: 4,
              bottom: 12,
              child: Image.asset(
                InstitutionOceanAmbience.characterAsset(variant),
                fit: BoxFit.contain,
                cacheWidth: 180,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDA032036)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: widget.draft.accent,
                      size: 17,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _oceanSectionChoices() {
    final sections = switch (widget.draft.role) {
      PreviewRole.student => InstitutionTemplatePreview.studentNavigation,
      PreviewRole.teacher => InstitutionTemplatePreview.teacherNavigation,
      PreviewRole.admin => InstitutionTemplatePreview.adminNavigation,
    };
    final selected = widget.draft.previewSectionIndex.clamp(
      0,
      sections.length - 1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo section',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 43,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) => ChoiceChip(
              key: ValueKey('ocean-section-$index'),
              label: Text(sections[index]),
              selected: selected == index,
              onSelected: (_) => widget.draft.update(
                () => widget.draft.previewSectionIndex = index,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _natureVariantCard(NatureVariant variant) {
    final selected =
        widget.draft.natureVariant == variant &&
        !widget.draft.naturePreviewBySection;
    final label = switch (variant) {
      NatureVariant.ancientGrove => 'Ancient Grove',
      NatureVariant.alpineVista => 'Alpine Vista',
      NatureVariant.waterfallHaven => 'Waterfall Haven',
    };
    return InkWell(
      key: ValueKey('nature-variant-${variant.name}'),
      onTap: () => widget.draft.update(() {
        widget.draft.natureVariant = variant;
        widget.draft.naturePreviewBySection = false;
      }),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 94,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF101B3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? widget.draft.accent : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                InstitutionNatureAssets.background,
                fit: BoxFit.cover,
                cacheWidth: 420,
              ),
            ),
            Positioned(
              right: 7,
              top: 3,
              bottom: 13,
              child: Image.asset(
                InstitutionNatureAssets.hero(variant),
                fit: BoxFit.contain,
                cacheWidth: 180,
              ),
            ),
            Positioned(
              left: 10,
              top: 22,
              width: 54,
              height: 42,
              child: Image.asset(
                InstitutionNatureAssets.songbirds,
                fit: BoxFit.contain,
                cacheWidth: 100,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xD8071029)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: widget.draft.accent,
                      size: 17,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _natureSectionChoices() {
    final sections = switch (widget.draft.role) {
      PreviewRole.student => InstitutionTemplatePreview.studentNavigation,
      PreviewRole.teacher => InstitutionTemplatePreview.teacherNavigation,
      PreviewRole.admin => InstitutionTemplatePreview.adminNavigation,
    };
    final selected = widget.draft.previewSectionIndex.clamp(
      0,
      sections.length - 1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo section',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 43,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) => ChoiceChip(
              key: ValueKey('nature-section-$index'),
              label: Text(sections[index]),
              selected: selected == index,
              onSelected: (_) => widget.draft.update(
                () => widget.draft.previewSectionIndex = index,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fantasyVariantCard(FantasyVariant variant) {
    final selected =
        widget.draft.fantasyVariant == variant &&
        !widget.draft.fantasyPreviewBySection;
    final label = switch (variant) {
      FantasyVariant.floatingCastle => 'Floating Castle',
      FantasyVariant.enchantedLibrary => 'Enchanted Library',
      FantasyVariant.dragonGarden => 'Dragon Garden',
    };
    return InkWell(
      key: ValueKey('fantasy-variant-${variant.name}'),
      onTap: () => widget.draft.update(() {
        widget.draft.fantasyVariant = variant;
        widget.draft.fantasyPreviewBySection = false;
      }),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 94,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF101B3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? widget.draft.accent : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                InstitutionFantasyAssets.background,
                fit: BoxFit.cover,
                cacheWidth: 420,
              ),
            ),
            Positioned(
              right: 7,
              top: 3,
              bottom: 13,
              child: Image.asset(
                InstitutionFantasyAssets.hero(variant),
                fit: BoxFit.contain,
                cacheWidth: 180,
              ),
            ),
            Positioned(
              left: 10,
              top: 22,
              width: 54,
              height: 42,
              child: Image.asset(
                InstitutionFantasyAssets.fireflies,
                fit: BoxFit.contain,
                cacheWidth: 100,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xD8071029)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: widget.draft.accent,
                      size: 17,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fantasySectionChoices() {
    final sections = switch (widget.draft.role) {
      PreviewRole.student => InstitutionTemplatePreview.studentNavigation,
      PreviewRole.teacher => InstitutionTemplatePreview.teacherNavigation,
      PreviewRole.admin => InstitutionTemplatePreview.adminNavigation,
    };
    final selected = widget.draft.previewSectionIndex.clamp(
      0,
      sections.length - 1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo section',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 43,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) => ChoiceChip(
              key: ValueKey('fantasy-section-$index'),
              label: Text(sections[index]),
              selected: selected == index,
              onSelected: (_) => widget.draft.update(
                () => widget.draft.previewSectionIndex = index,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _animalsVariantCard(AnimalsVariant variant) {
    final selected =
        widget.draft.animalsVariant == variant &&
        !widget.draft.animalsPreviewBySection;
    final label = switch (variant) {
      AnimalsVariant.foxGrove => 'Fox Grove',
      AnimalsVariant.deerMeadow => 'Deer Meadow',
      AnimalsVariant.owlCanopy => 'Owl Canopy',
    };
    return InkWell(
      key: ValueKey('animals-variant-${variant.name}'),
      onTap: () => widget.draft.update(() {
        widget.draft.animalsVariant = variant;
        widget.draft.animalsPreviewBySection = false;
      }),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 94,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF101B3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? widget.draft.accent : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                InstitutionAnimalsAssets.background,
                fit: BoxFit.cover,
                cacheWidth: 420,
              ),
            ),
            Positioned(
              right: 7,
              top: 3,
              bottom: 13,
              child: Image.asset(
                InstitutionAnimalsAssets.hero(variant),
                fit: BoxFit.contain,
                cacheWidth: 180,
              ),
            ),
            Positioned(
              left: 10,
              top: 22,
              width: 54,
              height: 42,
              child: Image.asset(
                InstitutionAnimalsAssets.butterflies,
                fit: BoxFit.contain,
                cacheWidth: 100,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xD8071029)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: widget.draft.accent,
                      size: 17,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animalsSectionChoices() {
    final sections = switch (widget.draft.role) {
      PreviewRole.student => InstitutionTemplatePreview.studentNavigation,
      PreviewRole.teacher => InstitutionTemplatePreview.teacherNavigation,
      PreviewRole.admin => InstitutionTemplatePreview.adminNavigation,
    };
    final selected = widget.draft.previewSectionIndex.clamp(
      0,
      sections.length - 1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo section',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 43,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) => ChoiceChip(
              key: ValueKey('animals-section-$index'),
              label: Text(sections[index]),
              selected: selected == index,
              onSelected: (_) => widget.draft.update(
                () => widget.draft.previewSectionIndex = index,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _spaceVariantCard(SpaceVariant variant) {
    final selected =
        widget.draft.spaceVariant == variant &&
        !widget.draft.spacePreviewBySection;
    final label = switch (variant) {
      SpaceVariant.planetExploration => 'Planet Exploration',
      SpaceVariant.orbitalStation => 'Orbital Station',
      SpaceVariant.asteroidExpedition => 'Asteroid Expedition',
    };
    return InkWell(
      key: ValueKey('space-variant-${variant.name}'),
      onTap: () => widget.draft.update(() {
        widget.draft.spaceVariant = variant;
        widget.draft.spacePreviewBySection = false;
      }),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 94,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF101B3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? widget.draft.accent : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                InstitutionSpaceAssets.background,
                fit: BoxFit.cover,
                cacheWidth: 420,
              ),
            ),
            Positioned(
              right: 7,
              top: 3,
              bottom: 13,
              child: Image.asset(
                InstitutionSpaceAssets.hero(variant),
                fit: BoxFit.contain,
                cacheWidth: 180,
              ),
            ),
            Positioned(
              left: 10,
              top: 22,
              width: 54,
              height: 42,
              child: Image.asset(
                InstitutionSpaceAssets.ship,
                fit: BoxFit.contain,
                cacheWidth: 100,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xD8071029)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: widget.draft.accent,
                      size: 17,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spaceSectionChoices() {
    final sections = switch (widget.draft.role) {
      PreviewRole.student => InstitutionTemplatePreview.studentNavigation,
      PreviewRole.teacher => InstitutionTemplatePreview.teacherNavigation,
      PreviewRole.admin => InstitutionTemplatePreview.adminNavigation,
    };
    final selected = widget.draft.previewSectionIndex.clamp(
      0,
      sections.length - 1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo section',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 43,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) => ChoiceChip(
              key: ValueKey('space-section-$index'),
              label: Text(sections[index]),
              selected: selected == index,
              onSelected: (_) => widget.draft.update(
                () => widget.draft.previewSectionIndex = index,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _colors() => SingleChildScrollView(
    key: const ValueKey('colors-editor'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Curated palettes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            key: const ValueKey('palette-list'),
            scrollDirection: Axis.horizontal,
            itemCount: institutionPalettes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _paletteCard(institutionPalettes[index], index),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) {
            const gap = 12.0;
            final columns = box.maxWidth >= 640 ? 2 : 1;
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final slot in InstitutionColorSlot.values)
                  SizedBox(
                    width: width,
                    child: _colorControl(
                      slot.name[0].toUpperCase() + slot.name.substring(1),
                      slot,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _contrastSummary(),
      ],
    ),
  );

  Widget _paletteCard(InstitutionPalette palette, int index) {
    final selected =
        widget.draft.primary == palette.primary &&
        widget.draft.secondary == palette.secondary &&
        widget.draft.accent == palette.accent &&
        widget.draft.background == palette.background &&
        InstitutionColorSlot.values.every(
          (slot) => widget.draft.transparencyFor(slot) == 0,
        );
    return InkWell(
      key: ValueKey('palette-$index'),
      onTap: () => widget.draft.applyPalette(palette),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 136,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (final color in [
                  palette.primary,
                  palette.secondary,
                  palette.accent,
                ])
                  Expanded(child: Container(height: 34, color: color)),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              palette.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _bestText(palette.background),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorControl(String label, InstitutionColorSlot slot) {
    final color = widget.draft.colorFor(slot);
    final hsl = widget.draft.hslFor(slot);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xA0111934),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                key: ValueKey('color-picker-$label'),
                onTap: () => _showColorPicker(
                  label,
                  color,
                  (value) => widget.draft.setColor(slot, value),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white54, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(painter: _TransparencyCheckerPainter()),
                      ColoredBox(color: widget.draft.surfaceColor(slot)),
                      Icon(
                        Icons.colorize_rounded,
                        color: _bestText(color),
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextFormField(
                  key: ValueKey('hex-$label-${color.toARGB32()}'),
                  initialValue: _hex(color),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) =>
                      _parseHex(value) == null ? 'Use #RRGGBB' : null,
                  onFieldSubmitted: (value) {
                    final parsed = _parseHex(value);
                    if (parsed != null) widget.draft.setColor(slot, parsed);
                  },
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF11172F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _colorAxis(
            label: 'Saturation',
            key: 'color-saturation-$label',
            value: hsl.saturation,
            color: color,
            onChanged: (value) => widget.draft.setColorSaturation(slot, value),
          ),
          _colorAxis(
            label: 'Lightness',
            key: 'color-lightness-$label',
            value: hsl.lightness,
            color: color,
            onChanged: (value) => widget.draft.setColorLightness(slot, value),
          ),
          _colorAxis(
            label: 'Transparency',
            key: 'color-transparency-$label',
            value: widget.draft.transparencyFor(slot) / 100,
            color: color,
            onChanged: (value) =>
                widget.draft.setTransparency(slot, value * 100),
          ),
        ],
      ),
    );
  }

  Widget _colorAxis({
    required String label,
    required String key,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) => Row(
    children: [
      SizedBox(
        width: 92,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ),
      Expanded(
        child: Slider(
          key: ValueKey(key),
          value: value.clamp(0, 1),
          min: 0,
          max: 1,
          divisions: 100,
          activeColor: color,
          label: '${(value * 100).round()}%',
          onChanged: onChanged,
        ),
      ),
      SizedBox(
        width: 40,
        child: Text(
          '${(value * 100).round()}%',
          key: ValueKey('$key-value'),
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          textAlign: TextAlign.end,
        ),
      ),
    ],
  );

  Future<void> _showColorPicker(
    String label,
    Color initial,
    ValueChanged<Color> setter,
  ) async {
    var selected = initial;
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int component(int shift) => (selected.toARGB32() >> shift) & 0xFF;
          Widget channel(String name, int value, void Function(int) set) => Row(
            children: [
              SizedBox(width: 22, child: Text(name)),
              Expanded(
                child: Slider(
                  value: value.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  activeColor: selected,
                  onChanged: (v) => setDialogState(() => set(v.round())),
                ),
              ),
              SizedBox(
                width: 34,
                child: Text('$value', textAlign: TextAlign.end),
              ),
            ],
          );
          return AlertDialog(
            title: Text('Choose $label'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: selected,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 14),
                  channel(
                    'R',
                    component(16),
                    (v) => selected = Color.fromARGB(
                      255,
                      v,
                      component(8),
                      component(0),
                    ),
                  ),
                  channel(
                    'G',
                    component(8),
                    (v) => selected = Color.fromARGB(
                      255,
                      component(16),
                      v,
                      component(0),
                    ),
                  ),
                  channel(
                    'B',
                    component(0),
                    (v) => selected = Color.fromARGB(
                      255,
                      component(16),
                      component(8),
                      v,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hex(selected),
                    style: const TextStyle(
                      fontFamily: 'Space Mono',
                      fontWeight: FontWeight.bold,
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
              FilledButton(
                onPressed: () => Navigator.pop(context, selected),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
    if (result != null) setter(result);
  }

  Widget _contrastSummary() {
    final draft = widget.draft;
    final backgrounds = _visibleBackgroundSamples();
    double worstText(InstitutionColorSlot slot, Color text) => backgrounds
        .map(
          (backdrop) => _contrast(
            Color.alphaBlend(draft.surfaceColor(slot), backdrop),
            text,
          ),
        )
        .reduce((a, b) => a < b ? a : b);
    final surfaceRatio = backgrounds
        .map(
          (backdrop) => _contrast(
            backdrop,
            draft.backgroundIsDark ? Colors.white : const Color(0xFF172033),
          ),
        )
        .reduce((a, b) => a < b ? a : b);
    final buttonRatio = worstText(
      InstitutionColorSlot.primary,
      _bestText(draft.primary),
    );
    double worstAccent(InstitutionColorSlot slot) => backgrounds
        .map((backdrop) => _contrast(draft.colorFor(slot), backdrop))
        .reduce((a, b) => a < b ? a : b);
    final warnings = <String>[
      if (surfaceRatio < 4.5)
        'Background text ${surfaceRatio.toStringAsFixed(1)}:1',
      if (buttonRatio < 4.5)
        'Primary button ${buttonRatio.toStringAsFixed(1)}:1',
      if (worstAccent(InstitutionColorSlot.primary) < 4.5)
        'Primary on Background ${worstAccent(InstitutionColorSlot.primary).toStringAsFixed(1)}:1',
      for (final slot in [
        InstitutionColorSlot.secondary,
        InstitutionColorSlot.accent,
      ])
        if (worstText(slot, _bestText(draft.colorFor(slot))) < 4.5)
          '${slot.name} surface ${worstText(slot, _bestText(draft.colorFor(slot))).toStringAsFixed(1)}:1',
    ];
    final pass = warnings.isEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pass ? const Color(0x1A169B62) : const Color(0x24D9435F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pass
              ? InstitutionBrandDraft.success
              : InstitutionBrandDraft.error,
        ),
      ),
      child: Row(
        children: [
          Icon(
            pass ? Icons.verified_outlined : Icons.warning_amber_rounded,
            color: pass
                ? InstitutionBrandDraft.success
                : InstitutionBrandDraft.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pass
                  ? (draft.ambience != InstitutionAmbience.none &&
                            InstitutionColorSlot.values.any(
                              (slot) => draft.transparencyFor(slot) > 0,
                            )
                        ? 'Sampled composite contrast meets 4.5:1. Illustration brightness varies; review text over the full scene.'
                        : 'Preview text and color accents meet 4.5:1 contrast.')
                  : 'Low contrast: ${warnings.join(', ')} after compositing visible layers. Illustrated areas vary by pixel; your colors are kept.',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          for (final semantic in [
            InstitutionBrandDraft.success,
            InstitutionBrandDraft.warning,
            InstitutionBrandDraft.error,
          ])
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: semantic,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Color> _visibleBackgroundSamples() {
    final draft = widget.draft;
    final base = draft.backgroundIsDark
        ? const Color(0xFF111327)
        : const Color(0xFFF3F0E9);
    // Samples measured from the bundled backdrops at 25%/25% and 75%/75%.
    // Test the composite at both points because the illustration varies.
    final images = switch (draft.ambience) {
      InstitutionAmbience.ocean => [
        const Color(0xFF0C98C8),
        const Color(0xFF034A76),
      ],
      InstitutionAmbience.space => [
        const Color(0xFF06223E),
        const Color(0xFF112744),
      ],
      InstitutionAmbience.animals => [
        const Color(0xFFFEF8DB),
        const Color(0xFFB5AC46),
      ],
      InstitutionAmbience.nature => [
        const Color(0xFFD19B72),
        const Color(0xFFCEA523),
      ],
      InstitutionAmbience.fantasy => [
        const Color(0xFF6D639C),
        const Color(0xFF454E67),
      ],
      InstitutionAmbience.my => [base],
      InstitutionAmbience.none => [base],
    };
    final tintStrength = switch (draft.ambience) {
      InstitutionAmbience.ocean => draft.backgroundIsDark ? .52 : .80,
      InstitutionAmbience.space => draft.backgroundIsDark ? .48 : .76,
      InstitutionAmbience.animals => draft.backgroundIsDark ? .38 : .67,
      InstitutionAmbience.nature ||
      InstitutionAmbience.fantasy => draft.backgroundIsDark ? .48 : .70,
      InstitutionAmbience.my => draft.backgroundIsDark ? .40 : .64,
      InstitutionAmbience.none => 0.0,
    };
    final opacity =
        1 - draft.transparencyFor(InstitutionColorSlot.background) / 100;
    if (draft.ambience == InstitutionAmbience.none) {
      return [
        Color.alphaBlend(draft.background.withValues(alpha: opacity), base),
      ];
    }
    return [
      for (final image in images)
        Color.alphaBlend(
          draft.background.withValues(alpha: opacity * tintStrength),
          Color.alphaBlend(
            image.withValues(alpha: draft.backgroundIntensity / 100),
            Color.alphaBlend(draft.background.withValues(alpha: opacity), base),
          ),
        ),
    ];
  }

  Widget _typography(Duration duration) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Bundled OFL fonts · Available offline',
          style: TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 12),
        for (final font in InstitutionFont.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _fontCard(font, duration),
          ),
      ],
    ),
  );

  Widget _fontCard(InstitutionFont font, Duration duration) {
    final label = switch (font) {
      InstitutionFont.inter => 'Inter Sans',
      InstitutionFont.lora => 'Lora Serif',
      InstitutionFont.spaceMono => 'Space Mono',
      InstitutionFont.nunito => 'Nunito Rounded',
      InstitutionFont.fredoka => 'Fredoka Playful',
      InstitutionFont.playfairDisplay => 'Playfair Display',
      InstitutionFont.poppins => 'Poppins Modern',
      InstitutionFont.quicksand => 'Quicksand Friendly',
      InstitutionFont.montserrat => 'Montserrat Professional',
      InstitutionFont.bitter => 'Bitter Editorial',
    };
    final family = switch (font) {
      InstitutionFont.inter => 'Inter',
      InstitutionFont.lora => 'Lora',
      InstitutionFont.spaceMono => 'Space Mono',
      InstitutionFont.nunito => 'Nunito',
      InstitutionFont.fredoka => 'Fredoka',
      InstitutionFont.playfairDisplay => 'Playfair Display',
      InstitutionFont.poppins => 'Poppins',
      InstitutionFont.quicksand => 'Quicksand',
      InstitutionFont.montserrat => 'Montserrat',
      InstitutionFont.bitter => 'Bitter',
    };
    final description = switch (font) {
      InstitutionFont.inter => 'Neutral, highly readable and versatile',
      InstitutionFont.lora => 'Editorial warmth with clear serif forms',
      InstitutionFont.spaceMono => 'Technical rhythm and distinctive numerals',
      InstitutionFont.nunito => 'Rounded, welcoming and easy to scan',
      InstitutionFont.fredoka => 'Playful display forms for younger learners',
      InstitutionFont.playfairDisplay =>
        'Refined editorial contrast for headings',
      InstitutionFont.poppins => 'Geometric and modern with a clean rhythm',
      InstitutionFont.quicksand =>
        'Friendly rounded terminals and open spacing',
      InstitutionFont.montserrat => 'Professional, confident and contemporary',
      InstitutionFont.bitter => 'Readable slab serif with editorial character',
    };
    final selected = widget.draft.font == font;
    return InkWell(
      key: ValueKey('font-$label'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => widget.draft.update(() => widget.draft.font = font),
      child: AnimatedContainer(
        duration: duration,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected
              ? widget.draft.primary.withValues(alpha: .20)
              : const Color(0xFF171C38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? widget.draft.primary : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: family,
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: family,
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aa Bb Cc · 0123456789 · Español: áéíóú ñ ¿Qué?',
                    key: ValueKey('font-sample-${font.name}'),
                    style: TextStyle(
                      fontFamily: family,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? widget.draft.accent : Colors.white30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buttons(Duration duration) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Shape',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _choiceWrap<InstitutionButtonShape>(
          InstitutionButtonShape.values,
          widget.draft.buttonShape,
          (value) =>
              widget.draft.update(() => widget.draft.buttonShape = value),
          (value) => switch (value) {
            InstitutionButtonShape.square => 'Square',
            InstitutionButtonShape.soft => 'Soft',
            InstitutionButtonShape.rounded => 'Rounded',
            InstitutionButtonShape.pill => 'Pill',
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Finish',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _choiceWrap<InstitutionButtonFinish>(
          InstitutionButtonFinish.values,
          widget.draft.buttonFinish,
          (value) =>
              widget.draft.update(() => widget.draft.buttonFinish = value),
          (value) => switch (value) {
            InstitutionButtonFinish.solid => 'Solid',
            InstitutionButtonFinish.outlined => 'Outlined',
            InstitutionButtonFinish.tonal => 'Tonal',
            InstitutionButtonFinish.gradient => 'Gradient',
            InstitutionButtonFinish.elevated => 'Elevated',
          },
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 14,
          children: [
            _buttonStateExample('Normal', ButtonVisualState.normal),
            _buttonStateExample('Pressed', ButtonVisualState.pressed),
            _buttonStateExample('Disabled', ButtonVisualState.disabled),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Minimum 44 px touch target · visible keyboard focus in live implementations',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    ),
  );

  Widget _choiceWrap<T>(
    List<T> values,
    T selected,
    ValueChanged<T> set,
    String Function(T) label,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final value in values)
        ChoiceChip(
          label: Text(label(value)),
          selected: selected == value,
          onSelected: (_) => set(value),
        ),
    ],
  );

  Widget _buttonStateExample(String label, ButtonVisualState state) {
    final disabled = state == ButtonVisualState.disabled;
    final pressed = state == ButtonVisualState.pressed;
    final finish = widget.draft.buttonFinish;
    final textColor = finish == InstitutionButtonFinish.outlined
        ? widget.draft.primary
        : finish == InstitutionButtonFinish.tonal
        ? Colors.white
        : _bestText(widget.draft.primary);
    final background = switch (finish) {
      InstitutionButtonFinish.outlined => Colors.transparent,
      InstitutionButtonFinish.tonal => widget.draft.primary.withValues(
        alpha: .22,
      ),
      _ => widget.draft.primary,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 7),
        Transform.translate(
          offset: pressed && finish == InstitutionButtonFinish.elevated
              ? const Offset(0, 4)
              : Offset.zero,
          child: Container(
            constraints: const BoxConstraints(minWidth: 150, minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: finish == InstitutionButtonFinish.gradient
                  ? null
                  : background.withValues(alpha: disabled ? .35 : 1),
              gradient: finish == InstitutionButtonFinish.gradient
                  ? LinearGradient(
                      colors: [
                        widget.draft.primary.withValues(
                          alpha: disabled ? .35 : 1,
                        ),
                        widget.draft.secondary.withValues(
                          alpha: disabled ? .35 : 1,
                        ),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(widget.draft.buttonRadius),
              border: finish == InstitutionButtonFinish.outlined
                  ? Border.all(
                      color: widget.draft.primary.withValues(
                        alpha: disabled ? .35 : 1,
                      ),
                      width: 2,
                    )
                  : Border.all(
                      color: pressed ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
              boxShadow:
                  finish == InstitutionButtonFinish.elevated &&
                      !pressed &&
                      !disabled
                  ? [
                      BoxShadow(
                        color: widget.draft.primary.withValues(alpha: .38),
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              'Continue learning',
              style: TextStyle(
                fontFamily: widget.draft.fontFamily,
                color: textColor.withValues(alpha: disabled ? .45 : 1),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _animations(Duration selectorDuration, bool reduced) =>
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth >= 760
                    ? 3
                    : box.maxWidth >= 440
                    ? 2
                    : 1;
                const gap = 10.0;
                final width = (box.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final motion in InstitutionMotion.values)
                      SizedBox(
                        width: width,
                        child: _motionCard(motion, selectorDuration),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _motionDemo(reduced),
          ],
        ),
      );

  Widget _motionCard(InstitutionMotion motion, Duration duration) {
    final selected = widget.draft.motion == motion;
    final meta = _motionMeta(motion);
    return InkWell(
      key: ValueKey('motion-${motion.name}'),
      onTap: () => widget.draft.update(() => widget.draft.motion = motion),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: duration,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? widget.draft.primary.withValues(alpha: .20)
              : const Color(0xFF171C38),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? widget.draft.primary : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              meta.$3,
              color: selected ? widget.draft.accent : Colors.white54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    meta.$2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: selected ? widget.draft.accent : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _motionDemo(bool reduced) {
    final duration = widget.draft.motionDuration(reduced: reduced);
    return Container(
      key: const ValueKey('motion-demo'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10162F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Interactive motion demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                reduced
                    ? 'Reduced motion active'
                    : _motionMeta(widget.draft.motion).$1,
                style: TextStyle(color: widget.draft.accent, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: AnimatedSwitcher(
              key: const ValueKey('motion-page-switcher'),
              duration: duration,
              switchInCurve: widget.draft.motionCurve(),
              switchOutCurve: widget.draft.motionCurve(entering: false),
              transitionBuilder: (child, animation) => _motionTransition(
                child,
                animation,
                widget.draft.motion,
                reduced,
              ),
              child: _buildMotionDemoPage(
                key: ValueKey('motion-demo-page-$_motionDemoPage'),
                page: _motionDemoPage,
                reduced: reduced,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const ValueKey('preview-page-transition'),
                onPressed: () => setState(() => _motionDemoPage++),
                icon: const Icon(Icons.slideshow_rounded),
                label: const Text('Preview page transition'),
              ),
              _motionTestButton(reduced),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMotionDemoPage({
    required Key key,
    required int page,
    required bool reduced,
  }) => Row(
    key: key,
    children: [
      for (var index = 0; index < 3; index++) ...[
        Expanded(
          child: _motionDemoCard(index: index, page: page, reduced: reduced),
        ),
        if (index < 2) const SizedBox(width: 8),
      ],
    ],
  );

  Widget _motionDemoCard({
    required int index,
    required int page,
    required bool reduced,
  }) {
    final duration = widget.draft.motionDuration(reduced: reduced);
    final animationDuration = reduced || duration == Duration.zero
        ? Duration.zero
        : duration + Duration(milliseconds: index * 70);
    return TweenAnimationBuilder<double>(
      key: ValueKey('motion-card-$page-$index'),
      duration: animationDuration,
      curve: widget.draft.motionCurve(),
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      builder: (context, value, child) {
        final motion = widget.draft.motion;
        final scale = switch (motion) {
          InstitutionMotion.spring => .82 + (.18 * value),
          InstitutionMotion.depth => .92 + (.08 * value),
          InstitutionMotion.playful => .90 + (.10 * value),
          _ => 1.0,
        };
        final dx = motion == InstitutionMotion.slide
            ? (1 - value) * (18 + index * 7)
            : 0.0;
        final angle = motion == InstitutionMotion.playful
            ? (1 - value) * (index.isEven ? -.05 : .05)
            : 0.0;
        return Opacity(
          opacity: motion == InstitutionMotion.none ? 1 : value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(
              dx,
              motion == InstitutionMotion.depth ? (1 - value) * 8 : 0,
            ),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: index == page % 3
              ? widget.draft.primary
              : widget.draft.secondary.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(14),
          boxShadow: widget.draft.motion == InstitutionMotion.depth
              ? [
                  BoxShadow(
                    color: widget.draft.primary.withValues(alpha: .22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          ['Overview', 'Learning', 'Progress'][index],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: index == page % 3
                ? _bestText(widget.draft.primary)
                : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _motionTestButton(bool reduced) {
    final duration = widget.draft.motionDuration(reduced: reduced);
    final pressed = reduced ? false : _motionDemoPressed;
    final scale = pressed
        ? switch (widget.draft.motion) {
            InstitutionMotion.spring => .91,
            InstitutionMotion.depth => .96,
            InstitutionMotion.playful => .94,
            InstitutionMotion.soft => .98,
            InstitutionMotion.slide => .98,
            InstitutionMotion.none => 1.0,
          }
        : 1.0;
    final offset = pressed
        ? switch (widget.draft.motion) {
            InstitutionMotion.slide => const Offset(.025, .04),
            InstitutionMotion.depth => const Offset(0, .07),
            InstitutionMotion.playful => const Offset(0, -.05),
            _ => Offset.zero,
          }
        : Offset.zero;
    return GestureDetector(
      key: const ValueKey('test-motion-button'),
      onTapDown: (_) => setState(() => _motionDemoPressed = true),
      onTapUp: (_) => setState(() => _motionDemoPressed = false),
      onTapCancel: () => setState(() => _motionDemoPressed = false),
      child: AnimatedSlide(
        offset: offset,
        duration: duration,
        curve: widget.draft.motionCurve(),
        child: AnimatedScale(
          scale: scale,
          duration: duration,
          curve: widget.draft.motionCurve(),
          child: AnimatedRotation(
            turns: pressed && widget.draft.motion == InstitutionMotion.playful
                ? -.012
                : 0,
            duration: duration,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: widget.draft.primary,
                borderRadius: BorderRadius.circular(widget.draft.buttonRadius),
                boxShadow:
                    widget.draft.motion == InstitutionMotion.depth && !pressed
                    ? [
                        BoxShadow(
                          color: widget.draft.primary.withValues(alpha: .35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                'Test button',
                style: TextStyle(
                  fontFamily: widget.draft.fontFamily,
                  color: _bestText(widget.draft.primary),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _motionTransition(
    Widget child,
    Animation<double> animation,
    InstitutionMotion motion,
    bool reduced,
  ) {
    if (reduced || motion == InstitutionMotion.none) return child;
    final fade = FadeTransition(opacity: animation, child: child);
    return switch (motion) {
      InstitutionMotion.none => child,
      InstitutionMotion.soft => fade,
      InstitutionMotion.slide => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.045, 0),
          end: Offset.zero,
        ).animate(animation),
        child: fade,
      ),
      InstitutionMotion.spring => ScaleTransition(
        scale: Tween<double>(begin: .90, end: 1).animate(animation),
        child: fade,
      ),
      InstitutionMotion.depth => ScaleTransition(
        scale: Tween<double>(begin: .96, end: 1).animate(animation),
        child: fade,
      ),
      InstitutionMotion.playful => RotationTransition(
        turns: Tween<double>(begin: -.008, end: 0).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: .94, end: 1).animate(animation),
          child: fade,
        ),
      ),
    };
  }

  (String, String, IconData) _motionMeta(InstitutionMotion motion) =>
      switch (motion) {
        InstitutionMotion.none => (
          'None',
          'Immediate changes without motion',
          Icons.block_rounded,
        ),
        InstitutionMotion.soft => (
          'Soft',
          'Gentle fades and discreet presses',
          Icons.blur_on_rounded,
        ),
        InstitutionMotion.slide => (
          'Slide',
          'Short shifts and staged entrances',
          Icons.swipe_rounded,
        ),
        InstitutionMotion.spring => (
          'Spring',
          'Moderate bounce and elastic response',
          Icons.compress_rounded,
        ),
        InstitutionMotion.depth => (
          'Depth',
          'Subtle scale, elevation and layers',
          Icons.layers_rounded,
        ),
        InstitutionMotion.playful => (
          'Playful',
          'Small hops and friendly tilts',
          Icons.toys_rounded,
        ),
      };

  Widget _previewControls() => LayoutBuilder(
    builder: (context, box) => Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        if (widget.draft.ambience == InstitutionAmbience.ocean)
          FilterChip(
            key: const ValueKey('edit-ocean-decorations'),
            label: const Text('Edit decorations'),
            avatar: const Icon(Icons.open_with_rounded, size: 18),
            selected: widget.draft.editOceanDecorations,
            onSelected: (value) => widget.draft.update(() {
              widget.draft.editOceanDecorations = value;
              widget.draft.oceanPlacementClamped = false;
            }),
          ),
        if (widget.draft.ambience == InstitutionAmbience.space)
          FilterChip(
            key: const ValueKey('edit-space-decorations'),
            label: const Text('Edit decorations'),
            avatar: const Icon(Icons.open_with_rounded, size: 18),
            selected: widget.draft.editSpaceDecorations,
            onSelected: (value) => widget.draft.update(
              () => widget.draft.editSpaceDecorations = value,
            ),
          ),
        if (widget.draft.ambience == InstitutionAmbience.animals)
          FilterChip(
            key: const ValueKey('edit-animals-decorations'),
            label: const Text('Edit decorations'),
            avatar: const Icon(Icons.open_with_rounded, size: 18),
            selected: widget.draft.editAnimalsDecorations,
            onSelected: (value) => widget.draft.update(
              () => widget.draft.editAnimalsDecorations = value,
            ),
          ),
        if (widget.draft.ambience == InstitutionAmbience.nature)
          FilterChip(
            key: const ValueKey('edit-nature-decorations'),
            label: const Text('Edit decorations'),
            avatar: const Icon(Icons.open_with_rounded, size: 18),
            selected: widget.draft.editNatureDecorations,
            onSelected: (value) => widget.draft.update(
              () => widget.draft.editNatureDecorations = value,
            ),
          ),
        if (widget.draft.ambience == InstitutionAmbience.fantasy)
          FilterChip(
            key: const ValueKey('edit-fantasy-decorations'),
            label: const Text('Edit decorations'),
            avatar: const Icon(Icons.open_with_rounded, size: 18),
            selected: widget.draft.editFantasyDecorations,
            onSelected: (value) => widget.draft.update(
              () => widget.draft.editFantasyDecorations = value,
            ),
          ),
        if (widget.draft.ambience == InstitutionAmbience.my)
          FilterChip(
            key: const ValueKey('edit-my-decorations'),
            label: const Text('Edit decorations'),
            avatar: const Icon(Icons.open_with_rounded, size: 18),
            selected: widget.draft.editMyDecorations,
            onSelected: (value) => widget.draft.update(
              () => widget.draft.editMyDecorations = value,
            ),
          ),
        SegmentedButton<PreviewRole>(
          segments: const [
            ButtonSegment(
              value: PreviewRole.student,
              label: Text('Student'),
              icon: Icon(Icons.person_outline),
            ),
            ButtonSegment(
              value: PreviewRole.teacher,
              label: Text('Teacher'),
              icon: Icon(Icons.school_outlined),
            ),
            ButtonSegment(
              value: PreviewRole.admin,
              label: Text('Admin'),
              icon: Icon(Icons.admin_panel_settings_outlined),
            ),
          ],
          selected: {widget.draft.role},
          onSelectionChanged: (value) =>
              widget.draft.update(() => widget.draft.role = value.first),
        ),
        SegmentedButton<PreviewDevice>(
          segments: const [
            ButtonSegment(
              value: PreviewDevice.mobile,
              label: Text('Mobile'),
              icon: Icon(Icons.phone_iphone),
            ),
            ButtonSegment(
              value: PreviewDevice.desktop,
              label: Text('Desktop'),
              icon: Icon(Icons.desktop_windows_outlined),
            ),
          ],
          selected: {widget.draft.device},
          onSelectionChanged: (value) =>
              widget.draft.update(() => widget.draft.device = value.first),
        ),
        OutlinedButton.icon(
          key: const ValueKey('restore-template-defaults'),
          onPressed: widget.draft.restoreTemplateDefaults,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Restore template recommendations'),
        ),
        FilledButton.tonalIcon(
          key: const ValueKey('expand-preview'),
          onPressed: _showExpandedPreview,
          icon: const Icon(Icons.fullscreen_rounded),
          label: const Text('Expand preview'),
        ),
      ],
    ),
  );

  OceanVariant get _activeOceanVariant {
    final draft = widget.draft;
    if (!draft.oceanPreviewBySection) return draft.oceanVariant;
    final navigation = switch (draft.role) {
      PreviewRole.student => InstitutionTemplatePreview.studentNavigation,
      PreviewRole.teacher => InstitutionTemplatePreview.teacherNavigation,
      PreviewRole.admin => InstitutionTemplatePreview.adminNavigation,
    };
    final index = draft.previewSectionIndex.clamp(0, navigation.length - 1);
    return draft.oceanVariantForSection(navigation[index]);
  }

  SpaceVariant get _activeSpaceVariant {
    final draft = widget.draft;
    if (!draft.spacePreviewBySection) return draft.spaceVariant;
    final navigation = switch (draft.role) {
      PreviewRole.student => InstitutionTemplatePreview.studentNavigation,
      PreviewRole.teacher => InstitutionTemplatePreview.teacherNavigation,
      PreviewRole.admin => InstitutionTemplatePreview.adminNavigation,
    };
    final index = draft.previewSectionIndex.clamp(0, navigation.length - 1);
    return draft.spaceVariantForSection(navigation[index]);
  }

  SpaceDecorationKey get _selectedSpaceKey => (
    variant: _activeSpaceVariant,
    template: widget.draft.template,
    device: widget.draft.device,
    element: widget.draft.selectedSpaceDecoration,
  );

  String _spaceElementLabel(SpaceDecorationId element) => switch (element) {
    SpaceDecorationId.hero => switch (_activeSpaceVariant) {
      SpaceVariant.planetExploration => 'Planet',
      SpaceVariant.orbitalStation => 'Station',
      SpaceVariant.asteroidExpedition => 'Asteroids',
    },
    SpaceDecorationId.craft => 'Explorer craft',
    SpaceDecorationId.probe => 'Satellite',
    SpaceDecorationId.stardust => 'Star cluster',
  };

  Widget _spaceEditControls() {
    final draft = widget.draft;
    final key = _selectedSpaceKey;
    final value = draft.spaceAdjustment(key);
    void change(OceanDecorationAdjustment requested) =>
        draft.changeSpaceAdjustment(
          key,
          SpaceDecorationGeometry.constrain(key, requested).$1,
        );
    return Container(
      key: const ValueKey('space-decoration-editor'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xDA14203A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x7979CFEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_activeSpaceVariant.name} · ${draft.template.name} · ${draft.device.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final element in SpaceDecorationId.values)
                ChoiceChip(
                  key: ValueKey('space-select-${element.name}'),
                  label: Text(_spaceElementLabel(element)),
                  selected: draft.selectedSpaceDecoration == element,
                  onSelected: (_) => draft.update(
                    () => draft.selectedSpaceDecoration = element,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Drag ${_spaceElementLabel(key.element)} anywhere on the canvas. '
            'Red outlines mark text, buttons and navigation; overlaps are warnings, not barriers.',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          if (draft.spaceOverlaps.isNotEmpty)
            Text(
              '${draft.spaceOverlaps.length} decoration(s) overlap reading or navigation areas. '
              'Reposition them before using this composition.',
              key: const ValueKey('space-overlap-warning'),
              style: const TextStyle(
                color: Color(0xFFFF8B95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          Row(
            children: [
              const SizedBox(width: 66, child: Text('Size')),
              Expanded(
                child: Slider(
                  key: const ValueKey('space-element-size'),
                  value: value.scale.clamp(
                    SpaceDecorationGeometry.minScale(key),
                    SpaceDecorationGeometry.maxScale(key),
                  ),
                  min: SpaceDecorationGeometry.minScale(key),
                  max: SpaceDecorationGeometry.maxScale(key),
                  divisions:
                      ((SpaceDecorationGeometry.maxScale(key) -
                                  SpaceDecorationGeometry.minScale(key)) *
                              20)
                          .round(),
                  label: '${(value.scale * 100).round()}%',
                  onChanged: (v) =>
                      change(draft.spaceAdjustment(key).copyWith(scale: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.scale * 100).round()}%'),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 66, child: Text('Opacity')),
              Expanded(
                child: Slider(
                  key: const ValueKey('space-element-opacity'),
                  value: value.opacity.clamp(0, 1),
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: '${(value.opacity * 100).round()}%',
                  onChanged: (v) =>
                      change(draft.spaceAdjustment(key).copyWith(opacity: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.opacity * 100).round()}%'),
              ),
            ],
          ),
          Text(
            'Visible artwork: approximately '
            '${SpaceDecorationGeometry.visibleRect(key, value).width.round()} × '
            '${SpaceDecorationGeometry.visibleRect(key, value).height.round()} preview px',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('space-reset-element'),
              onPressed: () => draft.resetSpaceAdjustment(key),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Restore element'),
            ),
          ),
          TextButton.icon(
            key: const ValueKey('space-remove-element'),
            onPressed: value.hidden
                ? null
                : () => change(value.copyWith(hidden: true)),
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('Remove element'),
          ),
        ],
      ),
    );
  }

  AnimalsVariant get _activeAnimalsVariant {
    final draft = widget.draft;
    if (!draft.animalsPreviewBySection) return draft.animalsVariant;
    final navigation = switch (draft.role) {
      PreviewRole.student => InstitutionTemplatePreview.studentNavigation,
      PreviewRole.teacher => InstitutionTemplatePreview.teacherNavigation,
      PreviewRole.admin => InstitutionTemplatePreview.adminNavigation,
    };
    final index = draft.previewSectionIndex.clamp(0, navigation.length - 1);
    return draft.animalsVariantForSection(navigation[index]);
  }

  AnimalsDecorationKey get _selectedAnimalsKey => (
    variant: _activeAnimalsVariant,
    template: widget.draft.template,
    device: widget.draft.device,
    element: widget.draft.selectedAnimalsDecoration,
  );

  String _animalsElementLabel(AnimalsDecorationId element) => switch (element) {
    AnimalsDecorationId.hero => switch (_activeAnimalsVariant) {
      AnimalsVariant.foxGrove => 'Fox',
      AnimalsVariant.deerMeadow => 'Deer',
      AnimalsVariant.owlCanopy => 'Owl',
    },
    AnimalsDecorationId.butterflies => 'Butterflies',
    AnimalsDecorationId.foliage => 'Foliage',
    AnimalsDecorationId.pawprints => 'Pawprints',
  };

  Widget _animalsEditControls() {
    final draft = widget.draft;
    final key = _selectedAnimalsKey;
    final value = draft.animalsAdjustment(key);
    void change(OceanDecorationAdjustment requested) =>
        draft.changeAnimalsAdjustment(
          key,
          AnimalsDecorationGeometry.constrain(key, requested).$1,
        );
    return Container(
      key: const ValueKey('animals-decoration-editor'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xDA14203A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x7979CFEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_activeAnimalsVariant.name} · ${draft.template.name} · ${draft.device.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final element in AnimalsDecorationId.values)
                ChoiceChip(
                  key: ValueKey('animals-select-${element.name}'),
                  label: Text(_animalsElementLabel(element)),
                  selected: draft.selectedAnimalsDecoration == element,
                  onSelected: (_) => draft.update(
                    () => draft.selectedAnimalsDecoration = element,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Drag ${_animalsElementLabel(key.element)} anywhere on the canvas. '
            'Red outlines mark text, buttons and navigation; overlaps are warnings, not barriers.',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          if (draft.animalsOverlaps.isNotEmpty)
            Text(
              '${draft.animalsOverlaps.length} decoration(s) overlap reading or navigation areas. '
              'Reposition them before using this composition.',
              key: const ValueKey('animals-overlap-warning'),
              style: const TextStyle(
                color: Color(0xFFFF8B95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          Row(
            children: [
              const SizedBox(width: 66, child: Text('Size')),
              Expanded(
                child: Slider(
                  key: const ValueKey('animals-element-size'),
                  value: value.scale.clamp(
                    AnimalsDecorationGeometry.minScale(key),
                    AnimalsDecorationGeometry.maxScale(key),
                  ),
                  min: AnimalsDecorationGeometry.minScale(key),
                  max: AnimalsDecorationGeometry.maxScale(key),
                  divisions:
                      ((AnimalsDecorationGeometry.maxScale(key) -
                                  AnimalsDecorationGeometry.minScale(key)) *
                              20)
                          .round(),
                  label: '${(value.scale * 100).round()}%',
                  onChanged: (v) =>
                      change(draft.animalsAdjustment(key).copyWith(scale: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.scale * 100).round()}%'),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 66, child: Text('Opacity')),
              Expanded(
                child: Slider(
                  key: const ValueKey('animals-element-opacity'),
                  value: value.opacity.clamp(0, 1),
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: '${(value.opacity * 100).round()}%',
                  onChanged: (v) =>
                      change(draft.animalsAdjustment(key).copyWith(opacity: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.opacity * 100).round()}%'),
              ),
            ],
          ),
          Text(
            'Visible artwork: approximately '
            '${AnimalsDecorationGeometry.visibleRect(key, value).width.round()} × '
            '${AnimalsDecorationGeometry.visibleRect(key, value).height.round()} preview px',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('animals-reset-element'),
              onPressed: () => draft.resetAnimalsAdjustment(key),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Restore element'),
            ),
          ),
          TextButton.icon(
            key: const ValueKey('animals-remove-element'),
            onPressed: value.hidden
                ? null
                : () => change(value.copyWith(hidden: true)),
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('Remove element'),
          ),
        ],
      ),
    );
  }

  NatureVariant get _activeNatureVariant {
    final draft = widget.draft;
    if (!draft.naturePreviewBySection) return draft.natureVariant;
    final navigation = switch (draft.role) {
      PreviewRole.student => InstitutionTemplatePreview.studentNavigation,
      PreviewRole.teacher => InstitutionTemplatePreview.teacherNavigation,
      PreviewRole.admin => InstitutionTemplatePreview.adminNavigation,
    };
    final index = draft.previewSectionIndex.clamp(0, navigation.length - 1);
    return draft.natureVariantForSection(navigation[index]);
  }

  NatureDecorationKey get _selectedNatureKey => (
    variant: _activeNatureVariant,
    template: widget.draft.template,
    device: widget.draft.device,
    element: widget.draft.selectedNatureDecoration,
  );

  String _natureElementLabel(NatureDecorationId element) => switch (element) {
    NatureDecorationId.hero => switch (_activeNatureVariant) {
      NatureVariant.ancientGrove => 'Ancient oak',
      NatureVariant.alpineVista => 'Alpine summit',
      NatureVariant.waterfallHaven => 'Waterfall',
    },
    NatureDecorationId.songbirds => 'Songbirds',
    NatureDecorationId.wildflowers => 'Wildflowers',
    NatureDecorationId.leaves => 'Leaves',
  };

  Widget _natureEditControls() {
    final draft = widget.draft;
    final key = _selectedNatureKey;
    final value = draft.natureAdjustment(key);
    void change(OceanDecorationAdjustment requested) =>
        draft.changeNatureAdjustment(
          key,
          NatureDecorationGeometry.constrain(key, requested).$1,
        );
    return Container(
      key: const ValueKey('nature-decoration-editor'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xDA14203A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x7979CFEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_activeNatureVariant.name} · ${draft.template.name} · ${draft.device.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final element in NatureDecorationId.values)
                ChoiceChip(
                  key: ValueKey('nature-select-${element.name}'),
                  label: Text(_natureElementLabel(element)),
                  selected: draft.selectedNatureDecoration == element,
                  onSelected: (_) => draft.update(
                    () => draft.selectedNatureDecoration = element,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Drag ${_natureElementLabel(key.element)} anywhere on the canvas. '
            'Red outlines mark text, buttons and navigation; overlaps are warnings, not barriers.',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          if (draft.natureOverlaps.isNotEmpty)
            Text(
              '${draft.natureOverlaps.length} decoration(s) overlap reading or navigation areas. '
              'Reposition them before using this composition.',
              key: const ValueKey('nature-overlap-warning'),
              style: const TextStyle(
                color: Color(0xFFFF8B95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          Row(
            children: [
              const SizedBox(width: 66, child: Text('Size')),
              Expanded(
                child: Slider(
                  key: const ValueKey('nature-element-size'),
                  value: value.scale.clamp(
                    NatureDecorationGeometry.minScale(key),
                    NatureDecorationGeometry.maxScale(key),
                  ),
                  min: NatureDecorationGeometry.minScale(key),
                  max: NatureDecorationGeometry.maxScale(key),
                  divisions:
                      ((NatureDecorationGeometry.maxScale(key) -
                                  NatureDecorationGeometry.minScale(key)) *
                              20)
                          .round(),
                  label: '${(value.scale * 100).round()}%',
                  onChanged: (v) =>
                      change(draft.natureAdjustment(key).copyWith(scale: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.scale * 100).round()}%'),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 66, child: Text('Opacity')),
              Expanded(
                child: Slider(
                  key: const ValueKey('nature-element-opacity'),
                  value: value.opacity.clamp(0, 1),
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: '${(value.opacity * 100).round()}%',
                  onChanged: (v) =>
                      change(draft.natureAdjustment(key).copyWith(opacity: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.opacity * 100).round()}%'),
              ),
            ],
          ),
          Text(
            'Visible artwork: approximately '
            '${NatureDecorationGeometry.visibleRect(key, value).width.round()} × '
            '${NatureDecorationGeometry.visibleRect(key, value).height.round()} preview px',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('nature-reset-element'),
              onPressed: () => draft.resetNatureAdjustment(key),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Restore element'),
            ),
          ),
          TextButton.icon(
            key: const ValueKey('nature-remove-element'),
            onPressed: value.hidden
                ? null
                : () => change(value.copyWith(hidden: true)),
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('Remove element'),
          ),
        ],
      ),
    );
  }

  FantasyVariant get _activeFantasyVariant {
    final draft = widget.draft;
    if (!draft.fantasyPreviewBySection) return draft.fantasyVariant;
    final navigation = switch (draft.role) {
      PreviewRole.student => InstitutionTemplatePreview.studentNavigation,
      PreviewRole.teacher => InstitutionTemplatePreview.teacherNavigation,
      PreviewRole.admin => InstitutionTemplatePreview.adminNavigation,
    };
    final index = draft.previewSectionIndex.clamp(0, navigation.length - 1);
    return draft.fantasyVariantForSection(navigation[index]);
  }

  FantasyDecorationKey get _selectedFantasyKey => (
    variant: _activeFantasyVariant,
    template: widget.draft.template,
    device: widget.draft.device,
    element: widget.draft.selectedFantasyDecoration,
  );

  String _fantasyElementLabel(FantasyDecorationId element) => switch (element) {
    FantasyDecorationId.hero => switch (_activeFantasyVariant) {
      FantasyVariant.floatingCastle => 'Floating castle',
      FantasyVariant.enchantedLibrary => 'Magic book',
      FantasyVariant.dragonGarden => 'Friendly dragon',
    },
    FantasyDecorationId.fireflies => 'Fireflies',
    FantasyDecorationId.mushrooms => 'Mushrooms',
    FantasyDecorationId.lantern => 'Lantern',
  };

  Widget _fantasyEditControls() {
    final draft = widget.draft;
    final key = _selectedFantasyKey;
    final value = draft.fantasyAdjustment(key);
    void change(OceanDecorationAdjustment requested) =>
        draft.changeFantasyAdjustment(
          key,
          FantasyDecorationGeometry.constrain(key, requested).$1,
        );
    return Container(
      key: const ValueKey('fantasy-decoration-editor'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xDA14203A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x7979CFEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_activeFantasyVariant.name} · ${draft.template.name} · ${draft.device.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final element in FantasyDecorationId.values)
                ChoiceChip(
                  key: ValueKey('fantasy-select-${element.name}'),
                  label: Text(_fantasyElementLabel(element)),
                  selected: draft.selectedFantasyDecoration == element,
                  onSelected: (_) => draft.update(
                    () => draft.selectedFantasyDecoration = element,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Drag ${_fantasyElementLabel(key.element)} anywhere on the canvas. '
            'Red outlines mark text, buttons and navigation; overlaps are warnings, not barriers.',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          if (draft.fantasyOverlaps.isNotEmpty)
            Text(
              '${draft.fantasyOverlaps.length} decoration(s) overlap reading or navigation areas. '
              'Reposition them before using this composition.',
              key: const ValueKey('fantasy-overlap-warning'),
              style: const TextStyle(
                color: Color(0xFFFF8B95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          Row(
            children: [
              const SizedBox(width: 66, child: Text('Size')),
              Expanded(
                child: Slider(
                  key: const ValueKey('fantasy-element-size'),
                  value: value.scale.clamp(
                    FantasyDecorationGeometry.minScale(key),
                    FantasyDecorationGeometry.maxScale(key),
                  ),
                  min: FantasyDecorationGeometry.minScale(key),
                  max: FantasyDecorationGeometry.maxScale(key),
                  divisions:
                      ((FantasyDecorationGeometry.maxScale(key) -
                                  FantasyDecorationGeometry.minScale(key)) *
                              20)
                          .round(),
                  label: '${(value.scale * 100).round()}%',
                  onChanged: (v) =>
                      change(draft.fantasyAdjustment(key).copyWith(scale: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.scale * 100).round()}%'),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 66, child: Text('Opacity')),
              Expanded(
                child: Slider(
                  key: const ValueKey('fantasy-element-opacity'),
                  value: value.opacity.clamp(0, 1),
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: '${(value.opacity * 100).round()}%',
                  onChanged: (v) =>
                      change(draft.fantasyAdjustment(key).copyWith(opacity: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.opacity * 100).round()}%'),
              ),
            ],
          ),
          Text(
            'Visible artwork: approximately '
            '${FantasyDecorationGeometry.visibleRect(key, value).width.round()} × '
            '${FantasyDecorationGeometry.visibleRect(key, value).height.round()} preview px',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('fantasy-reset-element'),
              onPressed: () => draft.resetFantasyAdjustment(key),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Restore element'),
            ),
          ),
          TextButton.icon(
            key: const ValueKey('fantasy-remove-element'),
            onPressed: value.hidden
                ? null
                : () => change(value.copyWith(hidden: true)),
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('Remove element'),
          ),
        ],
      ),
    );
  }

  OceanDecorationKey get _selectedOceanKey => (
    variant: _activeOceanVariant,
    template: widget.draft.template,
    device: widget.draft.device,
    element: widget.draft.selectedOceanDecoration,
  );

  String _oceanElementLabel(OceanDecorationId element) => switch (element) {
    OceanDecorationId.character => switch (_activeOceanVariant) {
      OceanVariant.turtleReef => 'Turtle',
      OceanVariant.sharkReef => 'Shark',
      OceanVariant.jellyfishGarden => 'Jellyfish',
    },
    OceanDecorationId.fishSchool => 'Fish school',
    OceanDecorationId.coral => 'Coral',
    OceanDecorationId.plants => 'Plants',
  };

  Widget _myEditControls() {
    final draft = widget.draft;
    final id = draft.selectedMyElementId;
    if (id == null || !draft.myElements.containsKey(id)) {
      return const Text(
        'Add an element in Ambience to edit its position, size and opacity.',
        style: TextStyle(color: Colors.white70),
      );
    }
    final file = draft.myElements[id]!;
    final key = (id: id, template: draft.template, device: draft.device);
    final value = draft.myAdjustment(key);
    void change(OceanDecorationAdjustment requested) =>
        draft.changeMyAdjustment(
          key,
          MyDecorationGeometry.constrain(key, file, requested),
        );
    return Container(
      key: const ValueKey('my-decoration-editor'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xDA14203A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x7979CFEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'My ambience · ${draft.template.name} · ${draft.device.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final entry in draft.myElements.entries)
                ChoiceChip(
                  key: ValueKey('my-select-${entry.key}'),
                  label: Text(
                    entry.value.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: draft.selectedMyElementId == entry.key,
                  onSelected: (_) =>
                      draft.update(() => draft.selectedMyElementId = entry.key),
                ),
            ],
          ),
          const Text(
            'Drag anywhere on the preview. Red outlines show text and controls; overlap warns but does not snap the element back.',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          if (draft.myOverlaps.contains(id))
            const Text(
              'This element overlaps text or navigation. Reposition it for readability.',
              key: ValueKey('my-overlap-warning'),
              style: TextStyle(
                color: Color(0xFFFF8B95),
                fontWeight: FontWeight.bold,
              ),
            ),
          Row(
            children: [
              const SizedBox(width: 64, child: Text('Size')),
              Expanded(
                child: Slider(
                  key: const ValueKey('my-element-size'),
                  value: value.scale.clamp(.25, 4.0),
                  min: .25,
                  max: 4,
                  divisions: 75,
                  onChanged: (v) => change(value.copyWith(scale: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.scale * 100).round()}%'),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 64, child: Text('Opacity')),
              Expanded(
                child: Slider(
                  key: const ValueKey('my-element-opacity'),
                  value: value.opacity.clamp(0, 1),
                  min: 0,
                  max: 1,
                  divisions: 100,
                  onChanged: (v) => change(value.copyWith(opacity: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.opacity * 100).round()}%'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('my-restore-element'),
                onPressed: () => draft.resetMyAdjustment(key),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Restore element'),
              ),
              TextButton.icon(
                key: const ValueKey('my-remove-element'),
                onPressed: () {
                  draft.removeMyElement(id);
                  MemoryImage(file.bytes).evict();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove element'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _oceanEditControls() {
    final draft = widget.draft;
    final key = _selectedOceanKey;
    final value = draft.oceanAdjustment(key);
    void change(OceanDecorationAdjustment requested) {
      final result = OceanDecorationGeometry.constrain(key, requested);
      draft.changeOceanAdjustment(key, result.$1, clamped: result.$2);
    }

    return Container(
      key: const ValueKey('ocean-decoration-editor'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xDA14203A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x7979CFEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_activeOceanVariant.name} · ${draft.template.name} · ${draft.device.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final element in OceanDecorationId.values)
                ChoiceChip(
                  key: ValueKey('ocean-select-${element.name}'),
                  label: Text(_oceanElementLabel(element)),
                  selected: draft.selectedOceanDecoration == element,
                  onSelected: (_) => draft.update(() {
                    draft.selectedOceanDecoration = element;
                    draft.oceanPlacementClamped = false;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Drag ${_oceanElementLabel(key.element)} anywhere on the canvas. Red outlines mark text, buttons and navigation; overlaps are warnings, not barriers.',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          if (draft.oceanOverlaps.isNotEmpty)
            Text(
              '${draft.oceanOverlaps.length} decoration(s) overlap reading or navigation areas. Reposition them before using this composition.',
              key: const ValueKey('ocean-overlap-warning'),
              style: const TextStyle(
                color: Color(0xFFFF8B95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          Row(
            children: [
              const SizedBox(width: 66, child: Text('Size')),
              Expanded(
                child: Slider(
                  key: const ValueKey('ocean-element-size'),
                  value: value.scale.clamp(
                    OceanDecorationGeometry.minScale(key),
                    OceanDecorationGeometry.maxScale(key),
                  ),
                  min: OceanDecorationGeometry.minScale(key),
                  max: OceanDecorationGeometry.maxScale(key),
                  divisions:
                      ((OceanDecorationGeometry.maxScale(key) -
                                  OceanDecorationGeometry.minScale(key)) *
                              20)
                          .round(),
                  label: '${(value.scale * 100).round()}%',
                  onChanged: (v) =>
                      change(draft.oceanAdjustment(key).copyWith(scale: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.scale * 100).round()}%'),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 66, child: Text('Opacity')),
              Expanded(
                child: Slider(
                  key: const ValueKey('ocean-element-opacity'),
                  value: value.opacity.clamp(0, 1),
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: '${(value.opacity * 100).round()}%',
                  onChanged: (v) =>
                      change(draft.oceanAdjustment(key).copyWith(opacity: v)),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${(value.opacity * 100).round()}%'),
              ),
            ],
          ),
          if (key.element != OceanDecorationId.character)
            Text(
              'Visible artwork: approximately ${OceanDecorationGeometry.visibleRect(key, value).width.round()} × ${OceanDecorationGeometry.visibleRect(key, value).height.round()} preview px',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('ocean-reset-element'),
              onPressed: () => draft.resetOceanAdjustment(key),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Restore element'),
            ),
          ),
          TextButton.icon(
            key: const ValueKey('ocean-remove-element'),
            onPressed: value.hidden
                ? null
                : () => change(value.copyWith(hidden: true)),
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('Remove element'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExpandedPreview() => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: const Color(0xFF070B1D),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Expanded local preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('close-expanded-preview'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    tooltip: 'Close preview',
                  ),
                ],
              ),
            ),
            if (widget.draft.ambience == InstitutionAmbience.ocean &&
                widget.draft.editOceanDecorations)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ListenableBuilder(
                    listenable: widget.draft,
                    builder: (context, _) => _oceanEditControls(),
                  ),
                ),
              ),
            if (widget.draft.ambience == InstitutionAmbience.space &&
                widget.draft.editSpaceDecorations)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ListenableBuilder(
                    listenable: widget.draft,
                    builder: (context, _) => _spaceEditControls(),
                  ),
                ),
              ),
            if (widget.draft.ambience == InstitutionAmbience.animals &&
                widget.draft.editAnimalsDecorations)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ListenableBuilder(
                    listenable: widget.draft,
                    builder: (context, _) => _animalsEditControls(),
                  ),
                ),
              ),
            if (widget.draft.ambience == InstitutionAmbience.nature &&
                widget.draft.editNatureDecorations)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ListenableBuilder(
                    listenable: widget.draft,
                    builder: (context, _) => _natureEditControls(),
                  ),
                ),
              ),
            if (widget.draft.ambience == InstitutionAmbience.fantasy &&
                widget.draft.editFantasyDecorations)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ListenableBuilder(
                    listenable: widget.draft,
                    builder: (context, _) => _fantasyEditControls(),
                  ),
                ),
              ),
            if (widget.draft.ambience == InstitutionAmbience.my &&
                widget.draft.editMyDecorations)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ListenableBuilder(
                    listenable: widget.draft,
                    builder: (context, _) => _myEditControls(),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ListenableBuilder(
                  listenable: widget.draft,
                  builder: (context, _) => InstitutionTemplatePreview(
                    draft: widget.draft,
                    institutionName: _institutionName,
                    logoBytes: widget.logoBytes,
                    logoUrl: widget.logoUrl,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  static String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  static Color? _parseHex(String? raw) {
    final value = raw?.trim().replaceFirst('#', '');
    if (value == null || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) {
      return null;
    }
    return Color(0xFF000000 | int.parse(value, radix: 16));
  }

  static Color _bestText(Color color) =>
      color.computeLuminance() > .42 ? Colors.black : Colors.white;

  static double _contrast(Color a, Color b) {
    final first = a.computeLuminance();
    final second = b.computeLuminance();
    final high = first > second ? first : second;
    final low = first > second ? second : first;
    return (high + .05) / (low + .05);
  }
}

enum ButtonVisualState { normal, pressed, disabled }

class _TransparencyCheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tile = 8.0;
    for (var y = 0.0; y < size.height; y += tile) {
      for (var x = 0.0; x < size.width; x += tile) {
        final dark = ((x / tile).floor() + (y / tile).floor()).isEven;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tile, tile),
          Paint()..color = dark ? const Color(0xFFB8BCC5) : Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
