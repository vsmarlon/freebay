import 'package:dartz/dartz.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class ArchiveChatUsecase {
  final IChatRepository _repository;

  ArchiveChatUsecase(this._repository);

  Future<Either<Failure, void>> call(
      String id, ChatThreadType type, bool archived) {
    return _repository.archiveChat(id, type, archived);
  }
}
