import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';

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
    ref.read(purchasesListProvider.notifier).loadPurchases(refresh: true);
    _scrollController.addListener(_onScroll);
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
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchasesListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Minhas Compras',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PurchasesListState state) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryContainer),
      );
    }

    if (state.error != null && state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outlined,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildRetryButton(),
          ],
        ),
      );
    }

    if (state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              color: AppColors.surfaceContainerHighest,
              child: const Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma compra ainda',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Suas compras aparecerão aqui',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryContainer,
      onRefresh: () => ref.read(purchasesListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(0),
        itemCount: state.orders.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.orders.length) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryContainer,
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final order = state.orders[index];
          return _buildOrderCard(order, index);
        },
      ),
    );
  }

  Widget _buildRetryButton() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        gradient: AppColors.brutalistGradient,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(purchasesListProvider.notifier).refresh();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Text(
                'Tentar novamente',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderEntity order, int index) {
    final backgroundColor =
        index.isEven ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow;

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                color: AppColors.surfaceContainerHighest,
                child: order.product?.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: order.product!.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 24,
                        ),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        color: AppColors.onSurfaceVariant,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${order.shortId}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        _buildStatusBadge(order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.product?.title ?? 'Produto',
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(order.createdAt),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: AppColors.surfaceContainerHighest,
                          child: Text(
                            order.formattedAmount,
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case OrderStatus.completed:
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        break;
      case OrderStatus.pending:
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        break;
      case OrderStatus.cancelled:
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        break;
      case OrderStatus.shipped:
      case OrderStatus.delivered:
        bgColor = AppColors.info.withValues(alpha: 0.1);
        textColor = AppColors.info;
        break;
      case OrderStatus.disputed:
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        break;
      case OrderStatus.confirmed:
        bgColor = AppColors.primaryContainer.withValues(alpha: 0.1);
        textColor = AppColors.primaryContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: bgColor,
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}
