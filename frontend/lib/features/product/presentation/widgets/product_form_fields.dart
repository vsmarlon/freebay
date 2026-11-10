import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class ProductBasicFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final String? titleLabel;
  final String? descriptionHint;
  final TextInputType priceKeyboardType;

  const ProductBasicFields({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.priceController,
    this.titleLabel,
    this.descriptionHint,
    this.priceKeyboardType = const TextInputType.numberWithOptions(
      decimal: true,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: titleController,
          label: titleLabel ?? strings.productTitleLabel,
          hint: strings.productTitleExample,
          maxLength: 100,
        ),
        Spacing.vMd,
        AppTextField(
          controller: descriptionController,
          label: strings.productDescription,
          hint: descriptionHint ?? strings.productDescriptionHint,
          maxLines: 4,
        ),
        Spacing.vMd,
        AppTextField(
          controller: priceController,
          label: strings.productPriceLabel,
          hint: strings.productPriceHint,
          keyboardType: priceKeyboardType,
        ),
      ],
    );
  }
}

class ProductConditionSelector extends StatelessWidget {
  final bool isNew;
  final ValueChanged<bool> onChanged;
  final String? label;
  final String? newLabel;
  final String? usedLabel;
  final TextStyle? labelStyle;

  const ProductConditionSelector({
    super.key,
    required this.isNew,
    required this.onChanged,
    this.label,
    this.newLabel,
    this.usedLabel,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          (label ?? strings.productConditionLabel).toUpperCase(),
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
                label: (newLabel ?? strings.productNew).toUpperCase(),
                variant: isNew
                    ? AppButtonVariant.primary
                    : AppButtonVariant.ghost,
                onPressed: () => onChanged(true),
              ),
            ),
            Spacing.hSm,
            Expanded(
              child: AppButton(
                label: (usedLabel ?? strings.productUsed).toUpperCase(),
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
