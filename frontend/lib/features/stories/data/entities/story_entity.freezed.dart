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
mixin _$StoryTextBlockEntity {

 String get id; String get text; double get x; double get y; double get scale; double get rotation; int get color; StoryTextStyle get style; int get zIndex;
/// Create a copy of StoryTextBlockEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryTextBlockEntityCopyWith<StoryTextBlockEntity> get copyWith => _$StoryTextBlockEntityCopyWithImpl<StoryTextBlockEntity>(this as StoryTextBlockEntity, _$identity);

  /// Serializes this StoryTextBlockEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryTextBlockEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.rotation, rotation) || other.rotation == rotation)&&(identical(other.color, color) || other.color == color)&&(identical(other.style, style) || other.style == style)&&(identical(other.zIndex, zIndex) || other.zIndex == zIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,x,y,scale,rotation,color,style,zIndex);

@override
String toString() {
  return 'StoryTextBlockEntity(id: $id, text: $text, x: $x, y: $y, scale: $scale, rotation: $rotation, color: $color, style: $style, zIndex: $zIndex)';
}


}

/// @nodoc
abstract mixin class $StoryTextBlockEntityCopyWith<$Res>  {
  factory $StoryTextBlockEntityCopyWith(StoryTextBlockEntity value, $Res Function(StoryTextBlockEntity) _then) = _$StoryTextBlockEntityCopyWithImpl;
@useResult
$Res call({
 String id, String text, double x, double y, double scale, double rotation, int color, StoryTextStyle style, int zIndex
});




}
/// @nodoc
class _$StoryTextBlockEntityCopyWithImpl<$Res>
    implements $StoryTextBlockEntityCopyWith<$Res> {
  _$StoryTextBlockEntityCopyWithImpl(this._self, this._then);

  final StoryTextBlockEntity _self;
  final $Res Function(StoryTextBlockEntity) _then;

/// Create a copy of StoryTextBlockEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? x = null,Object? y = null,Object? scale = null,Object? rotation = null,Object? color = null,Object? style = null,Object? zIndex = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as double,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as double,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as StoryTextStyle,zIndex: null == zIndex ? _self.zIndex : zIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StoryTextBlockEntity].
extension StoryTextBlockEntityPatterns on StoryTextBlockEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoryTextBlockEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoryTextBlockEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoryTextBlockEntity value)  $default,){
final _that = this;
switch (_that) {
case _StoryTextBlockEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoryTextBlockEntity value)?  $default,){
final _that = this;
switch (_that) {
case _StoryTextBlockEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  double x,  double y,  double scale,  double rotation,  int color,  StoryTextStyle style,  int zIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryTextBlockEntity() when $default != null:
return $default(_that.id,_that.text,_that.x,_that.y,_that.scale,_that.rotation,_that.color,_that.style,_that.zIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  double x,  double y,  double scale,  double rotation,  int color,  StoryTextStyle style,  int zIndex)  $default,) {final _that = this;
switch (_that) {
case _StoryTextBlockEntity():
return $default(_that.id,_that.text,_that.x,_that.y,_that.scale,_that.rotation,_that.color,_that.style,_that.zIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  double x,  double y,  double scale,  double rotation,  int color,  StoryTextStyle style,  int zIndex)?  $default,) {final _that = this;
switch (_that) {
case _StoryTextBlockEntity() when $default != null:
return $default(_that.id,_that.text,_that.x,_that.y,_that.scale,_that.rotation,_that.color,_that.style,_that.zIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoryTextBlockEntity implements StoryTextBlockEntity {
  const _StoryTextBlockEntity({required this.id, required this.text, required this.x, required this.y, required this.scale, required this.rotation, required this.color, required this.style, required this.zIndex});
  factory _StoryTextBlockEntity.fromJson(Map<String, dynamic> json) => _$StoryTextBlockEntityFromJson(json);

@override final  String id;
@override final  String text;
@override final  double x;
@override final  double y;
@override final  double scale;
@override final  double rotation;
@override final  int color;
@override final  StoryTextStyle style;
@override final  int zIndex;

/// Create a copy of StoryTextBlockEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoryTextBlockEntityCopyWith<_StoryTextBlockEntity> get copyWith => __$StoryTextBlockEntityCopyWithImpl<_StoryTextBlockEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoryTextBlockEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryTextBlockEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.rotation, rotation) || other.rotation == rotation)&&(identical(other.color, color) || other.color == color)&&(identical(other.style, style) || other.style == style)&&(identical(other.zIndex, zIndex) || other.zIndex == zIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,x,y,scale,rotation,color,style,zIndex);

@override
String toString() {
  return 'StoryTextBlockEntity(id: $id, text: $text, x: $x, y: $y, scale: $scale, rotation: $rotation, color: $color, style: $style, zIndex: $zIndex)';
}


}

/// @nodoc
abstract mixin class _$StoryTextBlockEntityCopyWith<$Res> implements $StoryTextBlockEntityCopyWith<$Res> {
  factory _$StoryTextBlockEntityCopyWith(_StoryTextBlockEntity value, $Res Function(_StoryTextBlockEntity) _then) = __$StoryTextBlockEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, double x, double y, double scale, double rotation, int color, StoryTextStyle style, int zIndex
});




}
/// @nodoc
class __$StoryTextBlockEntityCopyWithImpl<$Res>
    implements _$StoryTextBlockEntityCopyWith<$Res> {
  __$StoryTextBlockEntityCopyWithImpl(this._self, this._then);

  final _StoryTextBlockEntity _self;
  final $Res Function(_StoryTextBlockEntity) _then;

/// Create a copy of StoryTextBlockEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? x = null,Object? y = null,Object? scale = null,Object? rotation = null,Object? color = null,Object? style = null,Object? zIndex = null,}) {
  return _then(_StoryTextBlockEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as double,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as double,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as StoryTextStyle,zIndex: null == zIndex ? _self.zIndex : zIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


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

 String get id; String get userId; String get imageUrl; StoryMediaType get mediaType; StoryAudience get audience; String? get caption; List<StoryTextBlockEntity>? get textBlocks; DateTime get expiresAt; DateTime get createdAt; StoryUserEntity get user; bool get isViewed;
/// Create a copy of StoryEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryEntityCopyWith<StoryEntity> get copyWith => _$StoryEntityCopyWithImpl<StoryEntity>(this as StoryEntity, _$identity);

  /// Serializes this StoryEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other.textBlocks, textBlocks)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.isViewed, isViewed) || other.isViewed == isViewed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,imageUrl,mediaType,audience,caption,const DeepCollectionEquality().hash(textBlocks),expiresAt,createdAt,user,isViewed);

@override
String toString() {
  return 'StoryEntity(id: $id, userId: $userId, imageUrl: $imageUrl, mediaType: $mediaType, audience: $audience, caption: $caption, textBlocks: $textBlocks, expiresAt: $expiresAt, createdAt: $createdAt, user: $user, isViewed: $isViewed)';
}


}

/// @nodoc
abstract mixin class $StoryEntityCopyWith<$Res>  {
  factory $StoryEntityCopyWith(StoryEntity value, $Res Function(StoryEntity) _then) = _$StoryEntityCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String imageUrl, StoryMediaType mediaType, StoryAudience audience, String? caption, List<StoryTextBlockEntity>? textBlocks, DateTime expiresAt, DateTime createdAt, StoryUserEntity user, bool isViewed
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? imageUrl = null,Object? mediaType = null,Object? audience = null,Object? caption = freezed,Object? textBlocks = freezed,Object? expiresAt = null,Object? createdAt = null,Object? user = null,Object? isViewed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as StoryMediaType,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as StoryAudience,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,textBlocks: freezed == textBlocks ? _self.textBlocks : textBlocks // ignore: cast_nullable_to_non_nullable
as List<StoryTextBlockEntity>?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String imageUrl,  StoryMediaType mediaType,  StoryAudience audience,  String? caption,  List<StoryTextBlockEntity>? textBlocks,  DateTime expiresAt,  DateTime createdAt,  StoryUserEntity user,  bool isViewed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryEntity() when $default != null:
return $default(_that.id,_that.userId,_that.imageUrl,_that.mediaType,_that.audience,_that.caption,_that.textBlocks,_that.expiresAt,_that.createdAt,_that.user,_that.isViewed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String imageUrl,  StoryMediaType mediaType,  StoryAudience audience,  String? caption,  List<StoryTextBlockEntity>? textBlocks,  DateTime expiresAt,  DateTime createdAt,  StoryUserEntity user,  bool isViewed)  $default,) {final _that = this;
switch (_that) {
case _StoryEntity():
return $default(_that.id,_that.userId,_that.imageUrl,_that.mediaType,_that.audience,_that.caption,_that.textBlocks,_that.expiresAt,_that.createdAt,_that.user,_that.isViewed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String imageUrl,  StoryMediaType mediaType,  StoryAudience audience,  String? caption,  List<StoryTextBlockEntity>? textBlocks,  DateTime expiresAt,  DateTime createdAt,  StoryUserEntity user,  bool isViewed)?  $default,) {final _that = this;
switch (_that) {
case _StoryEntity() when $default != null:
return $default(_that.id,_that.userId,_that.imageUrl,_that.mediaType,_that.audience,_that.caption,_that.textBlocks,_that.expiresAt,_that.createdAt,_that.user,_that.isViewed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoryEntity extends StoryEntity {
  const _StoryEntity({required this.id, required this.userId, required this.imageUrl, this.mediaType = StoryMediaType.image, this.audience = StoryAudience.everyone, this.caption, final  List<StoryTextBlockEntity>? textBlocks, required this.expiresAt, required this.createdAt, required this.user, this.isViewed = false}): _textBlocks = textBlocks,super._();
  factory _StoryEntity.fromJson(Map<String, dynamic> json) => _$StoryEntityFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String imageUrl;
@override@JsonKey() final  StoryMediaType mediaType;
@override@JsonKey() final  StoryAudience audience;
@override final  String? caption;
 final  List<StoryTextBlockEntity>? _textBlocks;
@override List<StoryTextBlockEntity>? get textBlocks {
  final value = _textBlocks;
  if (value == null) return null;
  if (_textBlocks is EqualUnmodifiableListView) return _textBlocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other._textBlocks, _textBlocks)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.isViewed, isViewed) || other.isViewed == isViewed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,imageUrl,mediaType,audience,caption,const DeepCollectionEquality().hash(_textBlocks),expiresAt,createdAt,user,isViewed);

@override
String toString() {
  return 'StoryEntity(id: $id, userId: $userId, imageUrl: $imageUrl, mediaType: $mediaType, audience: $audience, caption: $caption, textBlocks: $textBlocks, expiresAt: $expiresAt, createdAt: $createdAt, user: $user, isViewed: $isViewed)';
}


}

/// @nodoc
abstract mixin class _$StoryEntityCopyWith<$Res> implements $StoryEntityCopyWith<$Res> {
  factory _$StoryEntityCopyWith(_StoryEntity value, $Res Function(_StoryEntity) _then) = __$StoryEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String imageUrl, StoryMediaType mediaType, StoryAudience audience, String? caption, List<StoryTextBlockEntity>? textBlocks, DateTime expiresAt, DateTime createdAt, StoryUserEntity user, bool isViewed
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? imageUrl = null,Object? mediaType = null,Object? audience = null,Object? caption = freezed,Object? textBlocks = freezed,Object? expiresAt = null,Object? createdAt = null,Object? user = null,Object? isViewed = null,}) {
  return _then(_StoryEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as StoryMediaType,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as StoryAudience,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,textBlocks: freezed == textBlocks ? _self._textBlocks : textBlocks // ignore: cast_nullable_to_non_nullable
as List<StoryTextBlockEntity>?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
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
