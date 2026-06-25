class TimeUtils {
  TimeUtils._();

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'agora';
    } else if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min atrás';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h h atrás';
    } else if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d d atrás';
    } else if (diff.inDays < 30) {
      final w = diff.inDays ~/ 7;
      return '$w sem atrás';
    } else if (diff.inDays < 365) {
      final mo = diff.inDays ~/ 30;
      return '$mo mes atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
