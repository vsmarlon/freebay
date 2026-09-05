// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserEntity {

 String get id; String? get displayName; String? get username; String? get email; String? get avatarUrl; String? get bannerUrl; String? get bio; String? get city; String? get state; bool get isVerified; bool get hasCpf; String? get cpf; num get reputationScore; int get totalReviews; int get salesCount; int get purchasesCount; int get followersCount; int get followingCount; int get postsCount; int get productsCount; bool get hasActiveStory;
/// Create a copy of UserEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserEntityCopyWith<UserEntity> get copyWith => _$UserEntityCopyWithImpl<UserEntity>(this as UserEntity, _$identity);

  /// Serializes this UserEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.hasCpf, hasCpf) || other.hasCpf == hasCpf)&&(identical(other.cpf, cpf) || other.cpf == cpf)&&(identical(other.reputationScore, reputationScore) || other.reputationScore == reputationScore)&&(identical(other.totalReviews, totalReviews) || other.totalReviews == totalReviews)&&(identical(other.salesCount, salesCount) || other.salesCount == salesCount)&&(identical(other.purchasesCount, purchasesCount) || other.purchasesCount == purchasesCount)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.postsCount, postsCount) || other.postsCount == postsCount)&&(identical(other.productsCount, productsCount) || other.productsCount == productsCount)&&(identical(other.hasActiveStory, hasActiveStory) || other.hasActiveStory == hasActiveStory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,username,email,avatarUrl,bannerUrl,bio,city,state,isVerified,hasCpf,cpf,reputationScore,totalReviews,salesCount,purchasesCount,followersCount,followingCount,postsCount,productsCount,hasActiveStory]);

@override
String toString() {
  return 'UserEntity(id: $id, displayName: $displayName, username: $username, email: $email, avatarUrl: $avatarUrl, bannerUrl: $bannerUrl, bio: $bio, city: $city, state: $state, isVerified: $isVerified, hasCpf: $hasCpf, cpf: $cpf, reputationScore: $reputationScore, totalReviews: $totalReviews, salesCount: $salesCount, purchasesCount: $purchasesCount, followersCount: $followersCount, followingCount: $followingCount, postsCount: $postsCount, productsCount: $productsCount, hasActiveStory: $hasActiveStory)';
}


}

/// @nodoc
abstract mixin class $UserEntityCopyWith<$Res>  {
  factory $UserEntityCopyWith(UserEntity value, $Res Function(UserEntity) _then) = _$UserEntityCopyWithImpl;
@useResult
$Res call({
 String id, String? displayName, String? username, String? email, String? avatarUrl, String? bannerUrl, String? bio, String? city, String? state, bool isVerified, bool hasCpf, String? cpf, num reputationScore, int totalReviews, int salesCount, int purchasesCount, int followersCount, int followingCount, int postsCount, int productsCount, bool hasActiveStory
});




}
/// @nodoc
class _$UserEntityCopyWithImpl<$Res>
    implements $UserEntityCopyWith<$Res> {
  _$UserEntityCopyWithImpl(this._self, this._then);

  final UserEntity _self;
  final $Res Function(UserEntity) _then;

/// Create a copy of UserEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = freezed,Object? username = freezed,Object? email = freezed,Object? avatarUrl = freezed,Object? bannerUrl = freezed,Object? bio = freezed,Object? city = freezed,Object? state = freezed,Object? isVerified = null,Object? hasCpf = null,Object? cpf = freezed,Object? reputationScore = null,Object? totalReviews = null,Object? salesCount = null,Object? purchasesCount = null,Object? followersCount = null,Object? followingCount = null,Object? postsCount = null,Object? productsCount = null,Object? hasActiveStory = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,hasCpf: null == hasCpf ? _self.hasCpf : hasCpf // ignore: cast_nullable_to_non_nullable
as bool,cpf: freezed == cpf ? _self.cpf : cpf // ignore: cast_nullable_to_non_nullable
as String?,reputationScore: null == reputationScore ? _self.reputationScore : reputationScore // ignore: cast_nullable_to_non_nullable
as num,totalReviews: null == totalReviews ? _self.totalReviews : totalReviews // ignore: cast_nullable_to_non_nullable
as int,salesCount: null == salesCount ? _self.salesCount : salesCount // ignore: cast_nullable_to_non_nullable
as int,purchasesCount: null == purchasesCount ? _self.purchasesCount : purchasesCount // ignore: cast_nullable_to_non_nullable
as int,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,postsCount: null == postsCount ? _self.postsCount : postsCount // ignore: cast_nullable_to_non_nullable
as int,productsCount: null == productsCount ? _self.productsCount : productsCount // ignore: cast_nullable_to_non_nullable
as int,hasActiveStory: null == hasActiveStory ? _self.hasActiveStory : hasActiveStory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserEntity].
extension UserEntityPatterns on UserEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserEntity value)  $default,){
final _that = this;
switch (_that) {
case _UserEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserEntity value)?  $default,){
final _that = this;
switch (_that) {
case _UserEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? displayName,  String? username,  String? email,  String? avatarUrl,  String? bannerUrl,  String? bio,  String? city,  String? state,  bool isVerified,  bool hasCpf,  String? cpf,  num reputationScore,  int totalReviews,  int salesCount,  int purchasesCount,  int followersCount,  int followingCount,  int postsCount,  int productsCount,  bool hasActiveStory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserEntity() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.email,_that.avatarUrl,_that.bannerUrl,_that.bio,_that.city,_that.state,_that.isVerified,_that.hasCpf,_that.cpf,_that.reputationScore,_that.totalReviews,_that.salesCount,_that.purchasesCount,_that.followersCount,_that.followingCount,_that.postsCount,_that.productsCount,_that.hasActiveStory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? displayName,  String? username,  String? email,  String? avatarUrl,  String? bannerUrl,  String? bio,  String? city,  String? state,  bool isVerified,  bool hasCpf,  String? cpf,  num reputationScore,  int totalReviews,  int salesCount,  int purchasesCount,  int followersCount,  int followingCount,  int postsCount,  int productsCount,  bool hasActiveStory)  $default,) {final _that = this;
switch (_that) {
case _UserEntity():
return $default(_that.id,_that.displayName,_that.username,_that.email,_that.avatarUrl,_that.bannerUrl,_that.bio,_that.city,_that.state,_that.isVerified,_that.hasCpf,_that.cpf,_that.reputationScore,_that.totalReviews,_that.salesCount,_that.purchasesCount,_that.followersCount,_that.followingCount,_that.postsCount,_that.productsCount,_that.hasActiveStory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? displayName,  String? username,  String? email,  String? avatarUrl,  String? bannerUrl,  String? bio,  String? city,  String? state,  bool isVerified,  bool hasCpf,  String? cpf,  num reputationScore,  int totalReviews,  int salesCount,  int purchasesCount,  int followersCount,  int followingCount,  int postsCount,  int productsCount,  bool hasActiveStory)?  $default,) {final _that = this;
switch (_that) {
case _UserEntity() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.email,_that.avatarUrl,_that.bannerUrl,_that.bio,_that.city,_that.state,_that.isVerified,_that.hasCpf,_that.cpf,_that.reputationScore,_that.totalReviews,_that.salesCount,_that.purchasesCount,_that.followersCount,_that.followingCount,_that.postsCount,_that.productsCount,_that.hasActiveStory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserEntity extends UserEntity {
  const _UserEntity({required this.id, this.displayName, this.username, this.email, this.avatarUrl, this.bannerUrl, this.bio, this.city, this.state, this.isVerified = false, this.hasCpf = false, this.cpf, this.reputationScore = 0, this.totalReviews = 0, this.salesCount = 0, this.purchasesCount = 0, this.followersCount = 0, this.followingCount = 0, this.postsCount = 0, this.productsCount = 0, this.hasActiveStory = false}): super._();
  factory _UserEntity.fromJson(Map<String, dynamic> json) => _$UserEntityFromJson(json);

@override final  String id;
@override final  String? displayName;
@override final  String? username;
@override final  String? email;
@override final  String? avatarUrl;
@override final  String? bannerUrl;
@override final  String? bio;
@override final  String? city;
@override final  String? state;
@override@JsonKey() final  bool isVerified;
@override@JsonKey() final  bool hasCpf;
@override final  String? cpf;
@override@JsonKey() final  num reputationScore;
@override@JsonKey() final  int totalReviews;
@override@JsonKey() final  int salesCount;
@override@JsonKey() final  int purchasesCount;
@override@JsonKey() final  int followersCount;
@override@JsonKey() final  int followingCount;
@override@JsonKey() final  int postsCount;
@override@JsonKey() final  int productsCount;
@override@JsonKey() final  bool hasActiveStory;

/// Create a copy of UserEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserEntityCopyWith<_UserEntity> get copyWith => __$UserEntityCopyWithImpl<_UserEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.hasCpf, hasCpf) || other.hasCpf == hasCpf)&&(identical(other.cpf, cpf) || other.cpf == cpf)&&(identical(other.reputationScore, reputationScore) || other.reputationScore == reputationScore)&&(identical(other.totalReviews, totalReviews) || other.totalReviews == totalReviews)&&(identical(other.salesCount, salesCount) || other.salesCount == salesCount)&&(identical(other.purchasesCount, purchasesCount) || other.purchasesCount == purchasesCount)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.postsCount, postsCount) || other.postsCount == postsCount)&&(identical(other.productsCount, productsCount) || other.productsCount == productsCount)&&(identical(other.hasActiveStory, hasActiveStory) || other.hasActiveStory == hasActiveStory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,username,email,avatarUrl,bannerUrl,bio,city,state,isVerified,hasCpf,cpf,reputationScore,totalReviews,salesCount,purchasesCount,followersCount,followingCount,postsCount,productsCount,hasActiveStory]);

@override
String toString() {
  return 'UserEntity(id: $id, displayName: $displayName, username: $username, email: $email, avatarUrl: $avatarUrl, bannerUrl: $bannerUrl, bio: $bio, city: $city, state: $state, isVerified: $isVerified, hasCpf: $hasCpf, cpf: $cpf, reputationScore: $reputationScore, totalReviews: $totalReviews, salesCount: $salesCount, purchasesCount: $purchasesCount, followersCount: $followersCount, followingCount: $followingCount, postsCount: $postsCount, productsCount: $productsCount, hasActiveStory: $hasActiveStory)';
}


}

/// @nodoc
abstract mixin class _$UserEntityCopyWith<$Res> implements $UserEntityCopyWith<$Res> {
  factory _$UserEntityCopyWith(_UserEntity value, $Res Function(_UserEntity) _then) = __$UserEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String? displayName, String? username, String? email, String? avatarUrl, String? bannerUrl, String? bio, String? city, String? state, bool isVerified, bool hasCpf, String? cpf, num reputationScore, int totalReviews, int salesCount, int purchasesCount, int followersCount, int followingCount, int postsCount, int productsCount, bool hasActiveStory
});




}
/// @nodoc
class __$UserEntityCopyWithImpl<$Res>
    implements _$UserEntityCopyWith<$Res> {
  __$UserEntityCopyWithImpl(this._self, this._then);

  final _UserEntity _self;
  final $Res Function(_UserEntity) _then;

/// Create a copy of UserEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = freezed,Object? username = freezed,Object? email = freezed,Object? avatarUrl = freezed,Object? bannerUrl = freezed,Object? bio = freezed,Object? city = freezed,Object? state = freezed,Object? isVerified = null,Object? hasCpf = null,Object? cpf = freezed,Object? reputationScore = null,Object? totalReviews = null,Object? salesCount = null,Object? purchasesCount = null,Object? followersCount = null,Object? followingCount = null,Object? postsCount = null,Object? productsCount = null,Object? hasActiveStory = null,}) {
  return _then(_UserEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,hasCpf: null == hasCpf ? _self.hasCpf : hasCpf // ignore: cast_nullable_to_non_nullable
as bool,cpf: freezed == cpf ? _self.cpf : cpf // ignore: cast_nullable_to_non_nullable
as String?,reputationScore: null == reputationScore ? _self.reputationScore : reputationScore // ignore: cast_nullable_to_non_nullable
as num,totalReviews: null == totalReviews ? _self.totalReviews : totalReviews // ignore: cast_nullable_to_non_nullable
as int,salesCount: null == salesCount ? _self.salesCount : salesCount // ignore: cast_nullable_to_non_nullable
as int,purchasesCount: null == purchasesCount ? _self.purchasesCount : purchasesCount // ignore: cast_nullable_to_non_nullable
as int,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,postsCount: null == postsCount ? _self.postsCount : postsCount // ignore: cast_nullable_to_non_nullable
as int,productsCount: null == productsCount ? _self.productsCount : productsCount // ignore: cast_nullable_to_non_nullable
as int,hasActiveStory: null == hasActiveStory ? _self.hasActiveStory : hasActiveStory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
