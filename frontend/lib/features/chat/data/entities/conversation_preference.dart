import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'conversation_preference.g.dart';

@JsonSerializable()
class ConversationPreference extends Equatable {
  final String id;
  final String userId;
  final String? orderId;
  final String? directConversationId;
  @JsonKey(defaultValue: false)
  final bool isArchived;
  @JsonKey(defaultValue: false)
  final bool isDeleted;
  @JsonKey(defaultValue: 'DEFAULT')
  final String theme;
  final String? backgroundUrl;

  const ConversationPreference({
    required this.id,
    required this.userId,
    this.orderId,
    this.directConversationId,
    this.isArchived = false,
    this.isDeleted = false,
    this.theme = 'DEFAULT',
    this.backgroundUrl,
  });

  factory ConversationPreference.fromJson(Map<String, dynamic> json) =>
      _$ConversationPreferenceFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationPreferenceToJson(this);

  ConversationPreference copyWith({
    bool? isArchived,
    bool? isDeleted,
    String? theme,
    String? backgroundUrl,
  }) {
    return ConversationPreference(
      id: id,
      userId: userId,
      orderId: orderId,
      directConversationId: directConversationId,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      theme: theme ?? this.theme,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        orderId,
        directConversationId,
        isArchived,
        isDeleted,
        theme,
        backgroundUrl
      ];
}

enum ChatTheme {
  defaultTheme('DEFAULT', '#8A1083'),
  crimson('CRIMSON', '#DC2626'),
  cobalt('COBALT', '#2563EB'),
  forest('FOREST', '#16A34A'),
  amber('AMBER', '#D97706'),
  slate('SLATE', '#64748B');

  const ChatTheme(this.apiValue, this.accentHex);

  final String apiValue;
  final String accentHex;

  static ChatTheme fromApiValue(String value) => ChatTheme.values.firstWhere(
        (t) => t.apiValue == value,
        orElse: () => ChatTheme.defaultTheme,
      );
}
