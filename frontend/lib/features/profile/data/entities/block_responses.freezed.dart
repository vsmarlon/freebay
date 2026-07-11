// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'block_responses.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BlockListUser {

 String get id; String get displayName; String? get avatarUrl; bool get isVerified; double get reputationScore;
/// Create a copy of BlockListUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlockListUserCopyWith<BlockListUser> get copyWith => _$BlockListUserCopyWithImpl<BlockListUser>(this as BlockListUser, _$identity);

  /// Serializes this BlockListUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlockListUser&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.reputationScore, reputationScore) || other.reputationScore == reputationScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,isVerified,reputationScore);

@override
String toString() {
  return 'BlockListUser(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified, reputationScore: $reputationScore)';
}


}

/// @nodoc
abstract mixin class $BlockListUserCopyWith<$Res>  {
  factory $BlockListUserCopyWith(BlockListUser value, $Res Function(BlockListUser) _then) = _$BlockListUserCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String? avatarUrl, bool isVerified, double reputationScore
});




}
/// @nodoc
class _$BlockListUserCopyWithImpl<$Res>
    implements $BlockListUserCopyWith<$Res> {
  _$BlockListUserCopyWithImpl(this._self, this._then);

  final BlockListUser _self;
  final $Res Function(BlockListUser) _then;

/// Create a copy of BlockListUser
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


/// Adds pattern-matching-related methods to [BlockListUser].
extension BlockListUserPatterns on BlockListUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlockListUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlockListUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlockListUser value)  $default,){
final _that = this;
switch (_that) {
case _BlockListUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlockListUser value)?  $default,){
final _that = this;
switch (_that) {
case _BlockListUser() when $default != null:
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
case _BlockListUser() when $default != null:
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
case _BlockListUser():
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
case _BlockListUser() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified,_that.reputationScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BlockListUser implements BlockListUser {
  const _BlockListUser({required this.id, required this.displayName, this.avatarUrl, required this.isVerified, required this.reputationScore});
  factory _BlockListUser.fromJson(Map<String, dynamic> json) => _$BlockListUserFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String? avatarUrl;
@override final  bool isVerified;
@override final  double reputationScore;

/// Create a copy of BlockListUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlockListUserCopyWith<_BlockListUser> get copyWith => __$BlockListUserCopyWithImpl<_BlockListUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlockListUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlockListUser&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.reputationScore, reputationScore) || other.reputationScore == reputationScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,isVerified,reputationScore);

@override
String toString() {
  return 'BlockListUser(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified, reputationScore: $reputationScore)';
}


}

/// @nodoc
abstract mixin class _$BlockListUserCopyWith<$Res> implements $BlockListUserCopyWith<$Res> {
  factory _$BlockListUserCopyWith(_BlockListUser value, $Res Function(_BlockListUser) _then) = __$BlockListUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? avatarUrl, bool isVerified, double reputationScore
});




}
/// @nodoc
class __$BlockListUserCopyWithImpl<$Res>
    implements _$BlockListUserCopyWith<$Res> {
  __$BlockListUserCopyWithImpl(this._self, this._then);

  final _BlockListUser _self;
  final $Res Function(_BlockListUser) _then;

/// Create a copy of BlockListUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? reputationScore = null,}) {
  return _then(_BlockListUser(
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
mixin _$BlockListResponse {

 List<BlockListUser> get users; int get limit; int get offset;
/// Create a copy of BlockListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlockListResponseCopyWith<BlockListResponse> get copyWith => _$BlockListResponseCopyWithImpl<BlockListResponse>(this as BlockListResponse, _$identity);

  /// Serializes this BlockListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlockListResponse&&const DeepCollectionEquality().equals(other.users, users)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(users),limit,offset);

@override
String toString() {
  return 'BlockListResponse(users: $users, limit: $limit, offset: $offset)';
}


}

/// @nodoc
abstract mixin class $BlockListResponseCopyWith<$Res>  {
  factory $BlockListResponseCopyWith(BlockListResponse value, $Res Function(BlockListResponse) _then) = _$BlockListResponseCopyWithImpl;
@useResult
$Res call({
 List<BlockListUser> users, int limit, int offset
});




}
/// @nodoc
class _$BlockListResponseCopyWithImpl<$Res>
    implements $BlockListResponseCopyWith<$Res> {
  _$BlockListResponseCopyWithImpl(this._self, this._then);

  final BlockListResponse _self;
  final $Res Function(BlockListResponse) _then;

/// Create a copy of BlockListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? users = null,Object? limit = null,Object? offset = null,}) {
  return _then(_self.copyWith(
users: null == users ? _self.users : users // ignore: cast_nullable_to_non_nullable
as List<BlockListUser>,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BlockListResponse].
extension BlockListResponsePatterns on BlockListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlockListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlockListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlockListResponse value)  $default,){
final _that = this;
switch (_that) {
case _BlockListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlockListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _BlockListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BlockListUser> users,  int limit,  int offset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BlockListResponse() when $default != null:
return $default(_that.users,_that.limit,_that.offset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BlockListUser> users,  int limit,  int offset)  $default,) {final _that = this;
switch (_that) {
case _BlockListResponse():
return $default(_that.users,_that.limit,_that.offset);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BlockListUser> users,  int limit,  int offset)?  $default,) {final _that = this;
switch (_that) {
case _BlockListResponse() when $default != null:
return $default(_that.users,_that.limit,_that.offset);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BlockListResponse implements BlockListResponse {
  const _BlockListResponse({final  List<BlockListUser> users = const [], required this.limit, required this.offset}): _users = users;
  factory _BlockListResponse.fromJson(Map<String, dynamic> json) => _$BlockListResponseFromJson(json);

 final  List<BlockListUser> _users;
@override@JsonKey() List<BlockListUser> get users {
  if (_users is EqualUnmodifiableListView) return _users;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_users);
}

@override final  int limit;
@override final  int offset;

/// Create a copy of BlockListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlockListResponseCopyWith<_BlockListResponse> get copyWith => __$BlockListResponseCopyWithImpl<_BlockListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlockListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlockListResponse&&const DeepCollectionEquality().equals(other._users, _users)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_users),limit,offset);

@override
String toString() {
  return 'BlockListResponse(users: $users, limit: $limit, offset: $offset)';
}


}

/// @nodoc
abstract mixin class _$BlockListResponseCopyWith<$Res> implements $BlockListResponseCopyWith<$Res> {
  factory _$BlockListResponseCopyWith(_BlockListResponse value, $Res Function(_BlockListResponse) _then) = __$BlockListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<BlockListUser> users, int limit, int offset
});




}
/// @nodoc
class __$BlockListResponseCopyWithImpl<$Res>
    implements _$BlockListResponseCopyWith<$Res> {
  __$BlockListResponseCopyWithImpl(this._self, this._then);

  final _BlockListResponse _self;
  final $Res Function(_BlockListResponse) _then;

/// Create a copy of BlockListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? users = null,Object? limit = null,Object? offset = null,}) {
  return _then(_BlockListResponse(
users: null == users ? _self._users : users // ignore: cast_nullable_to_non_nullable
as List<BlockListUser>,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$UnblockResponse {

 bool get blocked;
/// Create a copy of UnblockResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnblockResponseCopyWith<UnblockResponse> get copyWith => _$UnblockResponseCopyWithImpl<UnblockResponse>(this as UnblockResponse, _$identity);

  /// Serializes this UnblockResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnblockResponse&&(identical(other.blocked, blocked) || other.blocked == blocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,blocked);

@override
String toString() {
  return 'UnblockResponse(blocked: $blocked)';
}


}

/// @nodoc
abstract mixin class $UnblockResponseCopyWith<$Res>  {
  factory $UnblockResponseCopyWith(UnblockResponse value, $Res Function(UnblockResponse) _then) = _$UnblockResponseCopyWithImpl;
@useResult
$Res call({
 bool blocked
});




}
/// @nodoc
class _$UnblockResponseCopyWithImpl<$Res>
    implements $UnblockResponseCopyWith<$Res> {
  _$UnblockResponseCopyWithImpl(this._self, this._then);

  final UnblockResponse _self;
  final $Res Function(UnblockResponse) _then;

/// Create a copy of UnblockResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? blocked = null,}) {
  return _then(_self.copyWith(
blocked: null == blocked ? _self.blocked : blocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UnblockResponse].
extension UnblockResponsePatterns on UnblockResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnblockResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnblockResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnblockResponse value)  $default,){
final _that = this;
switch (_that) {
case _UnblockResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnblockResponse value)?  $default,){
final _that = this;
switch (_that) {
case _UnblockResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool blocked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnblockResponse() when $default != null:
return $default(_that.blocked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool blocked)  $default,) {final _that = this;
switch (_that) {
case _UnblockResponse():
return $default(_that.blocked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool blocked)?  $default,) {final _that = this;
switch (_that) {
case _UnblockResponse() when $default != null:
return $default(_that.blocked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnblockResponse implements UnblockResponse {
  const _UnblockResponse({required this.blocked});
  factory _UnblockResponse.fromJson(Map<String, dynamic> json) => _$UnblockResponseFromJson(json);

@override final  bool blocked;

/// Create a copy of UnblockResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnblockResponseCopyWith<_UnblockResponse> get copyWith => __$UnblockResponseCopyWithImpl<_UnblockResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnblockResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnblockResponse&&(identical(other.blocked, blocked) || other.blocked == blocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,blocked);

@override
String toString() {
  return 'UnblockResponse(blocked: $blocked)';
}


}

/// @nodoc
abstract mixin class _$UnblockResponseCopyWith<$Res> implements $UnblockResponseCopyWith<$Res> {
  factory _$UnblockResponseCopyWith(_UnblockResponse value, $Res Function(_UnblockResponse) _then) = __$UnblockResponseCopyWithImpl;
@override @useResult
$Res call({
 bool blocked
});




}
/// @nodoc
class __$UnblockResponseCopyWithImpl<$Res>
    implements _$UnblockResponseCopyWith<$Res> {
  __$UnblockResponseCopyWithImpl(this._self, this._then);

  final _UnblockResponse _self;
  final $Res Function(_UnblockResponse) _then;

/// Create a copy of UnblockResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? blocked = null,}) {
  return _then(_UnblockResponse(
blocked: null == blocked ? _self.blocked : blocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$BlockResponse {

 bool get blocked;
/// Create a copy of BlockResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlockResponseCopyWith<BlockResponse> get copyWith => _$BlockResponseCopyWithImpl<BlockResponse>(this as BlockResponse, _$identity);

  /// Serializes this BlockResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlockResponse&&(identical(other.blocked, blocked) || other.blocked == blocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,blocked);

@override
String toString() {
  return 'BlockResponse(blocked: $blocked)';
}


}

/// @nodoc
abstract mixin class $BlockResponseCopyWith<$Res>  {
  factory $BlockResponseCopyWith(BlockResponse value, $Res Function(BlockResponse) _then) = _$BlockResponseCopyWithImpl;
@useResult
$Res call({
 bool blocked
});




}
/// @nodoc
class _$BlockResponseCopyWithImpl<$Res>
    implements $BlockResponseCopyWith<$Res> {
  _$BlockResponseCopyWithImpl(this._self, this._then);

  final BlockResponse _self;
  final $Res Function(BlockResponse) _then;

/// Create a copy of BlockResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? blocked = null,}) {
  return _then(_self.copyWith(
blocked: null == blocked ? _self.blocked : blocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BlockResponse].
extension BlockResponsePatterns on BlockResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlockResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlockResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlockResponse value)  $default,){
final _that = this;
switch (_that) {
case _BlockResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlockResponse value)?  $default,){
final _that = this;
switch (_that) {
case _BlockResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool blocked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BlockResponse() when $default != null:
return $default(_that.blocked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool blocked)  $default,) {final _that = this;
switch (_that) {
case _BlockResponse():
return $default(_that.blocked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool blocked)?  $default,) {final _that = this;
switch (_that) {
case _BlockResponse() when $default != null:
return $default(_that.blocked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BlockResponse implements BlockResponse {
  const _BlockResponse({required this.blocked});
  factory _BlockResponse.fromJson(Map<String, dynamic> json) => _$BlockResponseFromJson(json);

@override final  bool blocked;

/// Create a copy of BlockResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlockResponseCopyWith<_BlockResponse> get copyWith => __$BlockResponseCopyWithImpl<_BlockResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlockResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlockResponse&&(identical(other.blocked, blocked) || other.blocked == blocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,blocked);

@override
String toString() {
  return 'BlockResponse(blocked: $blocked)';
}


}

/// @nodoc
abstract mixin class _$BlockResponseCopyWith<$Res> implements $BlockResponseCopyWith<$Res> {
  factory _$BlockResponseCopyWith(_BlockResponse value, $Res Function(_BlockResponse) _then) = __$BlockResponseCopyWithImpl;
@override @useResult
$Res call({
 bool blocked
});




}
/// @nodoc
class __$BlockResponseCopyWithImpl<$Res>
    implements _$BlockResponseCopyWith<$Res> {
  __$BlockResponseCopyWithImpl(this._self, this._then);

  final _BlockResponse _self;
  final $Res Function(_BlockResponse) _then;

/// Create a copy of BlockResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? blocked = null,}) {
  return _then(_BlockResponse(
blocked: null == blocked ? _self.blocked : blocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
