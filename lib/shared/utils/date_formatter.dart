/// Human-readable date formatting for the history list.
class DateFormatter {
  DateFormatter._();

  /// Format a [DateTime] into a human-readable relative or absolute string.
  ///
  /// - "Just now" for less than 1 minute ago
  /// - "5m ago" for less than 1 hour ago
  /// - "3h ago" for less than 24 hours ago
  /// - "Yesterday" for the previous calendar day
  /// - "Mon, Feb 24" for dates within the current year
  /// - "Feb 24, 2025" for older dates
  static String format(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (dateOnly == yesterday) {
      return 'Yesterday';
    }

    if (dateTime.year == now.year) {
      return '${_weekday(dateTime.weekday)}, '
          '${_month(dateTime.month)} ${dateTime.day}';
    }

    return '${_month(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
  }

  static String _weekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  static String _month(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
