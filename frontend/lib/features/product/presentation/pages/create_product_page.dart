import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/data/entities/create_product_input.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/features/product/presentation/widgets/category_selector_field.dart';
import 'package:freebay/features/product/presentation/widgets/product_preview_card.dart';
import 'package:freebay/features/product/presentation/widgets/product_form_fields.dart';
import 'package:freebay/features/product/presentation/widgets/product_form_validation.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class CreateProductPage extends HookConsumerWidget {
  const CreateProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final priceController = useTextEditingController();
    final isNewProduct = useState<bool>(true);
    final isLoading = useState<bool>(false);
    final selectedCategoryId = useState<String?>(null);
    final selectedImagePath = useState<String?>(null);

    useListenable(titleController);
    useListenable(descriptionController);
    useListenable(priceController);

    final categoriesAsync = ref.watch(flatCategoriesProvider);
    final currentUser = ref.watch(authControllerProvider).value;

    final selectedCategory = categoriesAsync.value
        ?.where((category) => category.id == selectedCategoryId.value)
        .firstOrNull;

    Future<void> pickImage(ImageSource source) async {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (image != null) selectedImagePath.value = image.path;
    }

    Future<void> submit() async {
      final title = titleController.text.trim();
      final description = descriptionController.text.trim();
      final price = CurrencyUtils.parseReaisToCents(priceController.text) ?? 0;

      if (!ProductFormValidation.isTitleValid(title)) {
        AppSnackbar.error(context, strings.productNameInvalid);
        return;
      }
      if (!ProductFormValidation.isDescriptionValid(description)) {
        AppSnackbar.error(context, strings.productDescriptionIncomplete);
        return;
      }
      if (!ProductFormValidation.isPriceValid(price)) {
        AppSnackbar.error(context, strings.productPriceInvalid);
        return;
      }
      if (selectedCategoryId.value == null) {
        AppSnackbar.error(context, strings.productCategoryRequired);
        return;
      }
      if (selectedImagePath.value == null) {
        AppSnackbar.error(context, strings.productImageRequired);
        return;
      }

      isLoading.value = true;
      final result = await ref.read(createProductUsecaseProvider)(
        CreateProductInput(
          title: title,
          description: description,
          price: price,
          condition: isNewProduct.value
              ? ProductCondition.isNew
              : ProductCondition.used,
          categoryId: selectedCategoryId.value!,
          imagePath: selectedImagePath.value!,
        ),
      );

      if (!context.mounted) return;
      isLoading.value = false;

      result.fold((failure) => AppSnackbar.handleFailure(context, failure), (
        _,
      ) {
        ref.invalidate(productsFeedProvider);
        context.pop();
        AppSnackbar.success(context, strings.productCreated);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.productCreateListing.toUpperCase(),
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProductPreviewCard(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      pricePreview: CurrencyUtils.formatCents(
                        CurrencyUtils.parseReaisToCents(priceController.text) ??
                            0,
                      ),
                      categoryName: selectedCategory?.name,
                      imagePath: selectedImagePath.value,
                      isNew: isNewProduct.value,
                      userName:
                          currentUser?.displayNameOrDefault ??
                          strings.commonYou,
                      userAvatarUrl: currentUser?.avatarUrl,
                    ),
                    Spacing.vLg,
                    ProductBasicFields(
                      titleController: titleController,
                      descriptionController: descriptionController,
                      priceController: priceController,
                      titleLabel: strings.productListingTitle,
                    ),
                    Spacing.vLg,
                    CategorySelectorField(
                      categoriesAsync: categoriesAsync,
                      selectedCategory: selectedCategory,
                      onCategorySelected: (value) =>
                          selectedCategoryId.value = value,
                      onRetry: () => ref.invalidate(categoriesProvider),
                    ),
                    Spacing.vMd,
                    Container(
                      color: context.surfaceColor,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedImagePath.value == null
                                  ? strings.productPhotoNotSelected
                                  : strings.productPhotoSelected,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          AppButton(
                            onPressed: () => pickImage(ImageSource.gallery),
                            icon: Icons.photo_library,
                            label: strings.commonGallery,
                            variant: AppButtonVariant.secondary,
                            size: AppButtonSize.compact,
                          ),
                          Spacing.hSm,
                          AppButton(
                            onPressed: () => pickImage(ImageSource.camera),
                            icon: Icons.camera_alt,
                            label: strings.commonCamera,
                            variant: AppButtonVariant.secondary,
                            size: AppButtonSize.compact,
                          ),
                        ],
                      ),
                    ),
                    Spacing.vLg,
                    ProductConditionSelector(
                      isNew: isNewProduct.value,
                      onChanged: (value) => isNewProduct.value = value,
                    ),
                    Spacing.vXl,
                    AppButton(
                      label: strings.productPublishListing,
                      isLoading: isLoading.value,
                      onPressed: submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
