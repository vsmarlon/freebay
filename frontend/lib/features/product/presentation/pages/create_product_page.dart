import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/presentation/widgets/category_selector_field.dart';
import 'package:freebay/features/product/presentation/widgets/product_preview_card.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/core/components/spacing.dart';

class CreateProductPage extends HookConsumerWidget {
  const CreateProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
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
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.valueOrNull;

    final pricePreview = _displayPrice(priceController.text);
    final selectedCategory = categoriesAsync.valueOrNull
        ?.where((category) => category.id == selectedCategoryId.value)
        .firstOrNull;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'NOVO ANÚNCIO',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: context.textPrimary,
                  size: 20,
                ),
              ),
            ),
            breadcrumbs: [
              BreadcrumbItem(label: 'Produtos', onTap: () => context.pop()),
              const BreadcrumbItem(label: 'Novo Anúncio'),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainer,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ANUNCIO SEPARADO DO FEED SOCIAL',
                          style: TextStyle(
                            fontFamily: AppTypography.headlineFontFamily,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? AppColors.white : AppColors.onSurface,
                          ),
                        ),
                        Spacing.vSm,
                        Text(
                          'Use anuncios para vender com preco, categoria e imagem. Posts sociais continuam no feed, enquanto sua reputacao fica visivel no perfil e nas avaliacoes.',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.inverseOnSurface
                                : AppColors.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacing.vLg,
                  ProductPreviewCard(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    pricePreview: pricePreview,
                    categoryName: selectedCategory?.name,
                    imagePath: selectedImagePath.value,
                    isNew: isNewProduct.value,
                    userName: currentUser?.displayName ?? 'Você',
                    userAvatarUrl: currentUser?.avatarUrl,
                  ),
                  Spacing.vLg,
                  AppTextField(
                    controller: titleController,
                    label: 'Título do anúncio',
                    hint: 'Ex: iPhone 13 Pro Max 256GB',
                  ),
                  Spacing.vMd,
                  AppTextField(
                    controller: descriptionController,
                    label: 'Descrição',
                    hint: 'Detalhes do estado, acessórios, tempo de uso...',
                    maxLines: 4,
                  ),
                  Spacing.vMd,
                  AppTextField(
                    controller: priceController,
                    label: 'Preço',
                    hint: '0,00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final normalized = _formatCurrencyInput(value);
                      if (normalized != value) {
                        priceController.value = TextEditingValue(
                          text: normalized,
                          selection: TextSelection.collapsed(
                              offset: normalized.length),
                        );
                      }
                    },
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
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1600,
                        maxHeight: 1600,
                        imageQuality: 82,
                      );
                      if (image != null) {
                        selectedImagePath.value = image.path;
                      }
                    },
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined,
                              color: AppColors.primaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedImagePath.value == null
                                  ? 'Selecionar imagem do produto'
                                  : 'Imagem selecionada',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.darkGray,
                                fontFamily: AppTypography.fontFamily,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Spacing.vLg,
                  Text(
                    'Condição',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.mediumGray : AppColors.darkGray,
                    ),
                  ),
                  Spacing.vSm,
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Novo',
                          variant: isNewProduct.value
                              ? AppButtonVariant.primary
                              : AppButtonVariant.ghost,
                          onPressed: () => isNewProduct.value = true,
                        ),
                      ),
                      Spacing.hSm,
                      Expanded(
                        child: AppButton(
                          label: 'Usado',
                          variant: !isNewProduct.value
                              ? AppButtonVariant.primary
                              : AppButtonVariant.ghost,
                          onPressed: () => isNewProduct.value = false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  AppButton(
                    label: 'Publicar anúncio',
                    isLoading: isLoading.value,
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final description = descriptionController.text.trim();
                      final price = _parsePriceToCents(priceController.text);

                      if (title.length < 3) {
                        AppSnackbar.error(context, 'Informe um título válido.');
                        return;
                      }

                      if (description.length < 10) {
                        AppSnackbar.error(
                            context, 'Adicione uma descrição mais completa.');
                        return;
                      }

                      if (price <= 0) {
                        AppSnackbar.error(context, 'Informe um preço válido.');
                        return;
                      }

                      if (selectedCategoryId.value == null) {
                        AppSnackbar.error(context, 'Selecione uma categoria.');
                        return;
                      }

                      if (selectedImagePath.value == null) {
                        AppSnackbar.error(
                            context, 'Adicione uma imagem do produto.');
                        return;
                      }

                      if (kDebugMode) {
                        debugPrint('[PRODUCT UI] publishing product...');
                        debugPrint('[PRODUCT UI] title=$title');
                        debugPrint(
                            '[PRODUCT UI] descriptionLength=${description.length}');
                        debugPrint('[PRODUCT UI] priceCents=$price');
                        debugPrint(
                            '[PRODUCT UI] condition=${isNewProduct.value ? 'NEW' : 'USED'}');
                        debugPrint(
                            '[PRODUCT UI] categoryId=${selectedCategoryId.value}');
                        debugPrint(
                            '[PRODUCT UI] imagePath=${selectedImagePath.value}');
                      }

                      isLoading.value = true;
                      try {
                        final usecase = ref.read(createProductUsecaseProvider);
                        final result = await usecase({
                          'title': title,
                          'description': description,
                          'price': price,
                          'condition': isNewProduct.value ? 'NEW' : 'USED',
                          'categoryId': selectedCategoryId.value,
                          'imagePath': selectedImagePath.value!,
                        });

                        result.fold(
                          (failure) {
                            if (context.mounted) {
                              AppSnackbar.error(context, failure.message);
                            }
                          },
                          (_) {
                            ref.invalidate(productsFeedProvider);
                            if (context.mounted) {
                              context.pop();
                              AppSnackbar.success(context, 'Anúncio criado!');
                            }
                          },
                        );
                      } catch (_) {
                        if (kDebugMode) {
                          debugPrint(
                              '[PRODUCT UI] unexpected publish exception');
                        }
                        if (context.mounted) {
                          AppSnackbar.error(
                              context, 'Não foi possível publicar o anúncio.');
                        }
                      } finally {
                        isLoading.value = false;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrencyInput(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return '';
    }
    if (digits.length == 1) {
      return '0,0$digits';
    }
    if (digits.length == 2) {
      return '0,$digits';
    }

    final rawIntegerPart = digits.substring(0, digits.length - 2);
    final integerPart = rawIntegerPart.replaceFirst(RegExp(r'^0+'), '').isEmpty
        ? '0'
        : rawIntegerPart.replaceFirst(RegExp(r'^0+'), '');
    final decimalPart = digits.substring(digits.length - 2);
    return '$integerPart,$decimalPart';
  }

  int _parsePriceToCents(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return int.tryParse(digits) ?? 0;
  }

  String _displayPrice(String value) {
    final cents = _parsePriceToCents(value);
    final reais = cents / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
