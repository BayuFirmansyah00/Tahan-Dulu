import '../datasources/mock/mock_data.dart';
import '../models/app_notification.dart';
import '../models/financial_account.dart';
import '../models/financial_goal.dart';
import '../models/financial_instrument.dart';
import '../models/goal_deposit.dart';
import '../models/financial_summary.dart';
import '../models/purchase_consideration.dart';
import '../models/reminder_settings.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'onboarding_repository.dart';

// ---------------------------------------------------------------------------
// Repository interfaces. UI hanya bergantung pada interface ini.
// Implementasi mock di bawah nanti diganti Laravel API tanpa mengubah UI.
// ---------------------------------------------------------------------------

abstract class DashboardRepository {
  Future<UserModel> getUser();
  Future<FinancialSummary> getSummary();
}

abstract class AccountRepository {
  Future<List<FinancialAccount>> getAccounts();
  Future<double> getTotalBalance();

  /// CRUD akun (diimplementasikan di atas satu sumber kanonis).
  Future<FinancialAccount> addAccount(FinancialAccount account);
  Future<FinancialAccount> updateAccount(FinancialAccount account);
  Future<void> removeAccount(String id);
}

abstract class TransactionRepository {
  Future<List<AppTransaction>> getRecentTransactions();
  Future<AppTransaction> addTransaction(AppTransaction transaction);
}

abstract class GoalRepository {
  Future<List<FinancialGoal>> getGoals();
  Future<FinancialGoal> addGoal(FinancialGoal goal);
  Future<FinancialGoal> updateGoal(FinancialGoal goal);
  Future<List<GoalDeposit>> getDeposits(String goalId);
  Future<GoalDeposit> addDeposit(GoalDeposit deposit);
  Future<void> saveGoalOrder(List<String> orderedIds);
}

abstract class PurchaseDecisionRepository {
  Future<List<PurchaseConsideration>> getConsiderations();
  Future<PurchaseConsideration> addConsideration(
    PurchaseConsideration item,
  );
  Future<PurchaseConsideration> updateConsideration(
    PurchaseConsideration item,
  );
}

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<List<ReminderPreference>> getPreferences();
  Future<void> setPreference(ReminderType type, bool enabled);
  Future<SavingReminderConfig> getSavingReminder();
  Future<SavingReminderConfig> saveSavingReminder(
    SavingReminderConfig config,
  );
  Future<SavingReminderConfig> deactivateSavingReminder();
}

// ---------------------------------------------------------------------------
// Mock implementations (sementara, menggantikan Laravel API).
// ---------------------------------------------------------------------------

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<UserModel> getUser() => mockDelay(MockData.user);

  @override
  Future<FinancialSummary> getSummary() => mockDelay(
        const FinancialSummary(
          income: MockData.income,
          expense: MockData.expense,
          saving: MockData.saving,
          investment: MockData.investment,
          remaining: MockData.remaining,
          flexibleBudget: MockData.flexibleBudget,
          safeSpendingToday: MockData.safeSpendingToday,
        ),
      );
}

/// Adapter akun di atas SATU list kanonis (instrumen onboarding).
/// Tidak ada list kedua: semua baca/tulis lewat OnboardingRepository,
/// sehingga total tak pernah ganda dan konsisten dengan engine.
/// Saldo tercatat = initialBalance; saldo saat ini dihitung engine.
class MockAccountRepository implements AccountRepository {
  MockAccountRepository(this._onboarding);

  final OnboardingRepository _onboarding;

  List<FinancialInstrument> get _items =>
      _onboarding.getOnboardingData()?.financialInstruments ?? const [];

  static AccountType _toAccountType(InstrumentType type) {
    switch (type) {
      case InstrumentType.bank:
        return AccountType.bank;
      case InstrumentType.digitalBank:
        return AccountType.digitalBank;
      case InstrumentType.ewallet:
        return AccountType.ewallet;
    }
  }

  static InstrumentType _toInstrumentType(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return InstrumentType.bank;
      case AccountType.digitalBank:
        return InstrumentType.digitalBank;
      case AccountType.ewallet:
        return InstrumentType.ewallet;
    }
  }

  static FinancialAccount _toAccount(FinancialInstrument e) {
    return FinancialAccount(
      id: e.id,
      name: e.name,
      type: _toAccountType(e.type),
      balance: e.initialBalance,
      institutionName: e.institutionName,
    );
  }

  @override
  Future<List<FinancialAccount>> getAccounts() =>
      mockDelay([for (final e in _items) _toAccount(e)]);

  @override
  Future<double> getTotalBalance() => mockDelay(
        _items.fold<double>(0, (sum, e) => sum + e.initialBalance),
      );

  @override
  Future<FinancialAccount> addAccount(FinancialAccount account) async {
    final saved = await _onboarding.addInstrument(
      FinancialInstrument(
        id: account.id,
        name: account.name,
        type: _toInstrumentType(account.type),
        initialBalance: account.balance,
        institutionName: account.institutionName,
        isSelected: true,
      ),
    );
    return _toAccount(saved);
  }

  @override
  Future<FinancialAccount> updateAccount(FinancialAccount account) async {
    final existing = _items.firstWhere((e) => e.id == account.id);
    final saved = await _onboarding.updateInstrument(
      existing.copyWith(
        name: account.name,
        type: _toInstrumentType(account.type),
        initialBalance: account.balance,
        institutionName: account.institutionName,
      ),
    );
    return _toAccount(saved);
  }

  @override
  Future<void> removeAccount(String id) {
    return _onboarding.removeInstrument(id);
  }
}

class MockTransactionRepository implements TransactionRepository {
  final List<AppTransaction> _items = List.of(MockData.recentTransactions);

  @override
  Future<List<AppTransaction>> getRecentTransactions() =>
      mockDelay(List.of(_items));

  @override
  Future<AppTransaction> addTransaction(AppTransaction transaction) {
    _items.add(transaction);
    return mockDelay(transaction);
  }
}

class MockGoalRepository implements GoalRepository {
  final List<FinancialGoal> _goals = [MockData.investmentGoal];
  final List<GoalDeposit> _deposits = [];

  @override
  Future<List<FinancialGoal>> getGoals() =>
      mockDelay(List.of(_goals));

  @override
  Future<FinancialGoal> addGoal(FinancialGoal goal) {
    _goals.add(goal);
    return mockDelay(goal);
  }

  @override
  Future<FinancialGoal> updateGoal(FinancialGoal goal) {
    final index = _goals.indexWhere((e) => e.id == goal.id);
    if (index == -1) throw StateError('Goal tidak ditemukan');
    _goals[index] = goal;
    return mockDelay(goal);
  }

  @override
  Future<List<GoalDeposit>> getDeposits(String goalId) {
    final items = _deposits.where((e) => e.goalId == goalId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return mockDelay(items);
  }

  @override
  Future<GoalDeposit> addDeposit(GoalDeposit deposit) async {
    _deposits.add(deposit);
    final index = _goals.indexWhere((e) => e.id == deposit.goalId);
    if (index != -1) {
      // Satu-satunya penulis currentAmount: akumulasi setoran tercatat.
      _goals[index] = _goals[index].copyWith(
        currentAmount: _goals[index].currentAmount + deposit.amount,
      );
    }
    return mockDelay(deposit);
  }

  @override
  Future<void> saveGoalOrder(List<String> orderedIds) {
    final byId = {for (final e in _goals) e.id: e};
    final ordered = [
      for (final id in orderedIds)
        if (byId.containsKey(id)) byId[id]!,
      // Id tak dikenal diabaikan; goal yang hilang dipertahankan.
      for (final e in _goals)
        if (!orderedIds.contains(e.id)) e,
    ];
    _goals
      ..clear()
      ..addAll([
        for (var i = 0; i < ordered.length; i++)
          ordered[i].copyWith(priority: i),
      ]);
    return mockDelay(null);
  }
}

class MockPurchaseDecisionRepository
    implements PurchaseDecisionRepository {
  final List<PurchaseConsideration> _items =
      List.of(MockData.tahanDuluItems);

  @override
  Future<List<PurchaseConsideration>> getConsiderations() =>
      mockDelay(List.of(_items));

  @override
  Future<PurchaseConsideration> addConsideration(
    PurchaseConsideration item,
  ) {
    _items.add(item);
    return mockDelay(item);
  }

  @override
  Future<PurchaseConsideration> updateConsideration(
    PurchaseConsideration item,
  ) {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index == -1) throw StateError('Barang tidak ditemukan');
    _items[index] = item;
    return mockDelay(item);
  }
}

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository();

  /// Seed menyerupai referensi visual (dibuat relatif terhadap hari ini
  /// agar pengelompokan Hari ini / Kemarin selalu benar).
  List<AppNotification> _items = _seed();

  static List<AppNotification> _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    return [
      AppNotification(
        id: 'notif-salary',
        title: 'Gaji masuk hari ini',
        message:
            'Jangan lupa alokasikan penghasilanmu sesuai rencana keuangan.',
        createdAt: today.add(const Duration(hours: 10)),
        category: NotificationCategory.salary,
        isReminder: true,
        targetRoute: '/transactions',
      ),
      AppNotification(
        id: 'notif-goal',
        title: 'Target tabungan',
        message: 'Kamu sudah mencapai 65% dari target Dana Darurat.',
        createdAt: today.add(const Duration(hours: 8, minutes: 30)),
        category: NotificationCategory.savingsGoal,
        targetRoute: '/goals',
      ),
      AppNotification(
        id: 'notif-tahandulu',
        title: 'TahanDulu selesai',
        message:
            'Waktu tunggu pembelian Adidas Samba sudah selesai. '
            'Saatnya menentukan keputusan.',
        createdAt: today.add(const Duration(hours: 8)),
        category: NotificationCategory.tahandulu,
        isReminder: true,
        targetRoute: '/tahan-dulu',
      ),
      AppNotification(
        id: 'notif-saving',
        title: 'Pengingat menabung',
        message:
            'Sudah waktunya menyisihkan Rp200.000 untuk targetmu.',
        createdAt: yesterday.add(const Duration(hours: 19)),
        isRead: true,
        category: NotificationCategory.savingsReminder,
        isReminder: true,
        targetRoute: '/notifications/savings',
      ),
      AppNotification(
        id: 'notif-budget',
        title: 'Pengeluaran mendekati batas',
        message:
            'Pengeluaran fleksibelmu sudah mencapai 80% dari budget '
            'bulan ini.',
        createdAt: yesterday.add(const Duration(hours: 15, minutes: 30)),
        isRead: true,
        category: NotificationCategory.budget,
        targetRoute: '/reports',
      ),
    ];
  }

  final List<ReminderPreference> _preferences = [
    for (final type in ReminderType.values)
      ReminderPreference(type: type),
  ];

  SavingReminderConfig _savingReminder = const SavingReminderConfig();

  /// Reset ke seed (dipakai test agar terisolasi).
  void reset() {
    _items = _seed();
    _preferences
      ..clear()
      ..addAll([
        for (final type in ReminderType.values)
          ReminderPreference(type: type),
      ]);
    _savingReminder = const SavingReminderConfig();
  }

  @override
  Future<List<AppNotification>> getNotifications() =>
      mockDelay(List.of(_items));

  @override
  Future<void> markAsRead(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1 && !_items[index].isRead) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
    return mockDelay(null);
  }

  @override
  Future<void> markAllAsRead() {
    _items = [for (final e in _items) e.copyWith(isRead: true)];
    return mockDelay(null);
  }

  @override
  Future<List<ReminderPreference>> getPreferences() =>
      mockDelay(List.of(_preferences));

  @override
  Future<void> setPreference(ReminderType type, bool enabled) {
    final index = _preferences.indexWhere((e) => e.type == type);
    if (index != -1) {
      _preferences[index] = _preferences[index].copyWith(enabled: enabled);
    }
    return mockDelay(null);
  }

  @override
  Future<SavingReminderConfig> getSavingReminder() =>
      mockDelay(_savingReminder);

  @override
  Future<SavingReminderConfig> saveSavingReminder(
    SavingReminderConfig config,
  ) {
    if (config.amount <= 0) throw ArgumentError('Nominal harus > 0');
    _savingReminder = config;
    return mockDelay(_savingReminder);
  }

  @override
  Future<SavingReminderConfig> deactivateSavingReminder() {
    _savingReminder = _savingReminder.copyWith(enabled: false);
    return mockDelay(_savingReminder);
  }
}
