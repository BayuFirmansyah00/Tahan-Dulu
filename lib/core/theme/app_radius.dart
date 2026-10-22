import 'package:flutter/material.dart';

/// Radius sudut terpusat: modern, rounded 18–20px.
abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;

  static BorderRadius get card => BorderRadius.circular(md);
  static BorderRadius get cardLarge => BorderRadius.circular(lg);

  /// Tombol & field modern: ekstra rounded namun tetap tegas.
  static BorderRadius get button => BorderRadius.circular(18);
  static BorderRadius get sheet =>
      const BorderRadius.vertical(top: Radius.circular(lg));
}

/// Soft shadows untuk cards.
abstract final class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFF0F2440).withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardLarge => [
    BoxShadow(
      color: const Color(0xFF0F2440).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Spacing & layout terpusat: generous whitespace.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pagePadding = 20;
}
