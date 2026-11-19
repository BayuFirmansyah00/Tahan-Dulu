import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tahan_dulu/data/models/financial_settings.dart';
import 'package:tahan_dulu/data/repositories/financial_settings_repository.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/features/profile/presentation/providers/financial_settings_controller.dart';

void main() {
  group('Fase 4B - FinancialSettings Models & Serialization Tests', () {
    test('FinancialTransitionInfo fromJson and toJson roundtrip', () {
      final json = {
        'current_monthly_income': 5000000,
        'current_salary_day': 25,
        'proposed_monthly_income': 6500000,
        'proposed_salary_day': 1,
        'effective_date': '2026-11-25',
        'effective_date_formatted': '25 November 2026',
        'has_transition': true,
        'transition_start': '2026-11-25',
        'transition_end': '2026-11-30',
        'transition_days': 6,
        'next_full_period_start': '2026-12-01',
        'next_full_period_start_formatted': '01 Desember 2026',
        'next_full_period_end': '2026-12-31',
        'next_full_period_end_formatted': '31 Desember 2026',
        'note': 'Perubahan tanggal gajian menghasilkan penyesuaian selama 6 hari.',
      };

      final info = FinancialTransitionInfo.fromJson(json);
      expect(info.currentMonthlyIncome, 5000000);
      expect(info.currentSalaryDay, 25);
      expect(info.proposedMonthlyIncome, 6500000);
      expect(info.proposedSalaryDay, 1);
      expect(info.hasTransition, isTrue);
      expect(info.transitionDays, 6);
      expect(info.effectiveDate, '2026-11-25');
      expect(info.nextFullPeriodStart, '2026-12-01');

      final serialized = info.toJson();
      expect(serialized['transition_days'], 6);
      expect(serialized['has_transition'], isTrue);
    });

    test('FinancialSettings full hierarchy parsing with activePeriod and pendingChange', () {
      final json = {
        'current_monthly_income': 5000000,
        'current_monthly_income_formatted': 'Rp 5.000.000',
        'current_salary_day': 25,
        'active_period': {
          'id': 10,
          'period_start': '2026-10-25',
          'period_end': '2026-11-24',
          'days_remaining': 8,
          'monthly_income': 5000000,
          'monthly_income_formatted': 'Rp 5.000.000',
          'is_active': true,
          'spendable_allocation': 4000000,
          'safe_daily_spending': 500000,
        },
        'pending_change': {
          'has_pending': true,
          'pending_monthly_income': 7000000,
          'pending_monthly_income_formatted': 'Rp 7.000.000',
          'pending_salary_day': 1,
          'effective_date': '2026-11-25',
          'effective_date_formatted': '25 November 2026',
          'transition_info': {
            'current_monthly_income': 5000000,
            'current_salary_day': 25,
            'proposed_monthly_income': 7000000,
            'proposed_salary_day': 1,
            'effective_date': '2026-11-25',
            'effective_date_formatted': '25 November 2026',
            'has_transition': true,
            'transition_start': '2026-11-25',
            'transition_end': '2026-11-30',
            'transition_days': 6,
            'next_full_period_start': '2026-12-01',
            'next_full_period_start_formatted': '01 Desember 2026',
            'next_full_period_end': '2026-12-31',
            'next_full_period_end_formatted': '31 Desember 2026',
            'note': 'Test note',
          },
        },
      };

      final settings = FinancialSettings.fromJson(json);
      expect(settings.currentMonthlyIncome, 5000000);
      expect(settings.currentSalaryDay, 25);
      expect(settings.hasPendingChange, isTrue);
      expect(settings.activePeriod?.spendableAllocation, 4000000);
      expect(settings.activePeriod?.safeDailySpending, 500000);
      expect(settings.pendingChange?.pendingMonthlyIncome, 7000000);
      expect(settings.pendingChange?.pendingSalaryDay, 1);
      expect(settings.pendingChange?.transitionInfo?.transitionDays, 6);
    });
  });

  group('Fase 4B - Mock Repository & Controller Tests', () {
    test('MockFinancialSettingsRepository handles lifecycle: get, preview, update, cancel', () async {
      final repo = MockFinancialSettingsRepository(
        initialIncome: 5000000,
        initialSalaryDay: 25,
      );

      final initial = await repo.getSettings();
      expect(initial.currentMonthlyIncome, 5000000);
      expect(initial.currentSalaryDay, 25);
      expect(initial.hasPendingChange, isFalse);

      final preview = await repo.getPreview(
        monthlyIncome: 8000000,
        salaryDay: 1,
      );
      expect(preview.proposedMonthlyIncome, 8000000);
      expect(preview.proposedSalaryDay, 1);
      expect(preview.hasTransition, isTrue);

      final updated = await repo.updateSettings(
        monthlyIncome: 8000000,
        salaryDay: 1,
      );
      expect(updated.hasPendingChange, isTrue);
      expect(updated.pendingChange?.pendingMonthlyIncome, 8000000);
      expect(updated.pendingChange?.pendingSalaryDay, 1);

      final cancelled = await repo.cancelPending();
      expect(cancelled.hasPendingChange, isFalse);
      expect(cancelled.pendingChange, isNull);
    });

    test('FinancialSettingsController state flow with Riverpod container', () async {
      final mockRepo = MockFinancialSettingsRepository(
        initialIncome: 6000000,
        initialSalaryDay: 20,
      );

      final container = ProviderContainer(
        overrides: [
          financialSettingsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Load initial state
      final initialAsync = await container.read(financialSettingsControllerProvider.future);
      expect(initialAsync.currentMonthlyIncome, 6000000);
      expect(initialAsync.currentSalaryDay, 20);
      expect(initialAsync.hasPendingChange, isFalse);

      // Preview
      final preview = await container
          .read(financialSettingsControllerProvider.notifier)
          .preview(monthlyIncome: 9000000, salaryDay: 28);
      expect(preview.proposedMonthlyIncome, 9000000);

      // Save new settings
      final saved = await container
          .read(financialSettingsControllerProvider.notifier)
          .saveSettings(monthlyIncome: 9000000, salaryDay: 28);
      expect(saved, isTrue);

      final stateAfterSave = container.read(financialSettingsControllerProvider).asData?.value;
      expect(stateAfterSave?.hasPendingChange, isTrue);
      expect(stateAfterSave?.pendingChange?.pendingMonthlyIncome, 9000000);
      expect(stateAfterSave?.pendingChange?.pendingSalaryDay, 28);

      // Cancel pending
      final cancelled = await container
          .read(financialSettingsControllerProvider.notifier)
          .cancelPending();
      expect(cancelled, isTrue);

      final stateAfterCancel = container.read(financialSettingsControllerProvider).asData?.value;
      expect(stateAfterCancel?.hasPendingChange, isFalse);
    });

    test('Bridge Mode - ActivePeriodInfo with isTransition parses correctly', () {
      final json = {
        'id': 15,
        'period_start': '2026-11-25',
        'period_end': '2026-11-30',
        'days_remaining': 6,
        'monthly_income': 1200000,
        'monthly_income_formatted': 'Rp 1.200.000',
        'is_active': true,
        'is_transition': true,
        'spendable_allocation': 960000,
        'safe_daily_spending': 160000,
      };

      final active = ActivePeriodInfo.fromJson(json);
      expect(active.isTransition, isTrue);
      expect(active.monthlyIncome, 1200000);
      expect(active.spendableAllocation, 960000);
      expect(active.safeDailySpending, 160000);

      final serialized = active.toJson();
      expect(serialized['is_transition'], isTrue);
    });

    test('Bridge Mode - PendingFinancialChange with transitionBudget and transitionConfirmed', () {
      final json = {
        'has_pending': true,
        'pending_monthly_income': 6500000,
        'pending_monthly_income_formatted': 'Rp 6.500.000',
        'pending_salary_day': 1,
        'effective_date': '2026-11-25',
        'effective_date_formatted': '25 November 2026',
        'transition_budget': 1200000,
        'transition_budget_formatted': 'Rp 1.200.000',
        'transition_confirmed': true,
        'transition_info': {
          'current_monthly_income': 5000000,
          'current_salary_day': 25,
          'proposed_monthly_income': 6500000,
          'proposed_salary_day': 1,
          'effective_date': '2026-11-25',
          'effective_date_formatted': '25 November 2026',
          'has_transition': true,
          'transition_start': '2026-11-25',
          'transition_end': '2026-11-30',
          'transition_days': 6,
          'suggested_transition_budget': 1300000,
          'suggested_transition_budget_formatted': 'Rp 1.300.000',
          'next_full_period_start': '2026-12-01',
          'next_full_period_start_formatted': '01 Desember 2026',
          'next_full_period_end': '2026-12-31',
          'next_full_period_end_formatted': '31 Desember 2026',
          'note': 'Transisi 6 hari',
        },
      };

      final pending = PendingFinancialChange.fromJson(json);
      expect(pending.hasPending, isTrue);
      expect(pending.transitionBudget, 1200000);
      expect(pending.transitionConfirmed, isTrue);
      expect(pending.transitionInfo?.suggestedTransitionBudget, 1300000);

      final serialized = pending.toJson();
      expect(serialized['transition_budget'], 1200000);
      expect(serialized['transition_confirmed'], isTrue);
    });

    test('Bridge Mode - Controller and Repository flow with transition parameters', () async {
      final mockRepo = MockFinancialSettingsRepository(
        initialIncome: 5000000,
        initialSalaryDay: 25,
      );

      final container = ProviderContainer(
        overrides: [
          financialSettingsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final saved = await container
          .read(financialSettingsControllerProvider.notifier)
          .saveSettings(
            monthlyIncome: 6500000,
            salaryDay: 1,
            transitionBudget: 1200000,
            transitionConfirmed: true,
          );
      expect(saved, isTrue);

      final state = container.read(financialSettingsControllerProvider).asData?.value;
      expect(state?.pendingChange?.transitionBudget, 1200000);
      expect(state?.pendingChange?.transitionConfirmed, isTrue);
    });
  });
}

