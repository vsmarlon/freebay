import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/repositories/order_repository.dart';
import 'package:freebay/features/orders/domain/repositories/order_repository.dart';
import 'package:freebay/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/can_review_order_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/get_my_purchases_usecase.dart';
import 'package:freebay/features/orders/domain/usecases/get_my_sales_usecase.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'dart:async';
import 'package:dio/dio.dart';

export 'package:freebay/features/orders/presentation/providers/order_providers_state.dart';

part 'order_providers.g.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepositoryImpl(client: HttpClient.instance),
);

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
  int _loadRequestId = 0;

  @override
  OrderDetailState build(String orderId) {
    ref.watch(orderRepositoryProvider);
    ref.watch(canReviewOrderUsecaseProvider);
    ref.watch(cancelOrderUsecaseProvider);
    return const OrderDetailState();
  }

  Future<void> loadOrder() async {
    final requestId = ++_loadRequestId;
    state = state.copyWith(isLoading: true, error: null);
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);

    final orderResult = await ref
        .read(orderRepositoryProvider)
        .getOrder(orderId, cancelToken: cancelToken);
    if (!ref.mounted || requestId != _loadRequestId) return;
    final canReviewResult = await ref.read(canReviewOrderUsecaseProvider)(
      orderId,
      cancelToken: cancelToken,
    );
    if (!ref.mounted || requestId != _loadRequestId) return;

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

  Future<String?> cancelOrder(String reason, String stepUpToken) async {
    state = state.copyWith(isPerformingAction: true, error: null);

    final result = await ref.read(cancelOrderUsecaseProvider)((
      orderId: orderId,
      reason: reason,
      stepUpToken: stepUpToken,
    ));
    return result.fold(
      (failure) {
        state = state.copyWith(
          isPerformingAction: false,
          error: failure.message,
        );
        return null;
      },
      (outcome) {
        state = state.copyWith(isPerformingAction: false);
        ref.invalidate(purchasesListProvider);
        ref.invalidate(salesListProvider);
        return outcome;
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

@Riverpod(keepAlive: true)
class PurchasesList extends _$PurchasesList {
  int _requestId = 0;
  String? _ownerId;
  bool _restored = false;

  @override
  PurchasesListState build() {
    ref.watch(getMyPurchasesUsecaseProvider);
    final ownerId = ref.watch(
      authControllerProvider.select((auth) => auth.asData?.value?.id),
    );
    if (_ownerId != ownerId) {
      _ownerId = ownerId;
      _requestId++;
      _restored = false;
      return const PurchasesListState();
    }
    return const PurchasesListState();
  }

  Future<void> loadPurchases({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore || state.isRefreshing) return;
    if (!refresh &&
        state.nextCursor == null &&
        state.orders.isNotEmpty &&
        !state.isStale) {
      return;
    }

    final requestId = ++_requestId;
    final ownerId = _ownerId;
    if (!_restored && ownerId != null && state.orders.isEmpty) {
      _restored = true;
      final cached = await StorageService.readCachedJson(
        userId: ownerId,
        key: 'orders.purchases.first-page.v1',
      );
      if (!ref.mounted ||
          requestId != _requestId ||
          ownerId != ref.read(authControllerProvider).asData?.value?.id) {
        return;
      }
      final orders = _decodeCachedOrders(cached);
      if (orders != null) {
        state = state.copyWith(orders: orders, isStale: true);
      }
    }

    final isFirstPage = refresh || state.nextCursor == null;
    state = state.copyWith(
      isLoading: isFirstPage && state.orders.isEmpty,
      isLoadingMore: !isFirstPage,
      isRefreshing: isFirstPage && state.orders.isNotEmpty,
      error: null,
    );

    final result = await ref.read(getMyPurchasesUsecaseProvider)(
      GetMyPurchasesParams(cursor: refresh ? null : state.nextCursor),
    );
    result.fold(
      (failure) {
        if (!ref.mounted || requestId != _requestId || ownerId != _ownerId) {
          return;
        }
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          isRefreshing: false,
          error: failure.message,
        );
      },
      (page) {
        if (!ref.mounted || requestId != _requestId || ownerId != _ownerId) {
          return;
        }
        if (isFirstPage && ownerId != null) {
          unawaited(
            _writeCachedOrders(
              ownerId,
              'orders.purchases.first-page.v1',
              page.items,
            ),
          );
        }
        state = PurchasesListState(
          orders: isFirstPage ? page.items : [...state.orders, ...page.items],
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        );
      },
    );
  }

  Future<void> loadMore() => loadPurchases();

  Future<void> refresh() => loadPurchases(refresh: true);
}

@Riverpod(keepAlive: true)
class SalesList extends _$SalesList {
  int _requestId = 0;
  String? _ownerId;
  bool _restored = false;

  @override
  SalesListState build() {
    ref.watch(getMySalesUsecaseProvider);
    final ownerId = ref.watch(
      authControllerProvider.select((auth) => auth.asData?.value?.id),
    );
    if (_ownerId != ownerId) {
      _ownerId = ownerId;
      _requestId++;
      _restored = false;
      return const SalesListState();
    }
    return const SalesListState();
  }

  Future<void> loadSales({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore || state.isRefreshing) return;
    if (!refresh &&
        state.nextCursor == null &&
        state.orders.isNotEmpty &&
        !state.isStale) {
      return;
    }

    final requestId = ++_requestId;
    final ownerId = _ownerId;
    if (!_restored &&
        ownerId != null &&
        state.orders.isEmpty &&
        state.selectedStatus == null) {
      _restored = true;
      final cached = await StorageService.readCachedJson(
        userId: ownerId,
        key: 'orders.sales.first-page.v1',
      );
      if (!ref.mounted ||
          requestId != _requestId ||
          ownerId != ref.read(authControllerProvider).asData?.value?.id) {
        return;
      }
      final orders = _decodeCachedOrders(cached);
      if (orders != null) state = state.copyWith(orders: orders, isStale: true);
    }

    final isFirstPage = refresh || state.nextCursor == null;
    state = state.copyWith(
      isLoading: isFirstPage && state.orders.isEmpty,
      isLoadingMore: !isFirstPage,
      isRefreshing: isFirstPage && state.orders.isNotEmpty,
      error: null,
    );

    final result = await ref.read(getMySalesUsecaseProvider)(
      GetMySalesParams(
        cursor: refresh ? null : state.nextCursor,
        status: state.selectedStatus,
      ),
    );
    result.fold(
      (failure) {
        if (!ref.mounted || requestId != _requestId || ownerId != _ownerId) {
          return;
        }
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          isRefreshing: false,
          error: failure.message,
        );
      },
      (page) {
        if (!ref.mounted || requestId != _requestId || ownerId != _ownerId) {
          return;
        }
        if (isFirstPage && ownerId != null && state.selectedStatus == null) {
          unawaited(
            _writeCachedOrders(
              ownerId,
              'orders.sales.first-page.v1',
              page.items,
            ),
          );
        }
        state = SalesListState(
          orders: isFirstPage
              ? page.items
              : _appendUnique(state.orders, page.items),
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
          selectedStatus: state.selectedStatus,
        );
      },
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

List<OrderEntity>? _decodeCachedOrders(Map<String, Object?>? cached) {
  final items = cached?['items'];
  if (cached?['pageVersion'] != 1 ||
      cached?['limit'] != 20 ||
      items is! List ||
      !items.every((item) => item is Map<String, dynamic>)) {
    return null;
  }
  try {
    return items.map((item) => OrderEntity.fromJson(item)).toList();
  } catch (_) {
    return null;
  }
}

Future<void> _writeCachedOrders(
  String ownerId,
  String key,
  List<OrderEntity> orders,
) async {
  final items = orders.map((order) {
    final json = order.toJson();
    for (final key in ['buyer', 'seller']) {
      final user = json[key];
      if (user is Map<String, dynamic> &&
          !_isSafeOrderMedia(user['avatarUrl'])) {
        user['avatarUrl'] = null;
      }
    }
    final product = json['product'];
    if (product is Map<String, dynamic>) {
      final images = product['images'];
      if (images is List &&
          images.any(
            (image) =>
                image is Map<String, dynamic> &&
                !_isSafeOrderMedia(image['url']),
          )) {
        product['images'] = [];
      }
      final seller = product['seller'];
      if (seller is Map<String, dynamic>) {
        product['seller'] = {
          'id': seller['id'],
          'displayName': seller['displayName'],
          'username': seller['username'],
          'avatarUrl': _isSafeOrderMedia(seller['avatarUrl'])
              ? seller['avatarUrl']
              : null,
          'isVerified': seller['isVerified'] ?? false,
        };
      }
    }
    return json;
  }).toList();
  await StorageService.writeCachedJson(
    userId: ownerId,
    key: key,
    json: {'pageVersion': 1, 'limit': 20, 'items': items},
  );
}

bool _isSafeOrderMedia(Object? url) {
  if (url is! String) return false;
  final normalized = url.toLowerCase();
  return !normalized.contains('/private/') &&
      !normalized.contains('/signed/') &&
      !normalized.contains('signature=') &&
      !normalized.contains('token=');
}
