import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';

sealed class ChatEvent {
  const ChatEvent();
}

class NewMessageEvent extends ChatEvent {
  final MessageEntity message;
  const NewMessageEvent(this.message);
}

class ReactionUpdatedEvent extends ChatEvent {
  final String messageId;
  final List<MessageReactionEntity> reactions;
  const ReactionUpdatedEvent(this.messageId, this.reactions);
}

class MessageDeletedEvent extends ChatEvent {
  final String messageId;
  const MessageDeletedEvent(this.messageId);
}

class UserTypingEvent extends ChatEvent {
  final String userId;
  const UserTypingEvent(this.userId);
}

class UserStoppedTypingEvent extends ChatEvent {
  final String userId;
  const UserStoppedTypingEvent(this.userId);
}

class UserOnlineEvent extends ChatEvent {
  final String userId;
  const UserOnlineEvent(this.userId);
}

class UserOfflineEvent extends ChatEvent {
  final String userId;
  const UserOfflineEvent(this.userId);
}
