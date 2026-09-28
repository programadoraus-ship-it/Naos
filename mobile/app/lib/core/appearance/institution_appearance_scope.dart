import 'package:flutter/material.dart';

import 'institution_appearance_config.dart';

class InstitutionAppearanceScope extends InheritedWidget {
  const InstitutionAppearanceScope({
    super.key,
    required this.appearance,
    required super.child,
  });

  final LoadedInstitutionAppearance appearance;

  InstitutionAppearanceConfig get config => appearance.config;

  static InstitutionAppearanceScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<InstitutionAppearanceScope>();
    assert(scope != null, 'InstitutionAppearanceScope is missing.');
    return scope!;
  }

  static InstitutionAppearanceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InstitutionAppearanceScope>();

  @override
  bool updateShouldNotify(InstitutionAppearanceScope oldWidget) =>
      oldWidget.appearance.revision != appearance.revision ||
      oldWidget.appearance.config.toJson().toString() !=
          appearance.config.toJson().toString();
}
