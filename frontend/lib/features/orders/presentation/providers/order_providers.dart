import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/repositories/order_repository.dart';
import 'package:freebay/features/orders/data/services/order_service.dart';
import 'package:freebay/features/orders/domain/repositories/i_order_repository.dart';
import 'package:freebay/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/can_review_order_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/confirm_delivery_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/create_order_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/get_my_purchases_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/get_my_sales_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/get_order_usecase.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/orders/presentation/providers/order_providers_state.dart';

part 'order_providers.g.dart';

final orderServiceProvider = Provider((ref) => OrderService());

final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  return OrderRepository(ref.watch(orderServiceProvider));
});

final getOrderUsecaseProvider = Provider(
  (ref) => GetOrderUsecase(ref.watch(orderRepositoryProvider)),
);
final getMyPurchasesUsecaseProvider = Provider(
  (ref) => GetMyPurchasesUsecase(ref.watch(orderRepositoryProvider)),
);
final getMySalesUsecaseProvider = Provider(
  (ref) => GetMySalesUsecase(ref.watch(orderRepositoryProvider)),
);
final confirmDeliveryUsecaseProvider = Provider(
  (ref) => ConfirmDeliveryUsecase(ref.watch(orderRepositoryProvider)),
);
final createOrderUsecaseProvider = Provider(
  (ref) => CreateOrderUsecase(ref.watch(orderRepositoryProvider)),
);
final cancelOrderUsecaseProvider = Provider(
  (ref) => CancelOrderUsecase(ref.watch(orderRepositoryProvider)),
);
final canReviewOrderUsecaseProvider = Provider(
  (ref) => CanReviewOrderUsecase(ref.watch(orderRepositoryProvider)),
);

@Riverpod(keepAlive: false)
class OrderDetail extends _$OrderDetail {
  @override
  OrderDetailState build(String orderId) {
    ref.watch(getOrderUsecaseProvider);
    ref.watch(canReviewOrderUsecaseProvider);
    ref.watch(confirmDeliveryUsecaseProvider);
    ref.watch(cancelOrderUsecaseProvider);
    return const OrderDetailState();
  }

  Future<void> loadOrder() async {
    state = state.copyWith(isLoading: true, error: null);

    final orderResult = await ref.read(getOrderUsecaseProvider)(orderId);
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
            canReviewResponse: const CanReviewResponse(canReview: false),
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

    final result = await ref.read(confirmDeliveryUsecaseProvider)(orderId);
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
      GetMySalesParams(cursor: refresh ? null : state.nextCursor),
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: failure.message,
        nextCursor: state.nextCursor,
      ),
      (page) => state = SalesListState(
        orders: refresh ? page.items : [...state.orders, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      ),
    );
  }

  Future<void> loadMore() => loadSales();

  Future<void> refresh() => loadSales(refresh: true);
}
