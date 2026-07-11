import 'package:freezed_annotation/freezed_annotation.dart';

part 'last_message_info.freezed.dart';
part 'last_message_info.g.dart';

@freezed
abstract class LastMessageInfo with _$LastMessageInfo {
  const factory LastMessageInfo({
    required String content,
    required DateTime createdAt,
  }) = _LastMessageInfo;

  factory LastMessageInfo.fromJson(Map<String, dynamic> json) =>
      _$LastMessageInfoFromJson(json);
}
