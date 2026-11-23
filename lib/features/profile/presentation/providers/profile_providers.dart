import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/models/app_preferences.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../goals/presentation/providers/goals_controller.dart';
import '../../data/help_articles.dart';

// ---------------------------------------------------------------------------
// Pengguna profil: sesi auth bila ada, fallback data dashboard (mock).
// ---------------------------------------------------------------------------

final profileUserProvider = FutureProvider<UserModel>((ref) async {
  final session = ref.watch(authControllerProvider).user;
  if (session != null) return session;
  return ref.watch(userProvider.future);
});

// ---------------------------------------------------------------------------
// Ringkasan: dihitung dari repository yang sama dengan fitur lain.
// Target aktif = belum tercapai (repo + onboarding, dedupe id).
// ---------------------------------------------------------------------------

class ProfileStats extends Equatable {
  const ProfileStats({
    required this.activeGoals,
    required this.accounts,
    required this.transactions,
  });

  final int activeGoals;
  final int accounts;
  final int transactions;

  @override
  List<Object?> get props => [activeGoals, accounts, transactions];
}

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final repoGoals = await ref.watch(goalsListProvider.future);
  final onboarding =
      ref.watch(onboardingRepositoryProvider).getOnboardingData();
  final seen = <String>{};
  var activeGoals = 0;
  final candidates = [
    if (onboarding?.financialGoal != null) onboarding!.financialGoal!,
    ...repoGoals,
  ];
  for (final goal in candidates) {
    if (!seen.add(goal.id)) continue;
    if (!goal.isReached) activeGoals++;
  }
  final accounts = await ref.watch(accountsProvider.future);
  final transactions = await ref.watch(transactionsProvider.future);
  return ProfileStats(
    activeGoals: activeGoals,
    accounts: accounts.length,
    transactions: transactions.length,
  );
});

// ---------------------------------------------------------------------------
// Preferensi aplikasi (tersimpan persisten via SharedPreferences).
// ---------------------------------------------------------------------------

class AppPreferencesController extends Notifier<AppPreferences> {
  static const _baseReduceMotion = 'app_prefs_reduce_motion';
  static const _baseInAppNotif = 'app_prefs_in_app_notif';
  static const _baseShowTips = 'app_prefs_show_tips';

  String? _userId;

  String _scopedKey(String base) {
    if (_userId != null && _userId!.isNotEmpty) {
      return '${base}_$_userId';
    }
    return base;
  }

  @override
  AppPreferences build() {
    _userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
    _loadFromStorage();
    return const AppPreferences();
  }

  Future<void> _loadFromStorage() async {
    final userId = _userId;
    final themeKey = _scopedKey('app_prefs_theme');
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted || userId != _userId) return;
      final scopedReduce = _scopedKey(_baseReduceMotion);
      final scopedNotif = _scopedKey(_baseInAppNotif);
      final scopedTips = _scopedKey(_baseShowTips);

      // Migrasi satu kali (one-time migration) dari global legacy keys:
      // Hanya jika user terautentikasi dan kunci global warisan masih ada di storage.
      if (_userId != null && _userId!.isNotEmpty) {
        final migrationKey = 'app_prefs_migrated_$_userId';
        if (!(prefs.getBool(migrationKey) ?? false)) {
          if (!prefs.containsKey(scopedReduce) && prefs.containsKey(_baseReduceMotion)) {
            final oldVal = prefs.getBool(_baseReduceMotion);
            if (oldVal != null) await prefs.setBool(scopedReduce, oldVal);
            await prefs.remove(_baseReduceMotion);
          }
          if (!prefs.containsKey(scopedNotif) && prefs.containsKey(_baseInAppNotif)) {
            final oldVal = prefs.getBool(_baseInAppNotif);
            if (oldVal != null) await prefs.setBool(scopedNotif, oldVal);
            await prefs.remove(_baseInAppNotif);
          }
          if (!prefs.containsKey(scopedTips) && prefs.containsKey(_baseShowTips)) {
            final oldVal = prefs.getBool(_baseShowTips);
            if (oldVal != null) await prefs.setBool(scopedTips, oldVal);
            await prefs.remove(_baseShowTips);
          }
          await prefs.setBool(migrationKey, true);
        }
      }

      // Baca nilai spesifik scoped. Jika akun baru belum pernah menyetel,
      // selalu gunakan default bersih aplikasi tanpa mewarisi preferensi akun lain.
      final reduceMotion = prefs.getBool(scopedReduce) ?? false;
      final showInAppNotifications = prefs.getBool(scopedNotif) ?? true;
      final showTips = prefs.getBool(scopedTips) ?? true;

      if (!ref.mounted || userId != _userId) return;
      final theme = AppThemeChoice.values.asNameMap()[prefs.getString(themeKey)];
      state = state.copyWith(
        theme: theme ?? state.theme,
        reduceMotion: reduceMotion,
        showInAppNotifications: showInAppNotifications,
        showTips: showTips,
      );
    } catch (_) {
      // Abaikan bila di environment test tanpa SharedPreferences mock
    }
  }

  Future<void> setTheme(AppThemeChoice theme) async {
    final key = _scopedKey('app_prefs_theme');
    state = state.copyWith(theme: theme);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, theme.name);
    } on Exception {
      // Pilihan tetap aktif untuk sesi ini bila penyimpanan lokal tidak tersedia.
    }
  }

  Future<void> setReduceMotion(bool value) async {
    state = state.copyWith(reduceMotion: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey(_baseReduceMotion), value);
    } catch (_) {}
  }

  Future<void> setShowInAppNotifications(bool value) async {
    state = state.copyWith(showInAppNotifications: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey(_baseInAppNotif), value);
    } catch (_) {}
  }

  Future<void> setShowTips(bool value) async {
    state = state.copyWith(showTips: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey(_baseShowTips), value);
    } catch (_) {}
  }
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesController, AppPreferences>(
  AppPreferencesController.new,
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  switch (ref.watch(appPreferencesProvider).theme) {
    case AppThemeChoice.system:
      return ThemeMode.system;
    case AppThemeChoice.light:
      return ThemeMode.light;
    case AppThemeChoice.dark:
      return ThemeMode.dark;
  }
});

final showInAppNotificationsProvider = Provider<bool>(
  (ref) => ref.watch(appPreferencesProvider).showInAppNotifications,
);

// ---------------------------------------------------------------------------
// Edit profil: draf + simpan anti-ganda via AuthController.
// ---------------------------------------------------------------------------

class EditProfileDraft extends Equatable {
  const EditProfileDraft({
    this.name = '',
    this.bio = '',
    this.monthlyIncome,
    this.salaryDay,
    this.loaded = false,
  });

  final String name;
  final String bio;
  final int? monthlyIncome;
  final int? salaryDay;
  final bool loaded;

  bool get isNameValid => name.trim().isNotEmpty;
  bool get isBioValid => bio.length <= 120;

  EditProfileDraft copyWith({
    String? name,
    String? bio,
    int? Function()? monthlyIncome,
    int? Function()? salaryDay,
    bool? loaded,
  }) {
    return EditProfileDraft(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      monthlyIncome: monthlyIncome != null ? monthlyIncome() : this.monthlyIncome,
      salaryDay: salaryDay != null ? salaryDay() : this.salaryDay,
      loaded: loaded ?? this.loaded,
    );
  }

  @override
  List<Object?> get props => [name, bio, monthlyIncome, salaryDay, loaded];
}

class EditProfileController extends Notifier<EditProfileDraft> {
  bool _saving = false;

  @override
  EditProfileDraft build() => const EditProfileDraft();

  void load(UserModel user) {
    if (state.loaded) return;
    state = EditProfileDraft(
      name: user.name,
      bio: user.bio ?? '',
      monthlyIncome: user.monthlyIncome,
      salaryDay: user.salaryDay,
      loaded: true,
    );
  }

  void setName(String value) => state = state.copyWith(name: value);
  void setBio(String value) => state = state.copyWith(bio: value);
  void setMonthlyIncome(int? value) =>
      state = state.copyWith(monthlyIncome: () => value);
  void setSalaryDay(int? value) => state = state.copyWith(salaryDay: () => value);

  Future<bool> save() async {
    if (_saving || !state.isNameValid || !state.isBioValid) return false;
    _saving = true;
    try {
      return await ref.read(authControllerProvider.notifier).updateProfile(
            name: state.name,
            bio: state.bio,
          );
    } finally {
      _saving = false;
    }
  }

  /// Simpan monthly_income + salary_day secara permanen ke backend.
  Future<bool> saveFinancialInfo() async {
    if (_saving) return false;
    _saving = true;
    try {
      return await ref.read(authControllerProvider.notifier).updateFinancialInfo(
            monthlyIncome: state.monthlyIncome,
            salaryDay: state.salaryDay,
          );
    } finally {
      _saving = false;
    }
  }
}

final editProfileControllerProvider =
    NotifierProvider<EditProfileController, EditProfileDraft>(
  EditProfileController.new,
);

// ---------------------------------------------------------------------------
// Bantuan: query pencarian + hasil filter lokal.
// ---------------------------------------------------------------------------

class HelpQueryController extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
  void clear() => state = '';
}

final helpQueryProvider =
    NotifierProvider<HelpQueryController, String>(HelpQueryController.new);

final filteredHelpArticlesProvider = Provider<List<HelpArticle>>((ref) {
  return searchHelpArticles(ref.watch(helpQueryProvider));
});
