import 'package:equatable/equatable.dart';

/// Model katalog bank dari backend Laravel (idn-finlogos).
class ApiBank extends Equatable {
  const ApiBank({
    required this.id,
    required this.name,
    required this.slug,
    this.category = 'bank-logo',
    this.aliases = const [],
    this.logoRef,
    this.logoUrl,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String slug;
  final String category;
  final List<String> aliases;
  final String? logoRef;
  final String? logoUrl;
  final bool isActive;

  factory ApiBank.fromJson(Map<String, dynamic> json) {
    final rawAliases = json['aliases'];
    List<String> parsedAliases = [];
    if (rawAliases is List) {
      parsedAliases = rawAliases.map((e) => '$e').toList();
    }

    return ApiBank(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      slug: '${json['slug'] ?? ''}',
      category: '${json['category'] ?? 'bank-logo'}',
      aliases: parsedAliases,
      logoRef: json['logo_ref'] as String?,
      logoUrl: json['logo_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'category': category,
      'aliases': aliases,
      'logo_ref': logoRef,
      'logo_url': logoUrl,
      'is_active': isActive,
    };
  }

  /// Memeriksa apakah kata kunci pencarian cocok dengan nama, slug, atau alias.
  bool matchesSearch(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return true;

    if (name.toLowerCase().contains(clean)) return true;
    if (slug.toLowerCase().contains(clean)) return true;
    for (final alias in aliases) {
      if (alias.toLowerCase().contains(clean)) return true;
    }
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        category,
        aliases,
        logoRef,
        logoUrl,
        isActive,
      ];
}

/// Envelope respons daftar bank: {success, message, data: [...]}.
class ApiBanksResponse extends Equatable {
  const ApiBanksResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final List<ApiBank> data;

  factory ApiBanksResponse.fromJson(Map<String, dynamic> json) {
    return ApiBanksResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: (json['data'] as List? ?? const [])
          .map((item) => ApiBank.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Envelope respons satu bank: {success, message, data: {...}}.
class ApiBankResponse extends Equatable {
  const ApiBankResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ApiBank data;

  factory ApiBankResponse.fromJson(Map<String, dynamic> json) {
    return ApiBankResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: ApiBank.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

