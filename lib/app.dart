import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_controller.dart';
import 'features/profile/presentation/providers/profile_providers.dart';

/// Provider GoRouter terpusat untuk aplikasi TahanDulu.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = AuthRouteNotifier();

  ref.listen<AuthState>(authControllerProvider, (_, next) {
    authNotifier.update(next);
  }, fireImmediately: true);

  ref.onDispose(authNotifier.dispose);

  return createAppRouter(authNotifier: authNotifier);
});

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