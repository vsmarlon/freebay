import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_preference.freezed.dart';
part 'conversation_preference.g.dart';

@freezed
abstract class ConversationPreference with _$ConversationPreference {
  const factory ConversationPreference({
    required String id,
    required String userId,
    String? orderId,
    String? directConversationId,
    @Default(false) bool isArchived,
    @Default(false) bool isDeleted,
    @Default('DEFAULT') String theme,
    String? backgroundUrl,
  }) = _ConversationPreference;

  factory ConversationPreference.fromJson(Map<String, dynamic> json) =>
      _$ConversationPreferenceFromJson(json);
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
