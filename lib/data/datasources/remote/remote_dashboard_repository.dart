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
    );
  }

  @override
  Future<FinancialSummary> getSummary() async {
    final token = await _requireToken();

    // Panggil tiga endpoint secara paralel.
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

    // --- Total saldo dari instrumen keuangan (digunakan sebagai dasar investasi) ---
    final totalBalance = instruments.fold<double>(
      0,
      (sum, e) => sum + e.balance.toDouble(),
    );

    // --- Aktual bulan berjalan dari transaksi (R6) ---
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

    // --- Saving dari aktual bulan ---
    final saving = actualMonthIncome - actualMonthExpense;

    // --- Investasi & kontribusi goal dari daftar target ---
    double investment = totalBalance;
    double goalContribution = 0;
    for (final g in goals) {
      if (g.type.toLowerCase() == 'investment') {
        investment = g.currentAmount.toDouble();
      }
      final deadline = g.parsedTargetDate;
      if (deadline != null) {
        final remaining = (g.targetAmount - g.currentAmount).toDouble();
        if (remaining > 0) {
          final months = monthsUntil(deadline, now: now);
          if (months > 0) {
            goalContribution += remaining / months;
          }
        }
      }
    }

    // --- Sisa fleksibel (R4) ---
    final remaining = saving - goalContribution;

    // --- Anggaran fleksibel ---
    final flexibleBudget = remaining;

    // --- Aman harian (R5) ---
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
