import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

enum _PostMenuAction { report, delete }

/// The post "..." menu: report for any signed-in viewer, delete for the author.
/// ponytail: hide/mute stay out until they have their own backend rules.
Future<void> showPostOverflowMenu(
  BuildContext context,
  WidgetRef ref, {
  required String postId,
  required String authorId,
  required String? viewerId,
  VoidCallback? onDeleted,
}) async {
  if (viewerId == null) return;
  final strings = l10n(context);
  final action = await showBrutalistSheet<_PostMenuAction>(
    context: context,
    title: strings.feedPostTitle,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: Text(strings.feedReportProblem),
          onTap: () => Navigator.pop(sheetContext, _PostMenuAction.report),
        ),
        if (viewerId == authorId)
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(strings.feedDeletePost),
            onTap: () => Navigator.pop(sheetContext, _PostMenuAction.delete),
          ),
      ],
    ),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _PostMenuAction.report:
      await _reportPost(context, ref, postId: postId);
    case _PostMenuAction.delete:
      await _confirmDelete(context, ref, postId: postId, onDeleted: onDeleted);
  }
}

Future<void> _reportPost(
  BuildContext context,
  WidgetRef ref, {
  required String postId,
}) async {
  final strings = l10n(context);
  final reasons = <(String, String)>[
    ('SPAM', strings.profileReportSpam),
    ('FRAUD', strings.profileReportFraud),
    ('HARASSMENT', strings.profileReportHarassment),
    ('FALSE_ADVERTISING', strings.profileReportFalseAdvertising),
    ('NUDITY', strings.profileReportNudity),
    ('OTHER', strings.profileReportOther),
  ];
  final reason = await showBrutalistSheet<String>(
    context: context,
    title: strings.feedReportProblem,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (value, label) in reasons)
          ListTile(
            title: Text(label),
            onTap: () => Navigator.pop(sheetContext, value),
          ),
      ],
    ),
  );
  if (reason == null || !context.mounted) return;
  final result = await ref
      .read(socialRepositoryProvider)
      .reportContent(targetType: 'POST', targetId: postId, reason: reason);
  if (!context.mounted) return;
  result.fold(
    (failure) => AppSnackbar.handleFailure(context, failure),
    (_) => AppSnackbar.success(context, strings.profileReportSubmitted),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref, {
  required String postId,
  VoidCallback? onDeleted,
}) async {
  final strings = l10n(context);
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  await AppDialog.show(
    context: context,
    icon: Icons.delete_outline,
    iconColor: AppColors.error,
    title: strings.feedDeletePost,
    subtitle: strings.feedPostDeletePending,
    dismissText: strings.commonCancel,
    okText: strings.commonDelete,
    isError: true,
    onOk: () async {
      final result = await ref
          .read(socialRepositoryProvider)
          .deletePost(postId);
      result.fold(
        (failure) {
          if (messenger.mounted) {
            AppSnackbar.errorOnMessenger(messenger, failure.message);
          }
        },
        (_) {
          container.read(feedProvider.notifier).removePost(postId);
          onDeleted?.call();
        },
      );
    },
  );
}
