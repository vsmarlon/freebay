import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/payments/data/entities/pix_payment_entity.dart';
import 'package:freebay/features/payments/domain/usecases/create_pix_payment_usecase.dart';
import 'package:freebay/features/payments/presentation/providers/payment_providers.dart';
import 'package:freebay/features/payments/presentation/widgets/pix_payment_view.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';

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
    final isDark = context.isDark;
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
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          PageHeader(
            text: isCartCheckout ? 'CHECKOUT' : 'PAGAMENTO PIX',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          BrutalistBreadcrumb(items: context.breadcrumbs),
          Expanded(
            child: isCartCheckout
                ? _buildCartUnavailable(context)
                : productId == null
                ? _buildInvalidState(context)
                : _buildProductCheckout(context, productId),
          ),
        ],
      ),
    );
  }

  Widget _buildCartUnavailable(BuildContext context) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainer,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHECKOUT MULTI-ITEM',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.onPrimaryContainer
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ainda indisponivel',
                  style: TextStyle(
                    fontFamily: AppTypography.headlineFontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'O backend ainda cria pedido por produto. Por enquanto, finalize a compra usando o botao Comprar agora dentro do produto.',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? AppColors.inverseOnSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Spacing.vLg,
          AppButton(
            label: 'Voltar ao carrinho',
            onPressed: () => context.go('/cart'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidState(BuildContext context) {
    final isDark = context.isDark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Produto nao informado para iniciar o pagamento.',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: isDark ? AppColors.white : AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildProductCheckout(BuildContext context, String productId) {
    final productAsync = ref.watch(productByIdProvider(productId));

    return productAsync.when(
      loading: () => SkeletonPage(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const ShimmerBlock(height: 100),
            const SizedBox(height: 12),
            const ShimmerBlock(height: 100),
            const SizedBox(height: 12),
            const ShimmerBlock(height: 100),
            const SizedBox(height: 16),
            const ShimmerBlock(height: 48),
            const SizedBox(height: 12),
            const ShimmerBlock(height: 48),
          ],
        ),
      ),
      error: (_, _) => _buildInvalidState(context),
      data: (product) {
        if (_pixPayment != null) {
          return PixPaymentView(
            product: product,
            pixPayment: _pixPayment!,
            createdOrderId: _createdOrderId,
          );
        }

        return _buildCheckoutForm(context, product);
      },
    );
  }

  Widget _buildCheckoutForm(BuildContext context, ProductEntity product) {
    final isDark = context.isDark;
    final formattedPrice = CurrencyUtils.formatCents(product.price);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLowest,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMPRA IMEDIATA',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.onPrimaryContainer
                      : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.title,
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.onSurface,
                ),
              ),
              Spacing.vMd,
              Container(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  formattedPrice,
                  style: TextStyle(
                    fontFamily: AppTypography.headlineFontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        Spacing.vLg,
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PaymentSectionLabel('DADOS DO PAGADOR'),
              const SizedBox(height: 12),
              _buildInput(
                controller: _nameController,
                hint: 'Nome completo',
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
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      !ValueUtils.validateEmail(value)) {
                    return 'Informe um email valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildInput(
                controller: _taxIdController,
                hint: 'CPF ou CNPJ',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length == 11) {
                    if (!ValueUtils.validateCPF(digits)) {
                      return 'Informe um CPF válido';
                    }
                  } else if (digits.length == 14) {
                    if (!ValueUtils.validateCNPJ(digits)) {
                      return 'Informe um CNPJ válido';
                    }
                  } else {
                    return 'Informe um CPF ou CNPJ valido';
                  }
                  return null;
                },
              ),
              Spacing.vLg,
              AppButton(
                label: 'Gerar PIX',
                onPressed: _isSubmitting
                    ? null
                    : () => _submitCheckout(context, product),
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return AppTextField(
      controller: controller,
      label: hint,
      hint: hint,
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  Future<void> _submitCheckout(
    BuildContext context,
    ProductEntity product,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final orderResult = await ref.read(createOrderUsecaseProvider)(product.id);

    await orderResult.fold(
      (failure) async {
        if (!context.mounted) {
          return;
        }
        AppSnackbar.error(context, failure.message);
      },
      (order) async {
        _createdOrderId = order.id;

        final paymentResult = await ref.read(createPixPaymentUsecaseProvider)(
          CreatePixPaymentParams(
            orderId: order.id,
            customerName: _nameController.text.trim(),
            customerTaxId: _taxIdController.text.replaceAll(RegExp(r'\D'), ''),
            customerEmail: _emailController.text.trim(),
            idempotencyKey: order.id,
          ),
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
