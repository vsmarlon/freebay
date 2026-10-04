import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:freebay/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('freebay-cache-');
    Hive.init(directory.path);
    StorageService.enableCacheStore();
  });

  test(
    'cached JSON is isolated by user and removed on logout cleanup',
    () async {
      await StorageService.writeCachedJson(
        userId: 'alice',
        key: 'profile',
        json: {'name': 'Alice'},
      );

      expect(
        await StorageService.readCachedJson(userId: 'alice', key: 'profile'),
        {'name': 'Alice'},
      );
      expect(
        await StorageService.readCachedJson(userId: 'bob', key: 'profile'),
        isNull,
      );

      await StorageService.clearUserCache(userId: 'alice');

      expect(
        await StorageService.readCachedJson(userId: 'alice', key: 'profile'),
        isNull,
      );
    },
  );

  test('a pending write cannot restore user cache after purge', () async {
    final write = StorageService.writeCachedJson(
      userId: 'alice',
      key: 'feed',
      json: {
        'items': ['cached'],
      },
    );

    await StorageService.clearUserCache(userId: 'alice');
    await write;

    expect(
      await StorageService.readCachedJson(userId: 'alice', key: 'feed'),
      isNull,
    );
  });

  test('logout purges persisted cache when its Hive box is closed', () async {
    await StorageService.writeCachedJson(
      userId: 'alice',
      key: 'profile',
      json: {'name': 'Alice'},
    );
    await Hive.box<String>('user_cache_v1').close();

    await StorageService.clearUserCache(userId: 'alice');

    final reopened = await Hive.openBox<String>('user_cache_v1');
    expect(reopened.containsKey('alice:profile'), isFalse);
  });
}
