import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class OrderCancellationSheet extends StatefulWidget {
  const OrderCancellationSheet({super.key, required this.onConfirm});

  final Future<bool> Function(String reason) onConfirm;

  @override
  State<OrderCancellationSheet> createState() => _OrderCancellationSheetState();
}

class _OrderCancellationSheetState extends State<OrderCancellationSheet> {
  static const _reasons = [
    'Mudei de ideia',
    'Encontrei um preço melhor',
    'Produto incorreto',
    'Demora na confirmação',
    'Problemas com o vendedor',
    'Outro motivo',
  ];

  String? _selectedReason;
  bool _isSubmitting = false;

  String _label(String reason) {
    final strings = l10n(context);
    return switch (reason) {
      'Mudei de ideia' => strings.ordersCancelReasonChangedMind,
      'Encontrei um preço melhor' => strings.ordersCancelReasonBetterPrice,
      'Produto incorreto' => strings.ordersCancelReasonWrongProduct,
      'Demora na confirmação' => strings.ordersCancelReasonConfirmationDelay,
      'Problemas com o vendedor' => strings.ordersCancelReasonSellerIssue,
      _ => strings.ordersCancelReasonOther,
    };
  }

  Future<void> _confirm() async {
    final reason = _selectedReason;
    if (reason == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final confirmed = await widget.onConfirm(reason);
    if (!mounted) return;
    if (confirmed) Navigator.of(context).pop();
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                strings.ordersCancelReasonPrompt,
                style: AppTypography.bodyMedium,
              ),
              Spacing.vSm,
              for (final reason in _reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.xs),
                  child: _ReasonOption(
                    label: _label(reason),
                    selected: _selectedReason == reason,
                    enabled: !_isSubmitting,
                    onTap: () => setState(() => _selectedReason = reason),
                  ),
                ),
            ],
          ),
        ),
        Spacing.vMd,
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: strings.commonBack,
                variant: AppButtonVariant.secondary,
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
            ),
            Spacing.hSm,
            Expanded(
              child: AppButton(
                label: strings.ordersCancel,
                variant: AppButtonVariant.danger,
                isLoading: _isSubmitting,
                onPressed: _selectedReason == null || _isSubmitting
                    ? null
                    : _confirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? context.surfaceHighColor : context.surfaceColor,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? context.textPrimary : context.borderSoftColor,
                width: selected ? AppDepth.borderThick : AppDepth.borderThin,
              ),
            ),
            child: Row(
              children: [
                Expanded(child: Text(label, style: AppTypography.bodyMedium)),
                if (selected) Icon(Icons.check, color: context.textPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
