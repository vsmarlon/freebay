import 'package:flutter/widgets.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:intl/intl.dart';

import 'generated/app_localizations.dart';

AppLocalizations l10n(BuildContext context) => AppLocalizations.of(context);

AppLocalizations? maybeL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations);

String localizedFailureMessage(BuildContext context, Object? error) {
  final strings = l10n(context);
  return switch (error) {
    InvalidCredentialsFailure() => strings.errorInvalidCredentials,
    NetworkFailure() => strings.errorNetwork,
    TimeoutFailure() => strings.errorTimeout,
    CacheFailure() => strings.errorCache,
    UnauthorizedFailure() => strings.errorUnauthorized,
    ValidationFailure() => strings.errorValidation,
    NotFoundFailure() => strings.errorNotFound,
    BiometryCancelledFailure() => strings.authBiometryCancelled,
    ServerFailure() => strings.errorServer,
    UnknownFailure() => strings.errorUnknown,
    Failure() => strings.errorUnknown,
    _ => strings.errorUnknown,
  };
}

String localizedTimeAgo(
  BuildContext context,
  DateTime date, {
  bool compact = false,
}) {
  final strings = l10n(context);
  final locale = Localizations.localeOf(context).toString();
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return strings.timeAgoNow;
  if (diff.inMinutes < 60) {
    final count = diff.inMinutes;
    return compact
        ? strings.timeCompactMinutes(count)
        : strings.timeAgoMinutes(count);
  }
  if (diff.inHours < 24) {
    final count = diff.inHours;
    return compact
        ? strings.timeCompactHours(count)
        : strings.timeAgoHours(count);
  }
  if (diff.inDays < 7) {
    final count = diff.inDays;
    return compact
        ? strings.timeCompactDays(count)
        : strings.timeAgoDays(count);
  }
  if (diff.inDays < 30) {
    final count = diff.inDays ~/ 7;
    return compact
        ? strings.timeCompactWeeks(count)
        : strings.timeAgoWeeks(count);
  }
  if (diff.inDays < 365) {
    final count = diff.inDays ~/ 30;
    return compact
        ? strings.timeCompactMonths(count)
        : strings.timeAgoMonths(count);
  }
  return DateFormat.yMd(locale).format(date.toLocal());
}

String localizedDateSeparator(BuildContext context, DateTime date) {
  final localDate = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(localDate.year, localDate.month, localDate.day);
  if (day == today) return l10n(context).dateToday.toUpperCase();
  if (day == today.subtract(const Duration(days: 1))) {
    return l10n(context).dateYesterday.toUpperCase();
  }
  return DateFormat.yMMMd(
    Localizations.localeOf(context).toString(),
  ).format(localDate).toUpperCase();
}

String localizedShortDate(BuildContext context, DateTime date) =>
    DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(date.toLocal());
