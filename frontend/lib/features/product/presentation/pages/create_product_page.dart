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
import 'package:freebay/features/product/presentation/widgets/category_selector_field.dart';
import 'package:freebay/features/product/presentation/widgets/product_preview_card.dart';

class CreateProductPage extends HookConsumerWidget {
  const CreateProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      final priceDigits = priceController.text.replaceAll(RegExp(r'\D'), '');
      final price = int.tryParse(priceDigits) ?? 0;

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

      isLoading.value = true;
      final result = await ref.read(createProductUsecaseProvider)(
        CreateProductInput(
          title: title,
          description: description,
          price: price,
          condition: isNewProduct.value ? 'NEW' : 'USED',
          categoryId: selectedCategoryId.value!,
          imagePath: selectedImagePath.value!,
        ),
      );

      if (!context.mounted) return;
      isLoading.value = false;

      result.fold((failure) => AppSnackbar.error(context, failure.message), (
        _,
      ) {
        ref.invalidate(productsFeedProvider);
        context.pop();
        AppSnackbar.success(context, 'Anúncio criado!');
      });
    }

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'NOVO ANÚNCIO',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
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
                      int.tryParse(
                            priceController.text.replaceAll(RegExp(r'\D'), ''),
                          ) ??
                          0,
                    ),
                    categoryName: selectedCategory?.name,
                    imagePath: selectedImagePath.value,
                    isNew: isNewProduct.value,
                    userName: currentUser?.displayNameOrDefault ?? 'Você',
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
                    label: 'Preço (R\$)',
                    hint: '0,00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                                ? 'Nenhuma foto selecionada'
                                : 'Foto selecionada',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 16),
                          label: const Text('Galeria'),
                          style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(),
                          ),
                        ),
                        Spacing.hSm,
                        OutlinedButton.icon(
                          onPressed: () => pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text('Câmera'),
                          style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacing.vLg,
                  Text(
                    'CONDIÇÃO',
                    style: TextStyle(
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
                          label: 'NOVO',
                          variant: isNewProduct.value
                              ? AppButtonVariant.primary
                              : AppButtonVariant.ghost,
                          onPressed: () => isNewProduct.value = true,
                        ),
                      ),
                      Spacing.hSm,
                      Expanded(
                        child: AppButton(
                          label: 'USADO',
                          variant: !isNewProduct.value
                              ? AppButtonVariant.primary
                              : AppButtonVariant.ghost,
                          onPressed: () => isNewProduct.value = false,
                        ),
                      ),
                    ],
                  ),
                  Spacing.vXl,
                  AppButton(
                    label: 'PUBLICAR ANÚNCIO',
                    isLoading: isLoading.value,
                    onPressed: submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
