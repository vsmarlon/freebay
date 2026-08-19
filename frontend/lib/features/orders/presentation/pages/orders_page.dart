import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
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
              leading: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    border: Border.all(color: context.borderColor, width: 1),
                  ),
                  child: const Icon(Icons.arrow_back, size: 20),
                ),
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
                indicatorColor: const Color(0xFF8A1083),
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
                children: const [_PurchasesTab(), _SalesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchasesTab extends ConsumerWidget {
  const _PurchasesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchasesListProvider);

    if (state.isLoading && state.orders.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (context, index) => Spacing.vSm,
        itemBuilder: (context, index) =>
            const ShimmerBlock(height: 110, width: double.infinity),
      );
    }

    if (state.error != null && state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erro ao carregar compras: ${state.error}',
              style: TextStyle(color: context.textSecondary),
            ),
            Spacing.vMd,
            AppButton(
              label: 'TENTAR NOVAMENTE',
              size: AppButtonSize.compact,
              onPressed: () =>
                  ref.read(purchasesListProvider.notifier).refresh(),
            ),
          ],
        ),
      );
    }

    if (state.orders.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'NENHUMA COMPRA',
        subtitle: 'Você ainda não realizou compras no FreeBay.',
        action: AppButton(
          label: 'EXPLORAR PRODUTOS',
          icon: Icons.explore_outlined,
          size: AppButtonSize.compact,
          onPressed: () => context.go('/explore'),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF8A1083),
      onRefresh: () => ref.read(purchasesListProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.orders.length,
        separatorBuilder: (context, index) => Spacing.vSm,
        itemBuilder: (context, index) {
          return _OrderCard(order: state.orders[index], isSeller: false);
        },
      ),
    );
  }
}

class _SalesTab extends ConsumerWidget {
  const _SalesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesListProvider);

    if (state.isLoading && state.orders.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (context, index) => Spacing.vSm,
        itemBuilder: (context, index) =>
            const ShimmerBlock(height: 110, width: double.infinity),
      );
    }

    if (state.error != null && state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erro ao carregar vendas: ${state.error}',
              style: TextStyle(color: context.textSecondary),
            ),
            Spacing.vMd,
            AppButton(
              label: 'TENTAR NOVAMENTE',
              size: AppButtonSize.compact,
              onPressed: () => ref.read(salesListProvider.notifier).refresh(),
            ),
          ],
        ),
      );
    }

    if (state.orders.isEmpty) {
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: 'NENHUMA VENDA',
        subtitle: 'Você ainda não vendeu produtos no FreeBay.',
        action: AppButton(
          label: 'CRIAR ANÚNCIO',
          icon: Icons.add_circle_outline,
          size: AppButtonSize.compact,
          onPressed: () => context.push('/products/create'),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF8A1083),
      onRefresh: () => ref.read(salesListProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.orders.length,
        separatorBuilder: (context, index) => Spacing.vSm,
        itemBuilder: (context, index) {
          return _OrderCard(order: state.orders[index], isSeller: true);
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
        return AppColors.accentAmber;
      case OrderStatus.shipped:
        return Colors.blueAccent;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.disputed:
        return AppColors.error;
      case OrderStatus.cancelled:
        return Colors.grey;
      case OrderStatus.pending:
        return const Color(0xFF8A1083);
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product image or placeholder
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.surfaceMidColor,
                border: Border.all(color: context.borderColor, width: 1),
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
                          border: Border.all(color: color, width: 1),
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
