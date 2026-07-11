// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StoryUserEntity {

 String get id; String get displayName; String? get avatarUrl; bool get isVerified;
/// Create a copy of StoryUserEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryUserEntityCopyWith<StoryUserEntity> get copyWith => _$StoryUserEntityCopyWithImpl<StoryUserEntity>(this as StoryUserEntity, _$identity);

  /// Serializes this StoryUserEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryUserEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,isVerified);

@override
String toString() {
  return 'StoryUserEntity(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class $StoryUserEntityCopyWith<$Res>  {
  factory $StoryUserEntityCopyWith(StoryUserEntity value, $Res Function(StoryUserEntity) _then) = _$StoryUserEntityCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String? avatarUrl, bool isVerified
});




}
/// @nodoc
class _$StoryUserEntityCopyWithImpl<$Res>
    implements $StoryUserEntityCopyWith<$Res> {
  _$StoryUserEntityCopyWithImpl(this._self, this._then);

  final StoryUserEntity _self;
  final $Res Function(StoryUserEntity) _then;

/// Create a copy of StoryUserEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? avatarUrl = freezed,Object? isVerified = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StoryUserEntity].
extension StoryUserEntityPatterns on StoryUserEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoryUserEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoryUserEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoryUserEntity value)  $default,){
final _that = this;
switch (_that) {
case _StoryUserEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoryUserEntity value)?  $default,){
final _that = this;
switch (_that) {
case _StoryUserEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String? avatarUrl,  bool isVerified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryUserEntity() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String? avatarUrl,  bool isVerified)  $default,) {final _that = this;
switch (_that) {
case _StoryUserEntity():
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String? avatarUrl,  bool isVerified)?  $default,) {final _that = this;
switch (_that) {
case _StoryUserEntity() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoryUserEntity implements StoryUserEntity {
  const _StoryUserEntity({required this.id, required this.displayName, this.avatarUrl, this.isVerified = false});
  factory _StoryUserEntity.fromJson(Map<String, dynamic> json) => _$StoryUserEntityFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isVerified;

/// Create a copy of StoryUserEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoryUserEntityCopyWith<_StoryUserEntity> get copyWith => __$StoryUserEntityCopyWithImpl<_StoryUserEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoryUserEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryUserEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,isVerified);

@override
String toString() {
  return 'StoryUserEntity(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class _$StoryUserEntityCopyWith<$Res> implements $StoryUserEntityCopyWith<$Res> {
  factory _$StoryUserEntityCopyWith(_StoryUserEntity value, $Res Function(_StoryUserEntity) _then) = __$StoryUserEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? avatarUrl, bool isVerified
});




}
/// @nodoc
class __$StoryUserEntityCopyWithImpl<$Res>
    implements _$StoryUserEntityCopyWith<$Res> {
  __$StoryUserEntityCopyWithImpl(this._self, this._then);

  final _StoryUserEntity _self;
  final $Res Function(_StoryUserEntity) _then;

/// Create a copy of StoryUserEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? avatarUrl = freezed,Object? isVerified = null,}) {
  return _then(_StoryUserEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$StoryEntity {

 String get id; String get userId; String get imageUrl; DateTime get expiresAt; DateTime get createdAt; StoryUserEntity get user; bool get isViewed;
/// Create a copy of StoryEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryEntityCopyWith<StoryEntity> get copyWith => _$StoryEntityCopyWithImpl<StoryEntity>(this as StoryEntity, _$identity);

  /// Serializes this StoryEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.isViewed, isViewed) || other.isViewed == isViewed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,imageUrl,expiresAt,createdAt,user,isViewed);

@override
String toString() {
  return 'StoryEntity(id: $id, userId: $userId, imageUrl: $imageUrl, expiresAt: $expiresAt, createdAt: $createdAt, user: $user, isViewed: $isViewed)';
}


}

/// @nodoc
abstract mixin class $StoryEntityCopyWith<$Res>  {
  factory $StoryEntityCopyWith(StoryEntity value, $Res Function(StoryEntity) _then) = _$StoryEntityCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String imageUrl, DateTime expiresAt, DateTime createdAt, StoryUserEntity user, bool isViewed
});


$StoryUserEntityCopyWith<$Res> get user;

}
/// @nodoc
class _$StoryEntityCopyWithImpl<$Res>
    implements $StoryEntityCopyWith<$Res> {
  _$StoryEntityCopyWithImpl(this._self, this._then);

  final StoryEntity _self;
  final $Res Function(StoryEntity) _then;

/// Create a copy of StoryEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? imageUrl = null,Object? expiresAt = null,Object? createdAt = null,Object? user = null,Object? isViewed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as StoryUserEntity,isViewed: null == isViewed ? _self.isViewed : isViewed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of StoryEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StoryUserEntityCopyWith<$Res> get user {
  
  return $StoryUserEntityCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [StoryEntity].
extension StoryEntityPatterns on StoryEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoryEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoryEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoryEntity value)  $default,){
final _that = this;
switch (_that) {
case _StoryEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoryEntity value)?  $default,){
final _that = this;
switch (_that) {
case _StoryEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String imageUrl,  DateTime expiresAt,  DateTime createdAt,  StoryUserEntity user,  bool isViewed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryEntity() when $default != null:
return $default(_that.id,_that.userId,_that.imageUrl,_that.expiresAt,_that.createdAt,_that.user,_that.isViewed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String imageUrl,  DateTime expiresAt,  DateTime createdAt,  StoryUserEntity user,  bool isViewed)  $default,) {final _that = this;
switch (_that) {
case _StoryEntity():
return $default(_that.id,_that.userId,_that.imageUrl,_that.expiresAt,_that.createdAt,_that.user,_that.isViewed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String imageUrl,  DateTime expiresAt,  DateTime createdAt,  StoryUserEntity user,  bool isViewed)?  $default,) {final _that = this;
switch (_that) {
case _StoryEntity() when $default != null:
return $default(_that.id,_that.userId,_that.imageUrl,_that.expiresAt,_that.createdAt,_that.user,_that.isViewed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoryEntity extends StoryEntity {
  const _StoryEntity({required this.id, required this.userId, required this.imageUrl, required this.expiresAt, required this.createdAt, required this.user, this.isViewed = false}): super._();
  factory _StoryEntity.fromJson(Map<String, dynamic> json) => _$StoryEntityFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String imageUrl;
@override final  DateTime expiresAt;
@override final  DateTime createdAt;
@override final  StoryUserEntity user;
@override@JsonKey() final  bool isViewed;

/// Create a copy of StoryEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoryEntityCopyWith<_StoryEntity> get copyWith => __$StoryEntityCopyWithImpl<_StoryEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoryEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.isViewed, isViewed) || other.isViewed == isViewed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,imageUrl,expiresAt,createdAt,user,isViewed);

@override
String toString() {
  return 'StoryEntity(id: $id, userId: $userId, imageUrl: $imageUrl, expiresAt: $expiresAt, createdAt: $createdAt, user: $user, isViewed: $isViewed)';
}


}

/// @nodoc
abstract mixin class _$StoryEntityCopyWith<$Res> implements $StoryEntityCopyWith<$Res> {
  factory _$StoryEntityCopyWith(_StoryEntity value, $Res Function(_StoryEntity) _then) = __$StoryEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String imageUrl, DateTime expiresAt, DateTime createdAt, StoryUserEntity user, bool isViewed
});


@override $StoryUserEntityCopyWith<$Res> get user;

}
/// @nodoc
class __$StoryEntityCopyWithImpl<$Res>
    implements _$StoryEntityCopyWith<$Res> {
  __$StoryEntityCopyWithImpl(this._self, this._then);

  final _StoryEntity _self;
  final $Res Function(_StoryEntity) _then;

/// Create a copy of StoryEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? imageUrl = null,Object? expiresAt = null,Object? createdAt = null,Object? user = null,Object? isViewed = null,}) {
  return _then(_StoryEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as StoryUserEntity,isViewed: null == isViewed ? _self.isViewed : isViewed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of StoryEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StoryUserEntityCopyWith<$Res> get user {
  
  return $StoryUserEntityCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
