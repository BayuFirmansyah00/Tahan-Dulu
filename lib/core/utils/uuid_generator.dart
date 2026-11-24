import 'dart:math';

/// Generator UUID v4 (RFC 4122) menggunakan [Random.secure].
/// Format: 8-4-4-4-12 hex string (contoh: c81d4e2e-bcf2-4a7b-a39c-2f8352654bc0).
String generateUuidV4([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));

  // Set bit versi 4 (0100xxxx di oktet ke-6 / byte 6)
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // Set bit varian RFC 4122 (10xxxxxx di oktet ke-8 / byte 8)
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();
  return '${hex.sublist(0, 4).join()}-'
      '${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-'
      '${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10, 16).join()}';
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Memeriksa apakah string adalah format UUID valid (RFC 4122).
bool isUuid(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  return _uuidPattern.hasMatch(value.trim());
}

/// Memeriksa apakah suatu ID adalah ID persistent backend (integer legacy atau UUID PostgreSQL v4/v7).
/// String ID lokal/draft sementara (seperti inst-..., acc-..., exp-..., goal-..., trx-...)
/// menghasilkan false sehingga repository tahu harus melakukan POST (create) alih-alih PUT (update).
bool isBackendId(String? id) {
  if (id == null) return false;
  final trimmed = id.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('inst-') ||
      trimmed.startsWith('acc-') ||
      trimmed.startsWith('exp-') ||
      trimmed.startsWith('goal-') ||
      trimmed.startsWith('trx-') ||
      trimmed.startsWith('flt-')) {
    return false;
  }
  if (int.tryParse(trimmed) != null) return true;
  if (isUuid(trimmed)) return true;
  return false;
}

