import 'dart:async';

import '../../../core/utils/finance_math.dart';
import '../../models/api_financial_goal.dart';
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

  FinancialSummary? _cachedSummary;

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

      final summary = FinancialSummary(
        income: actualMonthIncome,
        expense: actualMonthExpense,
        saving: saving,
        investment: investment,
        remaining: remaining,
        flexibleBudget: flexibleBudget,
        safeSpendingToday: safeDaily,
        isStale: false,
      );
      _cachedSummary = summary;
      return summary;
    } catch (e) {
      // Kebijakan F06C: Jika server gagal memberikan /dashboard/summary otoritatif:
      // 1. Jika ada cache dari panggilan sukses sebelumnya, kembalikan cache bertanda isStale = true.
      if (_cachedSummary != null) {
        return _cachedSummary!.copyWith(isStale: true);
      }
      // 2. JANGAN PERNAH menghitung sebagian dari 15 transaksi lokal secara diam-diam!
      //    Lempar error agar UI menampilkan status gagal / tombol coba lagi yang jelas.
      if (e is ApiException) rethrow;
      throw ApiException(
        'Gagal memuat ringkasan keuangan otoritatif dari server. Silakan coba lagi.',
      );
    }
  }
}
