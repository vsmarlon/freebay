import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';

class OrdersPage extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const OrdersPage({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchasesListProvider.notifier).loadPurchases();
      ref.read(salesListProvider.notifier).loadSales();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              text: 'MEUS PEDIDOS',
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.borderColor, width: 2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryContainer,
                indicatorWeight: 3,
                labelColor: context.textPrimary,
                unselectedLabelColor: context.textSecondary,
                labelStyle: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
                tabs: const [
                  Tab(text: 'COMPRAS'),
                  Tab(text: 'VENDAS'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  OrdersTab(isSeller: false),
                  OrdersTab(isSeller: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersTab extends ConsumerWidget {
  final bool isSeller;

  const OrdersTab({super.key, required this.isSeller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isSeller) {
      final state = ref.watch(salesListProvider);
      return Column(
        children: [
          SalesStatusFilters(
            selected: state.selectedStatus,
            onChanged: (status) =>
                ref.read(salesListProvider.notifier).changeStatus(status),
          ),
          Expanded(
            child: _buildState(
              context,
              ref,
              isSeller: true,
              isLoading: state.isLoading,
              isLoadingMore: state.isLoadingMore,
              hasMore: state.hasMore,
              orders: state.orders,
              error: state.error,
            ),
          ),
        ],
      );
    }
    final state = ref.watch(purchasesListProvider);
    return _buildState(
      context,
      ref,
      isSeller: false,
      isLoading: state.isLoading,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      orders: state.orders,
      error: state.error,
    );
  }

  Widget _buildState(
    BuildContext context,
    WidgetRef ref, {
    required bool isSeller,
    required bool isLoading,
    bool isLoadingMore = false,
    bool hasMore = false,
    required List<OrderEntity> orders,
    required String? error,
  }) {
    if (isLoading && orders.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (context, index) => Spacing.vSm,
        itemBuilder: (context, index) => const ShimmerBlock(height: 110),
      );
    }

    if (error != null && orders.isEmpty) {
      final refresh = isSeller
          ? () => ref.read(salesListProvider.notifier).refresh()
          : () => ref.read(purchasesListProvider.notifier).refresh();
      return EmptyState.error(message: error, onRetry: refresh);
    }

    if (orders.isEmpty) {
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
      onRefresh: () => isSeller
          ? ref.read(salesListProvider.notifier).refresh()
          : ref.read(purchasesListProvider.notifier).refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 240 &&
              hasMore &&
              !isLoadingMore) {
            if (isSeller) {
              ref.read(salesListProvider.notifier).loadMore();
            } else {
              ref.read(purchasesListProvider.notifier).loadMore();
            }
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount:
              orders.length +
              (isLoadingMore ? 1 : 0) +
              (error != null ? 1 : 0) +
              (!hasMore && error == null && !isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) => Spacing.vSm,
          itemBuilder: (context, index) {
            if (index == orders.length) {
              if (error != null) {
                final retry = isSeller
                    ? () => ref.read(salesListProvider.notifier).loadMore()
                    : () => ref.read(purchasesListProvider.notifier).loadMore();
                return Container(
                  color: context.surfaceMidColor,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(error, style: TextStyle(color: context.textPrimary)),
                      Spacing.vSm,
                      AppButton(
                        label: 'TENTAR NOVAMENTE',
                        size: AppButtonSize.compact,
                        onPressed: retry,
                      ),
                    ],
                  ),
                );
              }
              if (!hasMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('FIM DA LISTA')),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: ShimmerBlock(height: 48)),
              );
            }
            return _OrderCard(order: orders[index], isSeller: isSeller);
          },
        ),
      ),
    );
  }
}

class SalesStatusFilters extends StatelessWidget {
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onChanged;

  const SalesStatusFilters({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.surfaceMidColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Semantics(
              container: true,
              button: true,
              selected: selected == null,
              label: 'Todos os status',
              child: BrutalistFilterChip(
                label: 'TODOS',
                selected: selected == null,
                onTap: () => onChanged(null),
              ),
            ),
            Spacing.hSm,
            for (final status in OrderStatus.values) ...[
              Semantics(
                container: true,
                button: true,
                selected: selected == status,
                label: status.label,
                child: BrutalistFilterChip(
                  label: status.label.toUpperCase(),
                  selected: selected == status,
                  onTap: () => onChanged(status),
                ),
              ),
              Spacing.hSm,
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final bool isSeller;

  const _OrderCard({required this.order, required this.isSeller});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return AppColors.primaryContainer;
      case OrderStatus.shipped:
        return AppColors.info;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.disputed:
        return AppColors.error;
      case OrderStatus.cancelled:
        return AppColors.mediumGray;
      case OrderStatus.pending:
        return AppColors.primaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final color = _statusColor(status);
    final product = order.product;
    final otherUser = isSeller ? order.buyer : order.seller;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.orderPath(order.id));
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border.all(color: context.borderColor, width: 2),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image or placeholder
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.surfaceMidColor,
                border: Border.all(color: context.borderColor),
              ),
              child: product?.imageUrl != null && product!.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.inventory_2_outlined),
                    )
                  : const Icon(Icons.inventory_2_outlined),
            ),
            Spacing.hMd,
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product?.title ?? 'Item #${order.shortId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          status.label.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacing.vXs,
                  Text(
                    '${isSeller ? 'Comprador' : 'Vendedor'}: ${otherUser?.displayNameOrDefault ?? 'Anônimo'}',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                  Spacing.vXs,
                  Text(
                    CurrencyUtils.formatCents(order.amount),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
