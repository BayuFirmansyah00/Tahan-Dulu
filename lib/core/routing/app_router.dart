import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/features/auth/presentation/screens/login_screen.dart';
import 'package:tahan_dulu/features/auth/presentation/screens/register_screen.dart';
import 'package:tahan_dulu/features/auth/presentation/providers/auth_controller.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/about_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/app_settings_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/help_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/privacy_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/profile_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/security_screen.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/saving_reminder_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/account_detail_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/add_account_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/edit_account_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/transfer_screen.dart';
import 'package:tahan_dulu/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_create_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_deposit_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_detail_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_edit_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_history_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_priority_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_setup_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_simulate_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goals_list_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_add_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_analysis_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_decide_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_form_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_link_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_list_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_simulate_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_success_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_wait_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_form_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_record_method_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_review_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_scan_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_success_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_voice_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:tahan_dulu/features/investment/presentation/screens/add_investment_screen.dart';
import 'package:tahan_dulu/features/investment/presentation/screens/investments_screen.dart';
import 'package:tahan_dulu/features/recurring/presentation/screens/add_recurring_expense_screen.dart';
import 'package:tahan_dulu/features/recurring/presentation/screens/add_recurring_income_screen.dart';
import 'package:tahan_dulu/features/recurring/presentation/screens/recurring_expenses_screen.dart';
import 'package:tahan_dulu/features/recurring/presentation/screens/recurring_incomes_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/expenses_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/goals_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/plan_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_expenses_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_export_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_health_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_savings_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/reports_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/budget_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/instruments_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/salary_screen.dart';
import 'package:tahan_dulu/features/splash/presentation/screens/splash_screen.dart';
import 'app_routes.dart';

/// ChangeNotifier tipis yang membungkus AuthState agar GoRouter dapat
/// menggunakannya sebagai refreshListenable.
class AuthRouteNotifier extends ChangeNotifier {
  AuthState _authState = const AuthState.initial();

  AuthState get authState => _authState;

  void update(AuthState state) {
    _authState = state;
    notifyListeners();
  }
}



/// Transisi antar-menu utama: fade + geser horizontal ringan.
/// 250ms easeOutCubic, berlaku maju dan mundur (back button aman).
CustomTransitionPage<void> tabPage(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Router terpusat (go_router). Path dan nama route tidak berubah;
/// hanya 4 root menu utama memakai [tabPage] agar transisi smooth.
///
/// [authNotifier] digunakan sebagai refreshListenable dan sumber status auth
/// untuk redirect guard. Bila null (backward-compat), guard dinonaktifkan.
GoRouter createAppRouter({AuthRouteNotifier? authNotifier}) {
  // Route-route yang hanya boleh diakses pengguna yang sudah onboarding.
  const protectedPrefixes = [
    AppRoutes.dashboard,
    AppRoutes.transactions,
    AppRoutes.goals,
    AppRoutes.tahanDulu,
    AppRoutes.accounts,
    AppRoutes.investments,
    AppRoutes.recurringIncomes,
    AppRoutes.recurringExpenses,
    AppRoutes.reports,
    AppRoutes.notifications,
    AppRoutes.settings,
  ];

  bool isProtected(String location) =>
      protectedPrefixes.any((p) => location.startsWith(p));

  bool isOnboardingRoute(String location) =>
      location.startsWith(AppRoutes.onboarding);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      if (authNotifier == null) return null;
      final authState = authNotifier.authState;
      final location = state.uri.toString();

      final isAuth = authState.status == AuthStatus.authenticated;
      final isOnboarded = authState.user?.isOnboarded ?? false;

      // Sedang di splash â€” biarkan SplashScreen memutuskan navigasi sendiri.
      if (location == AppRoutes.splash) return null;

      // Belum terautentikasi: boleh akses login, register, splash saja.
      if (!isAuth) {
        if (isProtected(location) || isOnboardingRoute(location)) {
          return AppRoutes.login;
        }
        return null;
      }

      // Sudah autentikasi + sudah onboarding:
      // Jangan kembali ke onboarding atau auth pages.
      if (isOnboarded) {
        if (isOnboardingRoute(location) ||
            location == AppRoutes.login ||
            location == AppRoutes.register) {
          return AppRoutes.dashboard;
        }
        return null;
      }

      // Sudah autentikasi tapi BELUM onboarding:
      // Boleh akses onboarding, logout (settings/security), splash.
      // Blokir semua fitur utama.
      if (isProtected(location)) {
        return AppRoutes.onboardingSalary;
      }
      // Tetap boleh di login/register (edge case: double-navigate).
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        redirect: (context, state) =>
            state.uri.toString() == AppRoutes.onboarding
            ? AppRoutes.onboardingSalary
            : null,
        routes: [
          GoRoute(
            path: 'salary',
            builder: (context, state) => const SalaryScreen(),
          ),
          GoRoute(
            path: 'instruments',
            builder: (context, state) => const InstrumentsScreen(),
          ),
          GoRoute(
            path: 'budget',
            builder: (context, state) => const BudgetScreen(),
          ),
          GoRoute(
            path: 'recurring-expenses',
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: 'goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: 'plan',
            builder: (context, state) => const PlanScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (context, state) =>
            tabPage(state.pageKey, const DashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        pageBuilder: (context, state) => tabPage(
          state.pageKey,
          TransactionsScreen(accountId: state.uri.queryParameters['account']),
        ),
        routes: [
          GoRoute(
            path: 'record-method',
            builder: (context, state) =>
                const TransactionRecordMethodScreen(),
          ),
          GoRoute(
            path: 'voice',
            builder: (context, state) =>
                const TransactionVoiceScreen(),
          ),
          GoRoute(
            path: 'scan',
            builder: (context, state) =>
                const TransactionScanScreen(),
          ),
          GoRoute(
            path: 'add',
            builder: (context, state) {
              final type = state.uri.queryParameters['type'];
              return TransactionFormScreen(
                initialType: type == 'income'
                    ? TransactionType.income
                    : type == 'expense'
                    ? TransactionType.expense
                    : null,
              );
            },
          ),
          GoRoute(
            path: 'review',
            builder: (context, state) => const TransactionReviewScreen(),
          ),
          GoRoute(
            path: 'success',
            builder: (context, state) => const TransactionSuccessScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.goals,
        pageBuilder: (context, state) =>
            tabPage(state.pageKey, const GoalsListScreen()),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const GoalCreateScreen(),
          ),
          GoRoute(
            path: 'setup',
            builder: (context, state) => const GoalSetupScreen(),
          ),
          GoRoute(
            path: 'priority',
            builder: (context, state) => const GoalPriorityScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                GoalDetailScreen(goalId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    GoalEditScreen(goalId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'deposit',
                builder: (context, state) =>
                    GoalDepositScreen(goalId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'history',
                builder: (context, state) =>
                    GoalHistoryScreen(goalId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'simulate',
                builder: (context, state) =>
                    GoalSimulateScreen(goalId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.tahanDulu,
        builder: (context, state) => const TahanDuluListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const TahanDuluAddScreen(),
          ),
          GoRoute(
            path: 'form',
            builder: (context, state) => const TahanDuluFormScreen(),
          ),
          GoRoute(
            path: 'link',
            builder: (context, state) => const TahanDuluLinkScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                TahanDuluAnalysisScreen(itemId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'simulate',
                builder: (context, state) => TahanDuluSimulateScreen(
                  itemId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'wait',
                builder: (context, state) =>
                    TahanDuluWaitScreen(itemId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'decide',
                builder: (context, state) =>
                    TahanDuluDecideScreen(itemId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'success',
                builder: (context, state) =>
                    TahanDuluSuccessScreen(itemId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.accounts,
        builder: (context, state) => const AccountsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddAccountScreen(),
          ),
          GoRoute(
            path: 'transfer',
            builder: (context, state) => TransferScreen(
              initialSourceAccountId: state.uri.queryParameters['from'],
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                AccountDetailScreen(accountId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    EditAccountScreen(accountId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.investments,
        pageBuilder: (context, state) =>
            tabPage(state.pageKey, const InvestmentsScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddInvestmentScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.recurringIncomes,
        pageBuilder: (context, state) =>
            tabPage(state.pageKey, const RecurringIncomesScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddRecurringIncomeScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.recurringExpenses,
        pageBuilder: (context, state) =>
            tabPage(state.pageKey, const RecurringExpensesScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddRecurringExpenseScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'savings',
            builder: (context, state) => const SavingReminderScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.reports,
        pageBuilder: (context, state) =>
            tabPage(state.pageKey, const ReportsScreen()),
        routes: [
          GoRoute(
            path: 'export',
            builder: (context, state) => const ReportExportScreen(),
          ),
          GoRoute(
            path: 'expenses',
            builder: (context, state) => const ReportExpensesScreen(),
          ),
          GoRoute(
            path: 'savings',
            builder: (context, state) => const ReportSavingsScreen(),
          ),
          GoRoute(
            path: 'health',
            builder: (context, state) => const ReportHealthScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            tabPage(state.pageKey, const ProfileScreen()),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'app',
            builder: (context, state) => const AppSettingsScreen(),
          ),
          GoRoute(
            path: 'security',
            builder: (context, state) => const SecurityScreen(),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: 'help',
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
    ],
  );
}
