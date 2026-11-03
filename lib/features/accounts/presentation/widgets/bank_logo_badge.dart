import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../../../../core/theme/app_colors.dart';

/// Komponen logo bank reusable untuk TahanDulu.
///
/// Menampilkan logo bank asli dari katalog resmi `idn-finlogos` (SVG/Bitmap)
/// dengan fallback inisial tipografi yang rapi dan elegan ketika logo
/// tidak tersedia, gagal dimuat, atau saat aplikasi berada dalam mode offline.
///
/// Kepatuhan & Keamanan:
/// - Memvalidasi domain URL (whitelist `cdn.jsdelivr.net` dan `raw.githubusercontent.com`)
///   untuk mencegah eksploitasi URL arbitrer dari input eksternal.
/// - Mematuhi batasan lisensi aset CC BY-NC 4.0 dan perlindungan merek dagang bank.
/// - Menjaga rasio aspek logo (`BoxFit.contain`) agar tidak terdistorsi.
/// - Menggunakan in-memory cache untuk mencegah request jaringan berulang dan mencegah
///   logo bank yang berbeda tertukar.
class BankLogoBadge extends StatelessWidget {
  const BankLogoBadge({
    super.key,
    this.bankName,
    this.bankSlug,
    this.bankLogoUrl,
    this.rawSvg,
    this.size = 44,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.padding = 5.0,
  });

  final String? bankName;
  final String? bankSlug;
  final String? bankLogoUrl;
  final String? rawSvg;
  final double size;
  final double? width;
  final double? height;
  final double borderRadius;
  final double padding;

  double get effectiveWidth => width ?? size;
  double get effectiveHeight => height ?? size;

  /// Daftar domain resmi yang diizinkan untuk memuat aset logo pihak ketiga.
  static const List<String> allowedDomains = [
    'cdn.jsdelivr.net',
    'raw.githubusercontent.com',
  ];

  /// Memeriksa apakah URL berasal dari domain resmi yang diizinkan.
  static bool isAllowedUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.isScheme('https')) return false;
    final host = uri.host.toLowerCase();
    return allowedDomains.any((d) => host == d || host.endsWith('.$d'));
  }

  /// Menurunkan slug bank standar dari nama bank jika slug tidak tersedia.
  static String? deriveSlug(String? name, String? slug) {
    if (slug != null && slug.trim().isNotEmpty) {
      return slug.trim().toLowerCase();
    }
    if (name == null || name.trim().isEmpty) return null;
    final lower = name.trim().toLowerCase();
    if (lower.contains('bca digital') || lower.contains('blu')) return 'blu-bca';
    if (lower.contains('bca syariah')) return 'bca-syariah';
    if (lower.contains('bca')) return 'bca';
    if (lower.contains('mandiri')) return 'mandiri';
    if (lower.contains('bri') || lower.contains('rakyat indonesia')) return 'bri';
    if (lower.contains('bni') || lower.contains('negara indonesia')) return 'bni';
    if (lower.contains('jago')) return 'jago';
    if (lower.contains('seabank')) return 'seabank';
    if (lower.contains('aladin')) return 'aladin';
    if (lower.contains('allo')) return 'allo';
    if (lower.contains('cimb')) return 'cimb-niaga';
    if (lower.contains('bsi') || lower.contains('syariah indonesia')) return 'bsi';
    if (lower.contains('btn') || lower.contains('tabungan negara')) return 'btn';
    if (lower.contains('danamon')) return 'danamon';
    if (lower.contains('permata')) return 'permata';
    if (lower.contains('panin')) return 'paninbank';
    if (lower.contains('ocbc')) return 'ocbc-nisp';
    if (lower.contains('raya')) return 'bank-raya';
    if (lower.contains('neo')) return 'bank-neo-commerce';
    if (lower.contains('muamalat')) return 'muamalat';
    return null;
  }

  /// Menghasilkan URL resmi CDN yang aman dan tervalidasi.
  String? get resolvedLogoUrl {
    // 1. Jika URL diberikan dan valid sesuai whitelist domain
    if (bankLogoUrl != null && isAllowedUrl(bankLogoUrl)) {
      return bankLogoUrl!.trim();
    }

    // 2. Jika slug tersedia (atau dapat diturunkan dari nama bank), buat URL CDN resmi
    final slug = deriveSlug(bankName, bankSlug);
    if (slug != null && slug.isNotEmpty) {
      final safeSlug = Uri.encodeComponent(slug);
      return 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/$safeSlug.svg';
    }

    return null;
  }

  /// Menghasilkan inisial tipografi yang bersih untuk fallback.
  static String deriveAcronym(String? name, String? slug) {
    if (slug != null && slug.isNotEmpty) {
      final s = slug.toLowerCase().trim();
      switch (s) {
        case 'bca':
        case 'bca-syariah':
          return 'BCA';
        case 'mandiri':
        case 'livin':
          return 'BMRI';
        case 'bri':
        case 'brimo':
          return 'BRI';
        case 'bni':
          return 'BNI';
        case 'bsi':
          return 'BSI';
        case 'btn':
          return 'BTN';
        case 'cimb':
        case 'cimb-niaga':
        case 'cimb-niaga-syariah':
          return 'CIMB';
        case 'danamon':
          return 'BDMN';
        case 'permata':
          return 'BNLI';
        case 'panin':
        case 'paninbank':
        case 'panin-dubai-syariah':
          return 'PNBN';
        case 'ocbc':
        case 'ocbc-nisp':
          return 'OCBC';
        case 'jago':
          return 'JAGO';
        case 'seabank':
          return 'SEA';
        case 'aladin':
        case 'bank-aladin':
          return 'ALDN';
        case 'blu':
        case 'blu-bca':
        case 'bca-digital':
          return 'BLU';
        case 'jenius':
          return 'JNUS';
        case 'allo':
        case 'allo-bank':
          return 'ALLO';
        case 'raya':
        case 'bank-raya':
          return 'RAYA';
        case 'neo':
        case 'bank-neo-commerce':
          return 'NEO';
        case 'muamalat':
          return 'BMI';
      }
      if (s.length <= 4) {
        return s.toUpperCase();
      }
    }

    if (name == null || name.trim().isEmpty) {
      return 'BANK';
    }

    // Bersihkan prefix umum seperti "PT Bank", "Bank", dll.
    var clean = name.trim();
    clean = clean.replaceAll(RegExp(r'^PT\.?\s*', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'^Bank\s+', caseSensitive: false), '');

    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'BK';

    if (words.length == 1) {
      final single = words.first;
      return single.length <= 4 ? single.toUpperCase() : single.substring(0, 3).toUpperCase();
    }

    // Ambil inisial dari kata-kata utama (maksimal 4 karakter)
    final initials = words.take(4).map((w) => w[0].toUpperCase()).join();
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    final acronym = deriveAcronym(bankName, bankSlug);
    final minDim = effectiveWidth < effectiveHeight ? effectiveWidth : effectiveHeight;
    final fontSize = (minDim * 0.32).clamp(10.0, 16.0);
    final url = resolvedLogoUrl;

    final fallbackBadge = _AcronymBadge(
      acronym: acronym,
      fontSize: fontSize,
    );

    Widget content;

    if (rawSvg != null && rawSvg!.trim().isNotEmpty) {
      // 1. Rendering langsung string SVG (misal saat pengujian widget atau embed)
      content = SvgPicture.string(
        rawSvg!,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => fallbackBadge,
      );
    } else if (url != null) {
      final isSvg = url.toLowerCase().contains('.svg');

      if (isSvg) {
        // 2. Rendering logo SVG asli melalui safe network loader dengan cache
        content = _SvgNetworkImage(
          url: url,
          fallback: fallbackBadge,
          fit: BoxFit.contain,
        );
      } else {
        // 3. Rendering logo bitmap (PNG / JPG / WebP)
        content = Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => fallbackBadge,
        );
      }
    } else {
      // 4. Fallback inisial tipografi ketika logo tidak tersedia
      content = fallbackBadge;
    }

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.all(padding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          (borderRadius - padding).clamp(2.0, borderRadius),
        ),
        child: Center(child: content),
      ),
    );
  }
}

/// Widget loader jaringan untuk SVG dengan in-memory cache dan proteksi error.
class _SvgNetworkImage extends StatefulWidget {
  const _SvgNetworkImage({
    required this.url,
    required this.fallback,
    this.fit = BoxFit.contain,
  });

  final String url;
  final Widget fallback;
  final BoxFit fit;

  /// Cache memori statis untuk menyimpan string SVG yang telah diunduh.
  static final Map<String, String> cache = {};

  /// Cache memori untuk mencatat URL yang gagal agar tidak terus mencoba request berulang.
  static final Set<String> failedUrls = {};

  /// Menyuntikkan data cache untuk keperluan pengujian / preload.
  static void injectCache(String url, String svgContent) {
    cache[url] = svgContent;
  }

  /// Membersihkan cache SVG.
  static void clearCache() {
    cache.clear();
    failedUrls.clear();
  }

  @override
  State<_SvgNetworkImage> createState() => _SvgNetworkImageState();
}

class _SvgNetworkImageState extends State<_SvgNetworkImage> {
  String? _svgString;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  @override
  void didUpdateWidget(covariant _SvgNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _checkAndLoad();
    }
  }

  void _checkAndLoad() {
    final cached = _SvgNetworkImage.cache[widget.url];
    if (cached != null) {
      _svgString = cached;
      return;
    }

    if (_SvgNetworkImage.failedUrls.contains(widget.url)) {
      _svgString = null;
      return;
    }

    _loadSvg();
  }

  Future<void> _loadSvg() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final response = await http
          .get(Uri.parse(widget.url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 &&
          response.body.isNotEmpty &&
          response.body.contains('<svg')) {
        _SvgNetworkImage.cache[widget.url] = response.body;
        if (mounted) {
          setState(() {
            _svgString = response.body;
            _isLoading = false;
          });
        }
      } else {
        _SvgNetworkImage.failedUrls.add(widget.url);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      // Offline, network error, 400 in test runner, or timeout:
      // Catat sebagai gagal sementara dan gunakan inisial fallback yang rapi.
      _SvgNetworkImage.failedUrls.add(widget.url);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_svgString != null) {
      try {
        return SvgPicture.string(
          _svgString!,
          fit: widget.fit,
          placeholderBuilder: (_) => widget.fallback,
        );
      } catch (_) {
        return widget.fallback;
      }
    }

    return widget.fallback;
  }
}

/// Badge inisial tipografi yang konsisten dengan tema desain TahanDulu.
class _AcronymBadge extends StatelessWidget {
  const _AcronymBadge({
    required this.acronym,
    required this.fontSize,
  });

  final String acronym;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        acronym,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.fade,
        style: TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// Helper publik untuk manajemen cache logo SVG.
abstract final class BankLogoCache {
  static void inject(String url, String svgContent) =>
      _SvgNetworkImage.injectCache(url, svgContent);

  static void clear() => _SvgNetworkImage.clearCache();

  static bool has(String url) => _SvgNetworkImage.cache.containsKey(url);
}
