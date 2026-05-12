import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/domain/repositories/i_chat_repository.dart';

class ChatRepository implements IChatRepository {
  @override
  Future<Either<Failure, List<ChatEntity>>> getChats() async {
    try {
      final response = await HttpClient.instance.get('/chat/conversations');

      if (response.statusCode == 200 && response.data != null) {
        final conversations = response.data['data']['conversations'] as List;
        final chats = conversations
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
      final response =
          await HttpClient.instance.get('/chat/conversations/$chatId');

      if (response.statusCode == 200 && response.data != null) {
        final messages = response.data['data']['messages'] as List;
        if (messages.isEmpty) {
          return const Left(ServerFailure('Conversa não encontrada'));
        }
        final chat = ChatEntity.fromJson({
          'id': chatId,
          'messages': messages,
        });
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
      await HttpClient.instance.post('/chat/conversations/$chatId/messages',
          data: {'content': message});
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao enviar mensagem'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String chatId) async {
    try {
      await HttpClient.instance.patch('/chat/conversations/$chatId/read');
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao marcar como lido'));
    }
  }
}
