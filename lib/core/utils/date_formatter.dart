import 'package:intl/intl.dart';

/// Date and time formatting utilities for FloatWatch.
///
/// Display format throughout the app: MMM dd, yyyy  (e.g. "Mar 01, 2026")
/// Database date format: yyyy-MM-dd  (ISO 8601)
/// Database datetime format: yyyy-MM-dd HH:mm:ss
class DateFormatter {
  DateFormatter._();

  static final DateFormat _display = DateFormat('MMM dd, yyyy');
  static final DateFormat _displayShort = DateFormat('MMM dd');
  static final DateFormat _displayMonth = DateFormat('MMMM yyyy');
  static final DateFormat _db = DateFormat('yyyy-MM-dd');
  static final DateFormat _dbDateTime = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _dayOfWeek = DateFormat('EEEE');

  // ── To display strings ────────────────────────────────────────────────────

  /// DateTime → "Mar 01, 2026"
  static String toDisplay(DateTime date) => _display.format(date);

  /// DateTime → "Mar 01"
  static String toDisplayShort(DateTime date) => _displayShort.format(date);

  /// DateTime → "March 2026"
  static String toDisplayMonth(DateTime date) => _displayMonth.format(date);

  /// DateTime → "3:45 PM"
  static String toTime(DateTime dateTime) => _time.format(dateTime);

  /// DateTime → "Monday"
  static String toDayOfWeek(DateTime date) => _dayOfWeek.format(date);

  /// DB date string → "Mar 01, 2026"
  static String dbToDisplay(String dbDate) {
    try {
      return toDisplay(DateTime.parse(dbDate));
    } catch (_) {
      return dbDate;
    }
  }

  /// DB datetime string → "Mar 01, 2026 • 3:45 PM"
  static String dbToDisplayDateTime(String dbDateTime) {
    try {
      final dt = DateTime.parse(dbDateTime);
      return '${toDisplay(dt)} • ${toTime(dt)}';
    } catch (_) {
      return dbDateTime;
    }
  }

  // ── To database strings ───────────────────────────────────────────────────

  /// DateTime → "2026-03-01"
  static String toDb(DateTime date) => _db.format(date);

  /// DateTime → "2026-03-01 15:45:00"
  static String toDbDateTime(DateTime dateTime) => _dbDateTime.format(dateTime);

  // ── Convenient now/today helpers ──────────────────────────────────────────

  /// Today's date as a DB string: "2026-03-01"
  static String todayDb() => toDb(DateTime.now());

  /// Current datetime as a DB string: "2026-03-01 15:45:00"
  static String nowDb() => toDbDateTime(DateTime.now());

  /// Current datetime in UTC as a DB string (for sync timestamps)
  static String nowUtcDb() => toDbDateTime(DateTime.now().toUtc());

  // ── Parsing ───────────────────────────────────────────────────────────────

  /// Parse a DB date string to DateTime.
  static DateTime fromDb(String dbDate) => DateTime.parse(dbDate);

  /// Parse a DB datetime string to DateTime.
  static DateTime fromDbDateTime(String dbDateTime) =>
      DateTime.parse(dbDateTime);

  // ── Relative helpers ──────────────────────────────────────────────────────

  /// Returns true if the given DB date string is today.
  static bool isToday(String dbDate) {
    try {
      final d = DateTime.parse(dbDate);
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    } catch (_) {
      return false;
    }
  }

  /// Returns a human-friendly relative label: "Today", "Yesterday", or date.
  static String toRelativeDisplay(String dbDate) {
    if (isToday(dbDate)) return 'Today';
    try {
      final d = DateTime.parse(dbDate);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      if (d.year == yesterday.year &&
          d.month == yesterday.month &&
          d.day == yesterday.day) {
        return 'Yesterday';
      }
      return toDisplay(d);
    } catch (_) {
      return dbDate;
    }
  }
}
