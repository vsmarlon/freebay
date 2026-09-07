import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
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
      color: context.surfaceColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AÇÕES',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: context.textSecondary,
            ),
          ),
          Spacing.vMd,
          ...actions,
        ],
      ),
    );
  }

  List<Widget> _buildActionsList() {
    final List<Widget> actions = [];

    if (isBuyer && order.status == OrderStatus.delivered) {
      actions.add(
        AppButton(
          label: 'Confirmar Recebimento',
          icon: Icons.check,
          isLoading: isLoading,
          onPressed: onConfirmDelivery,
          width: double.infinity,
        ),
      );
      actions.add(const SizedBox(height: 12));
    }

    if (canReview && reviewType != null) {
      final reviewLabel = isBuyer ? 'Avaliar Vendedor' : 'Avaliar Comprador';
      actions.add(
        AppButton(
          label: reviewLabel,
          icon: Icons.star_outlined,
          variant: actions.isEmpty
              ? AppButtonVariant.primary
              : AppButtonVariant.secondary,
          onPressed: onReview,
          width: double.infinity,
        ),
      );
      actions.add(const SizedBox(height: 12));
    }

    actions.add(
      AppButton(
        label: 'Enviar Mensagem',
        icon: Icons.chat_outlined,
        variant: AppButtonVariant.secondary,
        onPressed: onChat,
        width: double.infinity,
      ),
    );

    if (_canDispute()) {
      actions.add(const SizedBox(height: 12));
      actions.add(
        AppButton(
          label: 'Abrir Disputa',
          icon: Icons.gavel_outlined,
          variant: AppButtonVariant.danger,
          onPressed: onDispute,
          width: double.infinity,
        ),
      );
    }

    if (_canCancel()) {
      actions.add(const SizedBox(height: 12));
      actions.add(
        AppButton(
          label: 'Cancelar Pedido',
          icon: Icons.close,
          variant: AppButtonVariant.danger,
          isLoading: isLoading,
          onPressed: onCancel,
          width: double.infinity,
        ),
      );
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
