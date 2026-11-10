// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_posts_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserPostsState {

 List<PostEntity> get posts; bool get isLoading; String? get cursor; bool get hasMore;
/// Create a copy of UserPostsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPostsStateCopyWith<UserPostsState> get copyWith => _$UserPostsStateCopyWithImpl<UserPostsState>(this as UserPostsState, _$identity);

  /// Serializes this UserPostsState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPostsState&&const DeepCollectionEquality().equals(other.posts, posts)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(posts),isLoading,cursor,hasMore);

@override
String toString() {
  return 'UserPostsState(posts: $posts, isLoading: $isLoading, cursor: $cursor, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $UserPostsStateCopyWith<$Res>  {
  factory $UserPostsStateCopyWith(UserPostsState value, $Res Function(UserPostsState) _then) = _$UserPostsStateCopyWithImpl;
@useResult
$Res call({
 List<PostEntity> posts, bool isLoading, String? cursor, bool hasMore
});




}
/// @nodoc
class _$UserPostsStateCopyWithImpl<$Res>
    implements $UserPostsStateCopyWith<$Res> {
  _$UserPostsStateCopyWithImpl(this._self, this._then);

  final UserPostsState _self;
  final $Res Function(UserPostsState) _then;

/// Create a copy of UserPostsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? posts = null,Object? isLoading = null,Object? cursor = freezed,Object? hasMore = null,}) {
  return _then(_self.copyWith(
posts: null == posts ? _self.posts : posts // ignore: cast_nullable_to_non_nullable
as List<PostEntity>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserPostsState].
extension UserPostsStatePatterns on UserPostsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPostsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPostsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPostsState value)  $default,){
final _that = this;
switch (_that) {
case _UserPostsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPostsState value)?  $default,){
final _that = this;
switch (_that) {
case _UserPostsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PostEntity> posts,  bool isLoading,  String? cursor,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPostsState() when $default != null:
return $default(_that.posts,_that.isLoading,_that.cursor,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PostEntity> posts,  bool isLoading,  String? cursor,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _UserPostsState():
return $default(_that.posts,_that.isLoading,_that.cursor,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PostEntity> posts,  bool isLoading,  String? cursor,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _UserPostsState() when $default != null:
return $default(_that.posts,_that.isLoading,_that.cursor,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserPostsState implements UserPostsState {
  const _UserPostsState({final  List<PostEntity> posts = const [], this.isLoading = false, this.cursor, this.hasMore = true}): _posts = posts;
  factory _UserPostsState.fromJson(Map<String, dynamic> json) => _$UserPostsStateFromJson(json);

 final  List<PostEntity> _posts;
@override@JsonKey() List<PostEntity> get posts {
  if (_posts is EqualUnmodifiableListView) return _posts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_posts);
}

@override@JsonKey() final  bool isLoading;
@override final  String? cursor;
@override@JsonKey() final  bool hasMore;

/// Create a copy of UserPostsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPostsStateCopyWith<_UserPostsState> get copyWith => __$UserPostsStateCopyWithImpl<_UserPostsState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserPostsStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPostsState&&const DeepCollectionEquality().equals(other._posts, _posts)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_posts),isLoading,cursor,hasMore);

@override
String toString() {
  return 'UserPostsState(posts: $posts, isLoading: $isLoading, cursor: $cursor, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$UserPostsStateCopyWith<$Res> implements $UserPostsStateCopyWith<$Res> {
  factory _$UserPostsStateCopyWith(_UserPostsState value, $Res Function(_UserPostsState) _then) = __$UserPostsStateCopyWithImpl;
@override @useResult
$Res call({
 List<PostEntity> posts, bool isLoading, String? cursor, bool hasMore
});




}
/// @nodoc
class __$UserPostsStateCopyWithImpl<$Res>
    implements _$UserPostsStateCopyWith<$Res> {
  __$UserPostsStateCopyWithImpl(this._self, this._then);

  final _UserPostsState _self;
  final $Res Function(_UserPostsState) _then;

/// Create a copy of UserPostsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? posts = null,Object? isLoading = null,Object? cursor = freezed,Object? hasMore = null,}) {
  return _then(_UserPostsState(
posts: null == posts ? _self._posts : posts // ignore: cast_nullable_to_non_nullable
as List<PostEntity>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
