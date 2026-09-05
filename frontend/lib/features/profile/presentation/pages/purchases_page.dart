import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';

class PurchasesPage extends ConsumerStatefulWidget {
  const PurchasesPage({super.key});

  @override
  ConsumerState<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends ConsumerState<PurchasesPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      ref.read(purchasesListProvider.notifier).loadPurchases(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(purchasesListProvider);
      if (state.hasMore && !state.isLoading) {
        ref.read(purchasesListProvider.notifier).loadPurchases();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchasesListProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'COMPRAS',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          Expanded(
            child: state.isLoading && state.orders.isEmpty
                ? const SkeletonPage(
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        ShimmerBlock(height: 90),
                        SizedBox(height: 12),
                        ShimmerBlock(height: 90),
                        SizedBox(height: 12),
                        ShimmerBlock(height: 90),
                      ],
                    ),
                  )
                : state.error != null && state.orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.error!,
                          style: TextStyle(color: context.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'TENTAR NOVAMENTE',
                          size: AppButtonSize.compact,
                          onPressed: () => ref
                              .read(purchasesListProvider.notifier)
                              .refresh(),
                        ),
                      ],
                    ),
                  )
                : state.orders.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'NENHUMA COMPRA AINDA',
                    subtitle: 'Suas compras aparecerão aqui.',
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(purchasesListProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.orders.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == state.orders.length) {
                          return const ShimmerBlock(height: 80);
                        }
                        final order = state.orders[index];
                        return _buildOrderCard(context, order);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderEntity order) {
    final product = order.product;
    return InkWell(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        color: context.surfaceColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              color: context.surfaceMidColor,
              child: product?.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product!.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.image_outlined, color: context.textSecondary),
            ),
            Spacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.title ?? 'Produto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.formattedAmount,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: context.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${order.status.name.toUpperCase()}',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textSecondary),
          ],
        ),
      ),
    );
  }
}
