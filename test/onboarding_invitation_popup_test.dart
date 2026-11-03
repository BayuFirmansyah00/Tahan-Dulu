import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/features/onboarding/presentation/providers/onboarding_status_provider.dart';
import 'package:tahan_dulu/features/onboarding/presentation/widgets/onboarding_invitation_popup.dart';

/// Status onboarding yang bisa diubah di tempat oleh test (tanpa membuat
/// ProviderScope baru sehingga state penanda "sudah ditampilkan" bertahan).
class _StatusNotifier extends Notifier<OnboardingStatus> {
  @override
  OnboardingStatus build() =>
      const OnboardingStatus(userId: 'u1', isCompleted: false);

  void set(OnboardingStatus value) => state = value;
}

final _statusProvider =
    NotifierProvider<_StatusNotifier, OnboardingStatus>(_StatusNotifier.new);

/// Harness: menampilkan [OnboardingInvitationPopup] di dalam Stack di atas
/// layar Dashboard tiruan, dengan GoRouter agar tombol "Lengkapi Sekarang"
/// dapat menavigasi ke rute onboarding.
Widget _harness() {
  final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const Scaffold(
          body: Stack(
            children: [
              Center(child: Text('DASHBOARD_BODY')),
              OnboardingInvitationPopup(),
            ],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingSalary,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('SALARY_SCREEN'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      // onboardingStatusProvider membaca _statusProvider agar bisa diubah test.
      onboardingStatusProvider
          .overrideWith((ref) async => ref.watch(_statusProvider)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

ProviderContainer _container(WidgetTester tester) => ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );

void main() {
  testWidgets('Popup muncul untuk pengguna yang belum menyelesaikan onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingPopupTitle), findsOneWidget);
    expect(find.text(AppStrings.onboardingPopupCompleteNow), findsOneWidget);
    expect(find.text(AppStrings.onboardingPopupLater), findsOneWidget);
  });

  testWidgets('Tombol "Lengkapi Sekarang" menutup dialog lalu ke onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.onboardingPopupCompleteNow));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingPopupTitle), findsNothing);
    expect(find.text('SALARY_SCREEN'), findsOneWidget);
  });

  testWidgets('Tombol "Nanti Saja" menutup dialog, tetap di Dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.onboardingPopupLater));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingPopupTitle), findsNothing);
    expect(find.text('DASHBOARD_BODY'), findsOneWidget);
    expect(find.text('SALARY_SCREEN'), findsNothing);
  });

  testWidgets('Pengguna yang sudah menyelesaikan onboarding tidak melihat popup', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingStatusProvider.overrideWith(
            (ref) async =>
                const OnboardingStatus(userId: 'u1', isCompleted: true),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.dashboard,
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const Scaffold(
                  body: Stack(
                    children: [
                      Center(child: Text('DASHBOARD_BODY')),
                      OnboardingInvitationPopup(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingPopupTitle), findsNothing);
  });

  testWidgets('Status refresh untuk akun sama tidak menampilkan popup ganda', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingPopupTitle), findsOneWidget);

    // Tutup lewat "Nanti Saja".
    await tester.tap(find.text(AppStrings.onboardingPopupLater));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingPopupTitle), findsNothing);

    // "Refresh" status (akun sama, masih belum selesai) memicu ulang
    // provider -> ref.listen fire -> TIDAK boleh tampil ganda.
    _container(tester).read(_statusProvider.notifier).set(
          const OnboardingStatus(userId: 'u1', isCompleted: false),
        );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingPopupTitle), findsNothing);
  });

  testWidgets('Berganti akun: popup tampil lagi untuk akun berbeda', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingPopupTitle), findsOneWidget);

    // Akun A menutup popup.
    await tester.tap(find.text(AppStrings.onboardingPopupLater));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingPopupTitle), findsNothing);

    // Ganti ke akun B (id berbeda, belum selesai) -> popup tampil lagi.
    _container(tester).read(_statusProvider.notifier).set(
          const OnboardingStatus(userId: 'user-B', isCompleted: false),
        );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingPopupTitle), findsOneWidget);
  });

  testWidgets('Status loading: popup tidak ditampilkan sebelum status diketahui', (
    tester,
  ) async {
    final completer = Completer<OnboardingStatus>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingStatusProvider.overrideWith((ref) => completer.future),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.dashboard,
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const Scaffold(
                  body: Stack(
                    children: [
                      Center(child: Text('DASHBOARD_BODY')),
                      OnboardingInvitationPopup(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppStrings.onboardingPopupTitle), findsNothing);
  });

  testWidgets('Status error: popup tidak ditampilkan dan tidak logout', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingStatusProvider.overrideWith((ref) async {
            throw Exception('backend down');
          }),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.dashboard,
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const Scaffold(
                  body: Stack(
                    children: [
                      Center(child: Text('DASHBOARD_BODY')),
                      OnboardingInvitationPopup(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingPopupTitle), findsNothing);
    expect(find.text('DASHBOARD_BODY'), findsOneWidget);
  });
}
