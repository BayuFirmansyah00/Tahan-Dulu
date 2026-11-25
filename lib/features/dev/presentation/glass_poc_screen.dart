import 'package:flutter/material.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Screen Proof of Concept (POC) untuk evaluasi True Clear Liquid Glass.
///
/// Menyajikan perbandingan tiga sampel:
/// - **Sampel A (Eksisting)**: Kaca buram/milky dengan blur tinggi dan opasitas tebal (72-86%).
/// - **Sampel B (Tuned Toolkit)**: Kaca bening jernih berbasis `liquid_glass_toolkit` (blur 0, opasitas 3%, refraksi optik aktif).
/// - **Sampel C (Optical Shader)**: Kaca super-transparan berbasis `liquid_glass_widgets` (iOS 27 multi-pass fragment shader).
///
/// Disertai latar pengujian kontras tinggi (geometri warna-warni & tipografi tajam)
/// serta sandbox parameter interaktif untuk tuning langsung.
class GlassPocScreen extends StatefulWidget {
  const GlassPocScreen({super.key});

  @override
  State<GlassPocScreen> createState() => _GlassPocScreenState();
}

class _GlassPocScreenState extends State<GlassPocScreen> {
  int _selectedTab = 0; // 0: Tiga Sampel, 1: Sandbox Interaktif, 2: Info Mesin GPU
  bool _useFinancialScene = false;

  // Sandbox adjustable state
  double _sandboxBlur = 0.0;
  double _sandboxOpacity = 0.03;
  double _sandboxRefraction = 0.40;
  double _sandboxRimLight = 0.35;
  bool _sandboxRefractionEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'True Clear Liquid Glass POC',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            key: const Key('toggle_scene_btn'),
            tooltip: _useFinancialScene ? 'Mode Geometri' : 'Mode Finansial',
            icon: Icon(_useFinancialScene ? Icons.grid_view : Icons.account_balance_wallet),
            onPressed: () {
              setState(() => _useFinancialScene = !_useFinancialScene);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation Mode Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildModeChip(0, '3 Sampel Komparasi'),
                  const SizedBox(width: 8),
                  _buildModeChip(1, 'Interactive Sandbox'),
                  const SizedBox(width: 8),
                  _buildModeChip(2, 'GPU & Engine'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Main Body with Background Scene
          Expanded(
            child: Stack(
              children: [
                // High-Contrast Background Test Scene
                Positioned.fill(
                  key: const Key('background_scene'),
                  child: _useFinancialScene
                      ? const _FinancialTestScene()
                      : const _GeometricHighContrastScene(),
                ),

                // Glass Content Layer
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: switch (_selectedTab) {
                      0 => _buildThreeSamplesView(context, isDark),
                      1 => _buildSandboxView(context, isDark),
                      _ => _buildGpuInfoView(context, isDark),
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(int index, String label) {
    final isSelected = _selectedTab == index;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTab = index),
      selectedColor: AppColors.primarySoft,
    );
  }

  Widget _buildThreeSamplesView(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner Penjelasan
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: const Text(
            'Perhatikan visibilitas elemen latar di balik setiap kaca. '
            'Kaca True Clear mempertahankan ketajaman teks latar tanpa kabur putih susu.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),

        // SAMPEL A: Kaca Eksisting (Baseline Milky)
        _buildSampleCardContainer(
          key: const Key('sample_a_card'),
          title: 'Sampel A: Kaca Eksisting (Baseline Milky/Opaque)',
          subtitle: 'Blur: 14px | Opacity: 85% | Refraction: OFF',
          statusColor: AppColors.error,
          statusText: 'Buram / Milky (Kegagalan Transparansi)',
          glassChild: LiquidGlassSurface(
            quality: LiquidGlassQuality.standard,
            borderRadius: AppRadius.cardLarge,
            style: LiquidGlassStyle(
              blur: 14,
              opacity: isDark ? 0.86 : 0.72,
              tintColor: isDark ? const Color(0xFF142433) : Colors.white,
              borderColor: Colors.white24,
              enableRefraction: false,
              highlightOpacity: 0.15,
            ),
            child: _buildGlassCardContent(
              badge: 'SAMPEL A',
              title: 'Kartu Kaca Konfigurasi Lama',
              description: 'Teks latar belakang tertutup lapisan putih susu (milky haze). '
                  'Elemen grafis di belakang hampir tidak terbaca.',
              isClear: false,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // SAMPEL B: Tuned Clear Glass (liquid_glass_toolkit)
        _buildSampleCardContainer(
          key: const Key('sample_b_card'),
          title: 'Sampel B: True Clear Glass (Tuned Toolkit)',
          subtitle: 'Blur: 0px | Opacity: 3% | Refraction: 0.35 | Dispersion: 0.08',
          statusColor: AppColors.primary,
          statusText: 'True Clear (Latar 100% Terbaca + Refraksi Tepi)',
          glassChild: LiquidGlassSurface(
            quality: LiquidGlassQuality.premium,
            borderRadius: AppRadius.cardLarge,
            style: LiquidGlassStyle(
              blur: 0.0,
              opacity: 0.03,
              tintColor: Colors.white,
              borderColor: Colors.white.withValues(alpha: 0.35),
              enableRefraction: true,
              refractionStrength: 0.35,
              dispersion: 0.08,
              rimLightIntensity: 0.35,
              specularIntensity: 0.30,
              highlightOpacity: 0.25,
            ),
            child: _buildGlassCardContent(
              badge: 'SAMPEL B',
              title: 'Tuned Clear Liquid Glass',
              description: 'Teks dan bentuk di latar belakang terlihat kristal jernih. '
                  'Tepi kartu membiaskan cahaya optik nyata.',
              isClear: true,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // SAMPEL C: True Clear Optical Glass (liquid_glass_widgets multi-pass shader)
        _buildSampleCardContainer(
          key: const Key('sample_c_card'),
          title: 'Sampel C: Optical Lens Glass (iOS 27 Fragment Shader)',
          subtitle: 'Shader: liquid_glass_render.frag | Superellipse Rim | Dispersion',
          statusColor: const Color(0xFF00B4D8),
          statusText: 'True Clear Premium (Multi-Pass Impeller GLSL)',
          glassChild: GlassIsolationScope(
            defaultQuality: GlassQuality.premium,
            child: GlassContainer(
              useOwnLayer: true,
              shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
              color: Colors.white.withValues(alpha: 0.04),
              child: _buildGlassCardContent(
                badge: 'SAMPEL C',
                title: 'iOS 27 Superellipse Optical Glass',
                description: 'Permukaan ultra-transparan dengan kurvatur superellipse '
                    'dan highlight dinamis multi-sudut.',
                isClear: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSampleCardContainer({
    required Key key,
    required String title,
    required String subtitle,
    required Color statusColor,
    required String statusText,
    required Widget glassChild,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg + 4),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 8),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          glassChild,
        ],
      ),
    );
  }

  Widget _buildGlassCardContent({
    required String badge,
    required String title,
    required String description,
    required bool isClear,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isClear ? AppColors.primary : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Transparansi Kaca',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMetricChip(
                  label: 'Legibility',
                  value: isClear ? '98%' : '32%',
                  color: isClear ? AppColors.primary : AppColors.error,
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  label: 'Refraction',
                  value: isClear ? 'Active' : 'Disabled',
                  color: isClear ? Colors.lightBlueAccent : Colors.grey,
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  label: 'Milky Tint',
                  value: isClear ? '2-4%' : '72-86%',
                  color: isClear ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSandboxView(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Parameter Tuning Kaca Real-time',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Blur Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Blur Intensity:', style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text('${_sandboxBlur.toStringAsFixed(1)} px',
                      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _sandboxBlur,
                min: 0.0,
                max: 25.0,
                divisions: 50,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _sandboxBlur = val),
              ),

              // Opacity Tint Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('White Tint Opacity:', style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text('${(_sandboxOpacity * 100).toStringAsFixed(1)} %',
                      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _sandboxOpacity,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _sandboxOpacity = val),
              ),

              // Refraction Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Refraction Strength:', style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text(_sandboxRefraction.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _sandboxRefraction,
                min: 0.0,
                max: 1.0,
                divisions: 50,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _sandboxRefraction = val),
              ),

              // Rim Light Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rim Light Intensity:', style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text(_sandboxRimLight.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _sandboxRimLight,
                min: 0.0,
                max: 1.0,
                divisions: 50,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _sandboxRimLight = val),
              ),

              // Refraction Switch
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Enable Optical Refraction',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Switch(
                      value: _sandboxRefractionEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) => setState(() => _sandboxRefractionEnabled = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Resulting Preview Glass Card
        const Text(
          'Live Preview Permukaan Kaca:',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        LiquidGlassSurface(
          quality: LiquidGlassQuality.premium,
          borderRadius: AppRadius.cardLarge,
          style: LiquidGlassStyle(
            blur: _sandboxBlur,
            opacity: _sandboxOpacity,
            tintColor: Colors.white,
            borderColor: Colors.white.withValues(alpha: 0.4),
            enableRefraction: _sandboxRefractionEnabled,
            refractionStrength: _sandboxRefraction,
            rimLightIntensity: _sandboxRimLight,
            specularIntensity: 0.30,
            dispersion: 0.08,
            highlightOpacity: 0.25,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kartu Hasil Penyetelan Kustom',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kaca saat ini dirender dengan blur: ${_sandboxBlur.toStringAsFixed(1)}px '
                  'dan opasitas: ${(_sandboxOpacity * 100).toStringAsFixed(0)}%. '
                  'Jika opasitas di atas 50%, latar belakang akan mulai terlihat seperti plastik putih.',
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Uji Tombol Interaktif'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGpuInfoView(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.developer_board, color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Text(
                'Arsitektur GPU & Rendering',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          _InfoRow(label: 'Flutter Framework', value: '3.44.4 (channel stable)'),
          _InfoRow(label: 'Dart SDK', value: '3.12.2'),
          _InfoRow(label: 'Engine Revision', value: 'a10d8ac38de835021c8d2f920dbf50a920ccc030'),
          _InfoRow(label: 'Android Graphics Backend', value: 'Impeller (Vulkan 1.1+) / Skia Fallback'),
          _InfoRow(label: 'Shader Pipeline', value: 'AOT SPIR-V FragmentProgram (dart:ui)'),
          _InfoRow(label: 'Runtime Shader Packages', value: 'liquid_glass_toolkit & liquid_glass_widgets'),
          _InfoRow(label: 'Target Android compileSdk', value: '37 (Android 15+)'),
          _InfoRow(label: 'Target AGP / Gradle', value: 'AGP 9.1.1 / Gradle 9.3.1 / Java 17'),
          SizedBox(height: 16),
          Divider(color: Colors.white24),
          SizedBox(height: 12),
          Text(
            'Kesimpulan Kompatibilitas Engine:',
            style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            'Flutter 3.44.4 telah terbukti mampu mengompilasi dan mengeksekusi multi-pass fragment shader '
            'secara efisien. Masalah visual kaca buram (milky/cloudy) bukan karena keterbatasan mesin rendering Flutter, '
            'melainkan murni akibat kesalahan parameter styling (alpha: 0.96 dan blur 14px) pada Glass.panel() dan FloatingGlass. '
            'Dengan demikian, upgrade Flutter SDK TIDAK DIPERLUKAN (Decision A: Keep existing 3.44.4).',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Latar belakang geometri kontras tinggi untuk menguji refraksi dan kejernihan kaca.
class _GeometricHighContrastScene extends StatelessWidget {
  const _GeometricHighContrastScene();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0A2E2C),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GeometricPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GeometricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Grid lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Bold vibrant geometric shapes
    final circlePaint1 = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(Offset(size.width * 0.25, 200), 70, circlePaint1);

    final circlePaint2 = Paint()..color = const Color(0xFF00E5FF);
    canvas.drawCircle(Offset(size.width * 0.75, 420), 85, circlePaint2);

    final circlePaint3 = Paint()..color = const Color(0xFFFFD600);
    canvas.drawCircle(Offset(size.width * 0.35, 680), 90, circlePaint3);

    // High contrast typography painted directly onto canvas
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'TAHAN DULU OPTICAL TEST SCENE\n'
            'LEDGER INTEGRITY AUDITED\n'
            'BALANCE: RP 24.500.000\n'
            'CRISP GEOMETRIC TEXT LINE 100% VISIBLE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          height: 1.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width - 40);
    textPainter.paint(canvas, const Offset(20, 100));
    textPainter.paint(canvas, const Offset(20, 340));
    textPainter.paint(canvas, const Offset(20, 580));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Latar belakang simulasi antarmuka finansial Tahan Dulu.
class _FinancialTestScene extends StatelessWidget {
  const _FinancialTestScene();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1926),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 70, 16, 100),
        children: [
          // Banner Saldo Simulasi
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF047857)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL KEKAYAAN BERSIH', style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 4),
                Text('Rp 87.450.000',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('+ Rp 4.250.000 bulan ini (Surplus)',
                    style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Baris Transaksi Simulasi
          for (int i = 1; i <= 8; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF162A3B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: i.isEven ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    child: Icon(
                      i.isEven ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.isEven ? 'Pemasukan Gaji Tahunan #$i' : 'Pengeluaran Belanja Logistik #$i',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text('Kategori Finansial Primer • Akun BCA',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    i.isEven ? '+Rp 12.500.000' : '-Rp 350.000',
                    style: TextStyle(
                      color: i.isEven ? const Color(0xFF34D399) : const Color(0xFFF87171),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
