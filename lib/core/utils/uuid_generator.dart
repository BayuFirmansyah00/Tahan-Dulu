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

