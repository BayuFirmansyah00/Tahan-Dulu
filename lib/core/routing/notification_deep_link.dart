import 'app_routes.dart';

/// Validator allowlist & resolver deep link untuk notifikasi in-app maupun FCM.
///
/// Menolak URL eksternal atau route tidak dikenal dan mengarahkannya ke
/// [AppRoutes.notifications] sebagai fallback aman.
abstract final class NotificationDeepLink {
  static final RegExp _numericId = RegExp(r'^[0-9]+$');
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool _isValidEntityId(String id) =>
      _numericId.hasMatch(id) || _uuidPattern.hasMatch(id);

  static final Set<String> _exactAllowedRoutes = {
    AppRoutes.dashboard,
    AppRoutes.transactions,
    AppRoutes.goals,
    AppRoutes.tahanDulu,
    AppRoutes.reports,
    AppRoutes.reportsExpenses,
    AppRoutes.reportsSavings,
    AppRoutes.reportsHealth,
    AppRoutes.investments,
    AppRoutes.recurringIncomes,
    AppRoutes.recurringExpenses,
    AppRoutes.accounts,
    AppRoutes.notifications,
    AppRoutes.notificationSettings,
    AppRoutes.notificationSavings,
    AppRoutes.settings,
  };

  /// Mengonversi data payload FCM atau `targetRoute` menjadi path GoRouter valid.
  static String resolve({
    String? route,
    String? type,
    String? entityId,
  }) {
    final trimmedRoute = route?.trim() ?? '';
    if (trimmedRoute.isNotEmpty && isAllowedRoute(trimmedRoute)) {
      return trimmedRoute;
    }

    final cleanEntityId = entityId?.trim() ?? '';
    final hasValidEntityId =
        cleanEntityId.isNotEmpty && _isValidEntityId(cleanEntityId);

    switch (type?.trim()) {
      case 'tahandulu':
        return hasValidEntityId
            ? '${AppRoutes.tahanDulu}/$cleanEntityId'
            : AppRoutes.tahanDulu;
      case 'savingsGoal':
        return hasValidEntityId
            ? '${AppRoutes.goals}/$cleanEntityId'
            : AppRoutes.goals;
      case 'savingsReminder':
        return hasValidEntityId
            ? '${AppRoutes.goals}/$cleanEntityId'
            : AppRoutes.notificationSavings;
      case 'salary':
        return AppRoutes.transactions;
      case 'investment':
      case 'investments':
        return AppRoutes.investments;
      case 'recurringIncome':
      case 'recurring_income':
        return AppRoutes.recurringIncomes;
      case 'recurringExpense':
      case 'recurring_expense':
      case 'bill':
        return AppRoutes.recurringExpenses;
      case 'budget':
      case 'overspending':
        return AppRoutes.dashboard;
      default:
        return AppRoutes.notifications;
    }
  }

  /// Memastikan path adalah internal route yang aman & terdaftar di GoRouter.
  static bool isAllowedRoute(String candidate) {
    if (!candidate.startsWith('/') || candidate.contains('://')) {
      return false;
    }

    final pathOnly = Uri.tryParse(candidate)?.path ?? candidate;
    if (_exactAllowedRoutes.contains(pathOnly)) {
      return true;
    }

    final segments =
        pathOnly.split('/').where((s) => s.isNotEmpty).toList(growable: false);

    // /goals/:id
    if (segments.length == 2 &&
        segments[0] == 'goals' &&
        _isValidEntityId(segments[1])) {
      return true;
    }

    // /tahan-dulu/:id atau /tahan-dulu/:id/{wait|decide|simulate|success}
    if (segments.length >= 2 &&
        segments[0] == 'tahan-dulu' &&
        _isValidEntityId(segments[1])) {
      if (segments.length == 2) return true;
      if (segments.length == 3 &&
          const {'wait', 'decide', 'simulate', 'success'}.contains(segments[2])) {
        return true;
      }
    }

    return false;
  }
}

