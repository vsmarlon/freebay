// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PostProductInfo {

 String get id; String get title; String get description; int get price;@JsonKey(name: 'condition', fromJson: _productConditionFromJson, toJson: _productConditionToJson) ProductCondition get condition;
/// Create a copy of PostProductInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostProductInfoCopyWith<PostProductInfo> get copyWith => _$PostProductInfoCopyWithImpl<PostProductInfo>(this as PostProductInfo, _$identity);

  /// Serializes this PostProductInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostProductInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.condition, condition) || other.condition == condition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,price,condition);

@override
String toString() {
  return 'PostProductInfo(id: $id, title: $title, description: $description, price: $price, condition: $condition)';
}


}

/// @nodoc
abstract mixin class $PostProductInfoCopyWith<$Res>  {
  factory $PostProductInfoCopyWith(PostProductInfo value, $Res Function(PostProductInfo) _then) = _$PostProductInfoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, int price,@JsonKey(name: 'condition', fromJson: _productConditionFromJson, toJson: _productConditionToJson) ProductCondition condition
});




}
/// @nodoc
class _$PostProductInfoCopyWithImpl<$Res>
    implements $PostProductInfoCopyWith<$Res> {
  _$PostProductInfoCopyWithImpl(this._self, this._then);

  final PostProductInfo _self;
  final $Res Function(PostProductInfo) _then;

/// Create a copy of PostProductInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? price = null,Object? condition = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as ProductCondition,
  ));
}

}


/// Adds pattern-matching-related methods to [PostProductInfo].
extension PostProductInfoPatterns on PostProductInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostProductInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostProductInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostProductInfo value)  $default,){
final _that = this;
switch (_that) {
case _PostProductInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostProductInfo value)?  $default,){
final _that = this;
switch (_that) {
case _PostProductInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  int price, @JsonKey(name: 'condition', fromJson: _productConditionFromJson, toJson: _productConditionToJson)  ProductCondition condition)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostProductInfo() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.price,_that.condition);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  int price, @JsonKey(name: 'condition', fromJson: _productConditionFromJson, toJson: _productConditionToJson)  ProductCondition condition)  $default,) {final _that = this;
switch (_that) {
case _PostProductInfo():
return $default(_that.id,_that.title,_that.description,_that.price,_that.condition);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  int price, @JsonKey(name: 'condition', fromJson: _productConditionFromJson, toJson: _productConditionToJson)  ProductCondition condition)?  $default,) {final _that = this;
switch (_that) {
case _PostProductInfo() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.price,_that.condition);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostProductInfo implements PostProductInfo {
  const _PostProductInfo({required this.id, required this.title, required this.description, this.price = 0, @JsonKey(name: 'condition', fromJson: _productConditionFromJson, toJson: _productConditionToJson) this.condition = ProductCondition.isNew});
  factory _PostProductInfo.fromJson(Map<String, dynamic> json) => _$PostProductInfoFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override@JsonKey() final  int price;
@override@JsonKey(name: 'condition', fromJson: _productConditionFromJson, toJson: _productConditionToJson) final  ProductCondition condition;

/// Create a copy of PostProductInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostProductInfoCopyWith<_PostProductInfo> get copyWith => __$PostProductInfoCopyWithImpl<_PostProductInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostProductInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostProductInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.condition, condition) || other.condition == condition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,price,condition);

@override
String toString() {
  return 'PostProductInfo(id: $id, title: $title, description: $description, price: $price, condition: $condition)';
}


}

/// @nodoc
abstract mixin class _$PostProductInfoCopyWith<$Res> implements $PostProductInfoCopyWith<$Res> {
  factory _$PostProductInfoCopyWith(_PostProductInfo value, $Res Function(_PostProductInfo) _then) = __$PostProductInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, int price,@JsonKey(name: 'condition', fromJson: _productConditionFromJson, toJson: _productConditionToJson) ProductCondition condition
});




}
/// @nodoc
class __$PostProductInfoCopyWithImpl<$Res>
    implements _$PostProductInfoCopyWith<$Res> {
  __$PostProductInfoCopyWithImpl(this._self, this._then);

  final _PostProductInfo _self;
  final $Res Function(_PostProductInfo) _then;

/// Create a copy of PostProductInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? price = null,Object? condition = null,}) {
  return _then(_PostProductInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as ProductCondition,
  ));
}


}


/// @nodoc
mixin _$PostEntity {

 String get id; String get userId; String? get content; String? get imageUrl; String? get imageBlurHash; PostType get type; PostAudience get audience; int get likesCount; int get commentsCount; int get sharesCount; bool get isLiked; bool get isSaved; bool get hasReposted; DateTime? get repostedAt; UserEntity? get repostedBy; DateTime get createdAt; UserEntity get user; PostProductInfo? get product;
/// Create a copy of PostEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostEntityCopyWith<PostEntity> get copyWith => _$PostEntityCopyWithImpl<PostEntity>(this as PostEntity, _$identity);

  /// Serializes this PostEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.content, content) || other.content == content)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.imageBlurHash, imageBlurHash) || other.imageBlurHash == imageBlurHash)&&(identical(other.type, type) || other.type == type)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.sharesCount, sharesCount) || other.sharesCount == sharesCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&(identical(other.hasReposted, hasReposted) || other.hasReposted == hasReposted)&&(identical(other.repostedAt, repostedAt) || other.repostedAt == repostedAt)&&(identical(other.repostedBy, repostedBy) || other.repostedBy == repostedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.product, product) || other.product == product));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,content,imageUrl,imageBlurHash,type,audience,likesCount,commentsCount,sharesCount,isLiked,isSaved,hasReposted,repostedAt,repostedBy,createdAt,user,product);

@override
String toString() {
  return 'PostEntity(id: $id, userId: $userId, content: $content, imageUrl: $imageUrl, imageBlurHash: $imageBlurHash, type: $type, audience: $audience, likesCount: $likesCount, commentsCount: $commentsCount, sharesCount: $sharesCount, isLiked: $isLiked, isSaved: $isSaved, hasReposted: $hasReposted, repostedAt: $repostedAt, repostedBy: $repostedBy, createdAt: $createdAt, user: $user, product: $product)';
}


}

/// @nodoc
abstract mixin class $PostEntityCopyWith<$Res>  {
  factory $PostEntityCopyWith(PostEntity value, $Res Function(PostEntity) _then) = _$PostEntityCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String? content, String? imageUrl, String? imageBlurHash, PostType type, PostAudience audience, int likesCount, int commentsCount, int sharesCount, bool isLiked, bool isSaved, bool hasReposted, DateTime? repostedAt, UserEntity? repostedBy, DateTime createdAt, UserEntity user, PostProductInfo? product
});


$UserEntityCopyWith<$Res>? get repostedBy;$UserEntityCopyWith<$Res> get user;$PostProductInfoCopyWith<$Res>? get product;

}
/// @nodoc
class _$PostEntityCopyWithImpl<$Res>
    implements $PostEntityCopyWith<$Res> {
  _$PostEntityCopyWithImpl(this._self, this._then);

  final PostEntity _self;
  final $Res Function(PostEntity) _then;

/// Create a copy of PostEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? content = freezed,Object? imageUrl = freezed,Object? imageBlurHash = freezed,Object? type = null,Object? audience = null,Object? likesCount = null,Object? commentsCount = null,Object? sharesCount = null,Object? isLiked = null,Object? isSaved = null,Object? hasReposted = null,Object? repostedAt = freezed,Object? repostedBy = freezed,Object? createdAt = null,Object? user = null,Object? product = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,imageBlurHash: freezed == imageBlurHash ? _self.imageBlurHash : imageBlurHash // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PostType,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as PostAudience,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,sharesCount: null == sharesCount ? _self.sharesCount : sharesCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,hasReposted: null == hasReposted ? _self.hasReposted : hasReposted // ignore: cast_nullable_to_non_nullable
as bool,repostedAt: freezed == repostedAt ? _self.repostedAt : repostedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,repostedBy: freezed == repostedBy ? _self.repostedBy : repostedBy // ignore: cast_nullable_to_non_nullable
as UserEntity?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserEntity,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as PostProductInfo?,
  ));
}
/// Create a copy of PostEntity
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
}/// Create a copy of PostEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res> get user {
  
  return $UserEntityCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of PostEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PostProductInfoCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $PostProductInfoCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}


/// Adds pattern-matching-related methods to [PostEntity].
extension PostEntityPatterns on PostEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostEntity value)  $default,){
final _that = this;
switch (_that) {
case _PostEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostEntity value)?  $default,){
final _that = this;
switch (_that) {
case _PostEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String? content,  String? imageUrl,  String? imageBlurHash,  PostType type,  PostAudience audience,  int likesCount,  int commentsCount,  int sharesCount,  bool isLiked,  bool isSaved,  bool hasReposted,  DateTime? repostedAt,  UserEntity? repostedBy,  DateTime createdAt,  UserEntity user,  PostProductInfo? product)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostEntity() when $default != null:
return $default(_that.id,_that.userId,_that.content,_that.imageUrl,_that.imageBlurHash,_that.type,_that.audience,_that.likesCount,_that.commentsCount,_that.sharesCount,_that.isLiked,_that.isSaved,_that.hasReposted,_that.repostedAt,_that.repostedBy,_that.createdAt,_that.user,_that.product);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String? content,  String? imageUrl,  String? imageBlurHash,  PostType type,  PostAudience audience,  int likesCount,  int commentsCount,  int sharesCount,  bool isLiked,  bool isSaved,  bool hasReposted,  DateTime? repostedAt,  UserEntity? repostedBy,  DateTime createdAt,  UserEntity user,  PostProductInfo? product)  $default,) {final _that = this;
switch (_that) {
case _PostEntity():
return $default(_that.id,_that.userId,_that.content,_that.imageUrl,_that.imageBlurHash,_that.type,_that.audience,_that.likesCount,_that.commentsCount,_that.sharesCount,_that.isLiked,_that.isSaved,_that.hasReposted,_that.repostedAt,_that.repostedBy,_that.createdAt,_that.user,_that.product);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String? content,  String? imageUrl,  String? imageBlurHash,  PostType type,  PostAudience audience,  int likesCount,  int commentsCount,  int sharesCount,  bool isLiked,  bool isSaved,  bool hasReposted,  DateTime? repostedAt,  UserEntity? repostedBy,  DateTime createdAt,  UserEntity user,  PostProductInfo? product)?  $default,) {final _that = this;
switch (_that) {
case _PostEntity() when $default != null:
return $default(_that.id,_that.userId,_that.content,_that.imageUrl,_that.imageBlurHash,_that.type,_that.audience,_that.likesCount,_that.commentsCount,_that.sharesCount,_that.isLiked,_that.isSaved,_that.hasReposted,_that.repostedAt,_that.repostedBy,_that.createdAt,_that.user,_that.product);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostEntity implements PostEntity {
  const _PostEntity({required this.id, required this.userId, this.content, this.imageUrl, this.imageBlurHash, this.type = PostType.regular, this.audience = PostAudience.everyone, this.likesCount = 0, this.commentsCount = 0, this.sharesCount = 0, this.isLiked = false, this.isSaved = false, this.hasReposted = false, this.repostedAt, this.repostedBy, required this.createdAt, required this.user, this.product});
  factory _PostEntity.fromJson(Map<String, dynamic> json) => _$PostEntityFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String? content;
@override final  String? imageUrl;
@override final  String? imageBlurHash;
@override@JsonKey() final  PostType type;
@override@JsonKey() final  PostAudience audience;
@override@JsonKey() final  int likesCount;
@override@JsonKey() final  int commentsCount;
@override@JsonKey() final  int sharesCount;
@override@JsonKey() final  bool isLiked;
@override@JsonKey() final  bool isSaved;
@override@JsonKey() final  bool hasReposted;
@override final  DateTime? repostedAt;
@override final  UserEntity? repostedBy;
@override final  DateTime createdAt;
@override final  UserEntity user;
@override final  PostProductInfo? product;

/// Create a copy of PostEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostEntityCopyWith<_PostEntity> get copyWith => __$PostEntityCopyWithImpl<_PostEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.content, content) || other.content == content)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.imageBlurHash, imageBlurHash) || other.imageBlurHash == imageBlurHash)&&(identical(other.type, type) || other.type == type)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.sharesCount, sharesCount) || other.sharesCount == sharesCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&(identical(other.hasReposted, hasReposted) || other.hasReposted == hasReposted)&&(identical(other.repostedAt, repostedAt) || other.repostedAt == repostedAt)&&(identical(other.repostedBy, repostedBy) || other.repostedBy == repostedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.product, product) || other.product == product));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,content,imageUrl,imageBlurHash,type,audience,likesCount,commentsCount,sharesCount,isLiked,isSaved,hasReposted,repostedAt,repostedBy,createdAt,user,product);

@override
String toString() {
  return 'PostEntity(id: $id, userId: $userId, content: $content, imageUrl: $imageUrl, imageBlurHash: $imageBlurHash, type: $type, audience: $audience, likesCount: $likesCount, commentsCount: $commentsCount, sharesCount: $sharesCount, isLiked: $isLiked, isSaved: $isSaved, hasReposted: $hasReposted, repostedAt: $repostedAt, repostedBy: $repostedBy, createdAt: $createdAt, user: $user, product: $product)';
}


}

/// @nodoc
abstract mixin class _$PostEntityCopyWith<$Res> implements $PostEntityCopyWith<$Res> {
  factory _$PostEntityCopyWith(_PostEntity value, $Res Function(_PostEntity) _then) = __$PostEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String? content, String? imageUrl, String? imageBlurHash, PostType type, PostAudience audience, int likesCount, int commentsCount, int sharesCount, bool isLiked, bool isSaved, bool hasReposted, DateTime? repostedAt, UserEntity? repostedBy, DateTime createdAt, UserEntity user, PostProductInfo? product
});


@override $UserEntityCopyWith<$Res>? get repostedBy;@override $UserEntityCopyWith<$Res> get user;@override $PostProductInfoCopyWith<$Res>? get product;

}
/// @nodoc
class __$PostEntityCopyWithImpl<$Res>
    implements _$PostEntityCopyWith<$Res> {
  __$PostEntityCopyWithImpl(this._self, this._then);

  final _PostEntity _self;
  final $Res Function(_PostEntity) _then;

/// Create a copy of PostEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? content = freezed,Object? imageUrl = freezed,Object? imageBlurHash = freezed,Object? type = null,Object? audience = null,Object? likesCount = null,Object? commentsCount = null,Object? sharesCount = null,Object? isLiked = null,Object? isSaved = null,Object? hasReposted = null,Object? repostedAt = freezed,Object? repostedBy = freezed,Object? createdAt = null,Object? user = null,Object? product = freezed,}) {
  return _then(_PostEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,imageBlurHash: freezed == imageBlurHash ? _self.imageBlurHash : imageBlurHash // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PostType,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as PostAudience,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,sharesCount: null == sharesCount ? _self.sharesCount : sharesCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,hasReposted: null == hasReposted ? _self.hasReposted : hasReposted // ignore: cast_nullable_to_non_nullable
as bool,repostedAt: freezed == repostedAt ? _self.repostedAt : repostedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,repostedBy: freezed == repostedBy ? _self.repostedBy : repostedBy // ignore: cast_nullable_to_non_nullable
as UserEntity?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserEntity,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as PostProductInfo?,
  ));
}

/// Create a copy of PostEntity
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
}/// Create a copy of PostEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res> get user {
  
  return $UserEntityCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of PostEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PostProductInfoCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $PostProductInfoCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}

// dart format on
