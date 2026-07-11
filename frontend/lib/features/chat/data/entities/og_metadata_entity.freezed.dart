// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'og_metadata_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OgMetadataEntity {

 String? get title; String? get description; String? get imageUrl; String? get siteName; String get url;
/// Create a copy of OgMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OgMetadataEntityCopyWith<OgMetadataEntity> get copyWith => _$OgMetadataEntityCopyWithImpl<OgMetadataEntity>(this as OgMetadataEntity, _$identity);

  /// Serializes this OgMetadataEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OgMetadataEntity&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.siteName, siteName) || other.siteName == siteName)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,imageUrl,siteName,url);

@override
String toString() {
  return 'OgMetadataEntity(title: $title, description: $description, imageUrl: $imageUrl, siteName: $siteName, url: $url)';
}


}

/// @nodoc
abstract mixin class $OgMetadataEntityCopyWith<$Res>  {
  factory $OgMetadataEntityCopyWith(OgMetadataEntity value, $Res Function(OgMetadataEntity) _then) = _$OgMetadataEntityCopyWithImpl;
@useResult
$Res call({
 String? title, String? description, String? imageUrl, String? siteName, String url
});




}
/// @nodoc
class _$OgMetadataEntityCopyWithImpl<$Res>
    implements $OgMetadataEntityCopyWith<$Res> {
  _$OgMetadataEntityCopyWithImpl(this._self, this._then);

  final OgMetadataEntity _self;
  final $Res Function(OgMetadataEntity) _then;

/// Create a copy of OgMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? description = freezed,Object? imageUrl = freezed,Object? siteName = freezed,Object? url = null,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,siteName: freezed == siteName ? _self.siteName : siteName // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OgMetadataEntity].
extension OgMetadataEntityPatterns on OgMetadataEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OgMetadataEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OgMetadataEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OgMetadataEntity value)  $default,){
final _that = this;
switch (_that) {
case _OgMetadataEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OgMetadataEntity value)?  $default,){
final _that = this;
switch (_that) {
case _OgMetadataEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? description,  String? imageUrl,  String? siteName,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OgMetadataEntity() when $default != null:
return $default(_that.title,_that.description,_that.imageUrl,_that.siteName,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? description,  String? imageUrl,  String? siteName,  String url)  $default,) {final _that = this;
switch (_that) {
case _OgMetadataEntity():
return $default(_that.title,_that.description,_that.imageUrl,_that.siteName,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? description,  String? imageUrl,  String? siteName,  String url)?  $default,) {final _that = this;
switch (_that) {
case _OgMetadataEntity() when $default != null:
return $default(_that.title,_that.description,_that.imageUrl,_that.siteName,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OgMetadataEntity implements OgMetadataEntity {
  const _OgMetadataEntity({this.title, this.description, this.imageUrl, this.siteName, required this.url});
  factory _OgMetadataEntity.fromJson(Map<String, dynamic> json) => _$OgMetadataEntityFromJson(json);

@override final  String? title;
@override final  String? description;
@override final  String? imageUrl;
@override final  String? siteName;
@override final  String url;

/// Create a copy of OgMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OgMetadataEntityCopyWith<_OgMetadataEntity> get copyWith => __$OgMetadataEntityCopyWithImpl<_OgMetadataEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OgMetadataEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OgMetadataEntity&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.siteName, siteName) || other.siteName == siteName)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,imageUrl,siteName,url);

@override
String toString() {
  return 'OgMetadataEntity(title: $title, description: $description, imageUrl: $imageUrl, siteName: $siteName, url: $url)';
}


}

/// @nodoc
abstract mixin class _$OgMetadataEntityCopyWith<$Res> implements $OgMetadataEntityCopyWith<$Res> {
  factory _$OgMetadataEntityCopyWith(_OgMetadataEntity value, $Res Function(_OgMetadataEntity) _then) = __$OgMetadataEntityCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? description, String? imageUrl, String? siteName, String url
});




}
/// @nodoc
class __$OgMetadataEntityCopyWithImpl<$Res>
    implements _$OgMetadataEntityCopyWith<$Res> {
  __$OgMetadataEntityCopyWithImpl(this._self, this._then);

  final _OgMetadataEntity _self;
  final $Res Function(_OgMetadataEntity) _then;

/// Create a copy of OgMetadataEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? description = freezed,Object? imageUrl = freezed,Object? siteName = freezed,Object? url = null,}) {
  return _then(_OgMetadataEntity(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,siteName: freezed == siteName ? _self.siteName : siteName // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
