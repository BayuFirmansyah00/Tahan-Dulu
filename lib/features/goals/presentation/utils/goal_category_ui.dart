import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/financial_goal.dart';

/// Label kategori target (Bahasa Indonesia, satu sumber).
String goalCategoryLabel(GoalCategory category) {
  switch (category) {
    case GoalCategory.emergency:
      return AppStrings.goalCatEmergency;
    case GoalCategory.savings:
      return AppStrings.goalCatSavings;
    case GoalCategory.investment:
      return AppStrings.goalCatInvestment;
    case GoalCategory.house:
      return AppStrings.goalCatHouse;
    case GoalCategory.vehicle:
      return AppStrings.goalCatVehicle;
    case GoalCategory.gadget:
      return AppStrings.goalCatGadget;
    case GoalCategory.holiday:
      return AppStrings.goalCatHoliday;
    case GoalCategory.education:
      return AppStrings.goalCatEducation;
    case GoalCategory.others:
      return AppStrings.goalCatOthers;
  }
}

/// Ikon kategori target (Material outline, tanpa emoji).
IconData goalCategoryIcon(GoalCategory category) {
  switch (category) {
    case GoalCategory.emergency:
      return Icons.shield_outlined;
    case GoalCategory.savings:
      return Icons.savings_outlined;
    case GoalCategory.investment:
      return Icons.show_chart_outlined;
    case GoalCategory.house:
      return Icons.home_outlined;
    case GoalCategory.vehicle:
      return Icons.directions_car_outlined;
    case GoalCategory.gadget:
      return Icons.smartphone_outlined;
    case GoalCategory.holiday:
      return Icons.flight_outlined;
    case GoalCategory.education:
      return Icons.school_outlined;
    case GoalCategory.others:
      return Icons.flag_outlined;
  }
}

/// Aset ikon 3D onboarding per kategori target (terverifikasi visual).
/// null berarti tidak ada aset yang cocok -> fallback outline
/// [goalCategoryIcon] agar konsisten.
/// CATATAN: khusus alur onboarding No.7 — jangan dipakai di fitur Goals
/// (fitur Goals memakai [goalFeatureIconFor] + [goalHeaderFor]).
String? goalOnboardingAssetFor(GoalCategory category) {  switch (category) {
    case GoalCategory.emergency:
      return AppAssets.obEmergency;
    case GoalCategory.savings:
      return AppAssets.obGoalSavings;
    case GoalCategory.investment:
      return AppAssets.obInvestment;
    case GoalCategory.house:
      return AppAssets.obHouse;
    case GoalCategory.education:
      return AppAssets.obEducation;
    case GoalCategory.holiday:
      return AppAssets.obHoliday;
    case GoalCategory.vehicle:
    case GoalCategory.gadget:
    case GoalCategory.others:
      return null;
  }
}

/// Header ilustrasi 3D per kategori (Tahap 32, satu pemetaan terpusat).
/// Semua path terverifikasi ada di `assets/illustrations/`.
/// Dipakai GoalHeader di seluruh layar fitur Goals; fallback konsisten
/// bila berkas tidak termuat.
String goalHeaderFor(GoalCategory category) {
  switch (category) {
    case GoalCategory.emergency:
      return AppAssets.goalHeaderEmergency;
    case GoalCategory.savings:
      return AppAssets.goalHeaderSavings;
    case GoalCategory.investment:
      return AppAssets.goalHeaderInvestment;
    case GoalCategory.house:
      return AppAssets.goalHeaderHouse;
    case GoalCategory.vehicle:
      return AppAssets.goalHeaderVehicle;
    case GoalCategory.gadget:
      return AppAssets.goalHeaderGadget;
    case GoalCategory.holiday:
      return AppAssets.goalHeaderTravel;
    case GoalCategory.education:
      return AppAssets.goalHeaderEducation;
    case GoalCategory.others:
      return AppAssets.goalHeaderOthers;
  }
}

/// Ikon kategori 3D per kategori (Tahap 32, satu pemetaan terpusat).
/// Semua path terverifikasi ada di `assets/icons/`.
/// Khusus fitur Goals (daftar, tile, ringkasan); onboarding memakai
/// [goalOnboardingAssetFor], dashboard memakai CategoryIcon bawaan.
String goalFeatureIconFor(GoalCategory category) {
  switch (category) {
    case GoalCategory.emergency:
      return AppAssets.goalIconEmergency;
    case GoalCategory.savings:
      return AppAssets.goalIconSavings;
    case GoalCategory.investment:
      return AppAssets.goalIconInvestment;
    case GoalCategory.house:
      return AppAssets.goalIconHouse;
    case GoalCategory.vehicle:
      return AppAssets.goalIconVehicle;
    case GoalCategory.gadget:
      return AppAssets.goalIconGadget;
    case GoalCategory.holiday:
      return AppAssets.goalIconTravel;
    case GoalCategory.education:
      return AppAssets.goalIconEducation;
    case GoalCategory.others:
      return AppAssets.goalIconOthers;
  }
}
