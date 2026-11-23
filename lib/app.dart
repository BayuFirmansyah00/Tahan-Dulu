import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/services/fcm_service.dart';
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

/// Root widget TahanDulu: theme + router terpusat + lifecycle FCM.
/// State management di-inject dari main.dart via ProviderScope.
class TahanDuluApp extends ConsumerStatefulWidget {
  const TahanDuluApp({super.key});

  @override
  ConsumerState<TahanDuluApp> createState() => _TahanDuluAppState();
}

class _TahanDuluAppState extends ConsumerState<TahanDuluApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      FcmService.instance.attach(container);
      if (ref.read(authControllerProvider).status == AuthStatus.authenticated) {
        unawaited(FcmService.instance.onAuthenticated());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) {
        unawaited(FcmService.instance.onAuthenticated());
      }
    });

    final router = ref.watch(goRouterProvider);
    final reduceMotion = ref.watch(appPreferencesProvider.select((p) => p.reduceMotion));
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeAnimationDuration: reduceMotion ? Duration.zero : kThemeAnimationDuration,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(disableAnimations: media.disableAnimations || reduceMotion),
          child: child!,
        );
      },
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
    );
  }
}