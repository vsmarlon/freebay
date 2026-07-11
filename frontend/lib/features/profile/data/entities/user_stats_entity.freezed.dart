// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_stats_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserStatsEntity {

 int get salesCount; int get purchasesCount; int get followersCount; int get followingCount;
/// Create a copy of UserStatsEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserStatsEntityCopyWith<UserStatsEntity> get copyWith => _$UserStatsEntityCopyWithImpl<UserStatsEntity>(this as UserStatsEntity, _$identity);

  /// Serializes this UserStatsEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserStatsEntity&&(identical(other.salesCount, salesCount) || other.salesCount == salesCount)&&(identical(other.purchasesCount, purchasesCount) || other.purchasesCount == purchasesCount)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,salesCount,purchasesCount,followersCount,followingCount);

@override
String toString() {
  return 'UserStatsEntity(salesCount: $salesCount, purchasesCount: $purchasesCount, followersCount: $followersCount, followingCount: $followingCount)';
}


}

/// @nodoc
abstract mixin class $UserStatsEntityCopyWith<$Res>  {
  factory $UserStatsEntityCopyWith(UserStatsEntity value, $Res Function(UserStatsEntity) _then) = _$UserStatsEntityCopyWithImpl;
@useResult
$Res call({
 int salesCount, int purchasesCount, int followersCount, int followingCount
});




}
/// @nodoc
class _$UserStatsEntityCopyWithImpl<$Res>
    implements $UserStatsEntityCopyWith<$Res> {
  _$UserStatsEntityCopyWithImpl(this._self, this._then);

  final UserStatsEntity _self;
  final $Res Function(UserStatsEntity) _then;

/// Create a copy of UserStatsEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? salesCount = null,Object? purchasesCount = null,Object? followersCount = null,Object? followingCount = null,}) {
  return _then(_self.copyWith(
salesCount: null == salesCount ? _self.salesCount : salesCount // ignore: cast_nullable_to_non_nullable
as int,purchasesCount: null == purchasesCount ? _self.purchasesCount : purchasesCount // ignore: cast_nullable_to_non_nullable
as int,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UserStatsEntity].
extension UserStatsEntityPatterns on UserStatsEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserStatsEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserStatsEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserStatsEntity value)  $default,){
final _that = this;
switch (_that) {
case _UserStatsEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserStatsEntity value)?  $default,){
final _that = this;
switch (_that) {
case _UserStatsEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int salesCount,  int purchasesCount,  int followersCount,  int followingCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserStatsEntity() when $default != null:
return $default(_that.salesCount,_that.purchasesCount,_that.followersCount,_that.followingCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int salesCount,  int purchasesCount,  int followersCount,  int followingCount)  $default,) {final _that = this;
switch (_that) {
case _UserStatsEntity():
return $default(_that.salesCount,_that.purchasesCount,_that.followersCount,_that.followingCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int salesCount,  int purchasesCount,  int followersCount,  int followingCount)?  $default,) {final _that = this;
switch (_that) {
case _UserStatsEntity() when $default != null:
return $default(_that.salesCount,_that.purchasesCount,_that.followersCount,_that.followingCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserStatsEntity implements UserStatsEntity {
  const _UserStatsEntity({this.salesCount = 0, this.purchasesCount = 0, this.followersCount = 0, this.followingCount = 0});
  factory _UserStatsEntity.fromJson(Map<String, dynamic> json) => _$UserStatsEntityFromJson(json);

@override@JsonKey() final  int salesCount;
@override@JsonKey() final  int purchasesCount;
@override@JsonKey() final  int followersCount;
@override@JsonKey() final  int followingCount;

/// Create a copy of UserStatsEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserStatsEntityCopyWith<_UserStatsEntity> get copyWith => __$UserStatsEntityCopyWithImpl<_UserStatsEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserStatsEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserStatsEntity&&(identical(other.salesCount, salesCount) || other.salesCount == salesCount)&&(identical(other.purchasesCount, purchasesCount) || other.purchasesCount == purchasesCount)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,salesCount,purchasesCount,followersCount,followingCount);

@override
String toString() {
  return 'UserStatsEntity(salesCount: $salesCount, purchasesCount: $purchasesCount, followersCount: $followersCount, followingCount: $followingCount)';
}


}

/// @nodoc
abstract mixin class _$UserStatsEntityCopyWith<$Res> implements $UserStatsEntityCopyWith<$Res> {
  factory _$UserStatsEntityCopyWith(_UserStatsEntity value, $Res Function(_UserStatsEntity) _then) = __$UserStatsEntityCopyWithImpl;
@override @useResult
$Res call({
 int salesCount, int purchasesCount, int followersCount, int followingCount
});




}
/// @nodoc
class __$UserStatsEntityCopyWithImpl<$Res>
    implements _$UserStatsEntityCopyWith<$Res> {
  __$UserStatsEntityCopyWithImpl(this._self, this._then);

  final _UserStatsEntity _self;
  final $Res Function(_UserStatsEntity) _then;

/// Create a copy of UserStatsEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? salesCount = null,Object? purchasesCount = null,Object? followersCount = null,Object? followingCount = null,}) {
  return _then(_UserStatsEntity(
salesCount: null == salesCount ? _self.salesCount : salesCount // ignore: cast_nullable_to_non_nullable
as int,purchasesCount: null == purchasesCount ? _self.purchasesCount : purchasesCount // ignore: cast_nullable_to_non_nullable
as int,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
