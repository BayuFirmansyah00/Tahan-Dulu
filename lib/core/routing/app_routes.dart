/// Route names & paths terpusat.
/// Alur: Splash -> Login/Register -> Onboarding -> Dashboard.
/// Dari Dashboard dapat menuju semua fitur utama.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String onboardingSalary = '/onboarding/salary';
  static const String onboardingInstruments = '/onboarding/instruments';
  static const String onboardingBudget = '/onboarding/budget';
  static const String onboardingExpenses = '/onboarding/recurring-expenses';
  static const String onboardingGoals = '/onboarding/goals';
  static const String onboardingPlan = '/onboarding/plan';
  static const String dashboard = '/dashboard';

  static const String transactions = '/transactions';
  static const String transactionRecordMethod = '/transactions/record-method';
  static const String transactionVoice = '/transactions/voice';
  static const String transactionScan = '/transactions/scan';
  static const String transactionAdd = '/transactions/add';
  static const String transactionReview = '/transactions/review';
  static const String transactionSuccess = '/transactions/success';

  // Investasi.
  static const String investments = '/investments';
  static const String investmentAdd = '/investments/add';

  // Transaksi berulang.
  static const String recurringIncomes = '/recurring-incomes';
  static const String recurringIncomeAdd = '/recurring-incomes/add';
  static const String recurringExpenses = '/recurring-expenses';
  static const String recurringExpenseAdd = '/recurring-expenses/add';
  static const String goals = '/goals';
  static const String goalsNew = '/goals/new';
  static const String goalsSetup = '/goals/setup';
  static const String goalsPriority = '/goals/priority';
  static const String tahanDulu = '/tahan-dulu';
  static const String tahanDuluAdd = '/tahan-dulu/add';
  static const String tahanDuluForm = '/tahan-dulu/form';
  static const String tahanDuluLink = '/tahan-dulu/link';
  static const String reports = '/reports';
  static const String reportsExport = '/reports/export';
  static const String reportsExpenses = '/reports/expenses';
  static const String reportsSavings = '/reports/savings';
  static const String reportsHealth = '/reports/health';
  static const String accounts = '/accounts';
  static const String accountAdd = '/accounts/add';
  static const String accountTransfer = '/accounts/transfer';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notifications/settings';
  static const String notificationSavings = '/notifications/savings';
  static const String settings = '/settings';
  static const String profileEdit = '/settings/edit';
  static const String profileApp = '/settings/app';
  static const String profileSecurity = '/settings/security';
  static const String profilePrivacy = '/settings/privacy';
  static const String profileHelp = '/settings/help';
  static const String profileAbout = '/settings/about';
}
