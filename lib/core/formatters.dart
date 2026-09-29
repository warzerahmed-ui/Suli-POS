import 'package:intl/intl.dart';

/// شێوەکردنی ژمارە، بەروار و کات بە شێوەی کوردی.
/// English: number/date helpers so every screen formats values identically.
class Formatters {
  const Formatters._();

  /// ناوی مانگەکان بە کوردی (مانگی مەنجەلەیی - `ی` ی پەیوەندی).
  static const List<String> kurdishMonths = <String>[
    'کانوونی دووەم',
    'شوبات',
    'ئازار',
    'نیسان',
    'ئایار',
    'حوزەیران',
    'تەمموز',
    'ئاب',
    'ئەیلوول',
    'تشرینی یەکەم',
    'تشرینی دووەم',
    'کانوونی یەکەم',
  ];

  /// ناوی ڕۆژەکانی حەفتە (ڕۆژی یەکشەممە دەست پێدەکات).
  static const List<String> kurdishWeekdays = <String>[
    'یەکشەممە',
    'دووشەممە',
    'سێشەممە',
    'چوارشەممە',
    'پێنجشەممە',
    'هەینی',
    'شەممە',
  ];

  static const List<String> kurdishWeekdaysShort = <String>[
    'یەک',
    'دوو',
    'سێ',
    'چوار',
    'پێنج',
    'هەینی',
    'شەم',
  ];

  static final NumberFormat _grouped = NumberFormat('#,##0');
  static final DateFormat _clock = DateFormat('HH:mm');
  static final DateFormat _clockSeconds = DateFormat('HH:mm:ss');

  /// ژمارە لەگەڵ جیاکەرەوەی هەزاران.
  static String number(num value, {int decimals = 0}) {
    if (decimals <= 0) return _grouped.format(value);
    return NumberFormat('#,##0.${'0' * decimals}').format(value);
  }

  /// بڕی کاڵا (تەنها ئەگەر دەیی هەبوو دەییەکان پیشان دەدات).
  static String quantity(num value) {
    if (value == value.roundToDouble()) return _grouped.format(value);
    return NumberFormat('#,##0.##').format(value);
  }

  /// بڕی پارە لەگەڵ هێمای دراو.
  static String money(num value, {String symbol = 'د.ع', int decimals = 0}) {
    final String text = number(value, decimals: decimals);
    return symbol.isEmpty ? text : '$text $symbol';
  }

  /// ڕێژە بە سەدە.
  static String percent(num value) => '${NumberFormat('#,##0.##').format(value)}%';

  static String monthName(int month) => kurdishMonths[(month - 1) % 12];

  static String weekdayName(DateTime date) =>
      kurdishWeekdays[date.weekday % 7];

  static String weekdayShort(DateTime date) =>
      kurdishWeekdaysShort[date.weekday % 7];

  /// وەک: «١٢ی ئازار ٢٠٢٦»
  static String date(DateTime date) =>
      '${date.day}ی ${monthName(date.month)} ${date.year}';

  /// وەک: «١٢ی ئازار ٢٠٢٦، ١٤:٣٠»
  static String dateTime(DateTime date) =>
      '${Formatters.date(date)}، ${_clock.format(date)}';

  static String time(DateTime date) => _clock.format(date);

  static String timeWithSeconds(DateTime date) => _clockSeconds.format(date);

  /// 2026/03/12 — بەکاردێت بۆ ناوەکانی فایل و CSV.
  static String isoDate(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String isoDateTime(DateTime date) =>
      '${isoDate(date)} ${_clockSeconds.format(date)}';

  static String _two(int value) => value.toString().padLeft(2, '0');

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// لیستی ڕۆژەکانی نێوان دوو بەروار (بەبێ کاتژمێر).
  static List<DateTime> daysBetween(DateTime from, DateTime to) {
    final List<DateTime> days = <DateTime>[];
    DateTime cursor = startOfDay(from);
    final DateTime last = startOfDay(to);
    while (!cursor.isAfter(last)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }
}
