import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';

part 'order_list_response.freezed.dart';
part 'order_list_response.g.dart';

@freezed
abstract class OrderListResponse with _$OrderListResponse {
  const OrderListResponse._();

  const factory OrderListResponse({
    @Default([]) List<OrderEntity> orders,
    @Default(0) int total,
    @Default(10) int limit,
    @Default(0) int offset,
  }) = _OrderListResponse;

  factory OrderListResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderListResponseFromJson(json);

  bool get hasMore => offset + orders.length < total;
}
