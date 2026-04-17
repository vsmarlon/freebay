import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/orders/data/services/order_service.dart';
import 'package:freebay/features/payments/data/entities/pix_payment_entity.dart';
import 'package:freebay/features/payments/data/services/payment_service.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _orderService = OrderService();
  final _paymentService = PaymentService();

  bool _isSubmitting = false;
  bool _didPrefill = false;
  String? _createdOrderId;
  PixPaymentEntity? _pixPayment;

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
    final query = GoRouterState.of(context).uri.queryParameters;
    final source = query['source'];
    final productId = query['productId'];
    final isCartCheckout = source == 'cart';
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
        title: Text(isCartCheckout ? 'Checkout do carrinho' : 'Pagamento PIX'),
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
      body: isCartCheckout
          ? _buildCartUnavailable(context, isDark)
          : productId == null
              ? _buildInvalidState(context, isDark)
              : _buildProductCheckout(context, productId, isDark),
    );
  }

  Widget _buildCartUnavailable(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHECKOUT MULTI-ITEM',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ainda indisponivel',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'O backend ainda cria pedido por produto. Por enquanto, finalize a compra usando o botao Comprar agora dentro do produto.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? AppColors.inverseOnSurface : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => context.go('/cart'),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: const BoxDecoration(
                gradient: AppColors.brutalistGradient,
              ),
              child: const Center(
                child: Text(
                  'Voltar ao carrinho',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Produto nao informado para iniciar o pagamento.',
          style: TextStyle(
            fontFamily: 'Inter',
            color: isDark ? AppColors.white : AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildProductCheckout(
    BuildContext context,
    String productId,
    bool isDark,
  ) {
    final productAsync = ref.watch(productByIdProvider(productId));

    return productAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildInvalidState(context, isDark),
      data: (product) {
        if (_pixPayment != null) {
          return _buildPixState(context, product, isDark, _pixPayment!);
        }

        return _buildCheckoutForm(context, product, isDark);
      },
    );
  }

  Widget _buildCheckoutForm(BuildContext context, ProductEntity product, bool isDark) {
    final formattedPrice = CurrencyUtils.formatCents(product.price);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMPRA IMEDIATA',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.title,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  formattedPrice,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(isDark, 'DADOS DO PAGADOR'),
              const SizedBox(height: 12),
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
                  if (value == null || value.trim().isEmpty || !value.contains('@')) {
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
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 11 || digits.length > 14) {
                    return 'Informe um CPF ou CNPJ valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _isSubmitting
                    ? null
                    : () => _submitCheckout(context, product),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: _isSubmitting ? null : AppColors.brutalistGradient,
                    color: _isSubmitting
                        ? (isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer)
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
                            'Gerar PIX',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimary,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPixState(
    BuildContext context,
    ProductEntity product,
    bool isDark,
    PixPaymentEntity pixPayment,
  ) {
    final expiresAt =
        '${pixPayment.expiresAt.day.toString().padLeft(2, '0')}/${pixPayment.expiresAt.month.toString().padLeft(2, '0')} ${pixPayment.expiresAt.hour.toString().padLeft(2, '0')}:${pixPayment.expiresAt.minute.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PIX GERADO',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.title,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Expira em $expiresAt',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isDark ? AppColors.inverseOnSurface : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel(isDark, 'CODIGO PIX'),
        const SizedBox(height: 12),
        Container(
          color: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLowest,
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            pixPayment.pixQrCode,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppColors.white : AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: pixPayment.pixQrCode));
            if (!context.mounted) {
              return;
            }
            AppSnackbar.success(context, 'Codigo PIX copiado');
          },
          child: Container(
            width: double.infinity,
            height: 48,
            color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerHighest,
            child: Center(
              child: Text(
                'Copiar codigo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _createdOrderId == null ? null : () => context.go('/orders/${_createdOrderId!}'),
          child: Container(
            width: double.infinity,
            height: 52,
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
      ],
    );
  }

  Widget _buildLabel(bool isDark, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
      ),
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
        fillColor: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLowest,
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

  Future<void> _submitCheckout(BuildContext context, ProductEntity product) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final orderResult = await _orderService.createOrder(product.id);

    await orderResult.fold(
      (failure) async {
        if (!context.mounted) {
          return;
        }
        AppSnackbar.error(context, failure.message);
      },
      (order) async {
        _createdOrderId = order.id;

        final paymentResult = await _paymentService.createPixPayment(
          orderId: order.id,
          customerName: _nameController.text.trim(),
          customerTaxId: _taxIdController.text.replaceAll(RegExp(r'\D'), ''),
          customerEmail: _emailController.text.trim(),
          idempotencyKey: order.id,
        );

        paymentResult.fold(
          (failure) {
            if (!context.mounted) {
              return;
            }
            AppSnackbar.error(context, failure.message);
          },
          (pixPayment) {
            if (!mounted) {
              return;
            }
            setState(() {
              _pixPayment = pixPayment;
            });
          },
        );
      },
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
