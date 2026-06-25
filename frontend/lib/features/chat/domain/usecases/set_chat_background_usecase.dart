import 'package:dartz/dartz.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class SetChatBackgroundUsecase {
  final IChatRepository _repository;

  SetChatBackgroundUsecase(this._repository);

  Future<Either<Failure, ConversationPreference>> call(
      String id, ChatThreadType type, String base64DataUri) {
    return _repository.setBackground(id, type, base64DataUri);
  }
}
