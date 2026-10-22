import 'package:flutter/material.dart';

/// Warna utama TahanDulu.
/// Modern vivid fintech: emerald menyala namun elegan, background
/// putih bersih, dark navy typography, blue accent yang hidup.
abstract final class AppColors {
  // Primary — Vivid emerald (menyala, tetap elegan).
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF0B8A5F);
  static const Color primarySoft = Color(0xFFD9F5E7);

  /// Ujung terang untuk aksen gradient/highlight tombol primer.
  static const Color primaryBright = Color(0xFF34D399);

  /// Glow lembut di bawah tombol primer (shadow).
  static const Color primaryGlow = Color(0x4010B981);

  // Secondary — Vivid blue accent.
  static const Color secondary = Color(0xFF2E7CF6);
  static const Color secondarySoft = Color(0xFFE3EDFE);

  // Background & surface — Putih bersih agar menyatu dengan assets.
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1EFE9);

  /// Warm off-white untuk latar dashboard (editorial, tetap terang).
  static const Color backgroundWarm = Color(0xFFF8FAFC);

  // Input fill — putih bersih untuk field modern.
  static const Color inputFill = Color(0xFFF4F4F5);

  /// Isi field modern: putih agar kontras dengan border dan glow fokus.
  /// [inputFill] lama dipertahankan untuk tile ikon yang memakainya.
  static const Color fieldFill = Color(0xFFFFFFFF);

  /// Border field netral yang crisp.
  static const Color fieldBorder = Color(0xFFE2E8F0);

  // Tombol muted (Login/Register) — abu seperti desain.
  static const Color buttonMuted = Color(0xFFECECF0);

  // Text — Dark navy.
  static const Color textPrimary = Color(0xFF0F2440);
  static const Color textSecondary = Color(0xFF5B6B82);
  static const Color textDisabled = Color(0xFF9AA7B8);

  // Border & divider.
  static const Color border = Color(0xFFE7E2D8);
  static const Color divider = Color(0xFFEEEAE0);

  // Semantic (menyala namun tetap elegan).
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFF43F5E);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Semantic soft backgrounds (pastel containers for icons & banners).
  static const Color successSoft = Color(0xFFD9F5E7);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color infoSoft = Color(0xFFE8EFFE);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPurpleSoft = Color(0xFFEEE9FE);
  static const Color accentTeal = Color(0xFF14B8A6);
}
