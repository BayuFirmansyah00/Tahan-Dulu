import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../models/financial_account.dart';
import '../models/financial_goal.dart';
import '../models/financial_summary.dart';
import '../models/purchase_consideration.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../repositories/repositories.dart';
import 'onboarding_providers.dart';

// --- Repository providers (ganti Mock -> API cukup di file ini) ---

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return MockDashboardRepository();
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return MockAccountRepository(ref.watch(onboardingRepositoryProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return MockTransactionRepository();
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return MockGoalRepository();
});

final purchaseDecisionRepositoryProvider =
    Provider<PurchaseDecisionRepository>((ref) {
  return MockPurchaseDecisionRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return MockNotificationRepository();
});

// --- Data providers (UI cukup watch provider ini) ---

final userProvider = FutureProvider<UserModel>((ref) {
  return ref.watch(dashboardRepositoryProvider).getUser();
});

final summaryProvider = FutureProvider<FinancialSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).getSummary();
});

final accountsProvider = FutureProvider<List<FinancialAccount>>((ref) {
  return ref.watch(accountRepositoryProvider).getAccounts();
});

final recentTransactionsProvider =
    FutureProvider<List<AppTransaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).getRecentTransactions();
});

/// Daftar transaksi terurut terbaru. Satu-satunya sumber daftar untuk
/// riwayat maupun agregat (tidak ada repository kedua).
final transactionsProvider = FutureProvider<List<AppTransaction>>((ref) async {
  final items =
      await ref.watch(transactionRepositoryProvider).getRecentTransactions();
  final sorted = List.of(items)
    ..sort((a, b) => b.date.compareTo(a.date));
  return sorted;
});

final goalsProvider = FutureProvider<List<FinancialGoal>>((ref) {
  return ref.watch(goalRepositoryProvider).getGoals();
});

final considerationsProvider =
    FutureProvider<List<PurchaseConsideration>>((ref) {
  return ref.watch(purchaseDecisionRepositoryProvider).getConsiderations();
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});
