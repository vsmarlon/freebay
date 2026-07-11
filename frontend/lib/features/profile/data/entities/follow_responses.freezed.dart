// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow_responses.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FollowResponse {

 bool get following; int get followersCount; int get followingCount;
/// Create a copy of FollowResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowResponseCopyWith<FollowResponse> get copyWith => _$FollowResponseCopyWithImpl<FollowResponse>(this as FollowResponse, _$identity);

  /// Serializes this FollowResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowResponse&&(identical(other.following, following) || other.following == following)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,following,followersCount,followingCount);

@override
String toString() {
  return 'FollowResponse(following: $following, followersCount: $followersCount, followingCount: $followingCount)';
}


}

/// @nodoc
abstract mixin class $FollowResponseCopyWith<$Res>  {
  factory $FollowResponseCopyWith(FollowResponse value, $Res Function(FollowResponse) _then) = _$FollowResponseCopyWithImpl;
@useResult
$Res call({
 bool following, int followersCount, int followingCount
});




}
/// @nodoc
class _$FollowResponseCopyWithImpl<$Res>
    implements $FollowResponseCopyWith<$Res> {
  _$FollowResponseCopyWithImpl(this._self, this._then);

  final FollowResponse _self;
  final $Res Function(FollowResponse) _then;

/// Create a copy of FollowResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? following = null,Object? followersCount = null,Object? followingCount = null,}) {
  return _then(_self.copyWith(
following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as bool,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowResponse].
extension FollowResponsePatterns on FollowResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowResponse value)  $default,){
final _that = this;
switch (_that) {
case _FollowResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowResponse value)?  $default,){
final _that = this;
switch (_that) {
case _FollowResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool following,  int followersCount,  int followingCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowResponse() when $default != null:
return $default(_that.following,_that.followersCount,_that.followingCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool following,  int followersCount,  int followingCount)  $default,) {final _that = this;
switch (_that) {
case _FollowResponse():
return $default(_that.following,_that.followersCount,_that.followingCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool following,  int followersCount,  int followingCount)?  $default,) {final _that = this;
switch (_that) {
case _FollowResponse() when $default != null:
return $default(_that.following,_that.followersCount,_that.followingCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowResponse implements FollowResponse {
  const _FollowResponse({required this.following, required this.followersCount, required this.followingCount});
  factory _FollowResponse.fromJson(Map<String, dynamic> json) => _$FollowResponseFromJson(json);

@override final  bool following;
@override final  int followersCount;
@override final  int followingCount;

/// Create a copy of FollowResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowResponseCopyWith<_FollowResponse> get copyWith => __$FollowResponseCopyWithImpl<_FollowResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowResponse&&(identical(other.following, following) || other.following == following)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,following,followersCount,followingCount);

@override
String toString() {
  return 'FollowResponse(following: $following, followersCount: $followersCount, followingCount: $followingCount)';
}


}

/// @nodoc
abstract mixin class _$FollowResponseCopyWith<$Res> implements $FollowResponseCopyWith<$Res> {
  factory _$FollowResponseCopyWith(_FollowResponse value, $Res Function(_FollowResponse) _then) = __$FollowResponseCopyWithImpl;
@override @useResult
$Res call({
 bool following, int followersCount, int followingCount
});




}
/// @nodoc
class __$FollowResponseCopyWithImpl<$Res>
    implements _$FollowResponseCopyWith<$Res> {
  __$FollowResponseCopyWithImpl(this._self, this._then);

  final _FollowResponse _self;
  final $Res Function(_FollowResponse) _then;

/// Create a copy of FollowResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? following = null,Object? followersCount = null,Object? followingCount = null,}) {
  return _then(_FollowResponse(
following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as bool,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$FollowStatusResponse {

 bool get isFollowing; int get followersCount; int get followingCount;
/// Create a copy of FollowStatusResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowStatusResponseCopyWith<FollowStatusResponse> get copyWith => _$FollowStatusResponseCopyWithImpl<FollowStatusResponse>(this as FollowStatusResponse, _$identity);

  /// Serializes this FollowStatusResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowStatusResponse&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isFollowing,followersCount,followingCount);

@override
String toString() {
  return 'FollowStatusResponse(isFollowing: $isFollowing, followersCount: $followersCount, followingCount: $followingCount)';
}


}

/// @nodoc
abstract mixin class $FollowStatusResponseCopyWith<$Res>  {
  factory $FollowStatusResponseCopyWith(FollowStatusResponse value, $Res Function(FollowStatusResponse) _then) = _$FollowStatusResponseCopyWithImpl;
@useResult
$Res call({
 bool isFollowing, int followersCount, int followingCount
});




}
/// @nodoc
class _$FollowStatusResponseCopyWithImpl<$Res>
    implements $FollowStatusResponseCopyWith<$Res> {
  _$FollowStatusResponseCopyWithImpl(this._self, this._then);

  final FollowStatusResponse _self;
  final $Res Function(FollowStatusResponse) _then;

/// Create a copy of FollowStatusResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isFollowing = null,Object? followersCount = null,Object? followingCount = null,}) {
  return _then(_self.copyWith(
isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowStatusResponse].
extension FollowStatusResponsePatterns on FollowStatusResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowStatusResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowStatusResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowStatusResponse value)  $default,){
final _that = this;
switch (_that) {
case _FollowStatusResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowStatusResponse value)?  $default,){
final _that = this;
switch (_that) {
case _FollowStatusResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isFollowing,  int followersCount,  int followingCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowStatusResponse() when $default != null:
return $default(_that.isFollowing,_that.followersCount,_that.followingCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isFollowing,  int followersCount,  int followingCount)  $default,) {final _that = this;
switch (_that) {
case _FollowStatusResponse():
return $default(_that.isFollowing,_that.followersCount,_that.followingCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isFollowing,  int followersCount,  int followingCount)?  $default,) {final _that = this;
switch (_that) {
case _FollowStatusResponse() when $default != null:
return $default(_that.isFollowing,_that.followersCount,_that.followingCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowStatusResponse implements FollowStatusResponse {
  const _FollowStatusResponse({required this.isFollowing, required this.followersCount, required this.followingCount});
  factory _FollowStatusResponse.fromJson(Map<String, dynamic> json) => _$FollowStatusResponseFromJson(json);

@override final  bool isFollowing;
@override final  int followersCount;
@override final  int followingCount;

/// Create a copy of FollowStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowStatusResponseCopyWith<_FollowStatusResponse> get copyWith => __$FollowStatusResponseCopyWithImpl<_FollowStatusResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowStatusResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowStatusResponse&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isFollowing,followersCount,followingCount);

@override
String toString() {
  return 'FollowStatusResponse(isFollowing: $isFollowing, followersCount: $followersCount, followingCount: $followingCount)';
}


}

/// @nodoc
abstract mixin class _$FollowStatusResponseCopyWith<$Res> implements $FollowStatusResponseCopyWith<$Res> {
  factory _$FollowStatusResponseCopyWith(_FollowStatusResponse value, $Res Function(_FollowStatusResponse) _then) = __$FollowStatusResponseCopyWithImpl;
@override @useResult
$Res call({
 bool isFollowing, int followersCount, int followingCount
});




}
/// @nodoc
class __$FollowStatusResponseCopyWithImpl<$Res>
    implements _$FollowStatusResponseCopyWith<$Res> {
  __$FollowStatusResponseCopyWithImpl(this._self, this._then);

  final _FollowStatusResponse _self;
  final $Res Function(_FollowStatusResponse) _then;

/// Create a copy of FollowStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isFollowing = null,Object? followersCount = null,Object? followingCount = null,}) {
  return _then(_FollowStatusResponse(
isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$FollowListUser {

 String get id; String get displayName; String? get avatarUrl; bool get isVerified; double get reputationScore;
/// Create a copy of FollowListUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowListUserCopyWith<FollowListUser> get copyWith => _$FollowListUserCopyWithImpl<FollowListUser>(this as FollowListUser, _$identity);

  /// Serializes this FollowListUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowListUser&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.reputationScore, reputationScore) || other.reputationScore == reputationScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,isVerified,reputationScore);

@override
String toString() {
  return 'FollowListUser(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified, reputationScore: $reputationScore)';
}


}

/// @nodoc
abstract mixin class $FollowListUserCopyWith<$Res>  {
  factory $FollowListUserCopyWith(FollowListUser value, $Res Function(FollowListUser) _then) = _$FollowListUserCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String? avatarUrl, bool isVerified, double reputationScore
});




}
/// @nodoc
class _$FollowListUserCopyWithImpl<$Res>
    implements $FollowListUserCopyWith<$Res> {
  _$FollowListUserCopyWithImpl(this._self, this._then);

  final FollowListUser _self;
  final $Res Function(FollowListUser) _then;

/// Create a copy of FollowListUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? reputationScore = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,reputationScore: null == reputationScore ? _self.reputationScore : reputationScore // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowListUser].
extension FollowListUserPatterns on FollowListUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowListUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowListUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowListUser value)  $default,){
final _that = this;
switch (_that) {
case _FollowListUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowListUser value)?  $default,){
final _that = this;
switch (_that) {
case _FollowListUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String? avatarUrl,  bool isVerified,  double reputationScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowListUser() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified,_that.reputationScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String? avatarUrl,  bool isVerified,  double reputationScore)  $default,) {final _that = this;
switch (_that) {
case _FollowListUser():
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified,_that.reputationScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String? avatarUrl,  bool isVerified,  double reputationScore)?  $default,) {final _that = this;
switch (_that) {
case _FollowListUser() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified,_that.reputationScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowListUser implements FollowListUser {
  const _FollowListUser({required this.id, required this.displayName, this.avatarUrl, required this.isVerified, required this.reputationScore});
  factory _FollowListUser.fromJson(Map<String, dynamic> json) => _$FollowListUserFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String? avatarUrl;
@override final  bool isVerified;
@override final  double reputationScore;

/// Create a copy of FollowListUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowListUserCopyWith<_FollowListUser> get copyWith => __$FollowListUserCopyWithImpl<_FollowListUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowListUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowListUser&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.reputationScore, reputationScore) || other.reputationScore == reputationScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,isVerified,reputationScore);

@override
String toString() {
  return 'FollowListUser(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified, reputationScore: $reputationScore)';
}


}

/// @nodoc
abstract mixin class _$FollowListUserCopyWith<$Res> implements $FollowListUserCopyWith<$Res> {
  factory _$FollowListUserCopyWith(_FollowListUser value, $Res Function(_FollowListUser) _then) = __$FollowListUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? avatarUrl, bool isVerified, double reputationScore
});




}
/// @nodoc
class __$FollowListUserCopyWithImpl<$Res>
    implements _$FollowListUserCopyWith<$Res> {
  __$FollowListUserCopyWithImpl(this._self, this._then);

  final _FollowListUser _self;
  final $Res Function(_FollowListUser) _then;

/// Create a copy of FollowListUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? reputationScore = null,}) {
  return _then(_FollowListUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,reputationScore: null == reputationScore ? _self.reputationScore : reputationScore // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$FollowListResponse {

 List<FollowListUser> get users; int get total; int get limit; int get offset;
/// Create a copy of FollowListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowListResponseCopyWith<FollowListResponse> get copyWith => _$FollowListResponseCopyWithImpl<FollowListResponse>(this as FollowListResponse, _$identity);

  /// Serializes this FollowListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowListResponse&&const DeepCollectionEquality().equals(other.users, users)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(users),total,limit,offset);

@override
String toString() {
  return 'FollowListResponse(users: $users, total: $total, limit: $limit, offset: $offset)';
}


}

/// @nodoc
abstract mixin class $FollowListResponseCopyWith<$Res>  {
  factory $FollowListResponseCopyWith(FollowListResponse value, $Res Function(FollowListResponse) _then) = _$FollowListResponseCopyWithImpl;
@useResult
$Res call({
 List<FollowListUser> users, int total, int limit, int offset
});




}
/// @nodoc
class _$FollowListResponseCopyWithImpl<$Res>
    implements $FollowListResponseCopyWith<$Res> {
  _$FollowListResponseCopyWithImpl(this._self, this._then);

  final FollowListResponse _self;
  final $Res Function(FollowListResponse) _then;

/// Create a copy of FollowListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? users = null,Object? total = null,Object? limit = null,Object? offset = null,}) {
  return _then(_self.copyWith(
users: null == users ? _self.users : users // ignore: cast_nullable_to_non_nullable
as List<FollowListUser>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowListResponse].
extension FollowListResponsePatterns on FollowListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowListResponse value)  $default,){
final _that = this;
switch (_that) {
case _FollowListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _FollowListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FollowListUser> users,  int total,  int limit,  int offset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowListResponse() when $default != null:
return $default(_that.users,_that.total,_that.limit,_that.offset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FollowListUser> users,  int total,  int limit,  int offset)  $default,) {final _that = this;
switch (_that) {
case _FollowListResponse():
return $default(_that.users,_that.total,_that.limit,_that.offset);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FollowListUser> users,  int total,  int limit,  int offset)?  $default,) {final _that = this;
switch (_that) {
case _FollowListResponse() when $default != null:
return $default(_that.users,_that.total,_that.limit,_that.offset);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowListResponse implements FollowListResponse {
  const _FollowListResponse({final  List<FollowListUser> users = const [], required this.total, required this.limit, required this.offset}): _users = users;
  factory _FollowListResponse.fromJson(Map<String, dynamic> json) => _$FollowListResponseFromJson(json);

 final  List<FollowListUser> _users;
@override@JsonKey() List<FollowListUser> get users {
  if (_users is EqualUnmodifiableListView) return _users;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_users);
}

@override final  int total;
@override final  int limit;
@override final  int offset;

/// Create a copy of FollowListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowListResponseCopyWith<_FollowListResponse> get copyWith => __$FollowListResponseCopyWithImpl<_FollowListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowListResponse&&const DeepCollectionEquality().equals(other._users, _users)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_users),total,limit,offset);

@override
String toString() {
  return 'FollowListResponse(users: $users, total: $total, limit: $limit, offset: $offset)';
}


}

/// @nodoc
abstract mixin class _$FollowListResponseCopyWith<$Res> implements $FollowListResponseCopyWith<$Res> {
  factory _$FollowListResponseCopyWith(_FollowListResponse value, $Res Function(_FollowListResponse) _then) = __$FollowListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<FollowListUser> users, int total, int limit, int offset
});




}
/// @nodoc
class __$FollowListResponseCopyWithImpl<$Res>
    implements _$FollowListResponseCopyWith<$Res> {
  __$FollowListResponseCopyWithImpl(this._self, this._then);

  final _FollowListResponse _self;
  final $Res Function(_FollowListResponse) _then;

/// Create a copy of FollowListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? users = null,Object? total = null,Object? limit = null,Object? offset = null,}) {
  return _then(_FollowListResponse(
users: null == users ? _self._users : users // ignore: cast_nullable_to_non_nullable
as List<FollowListUser>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
