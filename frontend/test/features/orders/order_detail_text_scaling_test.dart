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
  _AuthController({this.userId = 'buyer-1'});

  final String userId;

  @override
  AsyncValue<UserEntity?> build() => AsyncValue.data(UserEntity(id: userId));
}

class _OrderRepository implements OrderRepository {
  _OrderRepository(this.order);

  final OrderEntity order;
  int confirmDeliveryCalls = 0;

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
  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId) async {
    confirmDeliveryCalls++;
    return Right(order);
  }

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

  testWidgets('buyer can confirm a shipped order only after confirmation', (
    tester,
  ) async {
    final order = OrderEntity(
      id: 'order-shipped',
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: 'product-1',
      amount: 19990,
      platformFee: 1999,
      sellerAmount: 17991,
      status: OrderStatus.shipped,
      escrowStatus: EscrowStatus.held,
      createdAt: DateTime.utc(2026, 9, 30),
    );
    final buyerRepository = _OrderRepository(order);

    Future<void> pumpAsUser(String userId, _OrderRepository repository) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: [
              authControllerProvider.overrideWith(
                () => _AuthController(userId: userId),
              ),
              orderRepositoryProvider.overrideWithValue(repository),
            ],
            child: MaterialApp(
              locale: const Locale('pt', 'BR'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: OrderDetailPage(orderId: order.id),
            ),
          ),
        );

    await pumpAsUser('buyer-1', buyerRepository);
    await tester.pumpAndSettle();
    final confirmReceipt = find.text('Confirmar recebimento');
    expect(confirmReceipt, findsOneWidget);

    await tester.ensureVisible(confirmReceipt);
    await tester.tap(confirmReceipt);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Ao confirmar o recebimento, o pagamento será liberado para o vendedor.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(buyerRepository.confirmDeliveryCalls, 0);

    await tester.ensureVisible(confirmReceipt);
    await tester.tap(confirmReceipt);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(buyerRepository.confirmDeliveryCalls, 1);

    final sellerRepository = _OrderRepository(order);
    await pumpAsUser('seller-1', sellerRepository);
    await tester.pumpAndSettle();
    expect(find.text('Confirmar recebimento'), findsNothing);
    expect(sellerRepository.confirmDeliveryCalls, 0);
  });
}
