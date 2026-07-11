// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_list_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReviewListResponse {

 List<ReviewEntity> get reviews; int get total; int get limit; int get offset;
/// Create a copy of ReviewListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewListResponseCopyWith<ReviewListResponse> get copyWith => _$ReviewListResponseCopyWithImpl<ReviewListResponse>(this as ReviewListResponse, _$identity);

  /// Serializes this ReviewListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewListResponse&&const DeepCollectionEquality().equals(other.reviews, reviews)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(reviews),total,limit,offset);

@override
String toString() {
  return 'ReviewListResponse(reviews: $reviews, total: $total, limit: $limit, offset: $offset)';
}


}

/// @nodoc
abstract mixin class $ReviewListResponseCopyWith<$Res>  {
  factory $ReviewListResponseCopyWith(ReviewListResponse value, $Res Function(ReviewListResponse) _then) = _$ReviewListResponseCopyWithImpl;
@useResult
$Res call({
 List<ReviewEntity> reviews, int total, int limit, int offset
});




}
/// @nodoc
class _$ReviewListResponseCopyWithImpl<$Res>
    implements $ReviewListResponseCopyWith<$Res> {
  _$ReviewListResponseCopyWithImpl(this._self, this._then);

  final ReviewListResponse _self;
  final $Res Function(ReviewListResponse) _then;

/// Create a copy of ReviewListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reviews = null,Object? total = null,Object? limit = null,Object? offset = null,}) {
  return _then(_self.copyWith(
reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as List<ReviewEntity>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewListResponse].
extension ReviewListResponsePatterns on ReviewListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewListResponse value)  $default,){
final _that = this;
switch (_that) {
case _ReviewListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ReviewEntity> reviews,  int total,  int limit,  int offset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewListResponse() when $default != null:
return $default(_that.reviews,_that.total,_that.limit,_that.offset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ReviewEntity> reviews,  int total,  int limit,  int offset)  $default,) {final _that = this;
switch (_that) {
case _ReviewListResponse():
return $default(_that.reviews,_that.total,_that.limit,_that.offset);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ReviewEntity> reviews,  int total,  int limit,  int offset)?  $default,) {final _that = this;
switch (_that) {
case _ReviewListResponse() when $default != null:
return $default(_that.reviews,_that.total,_that.limit,_that.offset);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewListResponse extends ReviewListResponse {
  const _ReviewListResponse({required final  List<ReviewEntity> reviews, required this.total, required this.limit, required this.offset}): _reviews = reviews,super._();
  factory _ReviewListResponse.fromJson(Map<String, dynamic> json) => _$ReviewListResponseFromJson(json);

 final  List<ReviewEntity> _reviews;
@override List<ReviewEntity> get reviews {
  if (_reviews is EqualUnmodifiableListView) return _reviews;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reviews);
}

@override final  int total;
@override final  int limit;
@override final  int offset;

/// Create a copy of ReviewListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewListResponseCopyWith<_ReviewListResponse> get copyWith => __$ReviewListResponseCopyWithImpl<_ReviewListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewListResponse&&const DeepCollectionEquality().equals(other._reviews, _reviews)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_reviews),total,limit,offset);

@override
String toString() {
  return 'ReviewListResponse(reviews: $reviews, total: $total, limit: $limit, offset: $offset)';
}


}

/// @nodoc
abstract mixin class _$ReviewListResponseCopyWith<$Res> implements $ReviewListResponseCopyWith<$Res> {
  factory _$ReviewListResponseCopyWith(_ReviewListResponse value, $Res Function(_ReviewListResponse) _then) = __$ReviewListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<ReviewEntity> reviews, int total, int limit, int offset
});




}
/// @nodoc
class __$ReviewListResponseCopyWithImpl<$Res>
    implements _$ReviewListResponseCopyWith<$Res> {
  __$ReviewListResponseCopyWithImpl(this._self, this._then);

  final _ReviewListResponse _self;
  final $Res Function(_ReviewListResponse) _then;

/// Create a copy of ReviewListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reviews = null,Object? total = null,Object? limit = null,Object? offset = null,}) {
  return _then(_ReviewListResponse(
reviews: null == reviews ? _self._reviews : reviews // ignore: cast_nullable_to_non_nullable
as List<ReviewEntity>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
