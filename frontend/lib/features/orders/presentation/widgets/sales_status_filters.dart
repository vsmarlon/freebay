import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';

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
              label: 'Todos os status',
              child: BrutalistFilterChip(
                label: 'TODOS',
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
                label: status.label,
                child: BrutalistFilterChip(
                  label: status.label.toUpperCase(),
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
