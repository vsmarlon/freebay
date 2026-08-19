import 'package:freebay/features/orders/data/entities/order_entity.dart';

class OrderListResponse {
  final List<OrderEntity> orders;
  final int total;
  final int limit;
  final int offset;

  const OrderListResponse({
    this.orders = const [],
    this.total = 0,
    this.limit = 10,
    this.offset = 0,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) =>
      OrderListResponse(
        orders:
            (json['orders'] as List<dynamic>?)
                ?.map((e) => OrderEntity.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        total: json['total'] as int? ?? 0,
        limit: json['limit'] as int? ?? 10,
        offset: json['offset'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'orders': orders.map((e) => e.toJson()).toList(),
    'total': total,
    'limit': limit,
    'offset': offset,
  };

  bool get hasMore => offset + orders.length < total;
}
