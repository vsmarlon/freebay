import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

Future<void> showConversationMenu({
  required BuildContext context,
  required bool isArchived,
  required VoidCallback onCustomize,
  required Future<void> Function() onArchive,
}) {
  return showBrutalistSheet(
    context: context,
    title: 'OPÇÕES',
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Personalizar'),
          onTap: () {
            Navigator.pop(sheetContext);
            onCustomize();
          },
        ),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: Text(isArchived ? 'Desarquivar' : 'Arquivar'),
          onTap: () {
            Navigator.pop(sheetContext);
            onArchive();
          },
        ),
      ],
    ),
  );
}
