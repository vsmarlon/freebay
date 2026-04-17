import 'package:equatable/equatable.dart';

enum ReviewType {
  buyerReviewingSeller,
  sellerReviewingBuyer,
}

class ReviewEntity extends Equatable {
  final String id;
  final String reviewerId;
  final String reviewedId;
  final String orderId;
  final ReviewType type;
  final int score;
  final String? comment;
  final DateTime createdAt;
  final ReviewUserInfo? reviewer;

  const ReviewEntity({
    required this.id,
    required this.reviewerId,
    required this.reviewedId,
    required this.orderId,
    required this.type,
    required this.score,
    this.comment,
    required this.createdAt,
    this.reviewer,
  });

  factory ReviewEntity.fromJson(Map<String, dynamic> json) {
    return ReviewEntity(
      id: json['id'] as String,
      reviewerId: json['reviewerId'] as String,
      reviewedId: json['reviewedId'] as String,
      orderId: json['orderId'] as String,
      type: json['type'] == 'BUYER_REVIEWING_SELLER'
          ? ReviewType.buyerReviewingSeller
          : ReviewType.sellerReviewingBuyer,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewer: json['reviewer'] != null
          ? ReviewUserInfo.fromJson(json['reviewer'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        reviewerId,
        reviewedId,
        orderId,
        type,
        score,
        comment,
        createdAt,
        reviewer,
      ];
}

class ReviewUserInfo extends Equatable {
  final String id;
  final String? displayName;
  final String? avatarUrl;

  const ReviewUserInfo({
    required this.id,
    this.displayName,
    this.avatarUrl,
  });

  String get displayNameOrDefault => displayName ?? 'Usuário';

  factory ReviewUserInfo.fromJson(Map<String, dynamic> json) {
    return ReviewUserInfo(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, displayName, avatarUrl];
}

class ReviewListResponse {
  final List<ReviewEntity> reviews;
  final int total;
  final int limit;
  final int offset;

  const ReviewListResponse({
    required this.reviews,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) {
    return ReviewListResponse(
      reviews: (json['reviews'] as List)
          .map((e) => ReviewEntity.fromJson(e))
          .toList(),
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
    );
  }

  bool get hasMore => offset + reviews.length < total;
}
