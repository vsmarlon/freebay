import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/payments/presentation/providers/payment_providers.dart';
import 'package:freebay/features/payments/presentation/widgets/payment_view.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

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
  String? _userId;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<UserEntity?>>(authControllerProvider, (
      _,
      next,
    ) {
      _initializeForUser(next.value);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeForUser(ref.read(authControllerProvider).value);
    });
  }

  void _initializeForUser(UserEntity? user) {
    if (!mounted || user?.id == _userId) return;

    _userId = user?.id;
    ref.read(paymentCheckoutProvider.notifier).reset();
    _nameController.clear();
    _emailController.clear();
    _taxIdController.clear();

    if (user == null) return;
    _nameController.text = user.displayNameOrDefault;
    _emailController.text = user.email ?? '';
    if (kIsWeb && (user.cpf?.isNotEmpty ?? false)) {
      _taxIdController.text = user.cpf!;
    }
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
    final strings = l10n(context);
    final query = GoRouterState.of(context).uri.queryParameters;
    final productId = query['productId'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.paymentPageTitle,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: productId == null
                  ? Center(
                      child: Text(
                        strings.paymentProductMissing,
                        style: TextStyle(color: context.textPrimary),
                      ),
                    )
                  : _buildProductCheckout(context, productId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCheckout(BuildContext context, String productId) {
    final strings = l10n(context);
    final productAsync = ref.watch(productByIdProvider(productId));
    final checkout = ref.watch(paymentCheckoutProvider);

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
      error: (err, stack) => EmptyState.error(
        message: strings.productLoadError,
        onRetry: () => ref.invalidate(productByIdProvider(productId)),
      ),
      data: (product) {
        if (checkout.hasResult) {
          return PaymentView(
            product: product,
            payment: checkout.payment,
            paymentIntentClientSecret: checkout.paymentIntentClientSecret,
            createdOrderId: checkout.createdOrderId,
            amountCents: checkout.createdOrderAmount,
          );
        }
        return _buildForm(context, product, checkout.isSubmitting);
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    ProductEntity product,
    bool isSubmitting,
  ) {
    final strings = l10n(context);
    final isDark = context.isDark;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        BrutalistBox(
          backgroundColor: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.productTitle.toUpperCase(),
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
                label: strings.paymentFullName,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? strings.paymentNameRequired
                    : null,
              ),
              Spacing.vSm,
              AppTextField(
                controller: _emailController,
                label: strings.authEmail,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !ValueUtils.validateEmail(v))
                    ? strings.authEmailInvalid
                    : null,
              ),
              if (kIsWeb) ...[
                Spacing.vSm,
                AppTextField(
                  controller: _taxIdController,
                  label: strings.paymentCpfCnpj,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (d.length == 11 && ValueUtils.validateCPF(d)) {
                      return null;
                    }
                    if (d.length == 14 && ValueUtils.validateCNPJ(d)) {
                      return null;
                    }
                    return strings.paymentInvalidCpfCnpj;
                  },
                ),
              ],
              Spacing.vLg,
              AppButton(
                label: kIsWeb
                    ? strings.paymentPayWithStripe
                    : strings.paymentContinueToWallet,
                icon: Icons.payment,
                isLoading: isSubmitting,
                onPressed: () => _submit(product),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit(ProductEntity product) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final error = await ref
        .read(paymentCheckoutProvider.notifier)
        .submit(
          productId: product.id,
          customerName: _nameController.text.trim(),
          customerTaxId: _taxIdController.text.trim(),
          customerEmail: _emailController.text.trim(),
          isWeb: kIsWeb,
        );
    if (error != null && mounted) {
      AppSnackbar.error(context, l10n(context).paymentCheckoutFailed);
    }
  }
}
