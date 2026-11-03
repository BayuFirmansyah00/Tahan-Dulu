import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/app_providers.dart';
import 'features/profile/presentation/providers/profile_providers.dart';

/// Root widget TahanDulu: theme + router terpusat.
/// State management di-inject dari main.dart via ProviderScope.
class TahanDuluApp extends ConsumerWidget {
  const TahanDuluApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
    );
  }
}
