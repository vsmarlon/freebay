// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_provider_states.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedState {

 List<PostEntity> get posts; bool get isLoading; bool get isRefreshing; bool get isStale; bool get hasMore; String? get cursor; String? get error;
/// Create a copy of FeedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedStateCopyWith<FeedState> get copyWith => _$FeedStateCopyWithImpl<FeedState>(this as FeedState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedState&&const DeepCollectionEquality().equals(other.posts, posts)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(posts),isLoading,isRefreshing,isStale,hasMore,cursor,error);

@override
String toString() {
  return 'FeedState(posts: $posts, isLoading: $isLoading, isRefreshing: $isRefreshing, isStale: $isStale, hasMore: $hasMore, cursor: $cursor, error: $error)';
}


}

/// @nodoc
abstract mixin class $FeedStateCopyWith<$Res>  {
  factory $FeedStateCopyWith(FeedState value, $Res Function(FeedState) _then) = _$FeedStateCopyWithImpl;
@useResult
$Res call({
 List<PostEntity> posts, bool isLoading, bool isRefreshing, bool isStale, bool hasMore, String? cursor, String? error
});




}
/// @nodoc
class _$FeedStateCopyWithImpl<$Res>
    implements $FeedStateCopyWith<$Res> {
  _$FeedStateCopyWithImpl(this._self, this._then);

  final FeedState _self;
  final $Res Function(FeedState) _then;

/// Create a copy of FeedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? posts = null,Object? isLoading = null,Object? isRefreshing = null,Object? isStale = null,Object? hasMore = null,Object? cursor = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
posts: null == posts ? _self.posts : posts // ignore: cast_nullable_to_non_nullable
as List<PostEntity>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedState].
extension FeedStatePatterns on FeedState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedState value)  $default,){
final _that = this;
switch (_that) {
case _FeedState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedState value)?  $default,){
final _that = this;
switch (_that) {
case _FeedState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PostEntity> posts,  bool isLoading,  bool isRefreshing,  bool isStale,  bool hasMore,  String? cursor,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedState() when $default != null:
return $default(_that.posts,_that.isLoading,_that.isRefreshing,_that.isStale,_that.hasMore,_that.cursor,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PostEntity> posts,  bool isLoading,  bool isRefreshing,  bool isStale,  bool hasMore,  String? cursor,  String? error)  $default,) {final _that = this;
switch (_that) {
case _FeedState():
return $default(_that.posts,_that.isLoading,_that.isRefreshing,_that.isStale,_that.hasMore,_that.cursor,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PostEntity> posts,  bool isLoading,  bool isRefreshing,  bool isStale,  bool hasMore,  String? cursor,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _FeedState() when $default != null:
return $default(_that.posts,_that.isLoading,_that.isRefreshing,_that.isStale,_that.hasMore,_that.cursor,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _FeedState implements FeedState {
  const _FeedState({final  List<PostEntity> posts = const [], this.isLoading = false, this.isRefreshing = false, this.isStale = false, this.hasMore = true, this.cursor, this.error}): _posts = posts;
  

 final  List<PostEntity> _posts;
@override@JsonKey() List<PostEntity> get posts {
  if (_posts is EqualUnmodifiableListView) return _posts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_posts);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isRefreshing;
@override@JsonKey() final  bool isStale;
@override@JsonKey() final  bool hasMore;
@override final  String? cursor;
@override final  String? error;

/// Create a copy of FeedState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedStateCopyWith<_FeedState> get copyWith => __$FeedStateCopyWithImpl<_FeedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedState&&const DeepCollectionEquality().equals(other._posts, _posts)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_posts),isLoading,isRefreshing,isStale,hasMore,cursor,error);

@override
String toString() {
  return 'FeedState(posts: $posts, isLoading: $isLoading, isRefreshing: $isRefreshing, isStale: $isStale, hasMore: $hasMore, cursor: $cursor, error: $error)';
}


}

/// @nodoc
abstract mixin class _$FeedStateCopyWith<$Res> implements $FeedStateCopyWith<$Res> {
  factory _$FeedStateCopyWith(_FeedState value, $Res Function(_FeedState) _then) = __$FeedStateCopyWithImpl;
@override @useResult
$Res call({
 List<PostEntity> posts, bool isLoading, bool isRefreshing, bool isStale, bool hasMore, String? cursor, String? error
});




}
/// @nodoc
class __$FeedStateCopyWithImpl<$Res>
    implements _$FeedStateCopyWith<$Res> {
  __$FeedStateCopyWithImpl(this._self, this._then);

  final _FeedState _self;
  final $Res Function(_FeedState) _then;

/// Create a copy of FeedState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? posts = null,Object? isLoading = null,Object? isRefreshing = null,Object? isStale = null,Object? hasMore = null,Object? cursor = freezed,Object? error = freezed,}) {
  return _then(_FeedState(
posts: null == posts ? _self._posts : posts // ignore: cast_nullable_to_non_nullable
as List<PostEntity>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$LikesState {

 Map<String, bool> get likedOverrides; Map<String, int> get countOverrides;
/// Create a copy of LikesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LikesStateCopyWith<LikesState> get copyWith => _$LikesStateCopyWithImpl<LikesState>(this as LikesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LikesState&&const DeepCollectionEquality().equals(other.likedOverrides, likedOverrides)&&const DeepCollectionEquality().equals(other.countOverrides, countOverrides));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(likedOverrides),const DeepCollectionEquality().hash(countOverrides));

@override
String toString() {
  return 'LikesState(likedOverrides: $likedOverrides, countOverrides: $countOverrides)';
}


}

/// @nodoc
abstract mixin class $LikesStateCopyWith<$Res>  {
  factory $LikesStateCopyWith(LikesState value, $Res Function(LikesState) _then) = _$LikesStateCopyWithImpl;
@useResult
$Res call({
 Map<String, bool> likedOverrides, Map<String, int> countOverrides
});




}
/// @nodoc
class _$LikesStateCopyWithImpl<$Res>
    implements $LikesStateCopyWith<$Res> {
  _$LikesStateCopyWithImpl(this._self, this._then);

  final LikesState _self;
  final $Res Function(LikesState) _then;

/// Create a copy of LikesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? likedOverrides = null,Object? countOverrides = null,}) {
  return _then(_self.copyWith(
likedOverrides: null == likedOverrides ? _self.likedOverrides : likedOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,countOverrides: null == countOverrides ? _self.countOverrides : countOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [LikesState].
extension LikesStatePatterns on LikesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LikesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LikesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LikesState value)  $default,){
final _that = this;
switch (_that) {
case _LikesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LikesState value)?  $default,){
final _that = this;
switch (_that) {
case _LikesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, bool> likedOverrides,  Map<String, int> countOverrides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LikesState() when $default != null:
return $default(_that.likedOverrides,_that.countOverrides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, bool> likedOverrides,  Map<String, int> countOverrides)  $default,) {final _that = this;
switch (_that) {
case _LikesState():
return $default(_that.likedOverrides,_that.countOverrides);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, bool> likedOverrides,  Map<String, int> countOverrides)?  $default,) {final _that = this;
switch (_that) {
case _LikesState() when $default != null:
return $default(_that.likedOverrides,_that.countOverrides);case _:
  return null;

}
}

}

/// @nodoc


class _LikesState implements LikesState {
  const _LikesState({final  Map<String, bool> likedOverrides = const {}, final  Map<String, int> countOverrides = const {}}): _likedOverrides = likedOverrides,_countOverrides = countOverrides;
  

 final  Map<String, bool> _likedOverrides;
@override@JsonKey() Map<String, bool> get likedOverrides {
  if (_likedOverrides is EqualUnmodifiableMapView) return _likedOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_likedOverrides);
}

 final  Map<String, int> _countOverrides;
@override@JsonKey() Map<String, int> get countOverrides {
  if (_countOverrides is EqualUnmodifiableMapView) return _countOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_countOverrides);
}


/// Create a copy of LikesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LikesStateCopyWith<_LikesState> get copyWith => __$LikesStateCopyWithImpl<_LikesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LikesState&&const DeepCollectionEquality().equals(other._likedOverrides, _likedOverrides)&&const DeepCollectionEquality().equals(other._countOverrides, _countOverrides));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_likedOverrides),const DeepCollectionEquality().hash(_countOverrides));

@override
String toString() {
  return 'LikesState(likedOverrides: $likedOverrides, countOverrides: $countOverrides)';
}


}

/// @nodoc
abstract mixin class _$LikesStateCopyWith<$Res> implements $LikesStateCopyWith<$Res> {
  factory _$LikesStateCopyWith(_LikesState value, $Res Function(_LikesState) _then) = __$LikesStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, bool> likedOverrides, Map<String, int> countOverrides
});




}
/// @nodoc
class __$LikesStateCopyWithImpl<$Res>
    implements _$LikesStateCopyWith<$Res> {
  __$LikesStateCopyWithImpl(this._self, this._then);

  final _LikesState _self;
  final $Res Function(_LikesState) _then;

/// Create a copy of LikesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? likedOverrides = null,Object? countOverrides = null,}) {
  return _then(_LikesState(
likedOverrides: null == likedOverrides ? _self._likedOverrides : likedOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,countOverrides: null == countOverrides ? _self._countOverrides : countOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

/// @nodoc
mixin _$SavesState {

 Map<String, bool> get savedOverrides;
/// Create a copy of SavesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavesStateCopyWith<SavesState> get copyWith => _$SavesStateCopyWithImpl<SavesState>(this as SavesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavesState&&const DeepCollectionEquality().equals(other.savedOverrides, savedOverrides));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(savedOverrides));

@override
String toString() {
  return 'SavesState(savedOverrides: $savedOverrides)';
}


}

/// @nodoc
abstract mixin class $SavesStateCopyWith<$Res>  {
  factory $SavesStateCopyWith(SavesState value, $Res Function(SavesState) _then) = _$SavesStateCopyWithImpl;
@useResult
$Res call({
 Map<String, bool> savedOverrides
});




}
/// @nodoc
class _$SavesStateCopyWithImpl<$Res>
    implements $SavesStateCopyWith<$Res> {
  _$SavesStateCopyWithImpl(this._self, this._then);

  final SavesState _self;
  final $Res Function(SavesState) _then;

/// Create a copy of SavesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? savedOverrides = null,}) {
  return _then(_self.copyWith(
savedOverrides: null == savedOverrides ? _self.savedOverrides : savedOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}

}


/// Adds pattern-matching-related methods to [SavesState].
extension SavesStatePatterns on SavesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavesState value)  $default,){
final _that = this;
switch (_that) {
case _SavesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavesState value)?  $default,){
final _that = this;
switch (_that) {
case _SavesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, bool> savedOverrides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavesState() when $default != null:
return $default(_that.savedOverrides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, bool> savedOverrides)  $default,) {final _that = this;
switch (_that) {
case _SavesState():
return $default(_that.savedOverrides);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, bool> savedOverrides)?  $default,) {final _that = this;
switch (_that) {
case _SavesState() when $default != null:
return $default(_that.savedOverrides);case _:
  return null;

}
}

}

/// @nodoc


class _SavesState implements SavesState {
  const _SavesState({final  Map<String, bool> savedOverrides = const {}}): _savedOverrides = savedOverrides;
  

 final  Map<String, bool> _savedOverrides;
@override@JsonKey() Map<String, bool> get savedOverrides {
  if (_savedOverrides is EqualUnmodifiableMapView) return _savedOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_savedOverrides);
}


/// Create a copy of SavesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavesStateCopyWith<_SavesState> get copyWith => __$SavesStateCopyWithImpl<_SavesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavesState&&const DeepCollectionEquality().equals(other._savedOverrides, _savedOverrides));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_savedOverrides));

@override
String toString() {
  return 'SavesState(savedOverrides: $savedOverrides)';
}


}

/// @nodoc
abstract mixin class _$SavesStateCopyWith<$Res> implements $SavesStateCopyWith<$Res> {
  factory _$SavesStateCopyWith(_SavesState value, $Res Function(_SavesState) _then) = __$SavesStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, bool> savedOverrides
});




}
/// @nodoc
class __$SavesStateCopyWithImpl<$Res>
    implements _$SavesStateCopyWith<$Res> {
  __$SavesStateCopyWithImpl(this._self, this._then);

  final _SavesState _self;
  final $Res Function(_SavesState) _then;

/// Create a copy of SavesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? savedOverrides = null,}) {
  return _then(_SavesState(
savedOverrides: null == savedOverrides ? _self._savedOverrides : savedOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}


}

/// @nodoc
mixin _$RepostsState {

 Map<String, bool> get repostedOverrides; Map<String, int> get countOverrides;
/// Create a copy of RepostsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepostsStateCopyWith<RepostsState> get copyWith => _$RepostsStateCopyWithImpl<RepostsState>(this as RepostsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepostsState&&const DeepCollectionEquality().equals(other.repostedOverrides, repostedOverrides)&&const DeepCollectionEquality().equals(other.countOverrides, countOverrides));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(repostedOverrides),const DeepCollectionEquality().hash(countOverrides));

@override
String toString() {
  return 'RepostsState(repostedOverrides: $repostedOverrides, countOverrides: $countOverrides)';
}


}

/// @nodoc
abstract mixin class $RepostsStateCopyWith<$Res>  {
  factory $RepostsStateCopyWith(RepostsState value, $Res Function(RepostsState) _then) = _$RepostsStateCopyWithImpl;
@useResult
$Res call({
 Map<String, bool> repostedOverrides, Map<String, int> countOverrides
});




}
/// @nodoc
class _$RepostsStateCopyWithImpl<$Res>
    implements $RepostsStateCopyWith<$Res> {
  _$RepostsStateCopyWithImpl(this._self, this._then);

  final RepostsState _self;
  final $Res Function(RepostsState) _then;

/// Create a copy of RepostsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? repostedOverrides = null,Object? countOverrides = null,}) {
  return _then(_self.copyWith(
repostedOverrides: null == repostedOverrides ? _self.repostedOverrides : repostedOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,countOverrides: null == countOverrides ? _self.countOverrides : countOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [RepostsState].
extension RepostsStatePatterns on RepostsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RepostsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RepostsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RepostsState value)  $default,){
final _that = this;
switch (_that) {
case _RepostsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RepostsState value)?  $default,){
final _that = this;
switch (_that) {
case _RepostsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, bool> repostedOverrides,  Map<String, int> countOverrides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RepostsState() when $default != null:
return $default(_that.repostedOverrides,_that.countOverrides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, bool> repostedOverrides,  Map<String, int> countOverrides)  $default,) {final _that = this;
switch (_that) {
case _RepostsState():
return $default(_that.repostedOverrides,_that.countOverrides);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, bool> repostedOverrides,  Map<String, int> countOverrides)?  $default,) {final _that = this;
switch (_that) {
case _RepostsState() when $default != null:
return $default(_that.repostedOverrides,_that.countOverrides);case _:
  return null;

}
}

}

/// @nodoc


class _RepostsState implements RepostsState {
  const _RepostsState({final  Map<String, bool> repostedOverrides = const {}, final  Map<String, int> countOverrides = const {}}): _repostedOverrides = repostedOverrides,_countOverrides = countOverrides;
  

 final  Map<String, bool> _repostedOverrides;
@override@JsonKey() Map<String, bool> get repostedOverrides {
  if (_repostedOverrides is EqualUnmodifiableMapView) return _repostedOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_repostedOverrides);
}

 final  Map<String, int> _countOverrides;
@override@JsonKey() Map<String, int> get countOverrides {
  if (_countOverrides is EqualUnmodifiableMapView) return _countOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_countOverrides);
}


/// Create a copy of RepostsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepostsStateCopyWith<_RepostsState> get copyWith => __$RepostsStateCopyWithImpl<_RepostsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepostsState&&const DeepCollectionEquality().equals(other._repostedOverrides, _repostedOverrides)&&const DeepCollectionEquality().equals(other._countOverrides, _countOverrides));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_repostedOverrides),const DeepCollectionEquality().hash(_countOverrides));

@override
String toString() {
  return 'RepostsState(repostedOverrides: $repostedOverrides, countOverrides: $countOverrides)';
}


}

/// @nodoc
abstract mixin class _$RepostsStateCopyWith<$Res> implements $RepostsStateCopyWith<$Res> {
  factory _$RepostsStateCopyWith(_RepostsState value, $Res Function(_RepostsState) _then) = __$RepostsStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, bool> repostedOverrides, Map<String, int> countOverrides
});




}
/// @nodoc
class __$RepostsStateCopyWithImpl<$Res>
    implements _$RepostsStateCopyWith<$Res> {
  __$RepostsStateCopyWithImpl(this._self, this._then);

  final _RepostsState _self;
  final $Res Function(_RepostsState) _then;

/// Create a copy of RepostsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? repostedOverrides = null,Object? countOverrides = null,}) {
  return _then(_RepostsState(
repostedOverrides: null == repostedOverrides ? _self._repostedOverrides : repostedOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,countOverrides: null == countOverrides ? _self._countOverrides : countOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

/// @nodoc
mixin _$CommentLikesState {

 Map<String, bool> get likedOverrides; Map<String, int> get countOverrides;
/// Create a copy of CommentLikesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentLikesStateCopyWith<CommentLikesState> get copyWith => _$CommentLikesStateCopyWithImpl<CommentLikesState>(this as CommentLikesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentLikesState&&const DeepCollectionEquality().equals(other.likedOverrides, likedOverrides)&&const DeepCollectionEquality().equals(other.countOverrides, countOverrides));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(likedOverrides),const DeepCollectionEquality().hash(countOverrides));

@override
String toString() {
  return 'CommentLikesState(likedOverrides: $likedOverrides, countOverrides: $countOverrides)';
}


}

/// @nodoc
abstract mixin class $CommentLikesStateCopyWith<$Res>  {
  factory $CommentLikesStateCopyWith(CommentLikesState value, $Res Function(CommentLikesState) _then) = _$CommentLikesStateCopyWithImpl;
@useResult
$Res call({
 Map<String, bool> likedOverrides, Map<String, int> countOverrides
});




}
/// @nodoc
class _$CommentLikesStateCopyWithImpl<$Res>
    implements $CommentLikesStateCopyWith<$Res> {
  _$CommentLikesStateCopyWithImpl(this._self, this._then);

  final CommentLikesState _self;
  final $Res Function(CommentLikesState) _then;

/// Create a copy of CommentLikesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? likedOverrides = null,Object? countOverrides = null,}) {
  return _then(_self.copyWith(
likedOverrides: null == likedOverrides ? _self.likedOverrides : likedOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,countOverrides: null == countOverrides ? _self.countOverrides : countOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentLikesState].
extension CommentLikesStatePatterns on CommentLikesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentLikesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentLikesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentLikesState value)  $default,){
final _that = this;
switch (_that) {
case _CommentLikesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentLikesState value)?  $default,){
final _that = this;
switch (_that) {
case _CommentLikesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, bool> likedOverrides,  Map<String, int> countOverrides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentLikesState() when $default != null:
return $default(_that.likedOverrides,_that.countOverrides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, bool> likedOverrides,  Map<String, int> countOverrides)  $default,) {final _that = this;
switch (_that) {
case _CommentLikesState():
return $default(_that.likedOverrides,_that.countOverrides);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, bool> likedOverrides,  Map<String, int> countOverrides)?  $default,) {final _that = this;
switch (_that) {
case _CommentLikesState() when $default != null:
return $default(_that.likedOverrides,_that.countOverrides);case _:
  return null;

}
}

}

/// @nodoc


class _CommentLikesState implements CommentLikesState {
  const _CommentLikesState({final  Map<String, bool> likedOverrides = const {}, final  Map<String, int> countOverrides = const {}}): _likedOverrides = likedOverrides,_countOverrides = countOverrides;
  

 final  Map<String, bool> _likedOverrides;
@override@JsonKey() Map<String, bool> get likedOverrides {
  if (_likedOverrides is EqualUnmodifiableMapView) return _likedOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_likedOverrides);
}

 final  Map<String, int> _countOverrides;
@override@JsonKey() Map<String, int> get countOverrides {
  if (_countOverrides is EqualUnmodifiableMapView) return _countOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_countOverrides);
}


/// Create a copy of CommentLikesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentLikesStateCopyWith<_CommentLikesState> get copyWith => __$CommentLikesStateCopyWithImpl<_CommentLikesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentLikesState&&const DeepCollectionEquality().equals(other._likedOverrides, _likedOverrides)&&const DeepCollectionEquality().equals(other._countOverrides, _countOverrides));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_likedOverrides),const DeepCollectionEquality().hash(_countOverrides));

@override
String toString() {
  return 'CommentLikesState(likedOverrides: $likedOverrides, countOverrides: $countOverrides)';
}


}

/// @nodoc
abstract mixin class _$CommentLikesStateCopyWith<$Res> implements $CommentLikesStateCopyWith<$Res> {
  factory _$CommentLikesStateCopyWith(_CommentLikesState value, $Res Function(_CommentLikesState) _then) = __$CommentLikesStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, bool> likedOverrides, Map<String, int> countOverrides
});




}
/// @nodoc
class __$CommentLikesStateCopyWithImpl<$Res>
    implements _$CommentLikesStateCopyWith<$Res> {
  __$CommentLikesStateCopyWithImpl(this._self, this._then);

  final _CommentLikesState _self;
  final $Res Function(_CommentLikesState) _then;

/// Create a copy of CommentLikesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? likedOverrides = null,Object? countOverrides = null,}) {
  return _then(_CommentLikesState(
likedOverrides: null == likedOverrides ? _self._likedOverrides : likedOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,countOverrides: null == countOverrides ? _self._countOverrides : countOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
