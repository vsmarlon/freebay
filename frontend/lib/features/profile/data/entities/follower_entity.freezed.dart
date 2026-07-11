// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follower_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FollowerEntity {

 String get id; String get displayName; String? get avatarUrl; bool get isVerified; String? get bio; bool get isFollowing;
/// Create a copy of FollowerEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowerEntityCopyWith<FollowerEntity> get copyWith => _$FollowerEntityCopyWithImpl<FollowerEntity>(this as FollowerEntity, _$identity);

  /// Serializes this FollowerEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowerEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,isVerified,bio,isFollowing);

@override
String toString() {
  return 'FollowerEntity(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified, bio: $bio, isFollowing: $isFollowing)';
}


}

/// @nodoc
abstract mixin class $FollowerEntityCopyWith<$Res>  {
  factory $FollowerEntityCopyWith(FollowerEntity value, $Res Function(FollowerEntity) _then) = _$FollowerEntityCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String? avatarUrl, bool isVerified, String? bio, bool isFollowing
});




}
/// @nodoc
class _$FollowerEntityCopyWithImpl<$Res>
    implements $FollowerEntityCopyWith<$Res> {
  _$FollowerEntityCopyWithImpl(this._self, this._then);

  final FollowerEntity _self;
  final $Res Function(FollowerEntity) _then;

/// Create a copy of FollowerEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? bio = freezed,Object? isFollowing = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowerEntity].
extension FollowerEntityPatterns on FollowerEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowerEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowerEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowerEntity value)  $default,){
final _that = this;
switch (_that) {
case _FollowerEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowerEntity value)?  $default,){
final _that = this;
switch (_that) {
case _FollowerEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String? avatarUrl,  bool isVerified,  String? bio,  bool isFollowing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowerEntity() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified,_that.bio,_that.isFollowing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String? avatarUrl,  bool isVerified,  String? bio,  bool isFollowing)  $default,) {final _that = this;
switch (_that) {
case _FollowerEntity():
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified,_that.bio,_that.isFollowing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String? avatarUrl,  bool isVerified,  String? bio,  bool isFollowing)?  $default,) {final _that = this;
switch (_that) {
case _FollowerEntity() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified,_that.bio,_that.isFollowing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowerEntity implements FollowerEntity {
  const _FollowerEntity({required this.id, this.displayName = 'Usuário', this.avatarUrl, this.isVerified = false, this.bio, this.isFollowing = false});
  factory _FollowerEntity.fromJson(Map<String, dynamic> json) => _$FollowerEntityFromJson(json);

@override final  String id;
@override@JsonKey() final  String displayName;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isVerified;
@override final  String? bio;
@override@JsonKey() final  bool isFollowing;

/// Create a copy of FollowerEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowerEntityCopyWith<_FollowerEntity> get copyWith => __$FollowerEntityCopyWithImpl<_FollowerEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowerEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowerEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,isVerified,bio,isFollowing);

@override
String toString() {
  return 'FollowerEntity(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified, bio: $bio, isFollowing: $isFollowing)';
}


}

/// @nodoc
abstract mixin class _$FollowerEntityCopyWith<$Res> implements $FollowerEntityCopyWith<$Res> {
  factory _$FollowerEntityCopyWith(_FollowerEntity value, $Res Function(_FollowerEntity) _then) = __$FollowerEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? avatarUrl, bool isVerified, String? bio, bool isFollowing
});




}
/// @nodoc
class __$FollowerEntityCopyWithImpl<$Res>
    implements _$FollowerEntityCopyWith<$Res> {
  __$FollowerEntityCopyWithImpl(this._self, this._then);

  final _FollowerEntity _self;
  final $Res Function(_FollowerEntity) _then;

/// Create a copy of FollowerEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? bio = freezed,Object? isFollowing = null,}) {
  return _then(_FollowerEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
