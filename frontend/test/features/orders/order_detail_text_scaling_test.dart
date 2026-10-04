import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/domain/repositories/order_repository.dart';
import 'package:freebay/features/orders/presentation/pages/order_detail_page.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

class _AuthController extends AuthController {
  @override
  AsyncValue<UserEntity?> build() =>
      const AsyncValue.data(UserEntity(id: 'buyer-1'));
}

class _OrderRepository implements OrderRepository {
  const _OrderRepository(this.order);

  final OrderEntity order;

  @override
  Future<Either<Failure, OrderEntity>> getOrder(
    String orderId, {
    CancelToken? cancelToken,
  }) async => Right(order);

  @override
  Future<Either<Failure, CanReviewResponse>> canReviewOrder(
    String orderId, {
    CancelToken? cancelToken,
  }) async => const Right(CanReviewResponse());

  @override
  Future<Either<Failure, CursorPage<OrderEntity>>> getMyPurchases({
    String? cursor,
    int limit = defaultOrderPageLimit,
    OrderStatus? status,
  }) async => const Right(CursorPage.empty());

  @override
  Future<Either<Failure, CursorPage<OrderEntity>>> getMySales({
    String? cursor,
    int limit = defaultOrderPageLimit,
    OrderStatus? status,
  }) async => const Right(CursorPage.empty());

  @override
  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId) async =>
      Right(order);

  @override
  Future<Either<Failure, OrderEntity>> createOrder(String productId) async =>
      Right(order);

  @override
  Future<Either<Failure, String>> cancelOrder(
    String orderId, {
    String? reason,
    required String stepUpToken,
  }) async => const Right('cancelled');
}

void main() {
  for (final scale in [1.5, 2.0]) {
    testWidgets('loaded order detail fits at ${scale}x with long title', (
      tester,
    ) async {
      final order = OrderEntity(
        id: 'order-long',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        productId: 'product-1',
        amount: 19990,
        platformFee: 1999,
        sellerAmount: 17991,
        status: OrderStatus.confirmed,
        escrowStatus: EscrowStatus.held,
        createdAt: DateTime.utc(2026, 9, 30),
        product: const ProductEntity(
          id: 'product-1',
          title:
              'Produto com um nome muito longo para validar detalhes do pedido em acessibilidade',
          sellerId: 'seller-1',
          price: 19990,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_AuthController.new),
            orderRepositoryProvider.overrideWithValue(_OrderRepository(order)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: OrderDetailPage(orderId: order.id),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Produto com um nome muito longo'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
