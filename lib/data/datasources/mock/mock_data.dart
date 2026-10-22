import '../../models/app_notification.dart';
import '../../models/financial_goal.dart';
import '../../models/financial_instrument.dart';
import '../../models/purchase_consideration.dart';
import '../../models/recurring_expense.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';

/// DATA DEMO CANONICAL — satu-satunya sumber angka mock UI.
/// Jangan membuat angka demo berbeda tanpa alasan.
///
/// User: Bayu Firmansyah
/// Income 5.000.000 | Expense 2.450.000 | Saving 800.000
/// Investment 500.000 | Remaining 1.250.000
/// Flexible Budget 2.000.000 | Safe Spending Today 40.000
/// Target Investasi 3.500.000 / 10.000.000
/// TahanDulu: Adidas Samba Rp750.000
/// Instrumen kanonis: BCA 5.000.000 (Bank), Bank Jago 1.000.000
/// (Bank Digital), GoPay 500.000 (E-Wallet), Total 6.500.000
abstract final class MockData {
  static const user = UserModel(
    id: 'user-1',
    name: 'Bayu Firmansyah',
  );

  static const double income = 5000000;
  static const double expense = 2450000;
  static const double saving = 800000;
  static const double investment = 500000;
  static const double remaining = 1250000;
  static const double flexibleBudget = 2000000;
  static const double safeSpendingToday = 40000;
  static const int salaryDay = 25;

  /// Instrumen default No.4 (canonical). BCA terpilih sesuai desain.
  /// Tepat tiga jenis (Tahap 16): Bank, Bank Digital, E-Wallet.
  /// ID dan saldo dipertahankan agar relasi/transaksi tidak yatim.
  static const List<FinancialInstrument> instruments = [
    FinancialInstrument(
      id: 'inst-bca',
      name: 'BCA',
      type: InstrumentType.bank,
      initialBalance: 5000000,
      institutionName: 'BCA',
      monthlyAdminFee: 14000,
      adminFeeDay: 15,
      isSelected: true,
    ),
    FinancialInstrument(
      id: 'inst-jago',
      name: 'Bank Jago',
      type: InstrumentType.digitalBank,
      initialBalance: 1000000,
    ),
    FinancialInstrument(
      id: 'inst-cash',
      name: 'GoPay',
      type: InstrumentType.ewallet,
      initialBalance: 500000,
    ),
  ];

  static const FinancialGoal investmentGoal = FinancialGoal(
    id: 'goal-investment',
    name: 'Target Investasi',
    targetAmount: 10000000,
    currentAmount: 3500000,
    category: GoalCategory.investment,
  );

  /// Target default No.7 (canonical): Investasi Rp10.000.000, Juni 2027.
  static final FinancialGoal defaultGoal = FinancialGoal(
    id: 'goal-onboarding',
    name: 'Investasi',
    targetAmount: 10000000,
    currentAmount: 0,
    deadline: DateTime(2027, 6, 30),
    category: GoalCategory.investment,
  );

  /// Pengeluaran rutin default No.5 (canonical). Total Rp2.500.000.
  static const List<RecurringExpense> expenses = [
    RecurringExpense(
      id: 'exp-daily',
      name: 'Kebutuhan sehari-hari',
      category: ExpenseCategory.needs,
      monthlyAmount: 1500000,
    ),
    RecurringExpense(
      id: 'exp-transport',
      name: 'Transportasi',
      category: ExpenseCategory.transport,
      monthlyAmount: 400000,
    ),
    RecurringExpense(
      id: 'exp-bills',
      name: 'Tagihan',
      category: ExpenseCategory.bills,
      monthlyAmount: 300000,
    ),
    RecurringExpense(
      id: 'exp-shopping',
      name: 'Belanja',
      category: ExpenseCategory.shopping,
      monthlyAmount: 300000,
    ),
  ];

  static final List<PurchaseConsideration> tahanDuluItems = [
    PurchaseConsideration(
      id: 'td-1',
      itemName: 'Adidas Samba',
      price: 750000,
      status: ConsiderationStatus.considering,
      createdAt: DateTime(2026, 10, 1),
      reason: 'Pikir sebelum beli — masih dipertimbangkan.',
      category: ProductCategory.fashion,
    ),
  ];

  static final List<AppTransaction> recentTransactions = [
    AppTransaction(
      id: 'trx-1',
      title: 'Gaji Bulanan',
      amount: 5000000,
      type: TransactionType.income,
      date: DateTime(2026, 10, 1),
      category: 'Pemasukan',
      accountId: 'acc-bca',
    ),
    AppTransaction(
      id: 'trx-2',
      title: 'Belanja Bulanan',
      amount: 850000,
      type: TransactionType.expense,
      date: DateTime(2026, 10, 3),
      category: 'Kebutuhan',
      accountId: 'acc-dana',
    ),
    AppTransaction(
      id: 'trx-3',
      title: 'Top Up Investasi',
      amount: 500000,
      type: TransactionType.expense,
      date: DateTime(2026, 10, 5),
      category: 'Investasi',
      accountId: 'acc-bibit',
    ),
  ];

  static final List<AppNotification> notifications = [
    AppNotification(
      id: 'notif-1',
      title: 'Pengingat Budget',
      message: 'Batas aman hari ini Rp40.000. Pikir sebelum beli.',
      createdAt: DateTime(2026, 10, 8, 9, 0),
    ),
    AppNotification(
      id: 'notif-2',
      title: 'TahanDulu',
      message: 'Adidas Samba (Rp750.000) masih dalam pertimbangan.',
      createdAt: DateTime(2026, 10, 7, 18, 30),
    ),
  ];
}

/// Simulasi latency mock agar siap diganti Laravel API tanpa ubah UI.
Future<T> mockDelay<T>(T value, [int millis = 300]) =>
    Future.delayed(Duration(milliseconds: millis), () => value);
