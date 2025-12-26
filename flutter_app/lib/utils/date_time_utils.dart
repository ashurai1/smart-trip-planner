import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Returns a smart timestamp like:
  /// - Today • 10:45 AM
  /// - Yesterday • 6:12 PM
  /// - Mon • 9:30 AM (if within the last 7 days)
  /// - 12/24/2025 • 14:00 (older dates)
  static String formatSmartDate(DateTime? date) {
    if (date == null) return "Just now";

    final now = DateTime.now();
    final localDate = date.toLocal();
    final diff = now.difference(localDate);

    final timeStr = DateFormat('h:mm a').format(localDate);

    // Today
    if (diff.inDays == 0 && localDate.day == now.day) {
      return "Today • $timeStr";
    }

    // Yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (localDate.day == yesterday.day && 
        localDate.month == yesterday.month && 
        localDate.year == yesterday.year) {
      return "Yesterday • $timeStr";
    }

    // This week (last 7 days)
    if (diff.inDays < 7) {
      final dayStr = DateFormat('E').format(localDate); // Mon, Tue
      return "$dayStr • $timeStr";
    }

    // Older
    final dateStr = DateFormat('MM/dd/yyyy').format(localDate);
    return "$dateStr • $timeStr";
  }

  /// Parses various date string formats safely
  static DateTime? safeParse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}
