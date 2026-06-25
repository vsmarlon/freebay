import 'package:dartz/dartz.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class DeleteChatUsecase {
  final IChatRepository _repository;

  DeleteChatUsecase(this._repository);

  Future<Either<Failure, void>> call(String id, ChatThreadType type) {
    return _repository.deleteChat(id, type);
  }
}
