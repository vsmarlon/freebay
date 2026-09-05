import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/components/brutalist_box.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/payments/data/entities/payment_entity.dart';
import 'package:freebay/features/payments/data/entities/crypto_payment_entity.dart';
import 'package:freebay/features/payments/domain/usecases/create_payment_session_usecase.dart';
import 'package:freebay/features/payments/domain/usecases/create_payment_intent_usecase.dart';
import 'package:freebay/features/payments/domain/usecases/create_crypto_payment_usecase.dart';
import 'package:freebay/features/payments/presentation/providers/payment_providers.dart';
import 'package:freebay/features/payments/presentation/widgets/payment_view.dart';
import 'package:freebay/features/payments/presentation/widgets/monero_payment_view.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/core/components/spacing.dart';
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

  String _paymentMethod = 'stripe'; // 'stripe' or 'monero'
  bool _isSubmitting = false;
  bool _didPrefill = false;
  String? _createdOrderId;
  PaymentEntity? _payment;
  CryptoPaymentEntity? _cryptoPayment;
  String? _paymentIntentClientSecret;

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = GoRouterState.of(context).uri.queryParameters;
    final productId = query['productId'];
    final user = ref.watch(authControllerProvider).value;

    if (!_didPrefill && user != null) {
      _nameController.text = user.displayNameOrDefault;
      _emailController.text = user.email ?? '';
      if (kIsWeb && (user.cpf?.isNotEmpty ?? false)) {
        _taxIdController.text = user.cpf!;
      }
      _didPrefill = true;
    }

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'PAGAMENTO',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          Expanded(
            child: productId == null
                ? Center(
                    child: Text(
                      'Produto não informado.',
                      style: TextStyle(color: context.textPrimary),
                    ),
                  )
                : _buildProductCheckout(context, productId),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCheckout(BuildContext context, String productId) {
    final productAsync = ref.watch(productByIdProvider(productId));

    return productAsync.when(
      loading: () => const SkeletonPage(
        child: Column(
          children: [
            SizedBox(height: 16),
            ShimmerBlock(height: 100),
            SizedBox(height: 12),
            ShimmerBlock(height: 100),
          ],
        ),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Erro ao carregar produto',
          style: TextStyle(color: context.textPrimary),
        ),
      ),
      data: (product) {
        if (_cryptoPayment != null) {
          return MoneroPaymentView(
            product: product,
            cryptoPayment: _cryptoPayment!,
            createdOrderId: _createdOrderId,
          );
        }

        if (_payment != null || _paymentIntentClientSecret != null) {
          return PaymentView(
            product: product,
            payment: _payment,
            paymentIntentClientSecret: _paymentIntentClientSecret,
            createdOrderId: _createdOrderId,
          );
        }
        return _buildForm(context, product);
      },
    );
  }

  Widget _buildForm(BuildContext context, ProductEntity product) {
    final isDark = context.isDark;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        BrutalistBox(
          backgroundColor: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainer,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRODUTO',
                style: AppTypography.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
              Spacing.vSm,
              Text(
                product.title,
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
              Spacing.vSm,
              Text(
                CurrencyUtils.formatCents(product.price),
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Spacing.vLg,

        // Payment Method Selector
        Text(
          'MÉTODO DE PAGAMENTO',
          style: AppTypography.labelSmall.copyWith(
            color: context.textSecondary,
          ),
        ),
        Spacing.vSm,
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _paymentMethod = 'stripe'),
                child: BrutalistBox(
                  backgroundColor: _paymentMethod == 'stripe'
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isDark
                            ? AppColors.surfaceContainerLowDark
                            : AppColors.surfaceContainerLowest),
                  borderColor: _paymentMethod == 'stripe'
                      ? AppColors.primary
                      : context.borderColor,
                  borderWidth: _paymentMethod == 'stripe' ? 2 : 1,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Icon(
                        Icons.credit_card,
                        color: _paymentMethod == 'stripe'
                            ? AppColors.primary
                            : (isDark ? AppColors.white : AppColors.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'CARTÃO / STRIPE',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _paymentMethod == 'stripe'
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.white
                                    : AppColors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _paymentMethod = 'monero'),
                child: BrutalistBox(
                  backgroundColor: _paymentMethod == 'monero'
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isDark
                            ? AppColors.surfaceContainerLowDark
                            : AppColors.surfaceContainerLowest),
                  borderColor: _paymentMethod == 'monero'
                      ? AppColors.primary
                      : context.borderColor,
                  borderWidth: _paymentMethod == 'monero' ? 2 : 1,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock,
                        color: _paymentMethod == 'monero'
                            ? AppColors.primary
                            : (isDark ? AppColors.white : AppColors.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'MONERO (XMR)',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _paymentMethod == 'monero'
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.white
                                    : AppColors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        Spacing.vLg,

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_paymentMethod == 'stripe') ...[
                AppTextField(
                  controller: _nameController,
                  label: 'Nome completo',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                Spacing.vSm,
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !ValueUtils.validateEmail(v))
                      ? 'Informe um email válido'
                      : null,
                ),
                if (kIsWeb) ...[
                  Spacing.vSm,
                  AppTextField(
                    controller: _taxIdController,
                    label: 'CPF ou CNPJ',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (d.length == 11 && ValueUtils.validateCPF(d)) {
                        return null;
                      }
                      if (d.length == 14 && ValueUtils.validateCNPJ(d)) {
                        return null;
                      }
                      return 'CPF ou CNPJ inválido';
                    },
                  ),
                ],
              ] else ...[
                BrutalistBox(
                  backgroundColor: isDark
                      ? AppColors.surfaceContainerLowDark
                      : AppColors.surfaceContainerLowest,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pagamento 100% privado com custódia inteligente. Sem identificação bancária.',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Spacing.vLg,
              AppButton(
                label: _paymentMethod == 'stripe'
                    ? 'PAGAR COM STRIPE'
                    : 'PAGAR COM MONERO (XMR)',
                icon: _paymentMethod == 'stripe'
                    ? Icons.payment
                    : Icons.qr_code_2,
                isLoading: _isSubmitting,
                onPressed: () => _submit(product),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit(ProductEntity product) async {
    if (_paymentMethod == 'stripe' && !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final orderResult = await ref.read(createOrderUsecaseProvider)(
        product.id,
      );
      if (orderResult.isLeft) {
        if (mounted) {
          AppSnackbar.error(
            context,
            orderResult.leftOrNull?.message ?? 'Erro ao criar pedido.',
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }
      final order = orderResult.rightOrNull!;
      _createdOrderId = order.id;

      if (_paymentMethod == 'monero') {
        final cryptoResult = await ref.read(createCryptoPaymentUsecaseProvider)(
          CreateCryptoPaymentParams(orderId: order.id, currency: 'XMR'),
        );
        cryptoResult.fold(
          (f) => AppSnackbar.error(context, f.message),
          (p) => setState(() => _cryptoPayment = p),
        );
        return;
      }

      if (kIsWeb) {
        final sessionResult =
            await ref.read(createPaymentSessionUsecaseProvider)(
              CreatePaymentSessionParams(
                orderId: order.id,
                customerName: _nameController.text.trim(),
                customerTaxId: _taxIdController.text.trim(),
                customerEmail: _emailController.text.trim(),
              ),
            );
        sessionResult.fold(
          (f) => AppSnackbar.error(context, f.message),
          (p) => setState(() => _payment = p),
        );
      } else {
        final intentResult = await ref.read(createPaymentIntentUsecaseProvider)(
          CreatePaymentIntentParams(orderId: order.id),
        );
        intentResult.fold(
          (f) => AppSnackbar.error(context, f.message),
          (intent) => setState(
            () => _paymentIntentClientSecret = intent.paymentIntentClientSecret,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
