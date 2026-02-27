import 'package:freebay/shared/services/http_client.dart';
import '../../../../shared/errors/failures/failures.dart';
import 'package:dartz/dartz.dart';
import '../entities/chat_entity.dart';
import '../../domain/repositories/i_chat_repository.dart';

class ChatRepository implements IChatRepository {
  @override
  Future<Either<Failure, List<ChatEntity>>> getChats() async {
    try {
      final response = await HttpClient.instance.get('/chat');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List;
        final chats = data
            .map((json) => ChatEntity.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(chats);
      }
      return const Left(ServerFailure('Erro ao carregar conversas'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> getChatById(String chatId) async {
    try {
      final response = await HttpClient.instance.get('/chat/$chatId');

      if (response.statusCode == 200 && response.data != null) {
        final chat =
            ChatEntity.fromJson(response.data['data'] as Map<String, dynamic>);
        return Right(chat);
      }
      return const Left(ServerFailure('Erro ao carregar conversa'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage(
      String chatId, String message) async {
    try {
      await HttpClient.instance
          .post('/chat/$chatId/messages', data: {'message': message});
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao enviar mensagem'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String chatId) async {
    try {
      await HttpClient.instance.patch('/chat/$chatId/read');
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao marcar como lido'));
    }
  }
}
