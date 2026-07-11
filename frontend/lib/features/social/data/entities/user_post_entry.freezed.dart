// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_post_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserPostEntry {

 PostEntity get post; DateTime? get repostedAt; UserEntity? get repostedBy; bool get isReposted; int? get sharesCount;
/// Create a copy of UserPostEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPostEntryCopyWith<UserPostEntry> get copyWith => _$UserPostEntryCopyWithImpl<UserPostEntry>(this as UserPostEntry, _$identity);

  /// Serializes this UserPostEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPostEntry&&(identical(other.post, post) || other.post == post)&&(identical(other.repostedAt, repostedAt) || other.repostedAt == repostedAt)&&(identical(other.repostedBy, repostedBy) || other.repostedBy == repostedBy)&&(identical(other.isReposted, isReposted) || other.isReposted == isReposted)&&(identical(other.sharesCount, sharesCount) || other.sharesCount == sharesCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,post,repostedAt,repostedBy,isReposted,sharesCount);

@override
String toString() {
  return 'UserPostEntry(post: $post, repostedAt: $repostedAt, repostedBy: $repostedBy, isReposted: $isReposted, sharesCount: $sharesCount)';
}


}

/// @nodoc
abstract mixin class $UserPostEntryCopyWith<$Res>  {
  factory $UserPostEntryCopyWith(UserPostEntry value, $Res Function(UserPostEntry) _then) = _$UserPostEntryCopyWithImpl;
@useResult
$Res call({
 PostEntity post, DateTime? repostedAt, UserEntity? repostedBy, bool isReposted, int? sharesCount
});


$PostEntityCopyWith<$Res> get post;$UserEntityCopyWith<$Res>? get repostedBy;

}
/// @nodoc
class _$UserPostEntryCopyWithImpl<$Res>
    implements $UserPostEntryCopyWith<$Res> {
  _$UserPostEntryCopyWithImpl(this._self, this._then);

  final UserPostEntry _self;
  final $Res Function(UserPostEntry) _then;

/// Create a copy of UserPostEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? post = null,Object? repostedAt = freezed,Object? repostedBy = freezed,Object? isReposted = null,Object? sharesCount = freezed,}) {
  return _then(_self.copyWith(
post: null == post ? _self.post : post // ignore: cast_nullable_to_non_nullable
as PostEntity,repostedAt: freezed == repostedAt ? _self.repostedAt : repostedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,repostedBy: freezed == repostedBy ? _self.repostedBy : repostedBy // ignore: cast_nullable_to_non_nullable
as UserEntity?,isReposted: null == isReposted ? _self.isReposted : isReposted // ignore: cast_nullable_to_non_nullable
as bool,sharesCount: freezed == sharesCount ? _self.sharesCount : sharesCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of UserPostEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PostEntityCopyWith<$Res> get post {
  
  return $PostEntityCopyWith<$Res>(_self.post, (value) {
    return _then(_self.copyWith(post: value));
  });
}/// Create a copy of UserPostEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res>? get repostedBy {
    if (_self.repostedBy == null) {
    return null;
  }

  return $UserEntityCopyWith<$Res>(_self.repostedBy!, (value) {
    return _then(_self.copyWith(repostedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserPostEntry].
extension UserPostEntryPatterns on UserPostEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPostEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPostEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPostEntry value)  $default,){
final _that = this;
switch (_that) {
case _UserPostEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPostEntry value)?  $default,){
final _that = this;
switch (_that) {
case _UserPostEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PostEntity post,  DateTime? repostedAt,  UserEntity? repostedBy,  bool isReposted,  int? sharesCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPostEntry() when $default != null:
return $default(_that.post,_that.repostedAt,_that.repostedBy,_that.isReposted,_that.sharesCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PostEntity post,  DateTime? repostedAt,  UserEntity? repostedBy,  bool isReposted,  int? sharesCount)  $default,) {final _that = this;
switch (_that) {
case _UserPostEntry():
return $default(_that.post,_that.repostedAt,_that.repostedBy,_that.isReposted,_that.sharesCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PostEntity post,  DateTime? repostedAt,  UserEntity? repostedBy,  bool isReposted,  int? sharesCount)?  $default,) {final _that = this;
switch (_that) {
case _UserPostEntry() when $default != null:
return $default(_that.post,_that.repostedAt,_that.repostedBy,_that.isReposted,_that.sharesCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserPostEntry extends UserPostEntry {
  const _UserPostEntry({required this.post, this.repostedAt, this.repostedBy, this.isReposted = false, this.sharesCount}): super._();
  factory _UserPostEntry.fromJson(Map<String, dynamic> json) => _$UserPostEntryFromJson(json);

@override final  PostEntity post;
@override final  DateTime? repostedAt;
@override final  UserEntity? repostedBy;
@override@JsonKey() final  bool isReposted;
@override final  int? sharesCount;

/// Create a copy of UserPostEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPostEntryCopyWith<_UserPostEntry> get copyWith => __$UserPostEntryCopyWithImpl<_UserPostEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserPostEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPostEntry&&(identical(other.post, post) || other.post == post)&&(identical(other.repostedAt, repostedAt) || other.repostedAt == repostedAt)&&(identical(other.repostedBy, repostedBy) || other.repostedBy == repostedBy)&&(identical(other.isReposted, isReposted) || other.isReposted == isReposted)&&(identical(other.sharesCount, sharesCount) || other.sharesCount == sharesCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,post,repostedAt,repostedBy,isReposted,sharesCount);

@override
String toString() {
  return 'UserPostEntry(post: $post, repostedAt: $repostedAt, repostedBy: $repostedBy, isReposted: $isReposted, sharesCount: $sharesCount)';
}


}

/// @nodoc
abstract mixin class _$UserPostEntryCopyWith<$Res> implements $UserPostEntryCopyWith<$Res> {
  factory _$UserPostEntryCopyWith(_UserPostEntry value, $Res Function(_UserPostEntry) _then) = __$UserPostEntryCopyWithImpl;
@override @useResult
$Res call({
 PostEntity post, DateTime? repostedAt, UserEntity? repostedBy, bool isReposted, int? sharesCount
});


@override $PostEntityCopyWith<$Res> get post;@override $UserEntityCopyWith<$Res>? get repostedBy;

}
/// @nodoc
class __$UserPostEntryCopyWithImpl<$Res>
    implements _$UserPostEntryCopyWith<$Res> {
  __$UserPostEntryCopyWithImpl(this._self, this._then);

  final _UserPostEntry _self;
  final $Res Function(_UserPostEntry) _then;

/// Create a copy of UserPostEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? post = null,Object? repostedAt = freezed,Object? repostedBy = freezed,Object? isReposted = null,Object? sharesCount = freezed,}) {
  return _then(_UserPostEntry(
post: null == post ? _self.post : post // ignore: cast_nullable_to_non_nullable
as PostEntity,repostedAt: freezed == repostedAt ? _self.repostedAt : repostedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,repostedBy: freezed == repostedBy ? _self.repostedBy : repostedBy // ignore: cast_nullable_to_non_nullable
as UserEntity?,isReposted: null == isReposted ? _self.isReposted : isReposted // ignore: cast_nullable_to_non_nullable
as bool,sharesCount: freezed == sharesCount ? _self.sharesCount : sharesCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of UserPostEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PostEntityCopyWith<$Res> get post {
  
  return $PostEntityCopyWith<$Res>(_self.post, (value) {
    return _then(_self.copyWith(post: value));
  });
}/// Create a copy of UserPostEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res>? get repostedBy {
    if (_self.repostedBy == null) {
    return null;
  }

  return $UserEntityCopyWith<$Res>(_self.repostedBy!, (value) {
    return _then(_self.copyWith(repostedBy: value));
  });
}
}

// dart format on
