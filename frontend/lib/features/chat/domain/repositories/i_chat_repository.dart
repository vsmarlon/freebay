import 'package:dartz/dartz.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract class IChatRepository {
  Future<Either<Failure, List<ChatEntity>>> getChats();
  Future<Either<Failure, ChatEntity>> getChatById(String chatId);
  Future<Either<Failure, void>> sendMessage(String chatId, String message);
  Future<Either<Failure, void>> markAsRead(String chatId);
}
