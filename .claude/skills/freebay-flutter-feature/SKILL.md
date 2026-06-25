---
name: freebay-flutter-feature
description: Use when scaffolding or modifying a Flutter feature in the Freebay frontend — enforces Clean Architecture (data/domain/presentation), Riverpod state management, Dio HTTP, design-system components, and go_router registration.
---

# Freebay Flutter Feature Scaffold

## Feature structure

```
lib/features/<feature>/
├── data/
│   ├── entities/          # data classes / Freezed models
│   ├── repositories/      # concrete repo implementing domain interface (Dio)
│   └── datasources/       # (optional) remote/local data sources
├── domain/
│   ├── repositories/      # abstract repository interface
│   └── usecases/          # business logic
└── presentation/
    ├── controllers/       # Riverpod notifiers / providers
    ├── providers/         # Riverpod providers
    ├── pages/             # full-screen pages
    └── widgets/           # reusable UI widgets for this feature
```

## Step by step

### 1. Entity (`data/entities/`)

```dart
class MyEntity {
  final String id;
  final String name;
  final int amount; // cents

  const MyEntity({required this.id, required this.name, required this.amount});

  factory MyEntity.fromJson(Map<String, dynamic> json) => MyEntity(
    id: json['id'] as String,
    name: json['name'] as String,
    amount: json['amount'] as int,
  );
}
```

### 2. Repository interface (`domain/repositories/`)

```dart
abstract class MyEntityRepository {
  Future<List<MyEntity>> getAll();
  Future<MyEntity> getById(String id);
}
```

### 3. Concrete repository (`data/repositories/`)

Use the shared `http_client` from `shared/services/http_client.dart` (Dio-based):

```dart
import 'package:freebay/shared/services/http_client.dart';

class MyEntityRepositoryImpl implements MyEntityRepository {
  final HttpClient _client;

  MyEntityRepositoryImpl(this._client);

  @override
  Future<List<MyEntity>> getAll() async {
    final response = await _client.get('/my-entities');
    return (response.data['data'] as List).map((e) => MyEntity.fromJson(e)).toList();
  }
}
```

### 3. Riverpod providers (`presentation/providers/` or `controllers/`)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_entity_provider.g.dart';

@riverpod
MyEntityRepositoryImpl myEntityRepository(MyEntityRepositoryRef ref) {
  return MyEntityRepositoryImpl(ref.watch(httpClientProvider));
}

@riverpod
Future<List<MyEntity>> myEntityList(MyEntityListRef ref) async {
  final repo = ref.watch(myEntityRepositoryProvider);
  return repo.getAll();
}
```

### 4. Page (`presentation/pages/`)

Always consume design-system components from `core/components/`. Never inline a primitive.

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/theme/app_colors.dart';

class MyEntityListPage extends ConsumerWidget {
  const MyEntityListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitiesAsync = ref.watch(myEntityListProvider);

    return Scaffold(
      body: entitiesAsync.when(
        data: (entities) => ListView.builder(
          itemCount: entities.length,
          itemBuilder: (_, i) => ListTile(title: Text(entities[i].name)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
```

### 5. Route registration

Add the new page to `core/router/app_router.dart`:

```dart
// Import the page
import 'package:freebay/features/<feature>/presentation/pages/<feature>_page.dart';

// Add a GoRoute entry
GoRoute(
  path: '/<feature>',
  name: '<feature>',
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

## References

- Clean exemplar features: `features/reviews/`, `features/favorites/`
- Shared HTTP client: `shared/services/http_client.dart`
- Project Either type: `shared/either/either.dart`
- Design system components: `core/components/`
