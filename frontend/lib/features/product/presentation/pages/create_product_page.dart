import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/components/app_button.dart';
import '../../../../core/components/app_snackbar.dart';
import '../../../../core/components/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/entities/category_entity.dart';
import '../controllers/product_controller.dart';

class CreateProductPage extends HookConsumerWidget {
  const CreateProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final priceController = useTextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNewProduct = useState<bool>(true);
    final isLoading = useState<bool>(false);
    final selectedCategoryId = useState<String?>(null);
    final selectedImagePath = useState<String?>(null);
    final categoriesAsync = ref.watch(flatCategoriesProvider);

    final pricePreview = _displayPrice(priceController.text);
    final selectedCategory = categoriesAsync.valueOrNull
        ?.where((category) => category.id == selectedCategoryId.value)
        .firstOrNull;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Novo anúncio',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.onSurface,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.transparent,
        elevation: 0,
        iconTheme:
            IconThemeData(color: isDark ? AppColors.white : AppColors.onSurface),
      ),
      body: SingleChildScrollView(
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
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
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
            const SizedBox(height: 24),
            _buildPreviewCard(
              isDark: isDark,
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              pricePreview: pricePreview,
              categoryName: selectedCategory?.name,
              imagePath: selectedImagePath.value,
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: titleController,
              label: 'Título do anúncio',
              hint: 'Ex: iPhone 13 Pro Max 256GB',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: descriptionController,
              label: 'Descrição',
              hint: 'Detalhes do estado, acessórios, tempo de uso...',
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: priceController,
              label: 'Preço',
              hint: '0,00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final normalized = _formatCurrencyInput(value);
                if (normalized != value) {
                  priceController.value = TextEditingValue(
                    text: normalized,
                    selection: TextSelection.collapsed(offset: normalized.length),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            categoriesAsync.when(
              data: (categories) => InkWell(
                onTap: () => _showCategoryPicker(
                  context,
                  categories,
                  isDark,
                  selectedCategoryId.value,
                  (value) => selectedCategoryId.value = value,
                ),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: isDark ? AppColors.surfaceDark : AppColors.white,
                  child: Row(
                    children: [
                      const Icon(Icons.category_outlined,
                          color: AppColors.primaryPurple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Categoria',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.onPrimaryContainer
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedCategory?.name ?? 'Selecionar categoria',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward,
                          color: AppColors.primaryPurple),
                    ],
                  ),
                ),
              ),
              loading: () => Container(
                height: 64,
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Container(
                padding: const EdgeInsets.all(16),
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Não foi possível carregar categorias agora.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isDark ? AppColors.white : AppColors.darkGray,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => ref.invalidate(categoriesProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          gradient: AppColors.brutalistGradient,
                        ),
                        child: const Text(
                          'Tentar',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                        color: AppColors.primaryPurple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedImagePath.value == null
                            ? 'Selecionar imagem do produto'
                            : 'Imagem selecionada',
                        style: TextStyle(
                          color: isDark ? AppColors.white : AppColors.darkGray,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Condição',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.mediumGray : AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
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
                const SizedBox(width: 8),
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
                  AppSnackbar.error(context, 'Adicione uma descrição mais completa.');
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
                  AppSnackbar.error(context, 'Adicione uma imagem do produto.');
                  return;
                }

                if (kDebugMode) {
                  debugPrint('[PRODUCT UI] publishing product...');
                  debugPrint('[PRODUCT UI] title=$title');
                  debugPrint('[PRODUCT UI] descriptionLength=${description.length}');
                  debugPrint('[PRODUCT UI] priceCents=$price');
                  debugPrint('[PRODUCT UI] condition=${isNewProduct.value ? 'NEW' : 'USED'}');
                  debugPrint('[PRODUCT UI] categoryId=${selectedCategoryId.value}');
                  debugPrint('[PRODUCT UI] imagePath=${selectedImagePath.value}');
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
                      debugPrint('[PRODUCT UI] unexpected publish exception');
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
    );
  }

  Widget _buildPreviewCard({
    required bool isDark,
    required String title,
    required String description,
    required String pricePreview,
    required String? categoryName,
    required String? imagePath,
  }) {
    return Container(
      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREVIEW DO ANÚNCIO',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: imagePath != null
                      ? Image.file(File(imagePath), fit: BoxFit.cover)
                      : Container(
                          color: isDark
                              ? AppColors.surfaceContainerLowDark
                              : AppColors.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.mediumGray,
                              size: 40,
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'Seu título aparece aqui' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        color: isDark
                            ? AppColors.surfaceContainerLowDark
                            : AppColors.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          pricePreview,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.white : AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        categoryName ?? 'Categoria obrigatória',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.onPrimaryContainer
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description.isEmpty
                            ? 'A descrição do produto aparece aqui.'
                            : description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isDark
                              ? AppColors.mediumGray
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Future<void> _showCategoryPicker(
    BuildContext context,
    List<CategoryEntity> categories,
    bool isDark,
    String? selectedCategoryId,
    void Function(String) onSelected,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'ESCOLHER CATEGORIA',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.onSurface,
                    ),
                  ),
                );
              }

              final category = categories[index - 1];
              final isSelected = category.id == selectedCategoryId;
              return InkWell(
                onTap: () {
                  onSelected(category.id);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  color: isSelected
                      ? (isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainerHighest)
                      : (isDark ? AppColors.surfaceDark : AppColors.white),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isDark ? AppColors.white : AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check, color: AppColors.primaryPurple),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
