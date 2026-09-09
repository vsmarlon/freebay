import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
                  _OrdersTab(isSeller: false),
                  _OrdersTab(isSeller: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  final bool isSeller;

  const _OrdersTab({required this.isSeller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The generated providers expose distinct state classes with the same UI shape.
    final dynamic state = isSeller
        ? ref.watch(salesListProvider)
        : ref.watch(purchasesListProvider);

    if (state.isLoading && state.orders.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (context, index) => Spacing.vSm,
        itemBuilder: (context, index) => const ShimmerBlock(height: 110),
      );
    }

    if (state.error != null && state.orders.isEmpty) {
      final refresh = isSeller
          ? () => ref.read(salesListProvider.notifier).refresh()
          : () => ref.read(purchasesListProvider.notifier).refresh();
      return EmptyState.error(
        message: state.error ?? kGenericErrorMessage,
        onRetry: refresh,
      );
    }

    if (state.orders.isEmpty) {
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
          onPressed: () =>
              context.go(isSeller ? '/products/create' : '/explore'),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryContainer,
      onRefresh: () => isSeller
          ? ref.read(salesListProvider.notifier).refresh()
          : ref.read(purchasesListProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.orders.length,
        separatorBuilder: (context, index) => Spacing.vSm,
        itemBuilder: (context, index) {
          return _OrderCard(order: state.orders[index], isSeller: isSeller);
        },
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
        context.push('/orders/${order.id}');
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
