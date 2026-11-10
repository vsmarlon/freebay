import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class NewChatProductComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const NewChatProductComposer({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.chatMessageToSeller,
            style: TextStyle(color: context.textSecondary),
          ),
          Spacing.vSm,
          AppTextField(controller: controller, maxLines: 5),
          Spacing.vMd,
          AppButton(
            label: strings.chatSendText,
            onPressed: controller.text.trim().isEmpty ? null : onSend,
            isLoading: isSending,
          ),
        ],
      ),
    );
  }
}
