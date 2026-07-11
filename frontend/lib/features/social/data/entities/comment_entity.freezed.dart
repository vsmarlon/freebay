// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentEntity {

 String get id; String get content; String get userId; String get postId; String? get parentId; int get likesCount; bool get isLiked; DateTime get createdAt; UserEntity? get user; List<CommentEntity> get replies;
/// Create a copy of CommentEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentEntityCopyWith<CommentEntity> get copyWith => _$CommentEntityCopyWithImpl<CommentEntity>(this as CommentEntity, _$identity);

  /// Serializes this CommentEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other.replies, replies));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,userId,postId,parentId,likesCount,isLiked,createdAt,user,const DeepCollectionEquality().hash(replies));

@override
String toString() {
  return 'CommentEntity(id: $id, content: $content, userId: $userId, postId: $postId, parentId: $parentId, likesCount: $likesCount, isLiked: $isLiked, createdAt: $createdAt, user: $user, replies: $replies)';
}


}

/// @nodoc
abstract mixin class $CommentEntityCopyWith<$Res>  {
  factory $CommentEntityCopyWith(CommentEntity value, $Res Function(CommentEntity) _then) = _$CommentEntityCopyWithImpl;
@useResult
$Res call({
 String id, String content, String userId, String postId, String? parentId, int likesCount, bool isLiked, DateTime createdAt, UserEntity? user, List<CommentEntity> replies
});


$UserEntityCopyWith<$Res>? get user;

}
/// @nodoc
class _$CommentEntityCopyWithImpl<$Res>
    implements $CommentEntityCopyWith<$Res> {
  _$CommentEntityCopyWithImpl(this._self, this._then);

  final CommentEntity _self;
  final $Res Function(CommentEntity) _then;

/// Create a copy of CommentEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = null,Object? userId = null,Object? postId = null,Object? parentId = freezed,Object? likesCount = null,Object? isLiked = null,Object? createdAt = null,Object? user = freezed,Object? replies = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserEntity?,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as List<CommentEntity>,
  ));
}
/// Create a copy of CommentEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserEntityCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [CommentEntity].
extension CommentEntityPatterns on CommentEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentEntity value)  $default,){
final _that = this;
switch (_that) {
case _CommentEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CommentEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String content,  String userId,  String postId,  String? parentId,  int likesCount,  bool isLiked,  DateTime createdAt,  UserEntity? user,  List<CommentEntity> replies)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentEntity() when $default != null:
return $default(_that.id,_that.content,_that.userId,_that.postId,_that.parentId,_that.likesCount,_that.isLiked,_that.createdAt,_that.user,_that.replies);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String content,  String userId,  String postId,  String? parentId,  int likesCount,  bool isLiked,  DateTime createdAt,  UserEntity? user,  List<CommentEntity> replies)  $default,) {final _that = this;
switch (_that) {
case _CommentEntity():
return $default(_that.id,_that.content,_that.userId,_that.postId,_that.parentId,_that.likesCount,_that.isLiked,_that.createdAt,_that.user,_that.replies);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String content,  String userId,  String postId,  String? parentId,  int likesCount,  bool isLiked,  DateTime createdAt,  UserEntity? user,  List<CommentEntity> replies)?  $default,) {final _that = this;
switch (_that) {
case _CommentEntity() when $default != null:
return $default(_that.id,_that.content,_that.userId,_that.postId,_that.parentId,_that.likesCount,_that.isLiked,_that.createdAt,_that.user,_that.replies);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentEntity implements CommentEntity {
  const _CommentEntity({required this.id, required this.content, required this.userId, required this.postId, this.parentId, this.likesCount = 0, this.isLiked = false, required this.createdAt, this.user, final  List<CommentEntity> replies = const []}): _replies = replies;
  factory _CommentEntity.fromJson(Map<String, dynamic> json) => _$CommentEntityFromJson(json);

@override final  String id;
@override final  String content;
@override final  String userId;
@override final  String postId;
@override final  String? parentId;
@override@JsonKey() final  int likesCount;
@override@JsonKey() final  bool isLiked;
@override final  DateTime createdAt;
@override final  UserEntity? user;
 final  List<CommentEntity> _replies;
@override@JsonKey() List<CommentEntity> get replies {
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_replies);
}


/// Create a copy of CommentEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentEntityCopyWith<_CommentEntity> get copyWith => __$CommentEntityCopyWithImpl<_CommentEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other._replies, _replies));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,userId,postId,parentId,likesCount,isLiked,createdAt,user,const DeepCollectionEquality().hash(_replies));

@override
String toString() {
  return 'CommentEntity(id: $id, content: $content, userId: $userId, postId: $postId, parentId: $parentId, likesCount: $likesCount, isLiked: $isLiked, createdAt: $createdAt, user: $user, replies: $replies)';
}


}

/// @nodoc
abstract mixin class _$CommentEntityCopyWith<$Res> implements $CommentEntityCopyWith<$Res> {
  factory _$CommentEntityCopyWith(_CommentEntity value, $Res Function(_CommentEntity) _then) = __$CommentEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String content, String userId, String postId, String? parentId, int likesCount, bool isLiked, DateTime createdAt, UserEntity? user, List<CommentEntity> replies
});


@override $UserEntityCopyWith<$Res>? get user;

}
/// @nodoc
class __$CommentEntityCopyWithImpl<$Res>
    implements _$CommentEntityCopyWith<$Res> {
  __$CommentEntityCopyWithImpl(this._self, this._then);

  final _CommentEntity _self;
  final $Res Function(_CommentEntity) _then;

/// Create a copy of CommentEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,Object? userId = null,Object? postId = null,Object? parentId = freezed,Object? likesCount = null,Object? isLiked = null,Object? createdAt = null,Object? user = freezed,Object? replies = null,}) {
  return _then(_CommentEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserEntity?,replies: null == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<CommentEntity>,
  ));
}

/// Create a copy of CommentEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserEntityCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
