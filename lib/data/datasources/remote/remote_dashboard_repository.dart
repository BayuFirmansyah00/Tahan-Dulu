import 'dart:async';

import '../../../core/utils/finance_math.dart';
import '../../models/api_financial_goal.dart';
import '../../models/api_financial_instrument.dart';
import '../../models/api_transaction.dart';
import '../../models/financial_summary.dart';
import '../../models/user_model.dart';
import '../../repositories/repositories.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi [DashboardRepository] yang menyusun ringkasan keuangan dari
/// beberapa endpoint Laravel secara paralel (Future.wait), lalu menghitung
/// agregat di sisi klien karena backend tidak menyediakan endpoint /api/dashboard.
///
/// Endpoint yang dipanggil:
///   - GET /api/transactions
///   - GET /api/financial-instrumen
///   - GET /api/goals
///   - GET /api/me (untuk profil user)
class RemoteDashboardRepository implements DashboardRepository {
  RemoteDashboardRepository({
    required this._client,
    required this._tokens,
    this.onUnauthorized,
  });

  final ApiClient _client;
  final TokenStore _tokens;
  final void Function()? onUnauthorized;

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
  Future<UserModel> getUser() async {
    final token = await _requireToken();
    final body = await _client.get('/me', token: token);
    final data = body['data'] as Map<String, dynamic>;
    return UserModel(
      id: '${data['id']}',
      name: '${data['name'] ?? ''}',
      email: data['email'] as String?,
      bio: data['bio'] as String?,
      monthlyIncome: data['monthly_income'] != null
          ? (data['monthly_income'] is int
                ? data['monthly_income'] as int
                : int.tryParse('${data['monthly_income']}'))
          : null,
      salaryDay: data['salary_day'] != null
          ? (data['salary_day'] is int
                ? data['salary_day'] as int
                : int.tryParse('${data['salary_day']}'))
          : null,
      isOnboarded: data['is_onboarded'] as bool? ?? false,
    );
  }

  @override
  Future<FinancialSummary> getSummary() async {
    final token = await _requireToken();

    try {
      // Panggil GET /dashboard/summary dan GET /goals secara paralel untuk agregat otoritatif
      final results = await Future.wait([
        _client.get('/dashboard/summary', token: token),
        _client.get('/goals', token: token),
      ]);

      final dashboardBody = results[0];
      final goalsResp = ApiFinancialGoalsResponse.fromJson(results[1]);

      final data = dashboardBody['data'] as Map<String, dynamic>? ?? {};
      final overview = data['overview'] as Map<String, dynamic>? ?? {};
      final monthlyCashflow = data['monthly_cashflow'] as Map<String, dynamic>? ?? {};

      final actualMonthIncome = (monthlyCashflow['income'] as num?)?.toDouble() ?? 0.0;
      final actualMonthExpense = (monthlyCashflow['expense'] as num?)?.toDouble() ?? 0.0;
      final saving = (monthlyCashflow['cash_flow'] as num?)?.toDouble() ??
          (actualMonthIncome - actualMonthExpense);
      final investment = (overview['total_investment_value'] as num?)?.toDouble() ?? 0.0;

      final now = DateTime.now();
      double goalContribution = 0;
      for (final g in goalsResp.data) {
        final deadline = g.parsedTargetDate;
        if (deadline != null) {
          final rem = (g.targetAmount - g.currentAmount).toDouble();
          if (rem > 0) {
            final months = monthsUntil(deadline, now: now);
            if (months > 0) {
              goalContribution += rem / months;
            }
          }
        }
      }

      final remaining = saving - goalContribution;
      final flexibleBudget = remaining;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final safeDaily = daysInMonth > 0 && remaining > 0
          ? (remaining / daysInMonth ~/ 1000) * 1000.0
          : 0.0;

      return FinancialSummary(
        income: actualMonthIncome,
        expense: actualMonthExpense,
        saving: saving,
        investment: investment,
        remaining: remaining,
        flexibleBudget: flexibleBudget,
        safeSpendingToday: safeDaily,
      );
    } catch (_) {
      // Fallback jika /dashboard/summary gagal
      final results = await Future.wait([
        _client.get('/transactions', token: token),
        _client.get('/financial-instruments', token: token),
        _client.get('/goals', token: token),
      ]);

      final transactionsResp = ApiTransactionsResponse.fromJson(results[0]);
      final instrumentsResp = ApiFinancialInstrumentsResponse.fromJson(results[1]);
      final goalsResp = ApiFinancialGoalsResponse.fromJson(results[2]);

      final transactions = transactionsResp.data;
      final instruments = instrumentsResp.data;
      final goals = goalsResp.data;

      final now = DateTime.now();

      final totalBalance = instruments.fold<double>(
        0,
        (sum, e) => sum + e.balance.toDouble(),
      );

      double actualMonthIncome = 0;
      double actualMonthExpense = 0;
      for (final t in transactions) {
        final date = t.parsedCreatedAt;
        if (date != null && date.year == now.year && date.month == now.month) {
          if (t.type == 'income') {
            actualMonthIncome += t.amount.toDouble();
          } else {
            actualMonthExpense += t.amount.toDouble();
          }
        }
      }

      final saving = actualMonthIncome - actualMonthExpense;
      double investment = totalBalance;
      double goalContribution = 0;
      for (final g in goals) {
        if (g.type.toLowerCase() == 'investment') {
          investment = g.currentAmount.toDouble();
        }
        final deadline = g.parsedTargetDate;
        if (deadline != null) {
          final rem = (g.targetAmount - g.currentAmount).toDouble();
          if (rem > 0) {
            final months = monthsUntil(deadline, now: now);
            if (months > 0) {
              goalContribution += rem / months;
            }
          }
        }
      }

      final remaining = saving - goalContribution;
      final flexibleBudget = remaining;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final safeDaily = daysInMonth > 0 && remaining > 0
          ? (remaining / daysInMonth ~/ 1000) * 1000.0
          : 0.0;

      return FinancialSummary(
        income: actualMonthIncome,
        expense: actualMonthExpense,
        saving: saving,
        investment: investment,
        remaining: remaining,
        flexibleBudget: flexibleBudget,
        safeSpendingToday: safeDaily,
      );
    }
  }
}
