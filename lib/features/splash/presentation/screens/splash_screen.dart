import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

/// Splash / Welcome: logo di tengah, wordmark, tagline, loading kecil.
/// Lalu otomatis masuk ke Login — atau Dashboard bila sesi remote
/// valid berhasil dipulihkan (GET /me).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _proceed();
  }

  Future<void> _proceed() async {
    final stopwatch = Stopwatch()..start();
    final restored = await ref.read(authControllerProvider.notifier).restore();
    final elapsed = stopwatch.elapsed;
    if (elapsed < const Duration(milliseconds: 1200)) {
      await Future.delayed(const Duration(milliseconds: 1200) - elapsed);
    }
    if (!mounted) return;
    context.go(restored ? AppRoutes.dashboard : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: const AppLogo(height: 104),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppConstants.appName,
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.splashTagline,
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    AppStrings.splashLoading,
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
