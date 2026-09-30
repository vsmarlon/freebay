import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/domain/repositories/order_repository.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';

class _SalesRepository implements OrderRepository {
  final responses = <Future<Either<Failure, CursorPage<OrderEntity>>>>[];
  final calls = <({String? cursor, OrderStatus? status})>[];

  @override
  Future<Either<Failure, CursorPage<OrderEntity>>> getMySales({
    String? cursor,
    int limit = defaultOrderPageLimit,
    OrderStatus? status,
  }) {
    calls.add((cursor: cursor, status: status));
    return responses.removeAt(0);
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrder(String orderId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, CursorPage<OrderEntity>>> getMyPurchases({
    String? cursor,
    int limit = defaultOrderPageLimit,
    OrderStatus? status,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, OrderEntity>> createOrder(String productId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, String>> cancelOrder(
    String orderId, {
    String? reason,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, CanReviewResponse>> canReviewOrder(String orderId) =>
      throw UnimplementedError();
}

OrderEntity _order(String id) => OrderEntity(
  id: id,
  buyerId: 'buyer-1',
  sellerId: 'seller-1',
  productId: 'product-1',
  amount: 1000,
  platformFee: 100,
  sellerAmount: 900,
  status: OrderStatus.shipped,
  escrowStatus: EscrowStatus.held,
  createdAt: DateTime(2026, 9, 12),
);

Future<Either<Failure, CursorPage<OrderEntity>>> _page(
  List<OrderEntity> items, {
  bool hasMore = false,
  String? nextCursor,
}) async =>
    Right(CursorPage(items: items, hasMore: hasMore, nextCursor: nextCursor));

void main() {
  test(
    'owns status and resets to a first-page request when it changes',
    () async {
      final repository = _SalesRepository();
      repository.responses.add(
        _page([_order('order-1')], hasMore: true, nextCursor: 'cursor-1'),
      );
      repository.responses.add(_page([]));
      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(salesListProvider.notifier);

      await notifier.loadSales();
      expect(container.read(salesListProvider).orders, hasLength(1));
      await notifier.changeStatus(OrderStatus.shipped);

      final state = container.read(salesListProvider);
      expect(state.selectedStatus, OrderStatus.shipped);
      expect(state.orders, isEmpty);
      expect(state.nextCursor, isNull);
      expect(repository.calls, [
        (cursor: null, status: null),
        (cursor: null, status: OrderStatus.shipped),
      ]);
    },
  );

  test(
    'deduplicates appended IDs and retries a failed append with its cursor',
    () async {
      final repository = _SalesRepository();
      repository.responses.add(
        _page([_order('order-1')], hasMore: true, nextCursor: 'cursor-1'),
      );
      repository.responses.add(
        _page(
          [_order('order-1'), _order('order-2')],
          hasMore: true,
          nextCursor: 'cursor-2',
        ),
      );
      repository.responses.add(
        Future.value(const Left(ServerFailure('append failed'))),
      );
      repository.responses.add(_page([_order('order-3')]));
      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(salesListProvider.notifier);

      await notifier.loadSales();
      await notifier.loadMore();
      await notifier.loadMore();

      var state = container.read(salesListProvider);
      expect(state.orders.map((order) => order.id), ['order-1', 'order-2']);
      expect(state.nextCursor, 'cursor-2');
      expect(state.error, 'append failed');

      await notifier.loadMore();
      state = container.read(salesListProvider);
      expect(state.orders.map((order) => order.id), [
        'order-1',
        'order-2',
        'order-3',
      ]);
      expect(state.error, isNull);
      expect(repository.calls.last.cursor, 'cursor-2');
    },
  );

  test(
    'transitions through initial loading, loading more, error, empty, and terminal states',
    () async {
      final repository = _SalesRepository();
      final initial = Completer<Either<Failure, CursorPage<OrderEntity>>>();
      final more = Completer<Either<Failure, CursorPage<OrderEntity>>>();
      repository.responses.add(initial.future);
      repository.responses.add(more.future);
      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(salesListProvider.notifier);

      final firstLoad = notifier.loadSales();
      expect(container.read(salesListProvider).isLoading, isTrue);
      initial.complete(
        _page([_order('order-1')], hasMore: true, nextCursor: 'cursor-1'),
      );
      await firstLoad;

      final nextLoad = notifier.loadMore();
      expect(container.read(salesListProvider).isLoadingMore, isTrue);
      more.complete(const Left(ServerFailure('more failed')));
      await nextLoad;
      expect(container.read(salesListProvider).error, 'more failed');
      expect(container.read(salesListProvider).isLoadingMore, isFalse);

      repository.responses.add(_page([]));
      await notifier.changeStatus(OrderStatus.cancelled);
      final terminal = container.read(salesListProvider);
      expect(terminal.selectedStatus, OrderStatus.cancelled);
      expect(terminal.orders, isEmpty);
      expect(terminal.hasMore, isFalse);
    },
  );
}
