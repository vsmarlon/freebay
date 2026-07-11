// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatEntity {

 String get id;@JsonKey(fromJson: _threadTypeFromJson, toJson: _threadTypeToJson) ChatThreadType get threadType; UserEntity get otherUser;@JsonKey(name: 'lastMessage') LastMessageInfo? get lastMessageInfo; DateTime get createdAt; ConversationPreference? get preference; OrderInfo? get orderInfo; int get unreadCount;
/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatEntityCopyWith<ChatEntity> get copyWith => _$ChatEntityCopyWithImpl<ChatEntity>(this as ChatEntity, _$identity);

  /// Serializes this ChatEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.threadType, threadType) || other.threadType == threadType)&&(identical(other.otherUser, otherUser) || other.otherUser == otherUser)&&(identical(other.lastMessageInfo, lastMessageInfo) || other.lastMessageInfo == lastMessageInfo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.preference, preference) || other.preference == preference)&&(identical(other.orderInfo, orderInfo) || other.orderInfo == orderInfo)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,threadType,otherUser,lastMessageInfo,createdAt,preference,orderInfo,unreadCount);

@override
String toString() {
  return 'ChatEntity(id: $id, threadType: $threadType, otherUser: $otherUser, lastMessageInfo: $lastMessageInfo, createdAt: $createdAt, preference: $preference, orderInfo: $orderInfo, unreadCount: $unreadCount)';
}


}

/// @nodoc
abstract mixin class $ChatEntityCopyWith<$Res>  {
  factory $ChatEntityCopyWith(ChatEntity value, $Res Function(ChatEntity) _then) = _$ChatEntityCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(fromJson: _threadTypeFromJson, toJson: _threadTypeToJson) ChatThreadType threadType, UserEntity otherUser,@JsonKey(name: 'lastMessage') LastMessageInfo? lastMessageInfo, DateTime createdAt, ConversationPreference? preference, OrderInfo? orderInfo, int unreadCount
});


$UserEntityCopyWith<$Res> get otherUser;$LastMessageInfoCopyWith<$Res>? get lastMessageInfo;$ConversationPreferenceCopyWith<$Res>? get preference;$OrderInfoCopyWith<$Res>? get orderInfo;

}
/// @nodoc
class _$ChatEntityCopyWithImpl<$Res>
    implements $ChatEntityCopyWith<$Res> {
  _$ChatEntityCopyWithImpl(this._self, this._then);

  final ChatEntity _self;
  final $Res Function(ChatEntity) _then;

/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? threadType = null,Object? otherUser = null,Object? lastMessageInfo = freezed,Object? createdAt = null,Object? preference = freezed,Object? orderInfo = freezed,Object? unreadCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,threadType: null == threadType ? _self.threadType : threadType // ignore: cast_nullable_to_non_nullable
as ChatThreadType,otherUser: null == otherUser ? _self.otherUser : otherUser // ignore: cast_nullable_to_non_nullable
as UserEntity,lastMessageInfo: freezed == lastMessageInfo ? _self.lastMessageInfo : lastMessageInfo // ignore: cast_nullable_to_non_nullable
as LastMessageInfo?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,preference: freezed == preference ? _self.preference : preference // ignore: cast_nullable_to_non_nullable
as ConversationPreference?,orderInfo: freezed == orderInfo ? _self.orderInfo : orderInfo // ignore: cast_nullable_to_non_nullable
as OrderInfo?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res> get otherUser {
  
  return $UserEntityCopyWith<$Res>(_self.otherUser, (value) {
    return _then(_self.copyWith(otherUser: value));
  });
}/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastMessageInfoCopyWith<$Res>? get lastMessageInfo {
    if (_self.lastMessageInfo == null) {
    return null;
  }

  return $LastMessageInfoCopyWith<$Res>(_self.lastMessageInfo!, (value) {
    return _then(_self.copyWith(lastMessageInfo: value));
  });
}/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversationPreferenceCopyWith<$Res>? get preference {
    if (_self.preference == null) {
    return null;
  }

  return $ConversationPreferenceCopyWith<$Res>(_self.preference!, (value) {
    return _then(_self.copyWith(preference: value));
  });
}/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderInfoCopyWith<$Res>? get orderInfo {
    if (_self.orderInfo == null) {
    return null;
  }

  return $OrderInfoCopyWith<$Res>(_self.orderInfo!, (value) {
    return _then(_self.copyWith(orderInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatEntity].
extension ChatEntityPatterns on ChatEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatEntity value)  $default,){
final _that = this;
switch (_that) {
case _ChatEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ChatEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(fromJson: _threadTypeFromJson, toJson: _threadTypeToJson)  ChatThreadType threadType,  UserEntity otherUser, @JsonKey(name: 'lastMessage')  LastMessageInfo? lastMessageInfo,  DateTime createdAt,  ConversationPreference? preference,  OrderInfo? orderInfo,  int unreadCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatEntity() when $default != null:
return $default(_that.id,_that.threadType,_that.otherUser,_that.lastMessageInfo,_that.createdAt,_that.preference,_that.orderInfo,_that.unreadCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(fromJson: _threadTypeFromJson, toJson: _threadTypeToJson)  ChatThreadType threadType,  UserEntity otherUser, @JsonKey(name: 'lastMessage')  LastMessageInfo? lastMessageInfo,  DateTime createdAt,  ConversationPreference? preference,  OrderInfo? orderInfo,  int unreadCount)  $default,) {final _that = this;
switch (_that) {
case _ChatEntity():
return $default(_that.id,_that.threadType,_that.otherUser,_that.lastMessageInfo,_that.createdAt,_that.preference,_that.orderInfo,_that.unreadCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(fromJson: _threadTypeFromJson, toJson: _threadTypeToJson)  ChatThreadType threadType,  UserEntity otherUser, @JsonKey(name: 'lastMessage')  LastMessageInfo? lastMessageInfo,  DateTime createdAt,  ConversationPreference? preference,  OrderInfo? orderInfo,  int unreadCount)?  $default,) {final _that = this;
switch (_that) {
case _ChatEntity() when $default != null:
return $default(_that.id,_that.threadType,_that.otherUser,_that.lastMessageInfo,_that.createdAt,_that.preference,_that.orderInfo,_that.unreadCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatEntity extends ChatEntity {
  const _ChatEntity({required this.id, @JsonKey(fromJson: _threadTypeFromJson, toJson: _threadTypeToJson) required this.threadType, required this.otherUser, @JsonKey(name: 'lastMessage') this.lastMessageInfo, required this.createdAt, this.preference, this.orderInfo, this.unreadCount = 0}): super._();
  factory _ChatEntity.fromJson(Map<String, dynamic> json) => _$ChatEntityFromJson(json);

@override final  String id;
@override@JsonKey(fromJson: _threadTypeFromJson, toJson: _threadTypeToJson) final  ChatThreadType threadType;
@override final  UserEntity otherUser;
@override@JsonKey(name: 'lastMessage') final  LastMessageInfo? lastMessageInfo;
@override final  DateTime createdAt;
@override final  ConversationPreference? preference;
@override final  OrderInfo? orderInfo;
@override@JsonKey() final  int unreadCount;

/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatEntityCopyWith<_ChatEntity> get copyWith => __$ChatEntityCopyWithImpl<_ChatEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.threadType, threadType) || other.threadType == threadType)&&(identical(other.otherUser, otherUser) || other.otherUser == otherUser)&&(identical(other.lastMessageInfo, lastMessageInfo) || other.lastMessageInfo == lastMessageInfo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.preference, preference) || other.preference == preference)&&(identical(other.orderInfo, orderInfo) || other.orderInfo == orderInfo)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,threadType,otherUser,lastMessageInfo,createdAt,preference,orderInfo,unreadCount);

@override
String toString() {
  return 'ChatEntity(id: $id, threadType: $threadType, otherUser: $otherUser, lastMessageInfo: $lastMessageInfo, createdAt: $createdAt, preference: $preference, orderInfo: $orderInfo, unreadCount: $unreadCount)';
}


}

/// @nodoc
abstract mixin class _$ChatEntityCopyWith<$Res> implements $ChatEntityCopyWith<$Res> {
  factory _$ChatEntityCopyWith(_ChatEntity value, $Res Function(_ChatEntity) _then) = __$ChatEntityCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(fromJson: _threadTypeFromJson, toJson: _threadTypeToJson) ChatThreadType threadType, UserEntity otherUser,@JsonKey(name: 'lastMessage') LastMessageInfo? lastMessageInfo, DateTime createdAt, ConversationPreference? preference, OrderInfo? orderInfo, int unreadCount
});


@override $UserEntityCopyWith<$Res> get otherUser;@override $LastMessageInfoCopyWith<$Res>? get lastMessageInfo;@override $ConversationPreferenceCopyWith<$Res>? get preference;@override $OrderInfoCopyWith<$Res>? get orderInfo;

}
/// @nodoc
class __$ChatEntityCopyWithImpl<$Res>
    implements _$ChatEntityCopyWith<$Res> {
  __$ChatEntityCopyWithImpl(this._self, this._then);

  final _ChatEntity _self;
  final $Res Function(_ChatEntity) _then;

/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? threadType = null,Object? otherUser = null,Object? lastMessageInfo = freezed,Object? createdAt = null,Object? preference = freezed,Object? orderInfo = freezed,Object? unreadCount = null,}) {
  return _then(_ChatEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,threadType: null == threadType ? _self.threadType : threadType // ignore: cast_nullable_to_non_nullable
as ChatThreadType,otherUser: null == otherUser ? _self.otherUser : otherUser // ignore: cast_nullable_to_non_nullable
as UserEntity,lastMessageInfo: freezed == lastMessageInfo ? _self.lastMessageInfo : lastMessageInfo // ignore: cast_nullable_to_non_nullable
as LastMessageInfo?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,preference: freezed == preference ? _self.preference : preference // ignore: cast_nullable_to_non_nullable
as ConversationPreference?,orderInfo: freezed == orderInfo ? _self.orderInfo : orderInfo // ignore: cast_nullable_to_non_nullable
as OrderInfo?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res> get otherUser {
  
  return $UserEntityCopyWith<$Res>(_self.otherUser, (value) {
    return _then(_self.copyWith(otherUser: value));
  });
}/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastMessageInfoCopyWith<$Res>? get lastMessageInfo {
    if (_self.lastMessageInfo == null) {
    return null;
  }

  return $LastMessageInfoCopyWith<$Res>(_self.lastMessageInfo!, (value) {
    return _then(_self.copyWith(lastMessageInfo: value));
  });
}/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversationPreferenceCopyWith<$Res>? get preference {
    if (_self.preference == null) {
    return null;
  }

  return $ConversationPreferenceCopyWith<$Res>(_self.preference!, (value) {
    return _then(_self.copyWith(preference: value));
  });
}/// Create a copy of ChatEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderInfoCopyWith<$Res>? get orderInfo {
    if (_self.orderInfo == null) {
    return null;
  }

  return $OrderInfoCopyWith<$Res>(_self.orderInfo!, (value) {
    return _then(_self.copyWith(orderInfo: value));
  });
}
}

// dart format on
