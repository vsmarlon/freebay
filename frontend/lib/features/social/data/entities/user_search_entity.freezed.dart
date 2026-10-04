// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_search_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserSearchEntity {

 String get id; String get displayName; String? get username; String? get avatarUrl; String? get avatarBlurHash; String? get bio; bool get isVerified; double get reputationScore; int get totalReviews; int get followersCount; int get followingCount;
/// Create a copy of UserSearchEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSearchEntityCopyWith<UserSearchEntity> get copyWith => _$UserSearchEntityCopyWithImpl<UserSearchEntity>(this as UserSearchEntity, _$identity);

  /// Serializes this UserSearchEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSearchEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.avatarBlurHash, avatarBlurHash) || other.avatarBlurHash == avatarBlurHash)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.reputationScore, reputationScore) || other.reputationScore == reputationScore)&&(identical(other.totalReviews, totalReviews) || other.totalReviews == totalReviews)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,avatarBlurHash,bio,isVerified,reputationScore,totalReviews,followersCount,followingCount);

@override
String toString() {
  return 'UserSearchEntity(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, avatarBlurHash: $avatarBlurHash, bio: $bio, isVerified: $isVerified, reputationScore: $reputationScore, totalReviews: $totalReviews, followersCount: $followersCount, followingCount: $followingCount)';
}


}

/// @nodoc
abstract mixin class $UserSearchEntityCopyWith<$Res>  {
  factory $UserSearchEntityCopyWith(UserSearchEntity value, $Res Function(UserSearchEntity) _then) = _$UserSearchEntityCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String? username, String? avatarUrl, String? avatarBlurHash, String? bio, bool isVerified, double reputationScore, int totalReviews, int followersCount, int followingCount
});




}
/// @nodoc
class _$UserSearchEntityCopyWithImpl<$Res>
    implements $UserSearchEntityCopyWith<$Res> {
  _$UserSearchEntityCopyWithImpl(this._self, this._then);

  final UserSearchEntity _self;
  final $Res Function(UserSearchEntity) _then;

/// Create a copy of UserSearchEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? username = freezed,Object? avatarUrl = freezed,Object? avatarBlurHash = freezed,Object? bio = freezed,Object? isVerified = null,Object? reputationScore = null,Object? totalReviews = null,Object? followersCount = null,Object? followingCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,avatarBlurHash: freezed == avatarBlurHash ? _self.avatarBlurHash : avatarBlurHash // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,reputationScore: null == reputationScore ? _self.reputationScore : reputationScore // ignore: cast_nullable_to_non_nullable
as double,totalReviews: null == totalReviews ? _self.totalReviews : totalReviews // ignore: cast_nullable_to_non_nullable
as int,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSearchEntity].
extension UserSearchEntityPatterns on UserSearchEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSearchEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSearchEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSearchEntity value)  $default,){
final _that = this;
switch (_that) {
case _UserSearchEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSearchEntity value)?  $default,){
final _that = this;
switch (_that) {
case _UserSearchEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String? username,  String? avatarUrl,  String? avatarBlurHash,  String? bio,  bool isVerified,  double reputationScore,  int totalReviews,  int followersCount,  int followingCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSearchEntity() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.avatarBlurHash,_that.bio,_that.isVerified,_that.reputationScore,_that.totalReviews,_that.followersCount,_that.followingCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String? username,  String? avatarUrl,  String? avatarBlurHash,  String? bio,  bool isVerified,  double reputationScore,  int totalReviews,  int followersCount,  int followingCount)  $default,) {final _that = this;
switch (_that) {
case _UserSearchEntity():
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.avatarBlurHash,_that.bio,_that.isVerified,_that.reputationScore,_that.totalReviews,_that.followersCount,_that.followingCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String? username,  String? avatarUrl,  String? avatarBlurHash,  String? bio,  bool isVerified,  double reputationScore,  int totalReviews,  int followersCount,  int followingCount)?  $default,) {final _that = this;
switch (_that) {
case _UserSearchEntity() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.avatarBlurHash,_that.bio,_that.isVerified,_that.reputationScore,_that.totalReviews,_that.followersCount,_that.followingCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserSearchEntity implements UserSearchEntity {
  const _UserSearchEntity({required this.id, required this.displayName, this.username, this.avatarUrl, this.avatarBlurHash, this.bio, this.isVerified = false, this.reputationScore = 0.0, this.totalReviews = 0, this.followersCount = 0, this.followingCount = 0});
  factory _UserSearchEntity.fromJson(Map<String, dynamic> json) => _$UserSearchEntityFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String? username;
@override final  String? avatarUrl;
@override final  String? avatarBlurHash;
@override final  String? bio;
@override@JsonKey() final  bool isVerified;
@override@JsonKey() final  double reputationScore;
@override@JsonKey() final  int totalReviews;
@override@JsonKey() final  int followersCount;
@override@JsonKey() final  int followingCount;

/// Create a copy of UserSearchEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSearchEntityCopyWith<_UserSearchEntity> get copyWith => __$UserSearchEntityCopyWithImpl<_UserSearchEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserSearchEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSearchEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.avatarBlurHash, avatarBlurHash) || other.avatarBlurHash == avatarBlurHash)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.reputationScore, reputationScore) || other.reputationScore == reputationScore)&&(identical(other.totalReviews, totalReviews) || other.totalReviews == totalReviews)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,avatarBlurHash,bio,isVerified,reputationScore,totalReviews,followersCount,followingCount);

@override
String toString() {
  return 'UserSearchEntity(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, avatarBlurHash: $avatarBlurHash, bio: $bio, isVerified: $isVerified, reputationScore: $reputationScore, totalReviews: $totalReviews, followersCount: $followersCount, followingCount: $followingCount)';
}


}

/// @nodoc
abstract mixin class _$UserSearchEntityCopyWith<$Res> implements $UserSearchEntityCopyWith<$Res> {
  factory _$UserSearchEntityCopyWith(_UserSearchEntity value, $Res Function(_UserSearchEntity) _then) = __$UserSearchEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? username, String? avatarUrl, String? avatarBlurHash, String? bio, bool isVerified, double reputationScore, int totalReviews, int followersCount, int followingCount
});




}
/// @nodoc
class __$UserSearchEntityCopyWithImpl<$Res>
    implements _$UserSearchEntityCopyWith<$Res> {
  __$UserSearchEntityCopyWithImpl(this._self, this._then);

  final _UserSearchEntity _self;
  final $Res Function(_UserSearchEntity) _then;

/// Create a copy of UserSearchEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = freezed,Object? avatarUrl = freezed,Object? avatarBlurHash = freezed,Object? bio = freezed,Object? isVerified = null,Object? reputationScore = null,Object? totalReviews = null,Object? followersCount = null,Object? followingCount = null,}) {
  return _then(_UserSearchEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,avatarBlurHash: freezed == avatarBlurHash ? _self.avatarBlurHash : avatarBlurHash // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,reputationScore: null == reputationScore ? _self.reputationScore : reputationScore // ignore: cast_nullable_to_non_nullable
as double,totalReviews: null == totalReviews ? _self.totalReviews : totalReviews // ignore: cast_nullable_to_non_nullable
as int,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
