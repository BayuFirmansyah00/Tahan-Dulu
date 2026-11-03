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

  /// Ambil instrumen yang sudah tersimpan di backend pengguna saat ini.
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
                initialBalance: e.balance.toDouble(),
                institutionName: e.type?.name,
                isSelected: true,
              ))
          .toList();
      _cachedInstruments
        ..clear()
        ..addAll(items);
      return List.unmodifiable(_cachedInstruments);
    } catch (_) {
      return List.unmodifiable(_cachedInstruments);
    }
  }

  @override
  Future<OnboardingData> saveInstruments(
    List<FinancialInstrument> instruments,
  ) async {
    final token = await _requireToken();
    final saved = <FinancialInstrument>[];

    for (final instrument in instruments) {
      final body = await _client.post(
        '/financial-instruments',
        {
          'name': instrument.name,
          'type_id': instrument.typeId ?? 1,
          'balance': instrument.initialBalance.round(),
          'is_active': true,
        },
        token: token,
      );
      final resp =
          ApiFinancialInstrument.fromJson(body['data'] as Map<String, dynamic>);
      saved.add(instrument.copyWith(
        id: resp.id.toString(),
        typeId: resp.type?.id ?? instrument.typeId,
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
      final body = await _client.post(
        '/recurring-expenses',
        {
          'title': expense.name,
          'category': expense.category.name,
          'amount': expense.monthlyAmount.round(),
          'frequency': 'monthly',
          'next_due_date': nextDueDate,
          'instrument_id': null,
          'is_active': true,
          'make_automatic': false,
        },
        token: token,
      );
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
    final body = await _client.post(
      '/goals',
      {
        'title': goal.name,
        'type': goal.category.name,
        'target_amount': goal.targetAmount.round(),
        'current_amount': 0,
        'target_date': goal.deadline?.toIso8601String(),
        'reminder_date': null,
        'frequency': goal.frequency.name,
        'is_active': true,
      },
      token: token,
    );
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
    final body = await _client.post(
      '/financial-instruments',
      {
        'name': instrument.name,
        'type_id': instrument.typeId ?? 1,
        'balance': instrument.initialBalance.round(),
        'is_active': true,
      },
      token: token,
    );
    final resp =
        ApiFinancialInstrument.fromJson(body['data'] as Map<String, dynamic>);
    final saved = instrument.copyWith(
      id: resp.id.toString(),
      typeId: resp.type?.id ?? instrument.typeId,
    );
    _cachedInstruments.add(saved);
    return saved;
  }

  @override
  Future<FinancialInstrument> updateInstrument(
    FinancialInstrument instrument,
  ) async {
    final token = await _requireToken();
    final body = await _client.put(
      '/financial-instruments/${instrument.id}',
      {
        'name': instrument.name,
        'type_id': instrument.typeId ?? 1,
        'balance': instrument.initialBalance.round(),
        'is_active': true,
      },
      token: token,
    );
    final resp =
        ApiFinancialInstrument.fromJson(body['data'] as Map<String, dynamic>);
    final updated = instrument.copyWith(
      id: resp.id.toString(),
      typeId: resp.type?.id ?? instrument.typeId,
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
