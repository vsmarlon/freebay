// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderListResponse _$OrderListResponseFromJson(Map<String, dynamic> json) =>
    _OrderListResponse(
      orders:
          (json['orders'] as List<dynamic>?)
              ?.map((e) => OrderEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$OrderListResponseToJson(_OrderListResponse instance) =>
    <String, dynamic>{
      'orders': instance.orders,
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
    };
