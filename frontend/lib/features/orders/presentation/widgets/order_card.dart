import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';

class OrderCard extends StatelessWidget {
  final OrderEntity order;
  final bool isSeller;

  const OrderCard({super.key, required this.order, required this.isSeller});

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
