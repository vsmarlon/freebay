import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/utils/currency_utils.dart';

class MakeOfferDialog extends StatefulWidget {
  final String? initialTitle;
  final int? initialPriceCents;
  final void Function(Map<String, dynamic> offerData) onSendOffer;

  const MakeOfferDialog({
    super.key,
    this.initialTitle,
    this.initialPriceCents,
    required this.onSendOffer,
  });

  @override
  State<MakeOfferDialog> createState() => _MakeOfferDialogState();
}

class _MakeOfferDialogState extends State<MakeOfferDialog> {
  final _titleController = TextEditingController();
  final _offerPriceController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _offerPriceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final priceText = _offerPriceController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final offerCents = int.tryParse(priceText) ?? 0;

    if (title.isEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    if (offerCents <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.lightImpact();
    Navigator.pop(context);
    widget.onSendOffer({
      'title': title,
      'originalPrice': widget.initialPriceCents,
      'offerPrice': offerCents,
      'message': _messageController.text.trim(),
      'status': 'PENDING',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor, width: 2),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FAZER PROPOSTA',
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: context.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              Spacing.vMd,
              AppTextField(
                label: 'PRODUTO / ITEM',
                controller: _titleController,
                hint: 'Nome do produto anunciado',
              ),
              Spacing.vSm,
              if (widget.initialPriceCents != null) ...[
                Text(
                  'Preço original: ${CurrencyUtils.formatCents(widget.initialPriceCents!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacing.vSm,
              ],
              AppTextField(
                label: r'SUA OFERTA (R$)',
                controller: _offerPriceController,
                hint: 'Ex: 250,00',
                keyboardType: TextInputType.number,
              ),
              Spacing.vSm,
              AppTextField(
                label: 'MENSAGEM (OPCIONAL)',
                controller: _messageController,
                hint: 'Ex: Retiro em mãos hoje mesmo...',
                maxLines: 2,
              ),
              Spacing.vLg,
              AppButton(
                label: 'ENVIAR PROPOSTA',
                icon: Icons.send,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
