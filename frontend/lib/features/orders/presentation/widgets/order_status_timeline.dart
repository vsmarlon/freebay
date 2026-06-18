import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';

class OrderStatusTimeline extends StatelessWidget {
  final OrderStatus currentStatus;

  const OrderStatusTimeline({
    super.key,
    required this.currentStatus,
  });

  static const _statusOrder = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.shipped,
    OrderStatus.delivered,
    OrderStatus.completed,
  ];

  int get _currentIndex {
    if (currentStatus == OrderStatus.cancelled) return -1;
    if (currentStatus == OrderStatus.disputed) return -1;
    return _statusOrder.indexOf(currentStatus);
  }

  @override
  Widget build(BuildContext context) {
    if (currentStatus == OrderStatus.cancelled) {
      return _buildSpecialStatus(
        context,
        'Pedido Cancelado',
        Icons.close,
        AppColors.error,
      );
    }

    if (currentStatus == OrderStatus.disputed) {
      return _buildSpecialStatus(
        context,
        'Em Disputa',
        Icons.gavel_outlined,
        AppColors.warning,
      );
    }

    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS DO PEDIDO',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: context.textSecondary,
            ),
          ),
          Spacing.vLg,
          Row(
            children: List.generate(_statusOrder.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepIndex = index ~/ 2;
                final isCompleted = stepIndex < _currentIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? context.colors.primaryContainer
                        : context.surfaceMidColor,
                  ),
                );
              }
              final stepIndex = index ~/ 2;
              return _buildStep(
                context,
                _statusOrder[stepIndex],
                stepIndex,
              );
            }),
          ),
          Spacing.vMd,
          Center(
            child: Text(
              currentStatus.label,
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, OrderStatus status, int stepIndex) {
    final isCompleted = stepIndex <= _currentIndex;
    final isCurrent = stepIndex == _currentIndex;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted
            ? context.colors.primaryContainer
            : context.surfaceMidColor,
        border: isCurrent
            ? Border.all(color: context.colors.primary, width: 2)
            : null,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                color: context.colors.onPrimary,
                size: 18,
              )
            : Text(
                '${stepIndex + 1}',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? context.colors.onPrimary
                      : context.textSecondary,
                ),
              ),
      ),
    );
  }

  Widget _buildSpecialStatus(BuildContext context, String label, IconData icon, Color color) {
    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            color: color.withValues(alpha: 0.1),
            child: Center(
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          Spacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS DO PEDIDO',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: context.textSecondary,
                  ),
                ),
                Spacing.vXs,
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.headlineFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
