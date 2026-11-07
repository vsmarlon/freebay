import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

Future<void> showConversationMenu({
  required BuildContext context,
  required bool isArchived,
  required bool isMuted,
  required VoidCallback onCustomize,
  required VoidCallback onMute,
  required Future<void> Function() onArchive,
  required VoidCallback onDelete,
}) {
  final strings = l10n(context);
  return showBrutalistSheet(
    context: context,
    title: strings.chatOptions,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(strings.chatCustomize),
          onTap: () {
            Navigator.pop(sheetContext);
            onCustomize();
          },
        ),
        ListTile(
          leading: Icon(
            isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
          ),
          title: Text(isMuted ? strings.chatUnmute : strings.chatMute),
          onTap: () {
            Navigator.pop(sheetContext);
            onMute();
          },
        ),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: Text(isArchived ? strings.chatUnarchive : strings.chatArchive),
          onTap: () {
            Navigator.pop(sheetContext);
            onArchive();
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: AppColors.error),
          title: Text(
            strings.commonDelete,
            style: const TextStyle(color: AppColors.error),
          ),
          onTap: () {
            Navigator.pop(sheetContext);
            onDelete();
          },
        ),
      ],
    ),
  );
}
