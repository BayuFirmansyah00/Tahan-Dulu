import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/transaction_model.dart';

/// Metadata UI kategori: label + icon + daftar per jenis.
/// Label dipakai ulang saat menyimpan (tersimpan sebagai string).
String categoryLabel(TransactionCategory category) {
  switch (category) {
    case TransactionCategory.food:
      return AppStrings.catFood;
    case TransactionCategory.transport:
      return AppStrings.catTransport;
    case TransactionCategory.shopping:
      return AppStrings.catShopping;
    case TransactionCategory.entertainment:
      return AppStrings.catEntertainment;
    case TransactionCategory.bills:
      return AppStrings.catBills;
    case TransactionCategory.education:
      return AppStrings.catEducation;
    case TransactionCategory.salary:
      return AppStrings.catSalary;
    case TransactionCategory.bonus:
      return AppStrings.catBonus;
    case TransactionCategory.others:
      return AppStrings.catOthers;
  }
}

/// Kategori yang tersedia per jenis transaksi.
List<TransactionCategory> categoriesFor(TransactionType type) {
  switch (type) {
    case TransactionType.expense:
      return const [
        TransactionCategory.food,
        TransactionCategory.transport,
        TransactionCategory.shopping,
        TransactionCategory.entertainment,
        TransactionCategory.bills,
        TransactionCategory.education,
        TransactionCategory.others,
      ];
    case TransactionType.income:
      return const [
        TransactionCategory.salary,
        TransactionCategory.bonus,
        TransactionCategory.others,
      ];
  }
}

IconData categoryIcon(TransactionCategory category) {
  switch (category) {
    case TransactionCategory.food:
      return Icons.restaurant_outlined;
    case TransactionCategory.transport:
      return Icons.directions_car_outlined;
    case TransactionCategory.shopping:
      return Icons.shopping_bag_outlined;
    case TransactionCategory.entertainment:
      return Icons.movie_outlined;
    case TransactionCategory.bills:
      return Icons.receipt_long_outlined;
    case TransactionCategory.education:
      return Icons.school_outlined;
    case TransactionCategory.salary:
      return Icons.payments_outlined;
    case TransactionCategory.bonus:
      return Icons.card_giftcard_outlined;
    case TransactionCategory.others:
      return Icons.category_outlined;
  }
}

/// Icon untuk label kategori string warisan (data mock lama).
IconData iconForLabel(String? label) {
  for (final category in TransactionCategory.values) {
    if (categoryLabel(category) == label) return categoryIcon(category);
  }
  switch (label) {
    case 'Kebutuhan':
      return Icons.shopping_basket_outlined;
    case 'Investasi':
      return Icons.trending_up_outlined;
    case 'Pemasukan':
      return Icons.payments_outlined;
    default:
      return Icons.category_outlined;
  }
}
