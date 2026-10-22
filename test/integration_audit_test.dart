import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/financial_instrument.dart';
import 'package:tahan_dulu/data/models/financial_summary.dart';
import 'package:tahan_dulu/data/models/user_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/auth/presentation/providers/auth_controller.dart';
import 'package:tahan_dulu/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_deposit_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_detail_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_history_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goals_list_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/security_screen.dart';

/// Repository dashboard dengan nama depan sangat panjang (uji overflow).
class _LongNameDashboardRepo implements DashboardRepository {
  @override
  Future<UserModel> getUser() async => const UserModel(
        id: 'user-1',
        name: 'Supercalifragilisticexpialidocious Firmansyah',
      );

  @override
  Future<FinancialSummary> getSummary() async => const FinancialSummary(
        income: 5000000,
        expense: 2450000,
        saving: 800000,
        investment: 500000,
        remaining: 1250000,
        flexibleBudget: 2000000,
        safeSpendingToday: 40000,
      );
}

Widget _dummy(String label) => Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label)),
    );

GoRouter _router({required String initial}) {
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => _dummy('Dummy Reports'),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => GoalDetailScreen(
              goalId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) => GoalHistoryScreen(
                  goalId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'deposit',
                builder: (context, state) => GoalDepositScreen(
                  goalId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings/security',
        builder: (context, state) => const SecurityScreen(),
      ),
    ],
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required String initial,
  DashboardRepository? dashboardRepo,
  Future<void> Function(ProviderContainer)? arrange,
}) async {
  final container = ProviderContainer(
    overrides: [
      if (dashboardRepo != null)
        dashboardRepositoryProvider.overrideWithValue(dashboardRepo),
    ],
  );
  addTearDown(container.dispose);
  if (arrange != null) {
    await tester.runAsync(() => arrange(container));
  }
  final router = _router(initial: initial);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Audit 15: goal tak dikenal dapat dipulihkan', () {
    testWidgets('detail onboarding goal menampilkan recovery', (
      tester,
    ) async {
      await _pump(tester, initial: '/goals/goal-onboarding');

      expect(find.text(AppStrings.goalNotFound), findsOneWidget);
      expect(find.text(AppStrings.accountNotFound), findsNothing);
      await _tapVisible(
        tester,
        find.text(AppStrings.goalNotFoundAction),
      );
      expect(find.text(AppStrings.goalsListTitle), findsWidgets);
    });

    testWidgets('riwayat goal tak dikenal menampilkan recovery', (
      tester,
    ) async {
      await _pump(tester, initial: '/goals/goal-onboarding/history');

      expect(find.text(AppStrings.goalNotFound), findsOneWidget);
    });

    testWidgets('ketuk kartu goal dashboard tidak buntu', (tester) async {
      await _pump(tester, initial: '/dashboard');

      await _tapVisible(tester, find.text('Investasi'));
      expect(find.text(AppStrings.goalNotFound), findsOneWidget);
    });
  });

  group('Audit 15: keamanan & dashboard', () {
    testWidgets('baris metode login membuka info', (tester) async {
      await _pump(
        tester,
        initial: '/settings/security',
        arrange: (container) => container
            .read(authControllerProvider.notifier)
            .loginWithEmail(email: 'a@b.com', password: 'x')
            .then((_) {}),
      );

      await _tapVisible(
        tester,
        find.text(AppStrings.securityLoginEmail),
      );
      expect(
        find.text(AppStrings.securityMethodInfoBody),
        findsOneWidget,
      );
    });

    testWidgets('ketuk hero membuka laporan', (tester) async {
      await _pump(tester, initial: '/dashboard');

      await _tapVisible(tester, find.text(AppStrings.safeTodayTitle));
      expect(find.text('Dummy Reports'), findsWidgets);
    });

    testWidgets('nama depan panjang tidak overflow (360px)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pump(
        tester,
        initial: '/dashboard',
        dashboardRepo: _LongNameDashboardRepo(),
      );

      expect(
        find.text('Supercalifragilisticexpialidocious'),
        findsOneWidget,
      );
    });
  });

  group('Audit 15: dropdown akun tahan nama panjang', () {
    testWidgets('menu instrumen panjang tidak overflow', (tester) async {
      const longName =
          'Bank Pembangunan Daerah Istimewa Yogyakarta Syariah Tbk';
      await _pump(
        tester,
        initial: '/goals/goal-investment/deposit',
        arrange: (container) => container
            .read(onboardingRepositoryProvider)
            .addInstrument(
              const FinancialInstrument(
                id: 'inst-long',
                name: longName,
                type: InstrumentType.bank,
                initialBalance: 100000,
              ),
            )
            .then((_) {}),
      );

      final dropdown =
          find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);
      await _tapVisible(tester, dropdown);
      expect(find.text(longName), findsWidgets);
    });
  });
}
