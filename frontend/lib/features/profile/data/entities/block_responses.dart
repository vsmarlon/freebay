class BlockListUser {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  final double reputationScore;

  const BlockListUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.isVerified,
    required this.reputationScore,
  });

  factory BlockListUser.fromJson(Map<String, dynamic> json) => BlockListUser(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    isVerified: json['isVerified'] as bool? ?? false,
    reputationScore: (json['reputationScore'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'isVerified': isVerified,
    'reputationScore': reputationScore,
  };
}

class BlockListResponse {
  final List<BlockListUser> users;
  final int limit;
  final int offset;

  const BlockListResponse({
    this.users = const [],
    required this.limit,
    required this.offset,
  });

  factory BlockListResponse.fromJson(Map<String, dynamic> json) =>
      BlockListResponse(
        users:
            (json['users'] as List<dynamic>?)
                ?.map((e) => BlockListUser.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        limit: json['limit'] as int? ?? 0,
        offset: json['offset'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'users': users.map((e) => e.toJson()).toList(),
    'limit': limit,
    'offset': offset,
  };
}

class UnblockResponse {
  final bool blocked;

  const UnblockResponse({required this.blocked});

  factory UnblockResponse.fromJson(Map<String, dynamic> json) =>
      UnblockResponse(blocked: json['blocked'] as bool? ?? false);

  Map<String, dynamic> toJson() => {'blocked': blocked};
}

class BlockResponse {
  final bool blocked;

  const BlockResponse({required this.blocked});

  factory BlockResponse.fromJson(Map<String, dynamic> json) =>
      BlockResponse(blocked: json['blocked'] as bool? ?? false);

  Map<String, dynamic> toJson() => {'blocked': blocked};
}
