import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class ProductBasicFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final String titleLabel;
  final String descriptionHint;
  final TextInputType priceKeyboardType;

  const ProductBasicFields({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.priceController,
    this.titleLabel = 'Título',
    this.descriptionHint = 'Detalhes do estado, acessórios, tempo de uso...',
    this.priceKeyboardType = const TextInputType.numberWithOptions(
      decimal: true,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: titleController,
          label: titleLabel,
          hint: 'Ex: iPhone 13 Pro Max 256GB',
          maxLength: 100,
        ),
        Spacing.vMd,
        AppTextField(
          controller: descriptionController,
          label: 'Descrição',
          hint: descriptionHint,
          maxLines: 4,
        ),
        Spacing.vMd,
        AppTextField(
          controller: priceController,
          label: 'Preço (R\$)',
          hint: '0,00',
          keyboardType: priceKeyboardType,
        ),
      ],
    );
  }
}

class ProductConditionSelector extends StatelessWidget {
  final bool isNew;
  final ValueChanged<bool> onChanged;
  final String label;
  final String newLabel;
  final String usedLabel;
  final TextStyle? labelStyle;

  const ProductConditionSelector({
    super.key,
    required this.isNew,
    required this.onChanged,
    this.label = 'CONDIÇÃO',
    this.newLabel = 'NOVO',
    this.usedLabel = 'USADO',
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style:
              labelStyle ??
              TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.textSecondary,
              ),
        ),
        Spacing.vSm,
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: newLabel,
                variant: isNew
                    ? AppButtonVariant.primary
                    : AppButtonVariant.ghost,
                onPressed: () => onChanged(true),
              ),
            ),
            Spacing.hSm,
            Expanded(
              child: AppButton(
                label: usedLabel,
                variant: isNew
                    ? AppButtonVariant.ghost
                    : AppButtonVariant.primary,
                onPressed: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
