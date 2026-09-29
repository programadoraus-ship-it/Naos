import 'package:flutter/material.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/theme.dart';

class NaosApp extends StatelessWidget {
  const NaosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naos',
      debugShowCheckedModeBanner: false,

      theme: NaosTheme.lightTheme,

      initialRoute: AppRouter.splash,
      routes: AppRouter.routes,
    );
  }
}