import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/components/app_button.dart';
import '../../../../core/components/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/product_controller.dart';

class CreateProductPage extends HookConsumerWidget {
  const CreateProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final priceController = useTextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Simplification for MVP Condition (NEW or USED)
    final isNewProduct = useState<bool>(true);
    final isLoading = useState<bool>(false);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Novo Anúncio',
            style: TextStyle(
                color: isDark ? AppColors.white : AppColors.black)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
            color: isDark ? AppColors.white : AppColors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: titleController,
              label: 'Título do Anúncio',
              hint: 'Ex: iPhone 13 Pro Max 256GB',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: descriptionController,
              label: 'Descrição',
              hint: 'Detalhes sobre o estado do produto, tempo de uso, etc.',
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: priceController,
              label: 'Preço (R\$)',
              hint: '0,00',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Condition Toggle
            Text('Condição',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.mediumGray : AppColors.darkGray)),
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

            const SizedBox(height: 48),
            AppButton(
              label: 'Publicar Anúncio',
              isLoading: isLoading.value,
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                final priceText = priceController.text.replaceAll(',', '.');
                final price =
                    (double.tryParse(priceText) ?? 0) * 100; // to cents

                if (title.isNotEmpty && price > 0) {
                  isLoading.value = true;
                  try {
                    final usecase = ref.read(createProductUsecaseProvider);
                    final result = await usecase({
                      'title': title,
                      'description': description,
                      'price': price.toInt(),
                      'condition': isNewProduct.value ? 'NEW' : 'USED',
                      'status': 'ACTIVE',
                    });

                    result.fold((failure) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Erro: ${failure.message}'),
                            backgroundColor: AppColors.error));
                      }
                    }, (_) {
                      // Refresh the feed
                      ref.invalidate(productsFeedProvider);
                      if (context.mounted) {
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Anúncio criado!')));
                      }
                    });
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Erro inesperado: $e'),
                          backgroundColor: AppColors.error));
                    }
                  } finally {
                    isLoading.value = false;
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
