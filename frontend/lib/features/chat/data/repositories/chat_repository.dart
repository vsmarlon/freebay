import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';

import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';
import 'package:freebay/features/chat/domain/repositories/i_chat_repository.dart';

class ChatRepository implements IChatRepository {
  @override
  Future<Either<Failure, List<ChatEntity>>> getChats({String? query}) async {
    try {
      final path = query != null && query.isNotEmpty
          ? '/chat/conversations?q=${Uri.encodeQueryComponent(query)}'
          : '/chat/conversations';
      final response = await HttpClient.instance.get(path);

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
  Future<Either<Failure, List<ChatEntity>>> getArchivedChats() async {
    try {
      final response = await HttpClient.instance.get('/chat/archived');

      if (response.statusCode == 200 && response.data != null) {
        final conversations = response.data['data']['conversations'] as List;
        final chats = conversations
            .map((json) => ChatEntity.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(chats);
      }
      return const Left(ServerFailure('Erro ao carregar conversas arquivadas'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage(
    String chatId,
    String message,
  ) async {
    try {
      await HttpClient.instance.post(
        '/chat/conversations/$chatId/messages',
        data: {'content': message},
      );
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

  @override
  Future<Either<Failure, void>> archiveChat(
    String id,
    ChatThreadType type,
    bool archived,
  ) async {
    try {
      await HttpClient.instance.patch(
        '/chat/conversations/$id/archive',
        data: {'archived': archived},
      );
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao arquivar conversa'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChat(
    String id,
    ChatThreadType type,
  ) async {
    try {
      await HttpClient.instance.delete('/chat/conversations/$id');
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao excluir conversa'));
    }
  }

  @override
  Future<Either<Failure, ConversationPreference>> setTheme(
    String id,
    ChatThreadType type,
    String theme,
  ) async {
    try {
      final response = await HttpClient.instance.patch(
        '/chat/conversations/$id/theme',
        data: {'theme': theme},
      );
      if (response.statusCode == 200 && response.data != null) {
        final prefData =
            response.data['data']['preference'] as Map<String, dynamic>;
        return Right(ConversationPreference.fromJson(prefData));
      }
      return const Left(ServerFailure('Erro ao alterar tema'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, ConversationPreference>> setBackground(
    String id,
    ChatThreadType type,
    String base64DataUri,
  ) async {
    try {
      final response = await HttpClient.instance.patch(
        '/chat/conversations/$id/background',
        data: {'backgroundUrl': base64DataUri},
      );
      if (response.statusCode == 200 && response.data != null) {
        final prefData =
            response.data['data']['preference'] as Map<String, dynamic>;
        return Right(ConversationPreference.fromJson(prefData));
      }
      return const Left(ServerFailure('Erro ao alterar plano de fundo'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        return const Left(
          ServerFailure('Imagem muito grande. Escolha uma imagem menor.'),
        );
      }
      return const Left(ServerFailure('Erro de conexão'));
    } catch (_) {
      return const Left(ServerFailure('Erro ao alterar plano de fundo'));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendRichMessage({
    required String conversationId,
    String? content,
    String type = 'TEXT',
    String? attachmentUrl,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final data = <String, dynamic>{'type': type};
      if (content != null) data['content'] = content;
      if (attachmentUrl != null) data['attachmentUrl'] = attachmentUrl;
      if (replyToId != null) data['replyToId'] = replyToId;
      if (metadata != null) data['metadata'] = metadata;
      final response = await HttpClient.instance.post(
        '/chat/conversations/$conversationId/messages',
        data: data,
      );
      if (response.statusCode == 201 && response.data != null) {
        return Right(
          MessageEntity.fromJson(response.data['data'] as Map<String, dynamic>),
        );
      }
      return const Left(ServerFailure('Falha ao enviar mensagem'));
    } catch (_) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(
    String conversationId,
    String messageId,
  ) async {
    try {
      await HttpClient.instance.delete(
        '/chat/conversations/$conversationId/messages/$messageId',
      );
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure('Erro ao apagar mensagem'));
    }
  }

  @override
  Future<Either<Failure, List<MessageReactionEntity>>> reactToMessage(
    String conversationId,
    String messageId,
    String emoji,
  ) async {
    try {
      final response = await HttpClient.instance.post(
        '/chat/conversations/$conversationId/messages/$messageId/react',
        data: {'emoji': emoji},
      );
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data['data']['reactions'] as List;
        return Right(
          list
              .map(
                (e) =>
                    MessageReactionEntity.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        );
      }
      return const Left(ServerFailure('Falha ao reagir'));
    } catch (_) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }
}
