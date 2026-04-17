import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';

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
        'Pedido Cancelado',
        Icons.close,
        AppColors.error,
      );
    }

    if (currentStatus == OrderStatus.disputed) {
      return _buildSpecialStatus(
        'Em Disputa',
        Icons.gavel_outlined,
        AppColors.warning,
      );
    }

    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS DO PEDIDO',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(_statusOrder.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepIndex = index ~/ 2;
                final isCompleted = stepIndex < _currentIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainerHighest,
                  ),
                );
              }
              final stepIndex = index ~/ 2;
              return _buildStep(
                _statusOrder[stepIndex],
                stepIndex,
              );
            }),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              currentStatus.label,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(OrderStatus status, int stepIndex) {
    final isCompleted = stepIndex <= _currentIndex;
    final isCurrent = stepIndex == _currentIndex;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerHighest,
        border: isCurrent
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(
                Icons.check,
                color: AppColors.onPrimary,
                size: 18,
              )
            : Text(
                '${stepIndex + 1}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                ),
              ),
      ),
    );
  }

  Widget _buildSpecialStatus(String label, IconData icon, Color color) {
    return Container(
      color: AppColors.surfaceContainerLowest,
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATUS DO PEDIDO',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
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
