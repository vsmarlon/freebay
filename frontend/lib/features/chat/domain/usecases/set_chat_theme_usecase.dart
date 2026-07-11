import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class SetChatThemeUsecase {
  final IChatRepository _repository;

  SetChatThemeUsecase(this._repository);

  Future<Either<Failure, ConversationPreference>> call(
    String id,
    ChatThreadType type,
    String theme,
  ) {
    return _repository.setTheme(id, type, theme);
  }
}
