// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_preference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConversationPreference {

 String get id; String get userId; String? get orderId; String? get directConversationId; bool get isArchived; bool get isDeleted; String get theme; String? get backgroundUrl;
/// Create a copy of ConversationPreference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationPreferenceCopyWith<ConversationPreference> get copyWith => _$ConversationPreferenceCopyWithImpl<ConversationPreference>(this as ConversationPreference, _$identity);

  /// Serializes this ConversationPreference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationPreference&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.directConversationId, directConversationId) || other.directConversationId == directConversationId)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.backgroundUrl, backgroundUrl) || other.backgroundUrl == backgroundUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,orderId,directConversationId,isArchived,isDeleted,theme,backgroundUrl);

@override
String toString() {
  return 'ConversationPreference(id: $id, userId: $userId, orderId: $orderId, directConversationId: $directConversationId, isArchived: $isArchived, isDeleted: $isDeleted, theme: $theme, backgroundUrl: $backgroundUrl)';
}


}

/// @nodoc
abstract mixin class $ConversationPreferenceCopyWith<$Res>  {
  factory $ConversationPreferenceCopyWith(ConversationPreference value, $Res Function(ConversationPreference) _then) = _$ConversationPreferenceCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String? orderId, String? directConversationId, bool isArchived, bool isDeleted, String theme, String? backgroundUrl
});




}
/// @nodoc
class _$ConversationPreferenceCopyWithImpl<$Res>
    implements $ConversationPreferenceCopyWith<$Res> {
  _$ConversationPreferenceCopyWithImpl(this._self, this._then);

  final ConversationPreference _self;
  final $Res Function(ConversationPreference) _then;

/// Create a copy of ConversationPreference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? orderId = freezed,Object? directConversationId = freezed,Object? isArchived = null,Object? isDeleted = null,Object? theme = null,Object? backgroundUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,directConversationId: freezed == directConversationId ? _self.directConversationId : directConversationId // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,backgroundUrl: freezed == backgroundUrl ? _self.backgroundUrl : backgroundUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationPreference].
extension ConversationPreferencePatterns on ConversationPreference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationPreference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationPreference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationPreference value)  $default,){
final _that = this;
switch (_that) {
case _ConversationPreference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationPreference value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationPreference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String? orderId,  String? directConversationId,  bool isArchived,  bool isDeleted,  String theme,  String? backgroundUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationPreference() when $default != null:
return $default(_that.id,_that.userId,_that.orderId,_that.directConversationId,_that.isArchived,_that.isDeleted,_that.theme,_that.backgroundUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String? orderId,  String? directConversationId,  bool isArchived,  bool isDeleted,  String theme,  String? backgroundUrl)  $default,) {final _that = this;
switch (_that) {
case _ConversationPreference():
return $default(_that.id,_that.userId,_that.orderId,_that.directConversationId,_that.isArchived,_that.isDeleted,_that.theme,_that.backgroundUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String? orderId,  String? directConversationId,  bool isArchived,  bool isDeleted,  String theme,  String? backgroundUrl)?  $default,) {final _that = this;
switch (_that) {
case _ConversationPreference() when $default != null:
return $default(_that.id,_that.userId,_that.orderId,_that.directConversationId,_that.isArchived,_that.isDeleted,_that.theme,_that.backgroundUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConversationPreference implements ConversationPreference {
  const _ConversationPreference({this.id = '', this.userId = '', this.orderId, this.directConversationId, this.isArchived = false, this.isDeleted = false, this.theme = 'DEFAULT', this.backgroundUrl});
  factory _ConversationPreference.fromJson(Map<String, dynamic> json) => _$ConversationPreferenceFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String userId;
@override final  String? orderId;
@override final  String? directConversationId;
@override@JsonKey() final  bool isArchived;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  String theme;
@override final  String? backgroundUrl;

/// Create a copy of ConversationPreference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationPreferenceCopyWith<_ConversationPreference> get copyWith => __$ConversationPreferenceCopyWithImpl<_ConversationPreference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationPreferenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationPreference&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.directConversationId, directConversationId) || other.directConversationId == directConversationId)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.backgroundUrl, backgroundUrl) || other.backgroundUrl == backgroundUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,orderId,directConversationId,isArchived,isDeleted,theme,backgroundUrl);

@override
String toString() {
  return 'ConversationPreference(id: $id, userId: $userId, orderId: $orderId, directConversationId: $directConversationId, isArchived: $isArchived, isDeleted: $isDeleted, theme: $theme, backgroundUrl: $backgroundUrl)';
}


}

/// @nodoc
abstract mixin class _$ConversationPreferenceCopyWith<$Res> implements $ConversationPreferenceCopyWith<$Res> {
  factory _$ConversationPreferenceCopyWith(_ConversationPreference value, $Res Function(_ConversationPreference) _then) = __$ConversationPreferenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String? orderId, String? directConversationId, bool isArchived, bool isDeleted, String theme, String? backgroundUrl
});




}
/// @nodoc
class __$ConversationPreferenceCopyWithImpl<$Res>
    implements _$ConversationPreferenceCopyWith<$Res> {
  __$ConversationPreferenceCopyWithImpl(this._self, this._then);

  final _ConversationPreference _self;
  final $Res Function(_ConversationPreference) _then;

/// Create a copy of ConversationPreference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? orderId = freezed,Object? directConversationId = freezed,Object? isArchived = null,Object? isDeleted = null,Object? theme = null,Object? backgroundUrl = freezed,}) {
  return _then(_ConversationPreference(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,directConversationId: freezed == directConversationId ? _self.directConversationId : directConversationId // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,backgroundUrl: freezed == backgroundUrl ? _self.backgroundUrl : backgroundUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
