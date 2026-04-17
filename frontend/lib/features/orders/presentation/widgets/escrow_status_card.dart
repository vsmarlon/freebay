import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';

class EscrowStatusCard extends StatelessWidget {
  final EscrowStatus escrowStatus;
  final int amount;
  final int platformFee;
  final int sellerAmount;
  final bool isBuyer;

  const EscrowStatusCard({
    super.key,
    required this.escrowStatus,
    required this.amount,
    required this.platformFee,
    required this.sellerAmount,
    required this.isBuyer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                color: _getStatusColor().withValues(alpha: 0.1),
                child: Center(
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PAGAMENTO',
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
                      escrowStatus.label,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            color: AppColors.surfaceContainerLowest,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow('Valor total', CurrencyUtils.formatCents(amount)),
                if (!isBuyer) ...[
                  const SizedBox(height: 12),
                  _buildRow(
                    'Taxa da plataforma (10%)',
                    '- ${CurrencyUtils.formatCents(platformFee)}',
                    valueColor: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  _buildRow(
                    'Você recebe',
                    CurrencyUtils.formatCents(sellerAmount),
                    isBold: true,
                    valueColor: AppColors.success,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getStatusDescription(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: isBold ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (escrowStatus) {
      case EscrowStatus.held:
        return AppColors.warning;
      case EscrowStatus.released:
        return AppColors.success;
      case EscrowStatus.refunded:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon() {
    switch (escrowStatus) {
      case EscrowStatus.held:
        return Icons.lock_outlined;
      case EscrowStatus.released:
        return Icons.check_circle_outlined;
      case EscrowStatus.refunded:
        return Icons.replay_outlined;
    }
  }

  String _getStatusDescription() {
    switch (escrowStatus) {
      case EscrowStatus.held:
        return isBuyer
            ? 'O pagamento está retido em custódia até você confirmar o recebimento do produto.'
            : 'O pagamento está retido em custódia. Será liberado quando o comprador confirmar o recebimento.';
      case EscrowStatus.released:
        return isBuyer
            ? 'Pagamento liberado para o vendedor.'
            : 'Pagamento liberado! O valor será creditado na sua carteira.';
      case EscrowStatus.refunded:
        return isBuyer
            ? 'Valor reembolsado para sua carteira.'
            : 'Valor reembolsado ao comprador.';
    }
  }
}
