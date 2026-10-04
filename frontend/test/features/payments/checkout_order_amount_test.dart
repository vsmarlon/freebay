import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/domain/repositories/order_repository.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/payments/data/entities/payment_intent_entity.dart';
import 'package:freebay/features/payments/data/entities/payment_entity.dart';
import 'package:freebay/features/payments/domain/repositories/payment_repository.dart';
import 'package:freebay/features/payments/domain/usecases/create_payment_intent_usecase.dart';
import 'package:freebay/features/payments/presentation/pages/payment_page.dart';
import 'package:freebay/features/payments/presentation/providers/payment_providers.dart';
import 'package:freebay/features/payments/presentation/widgets/payment_view.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import 'package:freebay/shared/widgets/platform_wallet_payment_button.dart';

const _product = ProductEntity(
  id: 'product-1',
  title: 'Vintage Camera',
  description: 'A used film camera',
  price: 10000,
  condition: ProductCondition.used,
  sellerId: 'seller-1',
);

class _AuthController extends AuthController {
  @override
  AsyncValue<UserEntity?> build() =>
      const AsyncValue.data(UserEntity(id: 'buyer', displayName: 'Buyer'));
}

class _OrderRepository implements OrderRepository {
  _OrderRepository(this.order);

  final OrderEntity order;

  @override
  Future<Either<Failure, OrderEntity>> createOrder(String productId) async =>
      Right(order);

  @override
  Future<Either<Failure, OrderEntity>> getOrder(
    String orderId, {
    CancelToken? cancelToken,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, CursorPage<OrderEntity>>> getMyPurchases({
    String? cursor,
    int limit = defaultOrderPageLimit,
    OrderStatus? status,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, CursorPage<OrderEntity>>> getMySales({
    String? cursor,
    int limit = defaultOrderPageLimit,
    OrderStatus? status,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId) =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, String>> cancelOrder(
    String orderId, {
    String? reason,
    required String stepUpToken,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, CanReviewResponse>> canReviewOrder(
    String orderId, {
    CancelToken? cancelToken,
  }) => throw UnimplementedError();
}

class _PaymentRepository implements PaymentRepository {
  @override
  Future<Either<Failure, PaymentIntentEntity>> createPaymentIntent({
    required String orderId,
    String? idempotencyKey,
  }) async => Right(
    PaymentIntentEntity(
      orderId: orderId,
      paymentIntentClientSecret: 'pi_secret',
    ),
  );

  @override
  Future<Either<Failure, PaymentEntity>> createPaymentSession({
    required String orderId,
    required String customerName,
    required String customerTaxId,
    required String customerEmail,
    String? idempotencyKey,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets('checkout wallet amount comes from the created order', (
    tester,
  ) async {
    final order = OrderEntity(
      id: 'order-1',
      buyerId: 'buyer',
      sellerId: 'seller-1',
      productId: 'product-1',
      amount: 12500,
      platformFee: 1000,
      sellerAmount: 11500,
      status: OrderStatus.pending,
      escrowStatus: EscrowStatus.held,
      createdAt: DateTime(2026),
    );
    final router = GoRouter(
      initialLocation: '/payment?productId=product-1',
      routes: [
        GoRoute(path: '/payment', builder: (_, _) => const PaymentPage()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_AuthController.new),
          productByIdProvider('product-1').overrideWith((_) async => _product),
          orderRepositoryProvider.overrideWithValue(_OrderRepository(order)),
          createPaymentIntentUsecaseProvider.overrideWith(
            (_) => CreatePaymentIntentUsecase(_PaymentRepository()),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Buyer');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'buyer@example.com',
    );
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentView), findsOneWidget);
    expect(
      tester
          .widget<PlatformWalletPaymentButton>(
            find.byType(PlatformWalletPaymentButton),
          )
          .amountCents,
      12500,
    );
    expect(tester.takeException(), isNull);
  });
}
