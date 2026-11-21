import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/financial_settings.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import 'profile_providers.dart';

class FinancialSettingsController extends AsyncNotifier<FinancialSettings> {
  @override
  Future<FinancialSettings> build() async {
    return ref.watch(financialSettingsRepositoryProvider).getSettings();
  }

  /// Request simulasi jadwal transisi dari backend sebelum menyimpan.
  Future<FinancialTransitionInfo> preview({
    required int monthlyIncome,
    required int salaryDay,
  }) async {
    final repo = ref.read(financialSettingsRepositoryProvider);
    return repo.getPreview(
      monthlyIncome: monthlyIncome,
      salaryDay: salaryDay,
    );
  }

  /// Simpan pengaturan baru (berlaku mulai tanggal efektif periode berikutnya).
  Future<bool> saveSettings({
    required int monthlyIncome,
    required int salaryDay,
    List<Map<String, dynamic>>? allocations,
    int? transitionBudget,
    bool transitionConfirmed = false,
  }) async {
    final repo = ref.read(financialSettingsRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      final updated = await repo.updateSettings(
        monthlyIncome: monthlyIncome,
        salaryDay: salaryDay,
        allocations: allocations,
        transitionBudget: transitionBudget,
        transitionConfirmed: transitionConfirmed,
      );
      state = AsyncValue.data(updated);
      ref.invalidate(financialSettingsProvider);
      ref.invalidate(profileUserProvider);
      ref.invalidate(userProvider);
      ref.invalidate(currentBudgetProvider);
      ref.invalidate(dashboardDataProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Batalkan perubahan jadwal yang tertunda.
  Future<bool> cancelPending() async {
    final repo = ref.read(financialSettingsRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      final updated = await repo.cancelPending();
      state = AsyncValue.data(updated);
      ref.invalidate(financialSettingsProvider);
      ref.invalidate(profileUserProvider);
      ref.invalidate(userProvider);
      ref.invalidate(currentBudgetProvider);
      ref.invalidate(dashboardDataProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Muat ulang data terbaru dari backend.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await ref.read(financialSettingsRepositoryProvider).getSettings();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final financialSettingsControllerProvider =
    AsyncNotifierProvider<FinancialSettingsController, FinancialSettings>(
  FinancialSettingsController.new,
);

