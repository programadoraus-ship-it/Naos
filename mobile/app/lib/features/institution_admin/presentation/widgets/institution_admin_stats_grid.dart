import 'package:flutter/material.dart';

class InstitutionAdminStat {
  const InstitutionAdminStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
}

class InstitutionAdminStatsGrid extends StatelessWidget {
  const InstitutionAdminStatsGrid({
    super.key,
    required this.items,
    required this.foreground,
    required this.decorationBuilder,
  });

  final List<InstitutionAdminStat> items;
  final Color foreground;
  final BoxDecoration Function(int index) decorationBuilder;

  static const double _spacing = 12;
  static const double _baseMinimumCardWidth = 156;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final minimumCardWidth =
            _baseMinimumCardWidth + ((textScale - 1).clamp(0, 1.5) * 44);
        final availableWidth = constraints.maxWidth;
        final columns =
            ((availableWidth + _spacing) / (minimumCardWidth + _spacing))
                .floor()
                .clamp(1, 4);
        final rows = <Widget>[];

        for (var start = 0; start < items.length; start += columns) {
          final end = (start + columns).clamp(0, items.length);
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = start; index < end; index++) ...[
                    if (index > start) const SizedBox(width: _spacing),
                    Expanded(
                      child: _InstitutionAdminStatCard(
                        key: ValueKey('institution-stat-card-$index'),
                        stat: items[index],
                        foreground: foreground,
                        decoration: decorationBuilder(index),
                      ),
                    ),
                  ],
                  for (var index = end; index < start + columns; index++) ...[
                    if (index > start) const SizedBox(width: _spacing),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          );
          if (end < items.length) rows.add(const SizedBox(height: _spacing));
        }

        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }
}

class _InstitutionAdminStatCard extends StatelessWidget {
  const _InstitutionAdminStatCard({
    super.key,
    required this.stat,
    required this.foreground,
    required this.decoration,
  });

  final InstitutionAdminStat stat;
  final Color foreground;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: decoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, color: stat.color),
          const SizedBox(height: 10),
          Text(
            '${stat.value}',
            style: TextStyle(
              color: foreground,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            softWrap: true,
            style: TextStyle(
              color: foreground.withValues(alpha: .65),
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
