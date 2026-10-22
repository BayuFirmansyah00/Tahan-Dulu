import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
// Preferensi aplikasi (in-memory, sesi saja).
// ---------------------------------------------------------------------------

class AppPreferencesController extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => const AppPreferences();

  void setTheme(AppThemeChoice theme) {
    if (theme == AppThemeChoice.dark) return; // Belum tersedia.
    state = state.copyWith(theme: theme);
  }

  void setReduceMotion(bool value) {
    state = state.copyWith(reduceMotion: value);
  }

  void setShowInAppNotifications(bool value) {
    state = state.copyWith(showInAppNotifications: value);
  }

  void setShowTips(bool value) {
    state = state.copyWith(showTips: value);
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
      return ThemeMode.light; // Fallback aman: tema gelap belum ada.
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
    this.loaded = false,
  });

  final String name;
  final String bio;
  final bool loaded;

  bool get isNameValid => name.trim().isNotEmpty;
  bool get isBioValid => bio.length <= 120;

  EditProfileDraft copyWith({String? name, String? bio, bool? loaded}) {
    return EditProfileDraft(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      loaded: loaded ?? this.loaded,
    );
  }

  @override
  List<Object?> get props => [name, bio, loaded];
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
      loaded: true,
    );
  }

  void setName(String value) => state = state.copyWith(name: value);
  void setBio(String value) => state = state.copyWith(bio: value);

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
