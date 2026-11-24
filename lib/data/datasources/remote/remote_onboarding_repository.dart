import '../../../core/utils/uuid_generator.dart';
import '../../../data/models/api_financial_goal.dart';
import '../../../data/models/api_financial_instrument.dart';
import '../../../data/models/api_recurring_transaction.dart';
import '../../../data/models/financial_goal.dart';
import '../../../data/models/financial_instrument.dart';
import '../../../data/models/onboarding_data.dart';
import '../../../data/models/recurring_expense.dart';
import '../../../data/repositories/onboarding_repository.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi [OnboardingRepository] di atas Laravel API.
///
/// Data onboarding:
/// - No.3 (gaji): disimpan ke `PUT /api/user` (monthly_income & salary_day)
/// - No.4 (instrumen): disimpan ke `POST /api/financial-instruments`
/// - No.5 (pengeluaran rutin): disimpan ke `POST /api/recurring-expenses`
/// - No.7 (target): disimpan ke `POST /api/goals`
class RemoteOnboardingRepository implements OnboardingRepository {
  RemoteOnboardingRepository({
    required this._client,
    required this._tokens,
    this.onUnauthorized,
  });

  final ApiClient _client;
  final TokenStore _tokens;
  final void Function()? onUnauthorized;

  double _cachedIncome = 0;
  int _cachedSalaryDay = 25;
  final List<FinancialInstrument> _cachedInstruments = [];
  final List<RecurringExpense> _cachedExpenses = [];
  FinancialGoal? _cachedGoal;

  static ExpenseCategory _mapExpenseCategory(String? category) {
    switch (category?.toLowerCase().trim()) {
      case 'needs':
      case 'kebutuhan_pokok':
      case 'pokok':
        return ExpenseCategory.needs;
      case 'transport':
      case 'transportasi':
        return ExpenseCategory.transport;
      case 'bills':
      case 'tagihan':
        return ExpenseCategory.bills;
      case 'shopping':
      case 'belanja':
        return ExpenseCategory.shopping;
      case 'others':
      default:
        return ExpenseCategory.others;
    }
  }

  static GoalCategory _toGoalCategory(String? type) {
    switch (type?.toLowerCase()) {
      case 'emergency':
        return GoalCategory.emergency;
      case 'savings':
        return GoalCategory.savings;
      case 'investment':
        return GoalCategory.investment;
      case 'house':
        return GoalCategory.house;
      case 'vehicle':
        return GoalCategory.vehicle;
      case 'gadget':
        return GoalCategory.gadget;
      case 'holiday':
        return GoalCategory.holiday;
      case 'education':
        return GoalCategory.education;
      default:
        return GoalCategory.others;
    }
  }

  static InstrumentType mapType(String? type) {
    switch (type?.toLowerCase()) {
      case 'bank':
        return InstrumentType.bank;
      case 'digitalbank':
      case 'digital bank':
        return InstrumentType.digitalBank;
      case 'ewallet':
      case 'e-wallet':
      case 'e wallet':
        return InstrumentType.ewallet;
      case 'cash':
      case 'uang tunai':
      case 'tunai':
        return InstrumentType.cash;
      default:
        return InstrumentType.bank;
    }
  }

  Future<String> _requireToken() async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) {
      onUnauthorized?.call();
      throw ApiException('Token tidak tersedia. Silakan login ulang.',
          statusCode: 401);
    }
    return token;
  }

  @override
  OnboardingData? getSalarySetup() {
    if (_cachedIncome > 0) {
      return OnboardingData(
        monthlyIncome: _cachedIncome,
        salaryDay: _cachedSalaryDay,
        financialInstruments: List.unmodifiable(_cachedInstruments),
        recurringExpenses: List.unmodifiable(_cachedExpenses),
        financialGoal: _cachedGoal,
      );
    }
    return null;
  }

  @override
  Future<OnboardingData> saveSalarySetup({
    required double monthlyIncome,
    required int salaryDay,
  }) async {
    final token = await _requireToken();
    await _client.put(
      '/user',
      {
        'monthly_income': monthlyIncome.round(),
        'salary_day': salaryDay,
      },
      token: token,
    );

    _cachedIncome = monthlyIncome;
    _cachedSalaryDay = salaryDay;

    return OnboardingData(
      monthlyIncome: monthlyIncome,
      salaryDay: salaryDay,
      financialInstruments: List.unmodifiable(_cachedInstruments),
      recurringExpenses: List.unmodifiable(_cachedExpenses),
      financialGoal: _cachedGoal,
    );
  }

  @override
  OnboardingData? getOnboardingData() {
    if (_cachedIncome > 0 || _cachedInstruments.isNotEmpty) {
      return OnboardingData(
        monthlyIncome: _cachedIncome,
        salaryDay: _cachedSalaryDay,
        financialInstruments: List.unmodifiable(_cachedInstruments),
        recurringExpenses: List.unmodifiable(_cachedExpenses),
        financialGoal: _cachedGoal,
      );
    }
    return null;
  }

  /// Ambil gaji dan hari gajian pengguna saat ini dari backend.
  @override
  Future<({double income, int salaryDay})> fetchExistingSalary() async {
    final token = await _requireToken();
    try {
      final body = await _client.get('/me', token: token);
      final data = body['data'] as Map<String, dynamic>?;
      if (data != null) {
        final inc = (data['monthly_income'] is num)
            ? (data['monthly_income'] as num).toDouble()
            : (double.tryParse('${data['monthly_income']}') ?? 0.0);
        final day = (data['salary_day'] is int)
            ? data['salary_day'] as int
            : (int.tryParse('${data['salary_day']}') ?? 25);
        if (inc > 0) _cachedIncome = inc;
        if (day >= 1 && day <= 31) _cachedSalaryDay = day;
      }
    } catch (_) {}
    return (income: _cachedIncome, salaryDay: _cachedSalaryDay);
  }

  /// Ambil instrumen yang sudah tersimpan di backend pengguna saat ini.
  @override
  Future<List<FinancialInstrument>> fetchExistingInstruments() async {
    final token = await _requireToken();
    try {
      final body = await _client.get('/financial-instruments', token: token);
      final resp = ApiFinancialInstrumentsResponse.fromJson(body);
      final items = resp.data
          .map((e) => FinancialInstrument(
                id: e.id.toString(),
                name: e.name,
                type: mapType(e.type?.type),
                typeId: e.type?.id,
                bankId: e.bank?.id,
                bankSlug: e.bank?.slug,
                initialBalance: e.balance.toDouble(),
                institutionName: e.bank?.name ?? e.type?.name,
                monthlyAdminFee: e.monthlyAdminFee.toDouble(),
                adminFeeDay: e.adminFeeDay ?? 15,
                adminFeeEnabled: e.adminFeeEnabled,
                isSelected: true,
              ))
          .toList();
      if (items.isNotEmpty) {
        _cachedInstruments
          ..clear()
          ..addAll(items);
      }
      return List.unmodifiable(_cachedInstruments);
    } catch (_) {
      return List.unmodifiable(_cachedInstruments);
    }
  }

  /// Ambil pengeluaran rutin tersimpan di backend pengguna saat ini.
  @override
  Future<List<RecurringExpense>> fetchExistingExpenses() async {
    final token = await _requireToken();
    try {
      final body = await _client.get('/recurring-expenses', token: token);
      final resp = ApiRecurringTransactionsResponse.fromJson(body);
      final items = resp.data
          .where((e) => e.type.toLowerCase() == 'expense' && e.isActive)
          .map((e) => RecurringExpense(
                id: e.id.toString(),
                name: e.title,
                category: _mapExpenseCategory(e.category),
                monthlyAmount: e.amount.toDouble(),
              ))
          .toList();
      if (items.isNotEmpty) {
        _cachedExpenses
          ..clear()
          ..addAll(items);
      }
      return List.unmodifiable(_cachedExpenses);
    } catch (_) {
      return List.unmodifiable(_cachedExpenses);
    }
  }

  /// Ambil target keuangan aktif dari backend pengguna saat ini.
  @override
  Future<FinancialGoal?> fetchExistingGoal() async {
    final token = await _requireToken();
    try {
      final body = await _client.get('/goals', token: token);
      final resp = ApiFinancialGoalsResponse.fromJson(body);
      final activeGoals = resp.data.where((g) => g.isActive).toList();
      if (activeGoals.isNotEmpty) {
        final g = activeGoals.first;
        final mapped = FinancialGoal(
          id: g.id.toString(),
          name: g.title,
          targetAmount: g.targetAmount.toDouble(),
          currentAmount: g.currentAmount.toDouble(),
          deadline: g.parsedTargetDate,
          category: _toGoalCategory(g.type),
          frequency: g.frequency.toLowerCase() == 'weekly'
              ? DepositFrequency.weekly
              : DepositFrequency.monthly,
        );
        _cachedGoal = mapped;
      }
      return _cachedGoal;
    } catch (_) {
      return _cachedGoal;
    }
  }

  /// Hidrasi penuh seluruh state onboarding dari backend.
  @override
  Future<OnboardingData?> hydrateAll() async {
    await fetchExistingSalary();
    await fetchExistingInstruments();
    await fetchExistingExpenses();
    await fetchExistingGoal();
    return getOnboardingData();
  }

  @override
  Future<OnboardingData> saveInstruments(
    List<FinancialInstrument> instruments,
  ) async {
    final token = await _requireToken();
    final saved = <FinancialInstrument>[];

    for (final instrument in instruments) {
      final payload = <String, dynamic>{
        'name': instrument.name,
        'balance': instrument.initialBalance.round(),
        'monthly_admin_fee': instrument.adminFeeEnabled
            ? instrument.monthlyAdminFee.round()
            : 0,
        'admin_fee_day':
            instrument.adminFeeEnabled ? instrument.adminFeeDay : null,
        'admin_fee_enabled': instrument.adminFeeEnabled,
        'is_active': true,
      };
      if (instrument.typeId != null) payload['type_id'] = instrument.typeId;
      if (instrument.bankId != null) payload['bank_id'] = instrument.bankId;
      if (instrument.bankSlug != null && instrument.bankSlug!.isNotEmpty) {
        payload['bank_slug'] = instrument.bankSlug;
      }

      final isExistingBackendId = isBackendId(instrument.id);
      if (!isExistingBackendId) {
        payload['idempotency_key'] = 'onboarding-${instrument.id}';
      }
      final Map<String, dynamic> body;
      if (isExistingBackendId) {
        // Hindari duplikasi: perbarui instrumen yang sudah memiliki ID backend
        body = await _client.put(
          '/financial-instruments/${instrument.id}',
          payload,
          token: token,
        );
      } else {
        body = await _client.post(
          '/financial-instruments',
          payload,
          token: token,
        );
      }

      final resp =
          ApiFinancialInstrument.fromJson(body['data'] as Map<String, dynamic>);
      saved.add(instrument.copyWith(
        id: resp.id.toString(),
        typeId: resp.type?.id ?? instrument.typeId,
        bankId: resp.bank?.id ?? instrument.bankId,
        bankSlug: resp.bank?.slug ?? instrument.bankSlug,
        monthlyAdminFee: resp.monthlyAdminFee.toDouble(),
        adminFeeDay: resp.adminFeeDay ?? instrument.adminFeeDay,
        adminFeeEnabled: resp.adminFeeEnabled,
      ));
    }

    _cachedInstruments
      ..clear()
      ..addAll(saved);

    return OnboardingData(
      monthlyIncome: _cachedIncome,
      salaryDay: _cachedSalaryDay,
      financialInstruments: List.unmodifiable(_cachedInstruments),
      recurringExpenses: List.unmodifiable(_cachedExpenses),
      financialGoal: _cachedGoal,
    );
  }

  @override
  Future<OnboardingData> saveExpenses(List<RecurringExpense> expenses) async {
    final token = await _requireToken();
    final saved = <RecurringExpense>[];

    final now = DateTime.now();
    final nextDueDate = DateTime(now.year, now.month, now.day)
        .toIso8601String()
        .substring(0, 10);

    for (final expense in expenses) {
      final payload = <String, dynamic>{
        'title': expense.name,
        'category': expense.category.name,
        'amount': expense.monthlyAmount.round(),
        'frequency': 'monthly',
        'next_due_date': nextDueDate,
        'instrument_id': null,
        'is_active': true,
        'make_automatic': false,
      };

      final isExistingBackendId = isBackendId(expense.id);
      final Map<String, dynamic> body;
      if (isExistingBackendId) {
        // Hindari duplikasi: perbarui pengeluaran rutin yang sudah tersimpan
        body = await _client.put(
          '/recurring-expenses/${expense.id}',
          payload,
          token: token,
        );
      } else {
        body = await _client.post(
          '/recurring-expenses',
          payload,
          token: token,
        );
      }

      final resp =
          ApiRecurringTransaction.fromJson(body['data'] as Map<String, dynamic>);
      saved.add(expense.copyWith(
        id: resp.id.toString(),
      ));
    }

    _cachedExpenses
      ..clear()
      ..addAll(saved);

    return OnboardingData(
      monthlyIncome: _cachedIncome,
      salaryDay: _cachedSalaryDay,
      financialInstruments: List.unmodifiable(_cachedInstruments),
      recurringExpenses: List.unmodifiable(_cachedExpenses),
      financialGoal: _cachedGoal,
    );
  }

  @override
  Future<OnboardingData> saveGoal(FinancialGoal goal) async {
    final token = await _requireToken();
    final payload = <String, dynamic>{
      'title': goal.name,
      'type': goal.category.name,
      'target_amount': goal.targetAmount.round(),
      'current_amount': 0,
      'target_date': goal.deadline?.toIso8601String(),
      'reminder_date': null,
      'frequency': goal.frequency.name,
      'is_active': true,
    };

    final existingId = isBackendId(goal.id)
        ? goal.id
        : (isBackendId(_cachedGoal?.id) ? _cachedGoal!.id : null);

    final Map<String, dynamic> body;
    if (existingId != null) {
      // Hindari duplikasi: perbarui target yang sudah tersimpan
      body = await _client.put(
        '/goals/$existingId',
        payload,
        token: token,
      );
    } else {
      body = await _client.post(
        '/goals',
        payload,
        token: token,
      );
    }

    final resp = ApiFinancialGoal.fromJson(body['data'] as Map<String, dynamic>);

    _cachedGoal = goal.copyWith(
      id: resp.id.toString(),
    );

    return OnboardingData(
      monthlyIncome: _cachedIncome,
      salaryDay: _cachedSalaryDay,
      financialInstruments: List.unmodifiable(_cachedInstruments),
      recurringExpenses: List.unmodifiable(_cachedExpenses),
      financialGoal: _cachedGoal,
    );
  }

  // -------------------------------------------------------------------------
  // CRUD instrumen (sumber tunggal untuk fitur Akun).
  // -------------------------------------------------------------------------

  @override
  Future<FinancialInstrument> addInstrument(
    FinancialInstrument instrument,
  ) async {
    final token = await _requireToken();
    final payload = <String, dynamic>{
      'name': instrument.name,
      'balance': instrument.initialBalance.round(),
      'monthly_admin_fee': instrument.adminFeeEnabled
          ? instrument.monthlyAdminFee.round()
          : 0,
      'admin_fee_day':
          instrument.adminFeeEnabled ? instrument.adminFeeDay : null,
      'admin_fee_enabled': instrument.adminFeeEnabled,
      'is_active': true,
    };
    if (instrument.typeId != null) payload['type_id'] = instrument.typeId;
    if (instrument.bankId != null) payload['bank_id'] = instrument.bankId;
    if (instrument.bankSlug != null && instrument.bankSlug!.isNotEmpty) {
      payload['bank_slug'] = instrument.bankSlug;
    }

    final body = await _client.post(
      '/financial-instruments',
      payload,
      token: token,
    );
    final resp =
        ApiFinancialInstrument.fromJson(body['data'] as Map<String, dynamic>);
    final saved = instrument.copyWith(
      id: resp.id.toString(),
      typeId: resp.type?.id ?? instrument.typeId,
      bankId: resp.bank?.id ?? instrument.bankId,
      bankSlug: resp.bank?.slug ?? instrument.bankSlug,
      monthlyAdminFee: resp.monthlyAdminFee.toDouble(),
      adminFeeDay: resp.adminFeeDay ?? instrument.adminFeeDay,
      adminFeeEnabled: resp.adminFeeEnabled,
    );
    _cachedInstruments.add(saved);
    return saved;
  }

  @override
  Future<FinancialInstrument> updateInstrument(
    FinancialInstrument instrument,
  ) async {
    final token = await _requireToken();
    final payload = <String, dynamic>{
      'name': instrument.name,
      'balance': instrument.initialBalance.round(),
      'monthly_admin_fee': instrument.adminFeeEnabled
          ? instrument.monthlyAdminFee.round()
          : 0,
      'admin_fee_day':
          instrument.adminFeeEnabled ? instrument.adminFeeDay : null,
      'admin_fee_enabled': instrument.adminFeeEnabled,
      'is_active': true,
    };
    if (instrument.typeId != null) payload['type_id'] = instrument.typeId;
    if (instrument.bankId != null) payload['bank_id'] = instrument.bankId;
    if (instrument.bankSlug != null && instrument.bankSlug!.isNotEmpty) {
      payload['bank_slug'] = instrument.bankSlug;
    }

    final body = await _client.put(
      '/financial-instruments/${instrument.id}',
      payload,
      token: token,
    );
    final resp =
        ApiFinancialInstrument.fromJson(body['data'] as Map<String, dynamic>);
    final updated = instrument.copyWith(
      id: resp.id.toString(),
      typeId: resp.type?.id ?? instrument.typeId,
      bankId: resp.bank?.id ?? instrument.bankId,
      bankSlug: resp.bank?.slug ?? instrument.bankSlug,
      monthlyAdminFee: resp.monthlyAdminFee.toDouble(),
      adminFeeDay: resp.adminFeeDay ?? instrument.adminFeeDay,
      adminFeeEnabled: resp.adminFeeEnabled,
    );
    final idx = _cachedInstruments.indexWhere((e) => e.id == instrument.id);
    if (idx >= 0) {
      _cachedInstruments[idx] = updated;
    }
    return updated;
  }

  @override
  Future<void> removeInstrument(String id) async {
    final token = await _requireToken();
    await _client.delete('/financial-instruments/$id', token: token);
    _cachedInstruments.removeWhere((e) => e.id == id);
  }

  @override
  void clear() {
    _cachedIncome = 0;
    _cachedSalaryDay = 25;
    _cachedInstruments.clear();
    _cachedExpenses.clear();
    _cachedGoal = null;
  }
}
