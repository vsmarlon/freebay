import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_info.freezed.dart';
part 'order_info.g.dart';

@freezed
abstract class OrderInfo with _$OrderInfo {
  const factory OrderInfo({required String status}) = _OrderInfo;

  factory OrderInfo.fromJson(Map<String, dynamic> json) =>
      _$OrderInfoFromJson(json);
}
