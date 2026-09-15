import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/repositories/order_repository.dart';
import 'package:freebay/features/orders/data/services/order_service.dart';
import 'package:freebay/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/can_review_order_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/get_my_purchases_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/get_my_sales_usecase.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/orders/presentation/providers/order_providers_state.dart';

part 'order_providers.g.dart';

final orderServiceProvider = Provider((ref) => OrderService());

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(orderServiceProvider));
});

final getMyPurchasesUsecaseProvider = Provider(
  (ref) => GetMyPurchasesUsecase(ref.watch(orderRepositoryProvider)),
);
final getMySalesUsecaseProvider = Provider(
  (ref) => GetMySalesUsecase(ref.watch(orderRepositoryProvider)),
);
final cancelOrderUsecaseProvider = Provider(
  (ref) => CancelOrderUsecase(ref.watch(orderRepositoryProvider)),
);
final canReviewOrderUsecaseProvider = Provider(
  (ref) => CanReviewOrderUsecase(ref.watch(orderRepositoryProvider)),
);

@Riverpod()
class OrderDetail extends _$OrderDetail {
  @override
  OrderDetailState build(String orderId) {
    ref.watch(orderRepositoryProvider);
    ref.watch(canReviewOrderUsecaseProvider);
    ref.watch(cancelOrderUsecaseProvider);
    return const OrderDetailState();
  }

  Future<void> loadOrder() async {
    state = state.copyWith(isLoading: true, error: null);

    final orderResult = await ref
        .read(orderRepositoryProvider)
        .getOrder(orderId);
    final canReviewResult = await ref.read(canReviewOrderUsecaseProvider)(
      orderId,
    );

    orderResult.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (order) {
        canReviewResult.fold(
          (_) => state = state.copyWith(
            isLoading: false,
            order: order,
            canReviewResponse: const CanReviewResponse(),
          ),
          (canReview) => state = state.copyWith(
            isLoading: false,
            order: order,
            canReviewResponse: canReview,
          ),
        );
      },
    );
  }

  Future<bool> confirmDelivery() async {
    state = state.copyWith(isPerformingAction: true, error: null);

    final result = await ref
        .read(orderRepositoryProvider)
        .confirmDelivery(orderId);
    return result.fold(
      (failure) {
        state = state.copyWith(
          isPerformingAction: false,
          error: failure.message,
        );
        return false;
      },
      (updatedOrder) async {
        state = state.copyWith(isPerformingAction: false, order: updatedOrder);
        await loadOrder();
        return true;
      },
    );
  }

  Future<bool> cancelOrder() async {
    state = state.copyWith(isPerformingAction: true, error: null);

    final result = await ref.read(cancelOrderUsecaseProvider)(orderId);
    return result.fold(
      (failure) {
        state = state.copyWith(
          isPerformingAction: false,
          error: failure.message,
        );
        return false;
      },
      (updatedOrder) {
        state = state.copyWith(isPerformingAction: false, order: updatedOrder);
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

@Riverpod(keepAlive: true)
class PurchasesList extends _$PurchasesList {
  @override
  PurchasesListState build() {
    ref.watch(getMyPurchasesUsecaseProvider);
    return const PurchasesListState();
  }

  Future<void> loadPurchases({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && state.nextCursor == null && state.orders.isNotEmpty) return;

    final isFirstPage = refresh || state.orders.isEmpty;
    state = state.copyWith(
      isLoading: isFirstPage,
      isLoadingMore: !isFirstPage,
      error: null,
      orders: refresh ? [] : state.orders,
    );

    final result = await ref.read(getMyPurchasesUsecaseProvider)(
      GetMyPurchasesParams(cursor: refresh ? null : state.nextCursor),
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: failure.message,
        nextCursor: state.nextCursor,
      ),
      (page) => state = PurchasesListState(
        orders: refresh ? page.items : [...state.orders, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      ),
    );
  }

  Future<void> loadMore() => loadPurchases();

  Future<void> refresh() => loadPurchases(refresh: true);
}

@Riverpod(keepAlive: true)
class SalesList extends _$SalesList {
  @override
  SalesListState build() {
    ref.watch(getMySalesUsecaseProvider);
    return const SalesListState();
  }

  Future<void> loadSales({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && state.nextCursor == null && state.orders.isNotEmpty) return;

    final isFirstPage = refresh || state.orders.isEmpty;
    state = state.copyWith(
      isLoading: isFirstPage,
      isLoadingMore: !isFirstPage,
      error: null,
      orders: refresh ? [] : state.orders,
    );

    final result = await ref.read(getMySalesUsecaseProvider)(
      GetMySalesParams(
        cursor: refresh ? null : state.nextCursor,
        status: state.selectedStatus?.toApiString(),
      ),
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: failure.message,
        nextCursor: state.nextCursor,
      ),
      (page) => state = SalesListState(
        orders: refresh ? page.items : _appendUnique(state.orders, page.items),
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        selectedStatus: state.selectedStatus,
      ),
    );
  }

  Future<void> loadMore() => state.hasMore ? loadSales() : Future.value();

  Future<void> refresh() => loadSales(refresh: true);

  Future<void> changeStatus(OrderStatus? status) async {
    if (state.selectedStatus == status) return;
    state = SalesListState(selectedStatus: status);
    await loadSales();
  }

  List<OrderEntity> _appendUnique(
    List<OrderEntity> current,
    List<OrderEntity> next,
  ) {
    final ids = current.map((order) => order.id).toSet();
    return [...current, ...next.where((order) => ids.add(order.id))];
  }
}
