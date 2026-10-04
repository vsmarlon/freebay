import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

Future<void> showConversationMenu({
  required BuildContext context,
  required bool isArchived,
  required VoidCallback onCustomize,
  required Future<void> Function() onArchive,
}) {
  return showBrutalistSheet(
    context: context,
    title: l10n(context).chatOptions,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(l10n(context).chatCustomize),
          onTap: () {
            Navigator.pop(sheetContext);
            onCustomize();
          },
        ),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: Text(
            isArchived
                ? l10n(context).chatUnarchive
                : l10n(context).chatArchive,
          ),
          onTap: () {
            Navigator.pop(sheetContext);
            onArchive();
          },
        ),
      ],
    ),
  );
}
