import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/features/product/presentation/widgets/product_form_fields.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/features/product/presentation/widgets/product_form_validation.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class EditProductPage extends ConsumerStatefulWidget {
  final String productId;

  const EditProductPage({super.key, required this.productId});

  @override
  ConsumerState<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends ConsumerState<EditProductPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  bool _didPrefill = false;
  bool _isLoading = false;
  ProductStatus _status = ProductStatus.active;
  bool _isNewProduct = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(text: strings.productEditListing.toUpperCase()),
            Expanded(
              child: productAsync.when(
                loading: () => const SkeletonPage(
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      ShimmerBlock(height: 200),
                      SizedBox(height: 16),
                      ShimmerBlock(height: 48),
                      SizedBox(height: 12),
                      ShimmerBlock(height: 48),
                      SizedBox(height: 12),
                      ShimmerBlock(height: 48),
                      SizedBox(height: 12),
                      ShimmerBlock(height: 120),
                      SizedBox(height: 16),
                      ShimmerBlock(height: 48),
                    ],
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    strings.productLoadError,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                data: (product) {
                  _prefill(product);
                  return _buildForm(context, product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _prefill(ProductEntity product) {
    if (_didPrefill) {
      return;
    }

    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _priceController.text = (product.price / 100)
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    _status = product.status == ProductStatus.paused
        ? ProductStatus.paused
        : ProductStatus.active;
    _isNewProduct = product.condition == ProductCondition.isNew;
    _didPrefill = true;
  }

  Widget _buildForm(BuildContext context, ProductEntity product) {
    final strings = l10n(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        BrutalistBreadcrumb(items: context.breadcrumbs),
        Spacing.vMd,
        ProductBasicFields(
          titleController: _titleController,
          descriptionController: _descriptionController,
          priceController: _priceController,
          descriptionHint: strings.productDescriptionHint,
          priceKeyboardType: TextInputType.number,
        ),
        Spacing.vLg,
        ProductConditionSelector(
          label: strings.productConditionLabel,
          newLabel: strings.productNew,
          usedLabel: strings.productUsed,
          labelStyle: TextStyle(
            fontFamily: AppTypography.headlineFontFamily,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
          isNew: _isNewProduct,
          onChanged: (value) => setState(() => _isNewProduct = value),
        ),
        Spacing.vLg,
        Text(
          strings.productStatusLabel,
          style: TextStyle(
            fontFamily: AppTypography.headlineFontFamily,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        Spacing.vSm,
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: strings.productStatusActive,
                variant: _status == ProductStatus.active
                    ? AppButtonVariant.primary
                    : AppButtonVariant.ghost,
                onPressed: () => setState(() => _status = ProductStatus.active),
              ),
            ),
            Spacing.hSm,
            Expanded(
              child: AppButton(
                label: strings.productStatusPaused,
                variant: _status == ProductStatus.paused
                    ? AppButtonVariant.primary
                    : AppButtonVariant.ghost,
                onPressed: () => setState(() => _status = ProductStatus.paused),
              ),
            ),
          ],
        ),
        Spacing.vXl,
        AppButton(
          label: strings.productSaveChanges,
          isLoading: _isLoading,
          onPressed: () => _submit(context, product),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context, ProductEntity product) async {
    final strings = l10n(context);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final price = CurrencyUtils.parseReaisToCents(_priceController.text) ?? 0;

    if (!ProductFormValidation.isTitleValid(title) ||
        !ProductFormValidation.isDescriptionValid(description) ||
        !ProductFormValidation.isPriceValid(price)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.productFormInvalid),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref
        .read(productRepositoryProvider)
        .updateProduct(widget.productId, {
          'title': title,
          'description': description,
          'price': price,
          'condition': _isNewProduct
              ? ProductCondition.isNew.wireValue
              : ProductCondition.used.wireValue,
          'status': _status.wireValue,
        });

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedFailureMessage(context, failure)),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        ref.invalidate(productByIdProvider(widget.productId));
        setState(() => _isLoading = false);
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.productUpdated)));
      },
    );
  }
}
