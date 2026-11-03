import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../datasources/remote/api_config.dart';
import '../datasources/remote/api_client.dart';
import '../datasources/remote/remote_account_repository.dart';
import '../datasources/remote/remote_bank_repository.dart';
import '../datasources/remote/remote_budget_repository.dart';
import '../datasources/remote/remote_dashboard_repository.dart';
import '../datasources/remote/remote_goal_repository.dart';
import '../datasources/remote/remote_investment_repository.dart';
import '../datasources/remote/remote_instrument_type_repository.dart';
import '../datasources/remote/remote_recurring_repository.dart';
import '../datasources/remote/remote_purchase_decision_repository.dart';
import '../datasources/remote/remote_transaction_repository.dart';
import '../datasources/remote/remote_notification_repository.dart';
import '../datasources/remote/token_storage.dart';
import '../models/api_bank.dart';
import '../models/api_financial_instrument.dart';
import '../models/api_monthly_budget.dart';
import '../models/app_notification.dart';
import '../models/financial_account.dart';
import '../models/financial_goal.dart';
import '../models/financial_summary.dart';
import '../models/purchase_consideration.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../repositories/bank_repository.dart';
import '../repositories/budget_repository.dart';
import '../repositories/repositories.dart';
import 'onboarding_providers.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
// Note: authRepositoryProvider is defined in auth_controller.dart
// ---------------------------------------------------------------------------
// Handler HTTP 401 Unauthorized terpusat: memicu logout pada AuthController,
// yang secara otomatis mereset sesi dan memicu redirect guard GoRouter ke /login.
// ---------------------------------------------------------------------------
void _handleUnauthorized(Ref ref) {
  try {
    ref.read(authControllerProvider.notifier).logout();
  } catch (_) {}
}

// ---------------------------------------------------------------------------
// Repository providers — Default sekarang REMOTE (Laravel API).
// Gunakan --dart-define=USE_REMOTE_API=false atau USE_REMOTE_AUTH=false
// untuk paksa mock lokal.
// ---------------------------------------------------------------------------

// Note: authRepositoryProvider is defined in
// features/auth/presentation/providers/auth_controller.dart
// and re-exported from there. No duplicate needed here.

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  if (!ApiConfig.useRemoteApi) return MockDashboardRepository();
  return RemoteDashboardRepository(
    client: ApiClient(
      baseUrl: ApiConfig.baseUrl,
      onUnauthorized: () => _handleUnauthorized(ref),
    ),
    tokens: TokenStorage(),
  );
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  if (!ApiConfig.useRemoteApi) {
    return MockAccountRepository(ref.watch(onboardingRepositoryProvider));
  }
  return RemoteAccountRepository(
    client: ApiClient(
      baseUrl: ApiConfig.baseUrl,
      onUnauthorized: () => _handleUnauthorized(ref),
    ),
    tokens: TokenStorage(),
  );
});

final instrumentTypeRepositoryProvider = Provider<InstrumentTypeRepository>((
  ref,
) {
  if (!ApiConfig.useRemoteApi) return MockInstrumentTypeRepository();
  return RemoteInstrumentTypeRepository(
    client: ApiClient(
      baseUrl: ApiConfig.baseUrl,
      onUnauthorized: () => _handleUnauthorized(ref),
    ),
    tokens: TokenStorage(),
  );
});

/// FutureProvider daftar tipe instrumen master dari API.
final instrumentTypesProvider = FutureProvider<List<ApiInstrumentType>>((
  ref,
) async {
  return ref.read(instrumentTypeRepositoryProvider).getInstrumentTypes();
});

/// Repository katalog bank (dari API Laravel / idn-finlogos).
final bankRepositoryProvider = Provider<BankRepository>((ref) {
  if (!ApiConfig.useRemoteApi) {
    return MockBankRepository();
  }
  return RemoteBankRepository(
    client: ApiClient(
      baseUrl: ApiConfig.baseUrl,
      onUnauthorized: () => _handleUnauthorized(ref),
    ),
    tokens: TokenStorage(),
  );
});

/// Provider daftar bank dari katalog backend dengan filter pencarian opsional.
final banksProvider = FutureProvider.family<List<ApiBank>, String?>((
  ref,
  search,
) async {
  return ref.watch(bankRepositoryProvider).getBanks(search: search);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  if (!ApiConfig.useRemoteApi) {
    return MockBudgetRepository(
      () => ref.watch(authControllerProvider).user?.id,
    );
  }
  return RemoteBudgetRepository(
    ApiClient(baseUrl: ApiConfig.baseUrl),
    TokenStorage(),
  );
});

final currentBudgetProvider = FutureProvider<ApiMonthlyBudget?>((ref) async {
  return ref.watch(budgetRepositoryProvider).getCurrentBudget();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  if (!ApiConfig.useRemoteApi) {
    return MockTransactionRepository(
      () => ref.watch(authControllerProvider).user?.id,
    );
  }
  return RemoteTransactionRepository(
    client: ApiClient(
      baseUrl: ApiConfig.baseUrl,
      onUnauthorized: () => _handleUnauthorized(ref),
    ),
    tokens: TokenStorage(),
  );
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  if (!ApiConfig.useRemoteApi) {
    return MockGoalRepository(() => ref.watch(authControllerProvider).user?.id);
  }
  return RemoteGoalRepository(
    client: ApiClient(
      baseUrl: ApiConfig.baseUrl,
      onUnauthorized: () => _handleUnauthorized(ref),
    ),
    tokens: TokenStorage(),
  );
});

final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  if (!ApiConfig.useRemoteApi) {
    // Tidak ada mock implementation untuk investment; gunakan remote saja.
    // Jika USE_REMOTE_API=false, provider ini akan gagal saat diakses.
    return RemoteInvestmentRepository(
      client: ApiClient(baseUrl: ApiConfig.baseUrl),
      tokens: TokenStorage(),
    );
  }
  return RemoteInvestmentRepository(
    client: ApiClient(
      baseUrl: ApiConfig.baseUrl,
      onUnauthorized: () => _handleUnauthorized(ref),
    ),
    tokens: TokenStorage(),
  );
});

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  if (!ApiConfig.useRemoteApi) {
    return RemoteRecurringRepository(
      client: ApiClient(baseUrl: ApiConfig.baseUrl),
      tokens: TokenStorage(),
    );
  }
  return RemoteRecurringRepository(
    client: ApiClient(
      baseUrl: ApiConfig.baseUrl,
      onUnauthorized: () => _handleUnauthorized(ref),
    ),
    tokens: TokenStorage(),
  );
});

final purchaseDecisionRepositoryProvider = Provider<PurchaseDecisionRepository>(
  (ref) {
    if (!ApiConfig.useRemoteApi) {
      return MockPurchaseDecisionRepository(
        () => ref.watch(authControllerProvider).user?.id,
      );
    }
      return RemotePurchaseDecisionRepository(
      client: ApiClient(
        baseUrl: ApiConfig.baseUrl,
        onUnauthorized: () => _handleUnauthorized(ref),
      ),
      tokens: TokenStorage(),
    );
  },
);

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (!ApiConfig.useRemoteApi) {
    return MockNotificationRepository();
  }
  return RemoteNotificationRepository(
    client: ApiClient(
      baseUrl: ApiConfig.baseUrl,
      onUnauthorized: () => _handleUnauthorized(ref),
    ),
    tokens: TokenStorage(),
  );
});

// ---------------------------------------------------------------------------
// Data providers (UI cukup watch provider ini) —
// userProvider & summaryProvider sekarang dari Laravel API saat remote aktif.
// ---------------------------------------------------------------------------

final userProvider = FutureProvider<UserModel>((ref) {
  return ref.watch(dashboardRepositoryProvider).getUser();
});

final summaryProvider = FutureProvider<FinancialSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).getSummary();
});

final accountsProvider = FutureProvider<List<FinancialAccount>>((ref) {
  return ref.watch(accountRepositoryProvider).getAccounts();
});

final recentTransactionsProvider = FutureProvider<List<AppTransaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).getRecentTransactions();
});

/// Daftar transaksi terurut terbaru. Satu-satunya sumber daftar untuk
/// riwayat maupun agregat (tidak ada repository kedua).
final transactionsProvider = FutureProvider<List<AppTransaction>>((ref) async {
  final items = await ref
      .watch(transactionRepositoryProvider)
      .getRecentTransactions();
  final sorted = List.of(items)..sort((a, b) => b.date.compareTo(a.date));
  return sorted;
});

final goalsProvider = FutureProvider<List<FinancialGoal>>((ref) {
  return ref.watch(goalRepositoryProvider).getGoals();
});

final considerationsProvider = FutureProvider<List<PurchaseConsideration>>((
  ref,
) {
  return ref.watch(purchaseDecisionRepositoryProvider).getConsiderations();
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});
