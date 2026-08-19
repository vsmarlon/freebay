---
name: freebay-flutter-feature
description: Use when scaffolding or modifying a Flutter feature in the Freebay frontend — enforces Clean Architecture (data/domain/presentation), Riverpod state management, Dio HTTP, design-system components, and go_router registration.
---

# Freebay Flutter Feature Scaffold

## Feature structure

```
lib/features/<feature>/
├── data/
│   ├── entities/          # data classes with @JsonSerializable() & .g.dart
│   ├── repositories/      # concrete repo implementing domain interface (Dio)
│   └── datasources/       # (optional) remote/local data sources
├── domain/
│   ├── repositories/      # abstract repository interface
│   └── usecases/          # business logic invokers
└── presentation/
    ├── controllers/       # Riverpod StateNotifier / Notifier
    ├── providers/         # Riverpod providers
    ├── pages/             # full-screen pages
    └── widgets/           # reusable UI widgets for this feature
```

## Step by step

### 1. Entity (`data/entities/`)

```dart
import 'package:json_annotation/json_annotation.dart';

part 'my_entity.g.dart';

@JsonSerializable()
class MyEntity {
  final String id;
  final String name;
  final int amount; // cents

  const MyEntity({required this.id, required this.name, required this.amount});

  factory MyEntity.fromJson(Map<String, dynamic> json) => _$MyEntityFromJson(json);
  Map<String, dynamic> toJson() => _$MyEntityToJson(this);
}
```

### 2. Repository interface (`domain/repositories/`)

```dart
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failure.dart';
import 'package:freebay/features/my_feature/data/entities/my_entity.dart';

abstract class MyEntityRepository {
  Future<Either<Failure, List<MyEntity>>> getAll();
  Future<Either<Failure, MyEntity>> getById(String id);
}
```

### 3. Concrete repository (`data/repositories/`)

Use the shared `http_client` from `shared/services/http_client.dart` (Dio-based):

```dart
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failure.dart';
import 'package:freebay/shared/utils/safe_call.dart';
import 'package:freebay/features/my_feature/domain/repositories/my_entity_repository.dart';
import 'package:freebay/features/my_feature/data/entities/my_entity.dart';

class MyEntityRepositoryImpl implements MyEntityRepository {
  final HttpClient _client;

  MyEntityRepositoryImpl(this._client);

  @override
  Future<Either<Failure, List<MyEntity>>> getAll() async {
    return safeCall<List<MyEntity>>(
      () => _client.get('/my-entities'),
      debugLabel: 'MY_ENTITY getAll',
      onSuccess: (response) {
        final list = (response.data['data'] as List)
            .map((e) => MyEntity.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(list);
      },
    );
  }

  @override
  Future<Either<Failure, MyEntity>> getById(String id) async {
    return safeCall<MyEntity>(
      () => _client.get('/my-entities/$id'),
      debugLabel: 'MY_ENTITY getById',
      onSuccess: (response) => Right(MyEntity.fromJson(response.data['data'])),
    );
  }
}
```

### 4. Riverpod providers (`presentation/providers/` or `controllers/`)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/features/my_feature/domain/repositories/my_entity_repository.dart';
import 'package:freebay/features/my_feature/data/repositories/my_entity_repository_impl.dart';

final myEntityRepositoryProvider = Provider<MyEntityRepository>((ref) {
  return MyEntityRepositoryImpl(ref.watch(httpClientProvider));
});

final myEntityListProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(myEntityRepositoryProvider);
  final result = await repo.getAll();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});
```

### 5. Page (`presentation/pages/`)

Always consume design-system components from `package:freebay/core/components/` or `package:freebay_design_system/components/`. Never inline a raw unstyled primitive.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/brutalist_box.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/features/my_feature/presentation/providers/my_feature_providers.dart';

class MyEntityListPage extends ConsumerWidget {
  const MyEntityListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitiesAsync = ref.watch(myEntityListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Entidades', style: AppTypography.displaySmall)),
      body: entitiesAsync.when(
        data: (entities) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => BrutalistBox(
            child: Text(entities[i].name, style: AppTypography.bodyMedium),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e', style: AppTypography.bodySmall)),
      ),
    );
  }
}
```

### 6. Route registration

Add the new route constant to `lib/core/router/app_routes.dart` and register it in the appropriate router module in `lib/core/router/routes/` or `lib/core/router/app_router.dart`.

```dart
GoRoute(
  path: AppRoutes.myEntity,
  builder: (context, state) => const MyEntityListPage(),
)
```

## Design System rules

- **0px border radius** everywhere — never `BorderRadius.circular()`
- **No shadows** on cards — use tonal layering (surface color shifts)
- **No `Divider()`** — use adjacent surface tones for section breaks
- **Space Grotesk** for headlines, **Inter** for body text
- **Primary color** (`#8A1083`) sparingly — "a laser, not a paint bucket"
- **Animations:** 150ms max, `Curves.linear`
- All screens **must handle dark mode** — use `context.isDark` and theme extension accessors
