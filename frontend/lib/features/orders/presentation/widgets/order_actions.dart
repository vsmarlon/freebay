import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';

class OrderActions extends StatelessWidget {
  final OrderEntity order;
  final bool canReview;
  final String? reviewType;
  final bool isBuyer;
  final bool isLoading;
  final VoidCallback? onConfirmDelivery;
  final VoidCallback? onReview;
  final VoidCallback? onChat;
  final VoidCallback? onDispute;
  final VoidCallback? onCancel;

  const OrderActions({
    super.key,
    required this.order,
    required this.canReview,
    this.reviewType,
    required this.isBuyer,
    this.isLoading = false,
    this.onConfirmDelivery,
    this.onReview,
    this.onChat,
    this.onDispute,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _buildActionsList();

    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AÇÕES',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...actions,
        ],
      ),
    );
  }

  List<Widget> _buildActionsList() {
    final List<Widget> actions = [];

    if (isBuyer && order.status == OrderStatus.delivered) {
      actions.add(_BrutalistButton(
        label: 'Confirmar Recebimento',
        icon: Icons.check,
        isPrimary: true,
        isLoading: isLoading,
        onPressed: onConfirmDelivery,
      ));
      actions.add(const SizedBox(height: 12));
    }

    if (canReview && reviewType != null) {
      final reviewLabel = isBuyer ? 'Avaliar Vendedor' : 'Avaliar Comprador';
      actions.add(_BrutalistButton(
        label: reviewLabel,
        icon: Icons.star_outlined,
        isPrimary: actions.isEmpty,
        onPressed: onReview,
      ));
      actions.add(const SizedBox(height: 12));
    }

    actions.add(_BrutalistButton(
      label: 'Enviar Mensagem',
      icon: Icons.chat_outlined,
      isPrimary: false,
      onPressed: onChat,
    ));

    if (_canDispute()) {
      actions.add(const SizedBox(height: 12));
      actions.add(_BrutalistButton(
        label: 'Abrir Disputa',
        icon: Icons.gavel_outlined,
        isPrimary: false,
        isDanger: true,
        onPressed: onDispute,
      ));
    }

    if (_canCancel()) {
      actions.add(const SizedBox(height: 12));
      actions.add(_BrutalistButton(
        label: 'Cancelar Pedido',
        icon: Icons.close,
        isPrimary: false,
        isDanger: true,
        isLoading: isLoading,
        onPressed: onCancel,
      ));
    }

    return actions;
  }

  bool _canDispute() {
    return order.status == OrderStatus.delivered ||
        order.status == OrderStatus.shipped;
  }

  bool _canCancel() {
    return isBuyer && order.status == OrderStatus.pending;
  }
}

class _BrutalistButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDanger;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _BrutalistButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    this.isDanger = false,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    if (isPrimary && !isDanger) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: isDisabled ? null : AppColors.brutalistGradient,
          color: isDisabled ? AppColors.surfaceContainerHighest : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  else ...[
                    Icon(
                      icon,
                      color: isDisabled
                          ? AppColors.onSurfaceVariant
                          : AppColors.onPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? AppColors.onSurfaceVariant
                            : AppColors.onPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: isDanger
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.surfaceContainerHighest,
        border: Border.all(
          color: isDanger
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDanger ? AppColors.error : AppColors.onSurface,
                    ),
                  )
                else ...[
                  Icon(
                    icon,
                    color: isDanger ? AppColors.error : AppColors.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDanger ? AppColors.error : AppColors.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
