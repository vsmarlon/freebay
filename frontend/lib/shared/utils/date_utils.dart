import 'package:intl/intl.dart';

DateTime parseServerDateTime(String value) => DateTime.parse(value).toLocal();

/// Returns true if [a] and [b] are on the same calendar day (local time).
bool isSameDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

/// Chat timestamp: "14:30" (local time — entities keep UTC instants).
String formatMessageTime(DateTime date) {
  return DateFormat('HH:mm').format(date.toLocal());
}

/// Date separator: "HOJE", "ONTEM", or "23 DE JUL 2026" (local time).
String formatDateSeparator(DateTime date, {DateTime? now}) {
  date = date.toLocal();
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final target = DateTime(date.year, date.month, date.day);

  if (target == today) return 'HOJE';
  if (target == today.subtract(const Duration(days: 1))) return 'ONTEM';
  final month = DateUtilsCustom._monthsShort[date.month - 1].toUpperCase();
  return '${date.day} DE $month ${date.year}';
}

/// WhatsApp-style grouped timestamp:
/// Shows time only on the last message of a consecutive group.
/// Returns null if this message is not the last in its group.
String? groupTimestamp({
  required DateTime createdAt,
  required DateTime? nextCreatedAt,
  required bool isLastMessage,
}) {
  if (isLastMessage ||
      (nextCreatedAt != null && !isSameDay(createdAt, nextCreatedAt))) {
    return formatMessageTime(createdAt);
  }
  return null;
}

class DateUtilsCustom {
  DateUtilsCustom._();

  static const List<String> _months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static const List<String> _monthsShort = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  /// Formats date to full format: "3 de julho de 2026"
  static String formatFullDate(DateTime date) {
    if (date.month < 1 || date.month > 12) return '';
    final monthName = _months[date.month - 1];
    return '${date.day} de $monthName de ${date.year}';
  }

  /// Formats date to standard Brazilian short format: "03/07/2026"
  static String formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  /// Formats date to "day monthShort": "03 jul"
  static String formatDayMonth(DateTime date) {
    if (date.month < 1 || date.month > 12) return '';
    final day = date.day.toString().padLeft(2, '0');
    final monthName = _monthsShort[date.month - 1];
    return '$day $monthName';
  }

  /// Formats time to HH:mm format: "17:15"
  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Returns if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Returns if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Returns a contextual date separator for chat lists: "Hoje", "Ontem" or "03/07/2026"
  static String formatChatSeparator(DateTime date) {
    if (isToday(date)) {
      return 'Hoje';
    } else if (isYesterday(date)) {
      return 'Ontem';
    } else {
      return formatShortDate(date);
    }
  }

  /// Returns "Bom dia", "Boa tarde", "Boa noite" according to the current local hour
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return 'Bom dia';
    } else if (hour >= 12 && hour < 18) {
      return 'Boa tarde';
    } else {
      return 'Boa noite';
    }
  }
}
