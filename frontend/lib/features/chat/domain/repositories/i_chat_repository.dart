import 'package:dartz/dartz.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract class IChatRepository {
  Future<Either<Failure, List<ChatEntity>>> getChats({String? query});
  Future<Either<Failure, List<ChatEntity>>> getArchivedChats();
  Future<Either<Failure, void>> sendMessage(String chatId, String message);
  Future<Either<Failure, void>> markAsRead(String chatId);
  Future<Either<Failure, void>> archiveChat(
      String id, ChatThreadType type, bool archived);
  Future<Either<Failure, void>> deleteChat(String id, ChatThreadType type);
  Future<Either<Failure, ConversationPreference>> setTheme(
      String id, ChatThreadType type, String theme);
  Future<Either<Failure, ConversationPreference>> setBackground(
      String id, ChatThreadType type, String base64DataUri);
}
