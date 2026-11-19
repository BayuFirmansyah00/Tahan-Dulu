import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/routing/app_router.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/core/theme/app_theme.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/data/repositories/onboarding_repository.dart';
import 'package:tahan_dulu/data/repositories/budget_repository.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/budget_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/instruments_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/salary_screen.dart';

void main() {
  Widget createTestWidget({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: child),
    );
  }

  group('Onboarding 5-Step Flow Tests', () {
    testWidgets('Step 1: SalaryScreen renders correctly with default income', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(child: const SalaryScreen()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingStep), findsOneWidget);
      expect(find.text(AppStrings.salarySubtitle), findsOneWidget);
      expect(find.text(AppStrings.salaryIncomeQuestion), findsOneWidget);
      expect(find.text(AppStrings.salaryDayQuestion), findsOneWidget);
      expect(find.text(AppStrings.continueButton), findsOneWidget);
    });

    testWidgets(
      'Step 2: InstrumentsScreen renders with step indicator and tambah instrumen',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(child: const InstrumentsScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.onboardingStep2), findsOneWidget);
        expect(find.text(AppStrings.instrumentsSubtitle), findsOneWidget);
        expect(find.text(AppStrings.addInstrument), findsOneWidget);
        expect(find.text(AppStrings.continueButton), findsOneWidget);
      },
    );

    testWidgets(
      'Step 3: BudgetScreen renders with 4 categories and 50/5/30/15 default',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(child: const BudgetScreen()));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.onboardingStep3), findsOneWidget);
        expect(find.text('Atur Anggaran Bulanan'), findsOneWidget);
        expect(find.text('Kebutuhan Pokok'), findsOneWidget);
        expect(find.text('Pengeluaran Bebas'), findsOneWidget);
        expect(find.text('Investasi dan Tabungan'), findsOneWidget);
        expect(find.text('Dana Darurat'), findsOneWidget);

        expect(find.text('100% / 100%'), findsOneWidget);
        expect(find.text(AppStrings.continueButton), findsOneWidget);
      },
    );

    testWidgets('BudgetScreen reset recommendation button works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(child: const BudgetScreen()));
      await tester.pumpAndSettle();

      final resetButton = find.text('Reset ke Rekomendasi (50/5/30/15)');
      expect(resetButton, findsOneWidget);
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(find.text('100% / 100%'), findsOneWidget);
    });

    testWidgets('InstrumentsScreen navigates to onboardingBudget on continue', (
      WidgetTester tester,
    ) async {
      final router = createAppRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(
              InMemoryOnboardingRepository(),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Langsung go ke /onboarding/instruments
      router.go(AppRoutes.onboardingInstruments);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingStep2), findsOneWidget);

      // Tekan tombol lanjut
      final continueBtn = find.text(AppStrings.continueButton);
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Instrumen berlanjut ke Budget (langkah 3 dari 5).
      expect(find.text(AppStrings.onboardingStep3), findsOneWidget);
      expect(find.text('Atur Anggaran Bulanan'), findsOneWidget);
    });

    testWidgets('Budget continues to recurring expenses after successful save', (
      WidgetTester tester,
    ) async {
      final router = createAppRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(
              InMemoryOnboardingRepository(),
            ),
            budgetRepositoryProvider.overrideWithValue(MockBudgetRepository()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      router.go(AppRoutes.onboardingBudget);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.continueButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingStep4), findsOneWidget);
      expect(find.text(AppStrings.expensesTitle), findsOneWidget);
    });
  });
}
