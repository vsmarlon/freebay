import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/orders/presentation/widgets/order_card.dart';
import 'package:freebay/features/orders/presentation/widgets/sales_status_filters.dart';

typedef OrderListView = ({
  bool isLoading,
  bool isLoadingMore,
  bool isRefreshing,
  bool isStale,
  bool hasMore,
  List<OrderEntity> orders,
  String? error,
  OrderStatus? selectedStatus,
  Future<void> Function() refresh,
  Future<void> Function() loadMore,
});

class OrdersTab extends ConsumerWidget {
  final bool isSeller;

  const OrdersTab({super.key, required this.isSeller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = isSeller ? _sellerView(ref) : _buyerView(ref);
    return Column(
      children: [
        if (isSeller)
          SalesStatusFilters(
            selected: view.selectedStatus,
            onChanged: (status) =>
                ref.read(salesListProvider.notifier).changeStatus(status),
          ),
        Expanded(child: _buildState(context, view)),
      ],
    );
  }

  OrderListView _sellerView(WidgetRef ref) {
    final state = ref.watch(salesListProvider);
    final notifier = ref.read(salesListProvider.notifier);
    return (
      isLoading: state.isLoading,
      isLoadingMore: state.isLoadingMore,
      isRefreshing: state.isRefreshing,
      isStale: state.isStale,
      hasMore: state.hasMore,
      orders: state.orders,
      error: state.error,
      selectedStatus: state.selectedStatus,
      refresh: notifier.refresh,
      loadMore: notifier.loadMore,
    );
  }

  OrderListView _buyerView(WidgetRef ref) {
    final state = ref.watch(purchasesListProvider);
    final notifier = ref.read(purchasesListProvider.notifier);
    return (
      isLoading: state.isLoading,
      isLoadingMore: state.isLoadingMore,
      isRefreshing: state.isRefreshing,
      isStale: state.isStale,
      hasMore: state.hasMore,
      orders: state.orders,
      error: state.error,
      selectedStatus: null,
      refresh: notifier.refresh,
      loadMore: notifier.loadMore,
    );
  }

  Widget _buildState(BuildContext context, OrderListView view) {
    if (view.isLoading && view.orders.isEmpty) {
      return ShimmerScope(
        child: ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: 4,
          separatorBuilder: (context, index) => Spacing.vSm,
          itemBuilder: (context, index) => const ShimmerBlock(height: 110),
        ),
      );
    }

    if (view.error != null && view.orders.isEmpty) {
      return EmptyState.error(message: view.error!, onRetry: view.refresh);
    }

    if (view.orders.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: isSeller ? 'NENHUMA VENDA' : 'NENHUMA COMPRA',
        subtitle: isSeller
            ? 'Você ainda não vendeu produtos no FreeBay.'
            : 'Você ainda não realizou compras no FreeBay.',
        action: AppButton(
          label: isSeller ? 'CRIAR ANÚNCIO' : 'EXPLORAR PRODUTOS',
          icon: isSeller ? Icons.add_circle_outline : Icons.explore_outlined,
          size: AppButtonSize.compact,
          onPressed: () => isSeller
              ? context.push(AppRoutes.createProduct)
              : context.go(AppRoutes.explore),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryContainer,
      onRefresh: view.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 240 &&
              view.hasMore &&
              !view.isLoadingMore) {
            view.loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount:
              view.orders.length +
              (view.isRefreshing || view.isStale ? 1 : 0) +
              (view.isLoadingMore ? 1 : 0) +
              (view.error != null ? 1 : 0) +
              (!view.hasMore && view.error == null && !view.isLoadingMore
                  ? 1
                  : 0),
          separatorBuilder: (context, index) => Spacing.vSm,
          itemBuilder: (context, index) {
            final hasStatus = view.isRefreshing || view.isStale;
            if (hasStatus && index == 0) {
              return Container(
                color: context.surfaceMidColor,
                padding: const EdgeInsets.all(Spacing.md),
                child: Text(
                  view.error != null
                      ? 'Não foi possível atualizar. Exibindo os pedidos salvos.'
                      : view.isRefreshing
                      ? l10n(context).ordersRefreshing
                      : l10n(context).ordersShowingCached,
                  style: TextStyle(color: context.textPrimary),
                ),
              );
            }
            final orderIndex = index - (hasStatus ? 1 : 0);
            if (orderIndex == view.orders.length) {
              if (view.error != null) {
                return Container(
                  color: context.surfaceMidColor,
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    children: [
                      Text(
                        l10n(context).errorUnknown,
                        style: TextStyle(color: context.textPrimary),
                      ),
                      Spacing.vSm,
                      AppButton(
                        label: l10n(context).commonRetry.toUpperCase(),
                        size: AppButtonSize.compact,
                        onPressed: view.loadMore,
                      ),
                    ],
                  ),
                );
              }
              if (!view.hasMore) {
                return Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Center(child: Text(l10n(context).ordersEndOfList)),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(Spacing.md),
                child: Center(child: ShimmerBlock(height: 48)),
              );
            }
            return OrderCard(
              order: view.orders[orderIndex],
              isSeller: isSeller,
            );
          },
        ),
      ),
    );
  }
}
