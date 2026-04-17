import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';

class CartCheckoutPage extends ConsumerStatefulWidget {
  const CartCheckoutPage({super.key});

  @override
  ConsumerState<CartCheckoutPage> createState() => _CartCheckoutPageState();
}

class _CartCheckoutPageState extends ConsumerState<CartCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _emailController = TextEditingController();

  bool _didPrefill = false;
  bool _isSubmitting = false;
  CartCheckoutEntity? _checkout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).loadCart();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(cartProvider);
    final cart = state.cart;
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    if (!_didPrefill && user != null) {
      _nameController.text = user.displayNameOrDefault;
      _emailController.text = user.email ?? '';
      _didPrefill = true;
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Checkout do carrinho'),
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _checkout != null
              ? _buildCheckoutResult(context, isDark, _checkout!)
          : cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 72,
                        color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Carrinho vazio',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ...cart.items.map((item) {
                            final subtotal = CurrencyUtils.formatCents(item.subtotal);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              color: isDark ? AppColors.surfaceDark : AppColors.white,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.product.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.white : AppColors.darkGray,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${item.quantity}x',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'R\$ $subtotal',
                                    style: TextStyle(
                                      fontFamily: 'SpaceGrotesk',
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.white : AppColors.darkGray,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          Text(
                            'DADOS DO PAGADOR',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.onPrimaryContainer
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildInput(
                                  controller: _nameController,
                                  hint: 'Nome completo',
                                  isDark: isDark,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe o nome';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildInput(
                                  controller: _emailController,
                                  hint: 'Email',
                                  isDark: isDark,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty ||
                                        !value.contains('@')) {
                                      return 'Informe um email valido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildInput(
                                  controller: _taxIdController,
                                  hint: 'CPF ou CNPJ',
                                  isDark: isDark,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final digits =
                                        (value ?? '').replaceAll(RegExp(r'\D'), '');
                                    if (digits.length < 11 || digits.length > 14) {
                                      return 'Informe um CPF ou CNPJ valido';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Total (${cart.totalItems} itens)',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: isDark
                                          ? AppColors.mediumGray
                                          : AppColors.mediumGray,
                                    ),
                                  ),
                                  Text(
                                    CurrencyUtils.formatCents(cart.totalPrice),
                                    style: TextStyle(
                                      fontFamily: 'SpaceGrotesk',
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.white : AppColors.darkGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _isSubmitting
                                    ? null
                                    : () => _submitCheckout(context),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient:
                                        _isSubmitting ? null : AppColors.brutalistGradient,
                                    color: _isSubmitting
                                        ? (isDark
                                            ? AppColors.surfaceContainerDark
                                            : AppColors.surfaceContainerHighest)
                                        : null,
                                  ),
                                  child: Center(
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.onPrimary,
                                            ),
                                          )
                                        : const Text(
                                            'Gerar PIXs',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.onPrimary,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCheckoutResult(
    BuildContext context,
    bool isDark,
    CartCheckoutEntity checkout,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHECKOUT GERADO',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${checkout.totalOrders} pedidos criados',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...checkout.items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productTitle,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quantidade: ${item.quantity}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: isDark ? AppColors.mediumGray : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyUtils.formatCents(item.amount),
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: isDark
                      ? AppColors.surfaceContainerLowDark
                      : AppColors.surfaceContainerLowest,
                  child: SelectableText(
                    item.pixQrCode,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? AppColors.white : AppColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          await Clipboard.setData(
                            ClipboardData(text: item.pixQrCode),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackbar.success(context, 'Codigo PIX copiado');
                        },
                        child: Container(
                          height: 44,
                          color: isDark
                              ? AppColors.surfaceContainerDark
                              : AppColors.surfaceContainerHighest,
                          child: Center(
                            child: Text(
                              'Copiar',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.white : AppColors.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/orders/${item.orderId}'),
                        child: Container(
                          height: 44,
                          decoration: const BoxDecoration(
                            gradient: AppColors.brutalistGradient,
                          ),
                          child: const Center(
                            child: Text(
                              'Ver pedido',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontFamily: 'Inter',
        color: isDark ? AppColors.white : AppColors.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          color: isDark ? AppColors.mediumGray : AppColors.onSurfaceVariant,
        ),
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceContainerLowDark
            : AppColors.surfaceContainerLowest,
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }

  Future<void> _submitCheckout(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await ref.read(cartServiceProvider).checkoutCart(
          customerName: _nameController.text.trim(),
          customerTaxId: _taxIdController.text.replaceAll(RegExp(r'\D'), ''),
          customerEmail: _emailController.text.trim(),
        );

    result.fold(
      (failure) {
        if (!context.mounted) {
          return;
        }
        AppSnackbar.error(context, failure.message);
      },
      (checkout) {
        if (!mounted) {
          return;
        }
        setState(() {
          _checkout = checkout;
        });
        ref.read(cartProvider.notifier).loadCart();
      },
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
