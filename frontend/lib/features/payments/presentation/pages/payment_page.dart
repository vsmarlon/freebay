import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/payments/data/entities/payment_entity.dart';
import 'package:freebay/features/payments/domain/usecases/create_payment_session_usecase.dart';
import 'package:freebay/features/payments/domain/usecases/create_payment_intent_usecase.dart';
import 'package:freebay/features/payments/presentation/providers/payment_providers.dart';
import 'package:freebay/features/payments/presentation/widgets/payment_view.dart';
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

  bool _isSubmitting = false;
  bool _didPrefill = false;
  String? _createdOrderId;
  PaymentEntity? _payment;
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          color: context.surfaceColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRODUTO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                ),
              ),
              Spacing.vSm,
              Text(
                product.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
              Spacing.vSm,
              Text(
                CurrencyUtils.formatCents(product.price),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
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
                    if (d.length == 11 && ValueUtils.validateCPF(d))
                      return null;
                    if (d.length == 14 && ValueUtils.validateCNPJ(d))
                      return null;
                    return 'CPF ou CNPJ inválido';
                  },
                ),
              ],
              Spacing.vLg,
              AppButton(
                label: 'PAGAR COM STRIPE',
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final orderResult = await ref.read(createOrderUsecaseProvider)(
        product.id,
      );
      if (orderResult.isLeft) {
        if (mounted)
          AppSnackbar.error(
            context,
            orderResult.leftOrNull?.message ?? 'Erro ao criar pedido.',
          );
        setState(() => _isSubmitting = false);
        return;
      }
      final order = orderResult.rightOrNull!;
      _createdOrderId = order.id;

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
