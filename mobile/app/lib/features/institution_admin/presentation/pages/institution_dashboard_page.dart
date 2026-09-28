import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/appearance/institution_appearance_asset_gateway.dart';
import '../../../../core/appearance/institution_appearance_config.dart';
import '../../../../core/appearance/institution_appearance_repository.dart';
import '../../../../core/appearance/institution_appearance_scope.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/supabase/institution_admin_context.dart';
import '../../../institution_onboarding/presentation/pages/institution_brand_config_mapper.dart';
import '../../../institution_onboarding/presentation/pages/institution_brand_draft.dart';
import '../widgets/institution_admin_appearance_shell.dart';
import '../widgets/institution_admin_stats_grid.dart';

class InstitutionDashboardPage extends StatefulWidget {
  const InstitutionDashboardPage({super.key});

  @override
  State<InstitutionDashboardPage> createState() =>
      _InstitutionDashboardPageState();
}

class _InstitutionDashboardPageState extends State<InstitutionDashboardPage> {
  final client = Supabase.instance.client;
  final draft = InstitutionBrandDraft();
  late final InstitutionAppearanceAssetGateway assetGateway =
      InstitutionAppearanceAssetGateway(client: client);

  bool loading = true;
  String? fatalError;
  String? appearanceWarning;
  String? institutionId;
  String institutionName = 'Institution';
  String? logoUrl;
  LoadedInstitutionAppearance? appearance;
  int students = 0, teachers = 0, pending = 0, courses = 0;
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  @override
  void dispose() {
    assetGateway.close();
    draft.dispose();
    super.dispose();
  }

  Future<void> loadDashboard() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      fatalError = null;
      appearanceWarning = null;
    });
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user was found.');
      final context = await InstitutionAdminContextResolver(
        client,
      ).resolve(user.id);
      final id = context.institutionId;
      if (id == null) {
        throw Exception(
          'This administrator has not linked an institution yet.',
        );
      }
      final row = await client
          .from('institutions')
          .select(
            'id, name, logo_url, template, theme_color, font_style, button_style',
          )
          .eq('id', id)
          .maybeSingle();
      if (row == null) throw Exception('Institution not found.');
      institutionId = id;
      institutionName = row['name']?.toString() ?? 'Institution';
      logoUrl = row['logo_url']?.toString();
      try {
        final loaded = await InstitutionAppearanceRepository(
          SupabaseInstitutionAppearanceBackend(client),
        ).load(id);
        await _restore(loaded);
        appearance = loaded;
        if (loaded.usesFallback) {
          appearanceWarning =
              'No saved appearance exists yet. The compatible legacy design is shown.';
        }
      } catch (error) {
        final fallback = LoadedInstitutionAppearance(
          institutionId: id,
          revision: 0,
          assets: const [],
          usesFallback: true,
          config: InstitutionAppearanceConfig.safeDefault(
            legacyTemplate: row['template']?.toString(),
            legacyPrimary: row['theme_color']?.toString(),
            legacyFont: row['font_style']?.toString(),
            legacyButtonStyle: row['button_style']?.toString(),
          ),
        );
        InstitutionBrandConfigMapper.restore(draft, fallback.config);
        appearance = fallback;
        appearanceWarning =
            'The saved appearance could not be loaded. Its remote data was not changed.';
        debugPrint('NAOS APPEARANCE FALLBACK: $error');
      }
      await Future.wait([_loadCounts(id), _loadRequests(id)]);
      if (mounted) setState(() => loading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          loading = false;
          fatalError = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _restore(LoadedInstitutionAppearance loaded) async {
    final selection = InstitutionBrandConfigMapper.restore(
      draft,
      loaded.config,
    );
    draft.myBackground = null;
    draft.myElements.clear();
    if (loaded.config.ambience['kind'] != 'my') return;
    final byId = {for (final asset in loaded.assets) asset.id: asset};
    final background = byId[selection.backgroundAssetId];
    if (background?.signedUrl != null) {
      draft.myBackground = await _file(background!);
    }
    for (final entry in selection.elementAssetIds.entries) {
      final asset = byId[entry.value];
      if (asset?.signedUrl != null) {
        draft.myElements[entry.key] = await _file(asset!);
      }
    }
  }

  Future<MyAmbienceFile> _file(InstitutionAppearanceAsset asset) async =>
      MyAmbienceFile(
        name: asset.storagePath.split('/').last,
        bytes: await assetGateway.download(asset.signedUrl!),
        width: asset.width,
        height: asset.height,
        format: switch (asset.mimeType) {
          'image/jpeg' => 'jpg',
          'image/webp' => 'webp',
          _ => 'png',
        },
      );

  Future<void> _loadCounts(String id) async {
    final result = await Future.wait([
      client
          .from('institution_memberships')
          .select('id')
          .eq('institution_id', id)
          .eq('status', 'active')
          .eq('requested_role', 'student'),
      client
          .from('institution_teachers')
          .select('id')
          .eq('institution_id', id)
          .eq('is_active', true),
      client
          .from('institution_memberships')
          .select('id')
          .eq('institution_id', id)
          .eq('status', 'pending'),
      client
          .from('institution_courses')
          .select('id')
          .eq('institution_id', id)
          .eq('is_active', true),
    ]);
    students = (result[0] as List).length;
    teachers = (result[1] as List).length;
    pending = (result[2] as List).length;
    courses = (result[3] as List).length;
  }

  Future<void> _loadRequests(String id) async {
    final response = await client
        .from('institution_memberships')
        .select(
          'id, status, requested_role, requested_at, profiles(username, display_name)',
        )
        .eq('institution_id', id)
        .eq('status', 'pending')
        .order('requested_at', ascending: false)
        .limit(5);
    requests = List<Map<String, dynamic>>.from(response);
  }

  void open(String route) =>
      Navigator.pushNamed(context, route).then((_) => loadDashboard());

  Future<void> signOut() async {
    await client.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const _Loading();
    if (fatalError != null || appearance == null) {
      return _Fatal(
        message: fatalError ?? 'Dashboard unavailable.',
        retry: loadDashboard,
      );
    }
    return InstitutionAppearanceScope(
      appearance: appearance!,
      child: Scaffold(
        body: SafeArea(
          child: InstitutionAdminAppearanceShell(
            draft: draft,
            institutionName: institutionName,
            logoUrl: logoUrl,
            destinations: _destinations(),
            onRefresh: loadDashboard,
            onSignOut: signOut,
            body: InstitutionAdminDashboardContent(
              draft: draft,
              institutionName: institutionName,
              institutionId: institutionId!,
              counts: [students, teachers, pending, courses],
              requests: requests,
              warning: appearanceWarning,
              open: open,
              retry: loadDashboard,
            ),
          ),
        ),
      ),
    );
  }

  List<InstitutionAdminDestination> _destinations() => [
    InstitutionAdminDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
      selected: true,
      onTap: () {},
    ),
    InstitutionAdminDestination(
      label: 'Students',
      icon: Icons.people_alt_rounded,
      onTap: () => open('/institution-admin/students'),
    ),
    InstitutionAdminDestination(
      label: 'Access Requests',
      icon: Icons.assignment_ind_rounded,
      onTap: () => open('/institution-admin/access-requests'),
    ),
    InstitutionAdminDestination(
      label: 'Teachers',
      icon: Icons.school_rounded,
      onTap: () => open('/institution-admin/teachers'),
    ),
    InstitutionAdminDestination(
      label: 'Courses',
      icon: Icons.menu_book_rounded,
      onTap: () => open('/institution-admin/courses'),
    ),
    InstitutionAdminDestination(
      label: 'Classes',
      icon: Icons.groups_rounded,
      onTap: () => open(AppRouter.institutionAdminClasses),
    ),
    InstitutionAdminDestination(
      label: 'English Levels',
      icon: Icons.show_chart_rounded,
      onTap: () => open('/institution-admin/english-levels'),
    ),
    InstitutionAdminDestination(
      label: 'Rankings',
      icon: Icons.emoji_events_rounded,
      onTap: () => open('/institution-admin/rankings'),
    ),
    InstitutionAdminDestination(
      label: 'Institution',
      icon: Icons.business_rounded,
      onTap: () => open('/institution-admin/institution'),
    ),
    InstitutionAdminDestination(
      label: 'Appearance',
      icon: Icons.palette_rounded,
      onTap: () => open(AppRouter.institutionAdminAppearance),
    ),
    InstitutionAdminDestination(
      label: 'Settings',
      icon: Icons.settings_rounded,
      onTap: () => open('/settings'),
    ),
  ];
}

class InstitutionAdminDashboardContent extends StatelessWidget {
  const InstitutionAdminDashboardContent({
    super.key,
    required this.draft,
    required this.institutionName,
    required this.institutionId,
    required this.counts,
    required this.requests,
    required this.warning,
    required this.open,
    required this.retry,
  });
  final InstitutionBrandDraft draft;
  final String institutionName, institutionId;
  final List<int> counts;
  final List<Map<String, dynamic>> requests;
  final String? warning;
  final ValueChanged<String> open;
  final VoidCallback retry;

  Color get ink =>
      draft.backgroundIsDark ? Colors.white : const Color(0xFF172033);
  Color get surface {
    final alpha =
        (draft.backgroundIsDark ? .27 : .78) *
        (1 - draft.transparencyFor(InstitutionColorSlot.secondary) / 100);
    return draft.backgroundIsDark
        ? Colors.black.withValues(alpha: alpha)
        : Colors.white.withValues(alpha: alpha);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact = box.maxWidth < 680;
      return RefreshIndicator(
        onRefresh: () async => retry(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(compact),
              if (warning != null) ...[const SizedBox(height: 14), _warning()],
              const SizedBox(height: 18),
              _stats(),
              const SizedBox(height: 18),
              if (compact) ...[
                _actions(),
                const SizedBox(height: 18),
                _requests(),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _actions()),
                    const SizedBox(width: 18),
                    Expanded(flex: 4, child: _requests()),
                  ],
                ),
              const SizedBox(height: 18),
              _institution(),
            ],
          ),
        ),
      );
    },
  );

  Widget _hero(bool compact) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome back, Administrator',
          style: TextStyle(
            color: ink,
            fontSize: compact ? 24 : 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage $institutionName with live institutional data.',
          style: TextStyle(color: ink.withValues(alpha: .68)),
        ),
      ],
    );
    final appearance = button(
      Icons.palette_rounded,
      'Appearance',
      () => open(AppRouter.institutionAdminAppearance),
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 30),
      decoration: deco(featured: true),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 14), appearance],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: copy),
                const SizedBox(width: 20),
                appearance,
              ],
            ),
    );
  }

  Widget _stats() {
    final data = [
      InstitutionAdminStat(
        icon: Icons.people_alt_rounded,
        label: 'Students',
        value: counts[0],
        color: draft.primary,
      ),
      InstitutionAdminStat(
        icon: Icons.school_rounded,
        label: 'Teachers',
        value: counts[1],
        color: draft.secondary,
      ),
      InstitutionAdminStat(
        icon: Icons.pending_actions_rounded,
        label: 'Pending requests',
        value: counts[2],
        color: draft.accent,
      ),
      InstitutionAdminStat(
        icon: Icons.menu_book_rounded,
        label: 'Courses',
        value: counts[3],
        color: draft.primary,
      ),
    ];
    return InstitutionAdminStatsGrid(
      items: data,
      foreground: ink,
      decorationBuilder: (index) => deco(index: index),
    );
  }

  Widget _actions() => panel(
    'Quick actions',
    Icons.bolt_rounded,
    Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        button(
          Icons.people_alt_rounded,
          'Students',
          () => open('/institution-admin/students'),
        ),
        button(
          Icons.assignment_ind_rounded,
          'Access requests',
          () => open('/institution-admin/access-requests'),
        ),
        button(
          Icons.school_rounded,
          'Teachers',
          () => open('/institution-admin/teachers'),
        ),
        button(
          Icons.menu_book_rounded,
          'Courses',
          () => open('/institution-admin/courses'),
        ),
        button(
          Icons.groups_rounded,
          'Classes',
          () => open(AppRouter.institutionAdminClasses),
        ),
        button(
          Icons.show_chart_rounded,
          'Levels',
          () => open('/institution-admin/english-levels'),
        ),
      ],
    ),
  );

  Widget _requests() => panel(
    'Recent access requests',
    Icons.assignment_ind_rounded,
    requests.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 34),
            child: Center(
              child: Text(
                'No access requests yet.',
                style: TextStyle(color: ink.withValues(alpha: .62)),
              ),
            ),
          )
        : Column(children: [for (final row in requests) request(row)]),
  );

  Widget request(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final name =
        profile?['display_name']?.toString() ??
        profile?['username']?.toString() ??
        'User';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: draft.primary.withValues(alpha: .25),
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(color: ink),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(color: ink, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        row['requested_role']?.toString() ?? 'unknown',
        style: TextStyle(color: ink.withValues(alpha: .55)),
      ),
      trailing: Text(
        'PENDING',
        style: TextStyle(
          color: draft.accent,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _institution() => panel(
    'Institution',
    Icons.business_rounded,
    Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: draft.primary.withValues(alpha: .22),
            borderRadius: BorderRadius.circular(
              draft.buttonRadius.clamp(8, 18),
            ),
          ),
          child: Icon(Icons.business_rounded, color: draft.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                institutionName,
                style: TextStyle(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                institutionId,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink.withValues(alpha: .45),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _warning() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE49A22).withValues(alpha: .15),
      border: Border.all(color: const Color(0xFFE49A22).withValues(alpha: .55)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFE49A22)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(warning!, style: TextStyle(color: ink)),
        ),
        TextButton(onPressed: retry, child: const Text('Retry')),
      ],
    ),
  );
  Widget panel(String title, IconData icon, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: deco(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: draft.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: ink, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );

  BoxDecoration deco({int index = 0, bool featured = false}) {
    final radius = switch (draft.template) {
      InstitutionTemplate.heritage || InstitutionTemplate.studio => 2.0,
      InstitutionTemplate.nexus => 6.0,
      InstitutionTemplate.littleSteps || InstitutionTemplate.pulse => 28.0,
      InstitutionTemplate.prestige => 12.0,
      _ => 18.0,
    };
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color:
            (draft.template == InstitutionTemplate.heritage
                    ? draft.accent
                    : draft.primary)
                .withValues(alpha: featured ? .48 : .24),
      ),
      boxShadow:
          draft.template == InstitutionTemplate.orbit ||
              draft.template == InstitutionTemplate.prestige
          ? [
              BoxShadow(
                color: draft.primary.withValues(alpha: .11),
                blurRadius: featured ? 28 : 14,
                offset: const Offset(0, 7),
              ),
            ]
          : null,
    );
  }

  Widget button(IconData icon, String label, VoidCallback action) {
    final style = draft.buttonFinish == InstitutionButtonFinish.outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: BorderSide(color: draft.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(draft.buttonRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: draft.buttonFinish == InstitutionButtonFinish.tonal
                ? draft
                      .surfaceColor(InstitutionColorSlot.primary)
                      .withValues(
                        alpha:
                            .22 *
                            (1 -
                                draft.transparencyFor(
                                      InstitutionColorSlot.primary,
                                    ) /
                                    100),
                      )
                : draft.surfaceColor(InstitutionColorSlot.primary),
            foregroundColor: draft.buttonFinish == InstitutionButtonFinish.tonal
                ? ink
                : Colors.white,
            elevation: draft.buttonFinish == InstitutionButtonFinish.elevated
                ? 8
                : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(draft.buttonRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          );
    return ElevatedButton.icon(
      onPressed: action,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: style,
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF080D24),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading your school appearance…',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    ),
  );
}

class _Fatal extends StatelessWidget {
  const _Fatal({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080D24),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 42),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: retry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
