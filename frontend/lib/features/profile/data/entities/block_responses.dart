import 'package:json_annotation/json_annotation.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';

part 'block_responses.g.dart';

@JsonSerializable()
class BlockListResponse {
  final List<UserBrief> users;
  @JsonKey(defaultValue: 0)
  final int limit;
  @JsonKey(defaultValue: 0)
  final int offset;

  const BlockListResponse({
    this.users = const [],
    required this.limit,
    required this.offset,
  });

  factory BlockListResponse.fromJson(Map<String, dynamic> json) =>
      _$BlockListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BlockListResponseToJson(this);
}

typedef BlockListUser = UserBrief;

@JsonSerializable()
class UnblockResponse {
  @JsonKey(defaultValue: false)
  final bool blocked;

  const UnblockResponse({required this.blocked});

  factory UnblockResponse.fromJson(Map<String, dynamic> json) =>
      _$UnblockResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UnblockResponseToJson(this);
}

@JsonSerializable()
class BlockResponse {
  @JsonKey(defaultValue: false)
  final bool blocked;

  const BlockResponse({required this.blocked});

  factory BlockResponse.fromJson(Map<String, dynamic> json) =>
      _$BlockResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BlockResponseToJson(this);
}
