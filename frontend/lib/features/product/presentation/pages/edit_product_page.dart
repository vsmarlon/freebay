import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';

class EditProductPage extends ConsumerStatefulWidget {
  final String productId;

  const EditProductPage({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends ConsumerState<EditProductPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  bool _didPrefill = false;
  bool _isLoading = false;
  String _status = 'ACTIVE';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Editar anúncio',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.onSurface,
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        elevation: 0,
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Não foi possível carregar o anúncio.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark ? AppColors.white : AppColors.onSurface,
            ),
          ),
        ),
        data: (product) {
          _prefill(product);
          return _buildForm(context, product, isDark);
        },
      ),
    );
  }

  void _prefill(ProductEntity product) {
    if (_didPrefill) {
      return;
    }

    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _priceController.text = (product.price / 100).toStringAsFixed(2).replaceAll('.', ',');
    _status = product.status == 'PAUSED' ? 'PAUSED' : 'ACTIVE';
    _isNewProduct = product.condition == 'NEW';
    _didPrefill = true;
  }

  Widget _buildForm(BuildContext context, ProductEntity product, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AppTextField(
          controller: _titleController,
          label: 'Título',
          hint: 'Ex: iPhone 13 Pro Max 256GB',
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _descriptionController,
          label: 'Descrição',
          hint: 'Detalhes do produto',
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _priceController,
          label: 'Preço (R\$)',
          hint: '0,00',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        Text(
          'Condição',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Novo',
                variant: _isNewProduct
                    ? AppButtonVariant.primary
                    : AppButtonVariant.ghost,
                onPressed: () => setState(() => _isNewProduct = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: 'Usado',
                variant: !_isNewProduct
                    ? AppButtonVariant.primary
                    : AppButtonVariant.ghost,
                onPressed: () => setState(() => _isNewProduct = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Status',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Ativo',
                variant: _status == 'ACTIVE'
                    ? AppButtonVariant.primary
                    : AppButtonVariant.ghost,
                onPressed: () => setState(() => _status = 'ACTIVE'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: 'Pausado',
                variant: _status == 'PAUSED'
                    ? AppButtonVariant.primary
                    : AppButtonVariant.ghost,
                onPressed: () => setState(() => _status = 'PAUSED'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Salvar alterações',
          isLoading: _isLoading,
          onPressed: () => _submit(context, product),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context, ProductEntity product) async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final price = ((double.tryParse(
                  _priceController.text.replaceAll(',', '.'),
                ) ??
                0) *
            100)
        .toInt();

    if (title.length < 3 || description.length < 10 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha título, descrição e preço corretamente.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(productRepositoryProvider).updateProduct(
      widget.productId,
      {
        'title': title,
        'description': description,
        'price': price,
        'condition': _isNewProduct ? 'NEW' : 'USED',
        'status': _status,
      },
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        ref.invalidate(productByIdProvider(widget.productId));
        setState(() => _isLoading = false);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anúncio atualizado com sucesso.'),
          ),
        );
      },
    );
  }
}
