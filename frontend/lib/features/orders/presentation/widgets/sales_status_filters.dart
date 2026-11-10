import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class SalesStatusFilters extends StatelessWidget {
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onChanged;

  const SalesStatusFilters({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Container(
      color: context.surfaceMidColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Semantics(
              container: true,
              button: true,
              selected: selected == null,
              label: strings.ordersAllStatuses,
              child: BrutalistFilterChip(
                label: strings.commonAll.toUpperCase(),
                selected: selected == null,
                onTap: () => onChanged(null),
              ),
            ),
            Spacing.hSm,
            for (final status in OrderStatus.values) ...[
              Semantics(
                container: true,
                button: true,
                selected: selected == status,
                label: switch (status) {
                  OrderStatus.pending => strings.orderStatusPending,
                  OrderStatus.confirmed => strings.orderStatusConfirmed,
                  OrderStatus.shipped => strings.orderStatusShipped,
                  OrderStatus.delivered => strings.orderStatusDelivered,
                  OrderStatus.completed => strings.orderStatusCompleted,
                  OrderStatus.cancelled => strings.orderStatusCancelled,
                  OrderStatus.disputed => strings.orderStatusDisputed,
                },
                child: BrutalistFilterChip(
                  label: switch (status) {
                    OrderStatus.pending => strings.orderStatusPending,
                    OrderStatus.confirmed => strings.orderStatusConfirmed,
                    OrderStatus.shipped => strings.orderStatusShipped,
                    OrderStatus.delivered => strings.orderStatusDelivered,
                    OrderStatus.completed => strings.orderStatusCompleted,
                    OrderStatus.cancelled => strings.orderStatusCancelled,
                    OrderStatus.disputed => strings.orderStatusDisputed,
                  }.toUpperCase(),
                  selected: selected == status,
                  onTap: () => onChanged(status),
                ),
              ),
              Spacing.hSm,
            ],
          ],
        ),
      ),
    );
  }
}
