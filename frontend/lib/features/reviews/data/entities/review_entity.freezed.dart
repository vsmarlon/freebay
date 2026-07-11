// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReviewEntity {

 String get id; String get reviewerId; String get reviewedId; String get orderId;@JsonKey(fromJson: _reviewTypeFromJson, toJson: _reviewTypeToJson) ReviewType get type; int get score; String? get comment; List<String> get images; DateTime get createdAt; ReviewUserInfo? get reviewer;
/// Create a copy of ReviewEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewEntityCopyWith<ReviewEntity> get copyWith => _$ReviewEntityCopyWithImpl<ReviewEntity>(this as ReviewEntity, _$identity);

  /// Serializes this ReviewEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.reviewedId, reviewedId) || other.reviewedId == reviewedId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.type, type) || other.type == type)&&(identical(other.score, score) || other.score == score)&&(identical(other.comment, comment) || other.comment == comment)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewer, reviewer) || other.reviewer == reviewer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reviewerId,reviewedId,orderId,type,score,comment,const DeepCollectionEquality().hash(images),createdAt,reviewer);

@override
String toString() {
  return 'ReviewEntity(id: $id, reviewerId: $reviewerId, reviewedId: $reviewedId, orderId: $orderId, type: $type, score: $score, comment: $comment, images: $images, createdAt: $createdAt, reviewer: $reviewer)';
}


}

/// @nodoc
abstract mixin class $ReviewEntityCopyWith<$Res>  {
  factory $ReviewEntityCopyWith(ReviewEntity value, $Res Function(ReviewEntity) _then) = _$ReviewEntityCopyWithImpl;
@useResult
$Res call({
 String id, String reviewerId, String reviewedId, String orderId,@JsonKey(fromJson: _reviewTypeFromJson, toJson: _reviewTypeToJson) ReviewType type, int score, String? comment, List<String> images, DateTime createdAt, ReviewUserInfo? reviewer
});


$ReviewUserInfoCopyWith<$Res>? get reviewer;

}
/// @nodoc
class _$ReviewEntityCopyWithImpl<$Res>
    implements $ReviewEntityCopyWith<$Res> {
  _$ReviewEntityCopyWithImpl(this._self, this._then);

  final ReviewEntity _self;
  final $Res Function(ReviewEntity) _then;

/// Create a copy of ReviewEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reviewerId = null,Object? reviewedId = null,Object? orderId = null,Object? type = null,Object? score = null,Object? comment = freezed,Object? images = null,Object? createdAt = null,Object? reviewer = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reviewerId: null == reviewerId ? _self.reviewerId : reviewerId // ignore: cast_nullable_to_non_nullable
as String,reviewedId: null == reviewedId ? _self.reviewedId : reviewedId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ReviewType,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewer: freezed == reviewer ? _self.reviewer : reviewer // ignore: cast_nullable_to_non_nullable
as ReviewUserInfo?,
  ));
}
/// Create a copy of ReviewEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewUserInfoCopyWith<$Res>? get reviewer {
    if (_self.reviewer == null) {
    return null;
  }

  return $ReviewUserInfoCopyWith<$Res>(_self.reviewer!, (value) {
    return _then(_self.copyWith(reviewer: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReviewEntity].
extension ReviewEntityPatterns on ReviewEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewEntity value)  $default,){
final _that = this;
switch (_that) {
case _ReviewEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String reviewerId,  String reviewedId,  String orderId, @JsonKey(fromJson: _reviewTypeFromJson, toJson: _reviewTypeToJson)  ReviewType type,  int score,  String? comment,  List<String> images,  DateTime createdAt,  ReviewUserInfo? reviewer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewEntity() when $default != null:
return $default(_that.id,_that.reviewerId,_that.reviewedId,_that.orderId,_that.type,_that.score,_that.comment,_that.images,_that.createdAt,_that.reviewer);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String reviewerId,  String reviewedId,  String orderId, @JsonKey(fromJson: _reviewTypeFromJson, toJson: _reviewTypeToJson)  ReviewType type,  int score,  String? comment,  List<String> images,  DateTime createdAt,  ReviewUserInfo? reviewer)  $default,) {final _that = this;
switch (_that) {
case _ReviewEntity():
return $default(_that.id,_that.reviewerId,_that.reviewedId,_that.orderId,_that.type,_that.score,_that.comment,_that.images,_that.createdAt,_that.reviewer);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String reviewerId,  String reviewedId,  String orderId, @JsonKey(fromJson: _reviewTypeFromJson, toJson: _reviewTypeToJson)  ReviewType type,  int score,  String? comment,  List<String> images,  DateTime createdAt,  ReviewUserInfo? reviewer)?  $default,) {final _that = this;
switch (_that) {
case _ReviewEntity() when $default != null:
return $default(_that.id,_that.reviewerId,_that.reviewedId,_that.orderId,_that.type,_that.score,_that.comment,_that.images,_that.createdAt,_that.reviewer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewEntity implements ReviewEntity {
  const _ReviewEntity({required this.id, required this.reviewerId, required this.reviewedId, required this.orderId, @JsonKey(fromJson: _reviewTypeFromJson, toJson: _reviewTypeToJson) required this.type, required this.score, this.comment, final  List<String> images = const [], required this.createdAt, this.reviewer}): _images = images;
  factory _ReviewEntity.fromJson(Map<String, dynamic> json) => _$ReviewEntityFromJson(json);

@override final  String id;
@override final  String reviewerId;
@override final  String reviewedId;
@override final  String orderId;
@override@JsonKey(fromJson: _reviewTypeFromJson, toJson: _reviewTypeToJson) final  ReviewType type;
@override final  int score;
@override final  String? comment;
 final  List<String> _images;
@override@JsonKey() List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override final  DateTime createdAt;
@override final  ReviewUserInfo? reviewer;

/// Create a copy of ReviewEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewEntityCopyWith<_ReviewEntity> get copyWith => __$ReviewEntityCopyWithImpl<_ReviewEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.reviewedId, reviewedId) || other.reviewedId == reviewedId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.type, type) || other.type == type)&&(identical(other.score, score) || other.score == score)&&(identical(other.comment, comment) || other.comment == comment)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewer, reviewer) || other.reviewer == reviewer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reviewerId,reviewedId,orderId,type,score,comment,const DeepCollectionEquality().hash(_images),createdAt,reviewer);

@override
String toString() {
  return 'ReviewEntity(id: $id, reviewerId: $reviewerId, reviewedId: $reviewedId, orderId: $orderId, type: $type, score: $score, comment: $comment, images: $images, createdAt: $createdAt, reviewer: $reviewer)';
}


}

/// @nodoc
abstract mixin class _$ReviewEntityCopyWith<$Res> implements $ReviewEntityCopyWith<$Res> {
  factory _$ReviewEntityCopyWith(_ReviewEntity value, $Res Function(_ReviewEntity) _then) = __$ReviewEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String reviewerId, String reviewedId, String orderId,@JsonKey(fromJson: _reviewTypeFromJson, toJson: _reviewTypeToJson) ReviewType type, int score, String? comment, List<String> images, DateTime createdAt, ReviewUserInfo? reviewer
});


@override $ReviewUserInfoCopyWith<$Res>? get reviewer;

}
/// @nodoc
class __$ReviewEntityCopyWithImpl<$Res>
    implements _$ReviewEntityCopyWith<$Res> {
  __$ReviewEntityCopyWithImpl(this._self, this._then);

  final _ReviewEntity _self;
  final $Res Function(_ReviewEntity) _then;

/// Create a copy of ReviewEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reviewerId = null,Object? reviewedId = null,Object? orderId = null,Object? type = null,Object? score = null,Object? comment = freezed,Object? images = null,Object? createdAt = null,Object? reviewer = freezed,}) {
  return _then(_ReviewEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reviewerId: null == reviewerId ? _self.reviewerId : reviewerId // ignore: cast_nullable_to_non_nullable
as String,reviewedId: null == reviewedId ? _self.reviewedId : reviewedId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ReviewType,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewer: freezed == reviewer ? _self.reviewer : reviewer // ignore: cast_nullable_to_non_nullable
as ReviewUserInfo?,
  ));
}

/// Create a copy of ReviewEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewUserInfoCopyWith<$Res>? get reviewer {
    if (_self.reviewer == null) {
    return null;
  }

  return $ReviewUserInfoCopyWith<$Res>(_self.reviewer!, (value) {
    return _then(_self.copyWith(reviewer: value));
  });
}
}

// dart format on
