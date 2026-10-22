/// Format tanggal Indonesia tanpa dependensi runtime locale.
/// Deterministik di app, test, dan semua environment.
abstract final class DateFormatter {
  static const List<String> _monthsId = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// DateTime(2027, 6, 30) -> "Juni 2027".
  static String monthYear(DateTime date) =>
      '${_monthsId[date.month - 1]} ${date.year}';

  static const List<String> _shortMonthsId = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Nama bulan pendek untuk sumbu grafik. 1 -> "Jan".
  static String shortMonth(int month) => _shortMonthsId[month - 1];

  /// DateTime(2026, 10, 8) -> "8 Oktober 2026".
  static String dayMonthYear(DateTime date) =>
      '${date.day} ${_monthsId[date.month - 1]} ${date.year}';

  static const List<String> _weekdaysId = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Nama hari Indonesia. DateTime.weekday 1 (Senin)..7 (Minggu).
  static String weekdayName(DateTime date) => _weekdaysId[date.weekday - 1];

  /// DateTime(2026, 10, 8) -> "Rabu, 8 Oktober 2026".
  static String fullDate(DateTime date) =>
      '${weekdayName(date)}, ${dayMonthYear(date)}';

  /// "10:00" untuk jam notifikasi.
  static String hourMinute(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  /// True jika tanggal kalender sama (abaikan jam).
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
