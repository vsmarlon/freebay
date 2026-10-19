import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';

class _Adapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions)> handlers = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final handler = handlers['${options.method} ${options.path}'];
    return handler?.call(options) ??
        ResponseBody.fromString(
          '',
          404,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, dynamic> _user(String id, String name) => {
  'id': id,
  'displayName': name,
};

Map<String, dynamic> _chat({
  required String id,
  required String threadType,
  required String message,
  required String userId,
  required String userName,
  Map<String, dynamic>? product,
  Map<String, dynamic>? orderInfo,
}) => {
  'id': id,
  'threadType': threadType,
  'otherUser': _user(userId, userName),
  'createdAt': '2026-09-14T05:00:00.000Z',
  'lastMessage': {'content': message, 'createdAt': '2026-09-14T05:00:00.000Z'},
  'unreadCount': 7,
  'product': ?product,
  'orderInfo': ?orderInfo,
};

void main() {
  test('parses active chats with direct and order product context', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;
    adapter.handlers['GET /chat/conversations'] = (_) => _json({
      'success': true,
      'data': {
        'items': [
          _chat(
            id: 'direct-1',
            threadType: 'DIRECT',
            message: 'Mensagem direta',
            userId: 'user-2',
            userName: 'Alice',
            product: {
              'id': 'product-1',
              'title': 'Produto direto',
              'imageUrl': null,
              'status': 'ACTIVE',
            },
          ),
          _chat(
            id: 'order-1',
            threadType: 'ORDER',
            message: 'Mensagem do pedido',
            userId: 'user-3',
            userName: 'Bob',
            orderInfo: {
              'id': 'order-1',
              'status': 'PAID',
              'productTitle': 'Produto pedido',
            },
          ),
        ],
        'hasMore': true,
        'nextCursor': 'next-cursor',
      },
    });

    final result = await ChatRepository(client: dio).getChats();

    expect(result.isRight, isTrue);
    result.fold((_) => fail('active chats parse'), (page) {
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'next-cursor');
      expect(page.items[0].productTitle, 'Produto direto');
      expect(page.items[0].otherName, 'Alice');
      expect(page.items[0].unreadCount, 7);
      expect(page.items[0].lastMessage, 'Mensagem direta');
      expect(page.items[0].timestamp.toUtc(), DateTime.utc(2026, 9, 14, 5));
      expect(page.items[1].productTitle, 'Produto pedido');
      expect(page.items[1].otherName, 'Bob');
    });
  });

  test('mute writes the canonical per-conversation preference', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;
    RequestOptions? captured;
    adapter.handlers['PATCH /chat/conversations/direct-1/theme'] = (options) {
      captured = options;
      return _json({
        'success': true,
        'data': {'id': 'preference-1', 'muted': true, 'theme': 'COBALT'},
      });
    };

    final result = await ChatRepository(
      client: dio,
    ).setMuted('direct-1', ChatThreadType.direct, true);

    expect(captured?.data, {'muted': true});
    expect(result.isRight, isTrue);
    result.fold((_) => fail('mute preference response'), (preference) {
      expect(preference.muted, isTrue);
      expect(preference.theme, 'COBALT');
    });
  });

  test(
    'view-once open sends the opening key in JSON and parses server time',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final adapter = _Adapter();
      dio.httpClientAdapter = adapter;
      RequestOptions? captured;
      adapter.handlers['POST /chat/conversations/direct-1/messages/message-1/view-once/open'] =
          (options) {
            captured = options;
            return _json({
              'success': true,
              'data': {
                'messageId': 'message-1',
                'readAt': '2026-10-09T12:00:00.000Z',
                'mediaUrl': '/media/chat/once.jpg',
              },
            });
          };

      final result = await ChatRepository(client: dio).openViewOnce(
        'direct-1',
        'message-1',
        '9c858901-8a57-4791-81fe-4c455b099bc9',
      );

      expect(captured?.data, {
        'openingKey': '9c858901-8a57-4791-81fe-4c455b099bc9',
      });
      expect(captured?.uri.queryParameters, isEmpty);
      expect(result.isRight, isTrue);
      result.fold((_) => fail('view-once open response'), (opened) {
        expect(opened.mediaUrl, '/media/chat/once.jpg');
        expect(opened.readAt, DateTime.utc(2026, 10, 9, 12));
      });
    },
  );

  test('view-once close sends the opening key only in JSON', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;
    RequestOptions? captured;
    adapter.handlers['POST /chat/conversations/direct-1/messages/message-1/view-once/close'] =
        (options) {
          captured = options;
          return _json({'success': true, 'data': null});
        };

    final result = await ChatRepository(client: dio).closeViewOnce(
      'direct-1',
      'message-1',
      '9c858901-8a57-4791-81fe-4c455b099bc9',
    );

    expect(captured?.data, {
      'openingKey': '9c858901-8a57-4791-81fe-4c455b099bc9',
    });
    expect(captured?.uri.queryParameters, isEmpty);
    expect(result.isRight, isTrue);
  });
}
