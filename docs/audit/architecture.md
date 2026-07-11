# Architectural Audit & Layering Violations

This report details the architectural deviations and layering violations discovered in the FreeBay backend. These violations compromise the maintainability, scalability, and testability of the system by breaking Clean Architecture principles.

---

## 1. Controller Direct Injection of PrismaService

According to the request-flow guidelines of the project, controllers should interact only with Use Cases, which in turn query abstractions. However, `UsersController` directly injects `PrismaService` and performs database queries or updates in multiple endpoints:

- **Injecting Prisma directly:**
  [users.controller.ts:L55](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/users/users.controller.ts#L55)
  ```typescript
  constructor(
    private readonly prisma: PrismaService,
    ...
  ) {}
  ```
- **Direct database counts during profile query:**
  [users.controller.ts:L84-L91](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/users/users.controller.ts#L84-L91) and [L399-L406](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/users/users.controller.ts#L399-L406)
  ```typescript
  const [postsCount, productsCount, activeStory] = await Promise.all([
    this.prisma.post.count({ where: { userId } }),
    this.prisma.product.count({ where: { sellerId: userId, status: { not: 'DELETED' } } }),
    this.prisma.story.findFirst({
      where: { userId, expiresAt: { gt: new Date() } },
      select: { id: true },
    }),
  ]);
  ```
- **Direct database write in FCM token updates:**
  [users.controller.ts:L269-L272](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/users/users.controller.ts#L269-L272)
  ```typescript
  await this.prisma.user.update({
    where: { id: userId },
    data: updateData,
  });
  ```

> [!WARNING]
> Direct database queries in controllers bypass the application's domain boundaries, making unit testing impossible without heavy mocking of the global Prisma client inside controller specs.

---

## 2. Bypassing of Use Cases (Direct Repository Injections)

Several endpoints in the `UsersController` bypass Use Cases entirely. They directly call repository methods to perform follow/unfollow and block/unblock actions:

- **Follow Endpoints:** Calling `FollowRepository` directly:
  [users.controller.ts:L445](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/users/users.controller.ts#L445)
  ```typescript
  await this.followRepository.follow(followerId, followingId);
  ```
- **Block Endpoints:** Calling `BlockRepository` directly:
  [users.controller.ts:L659](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/users/users.controller.ts#L659)
  ```typescript
  await this.blockRepository.block(blockerId, blockedId);
  ```

This bypasses orchestration, event dispatching, and business validation layers that belong in the Use Case execute methods.

---

## 3. Dependency Inversion Violation (Concrete Repositories in Use Cases)

Use Cases are injecting concrete database repository implementations (e.g., `PrismaOrderRepository`) instead of their domain-level abstract class/interface contracts. 

For instance, in `GetUserStatsUseCase`:
[get-user-stats.usecase.ts:L4-L14](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/users/usecases/get-user-stats.usecase.ts#L4-L14)
```typescript
import { PrismaOrderRepository } from '@/modules/orders/repositories/order.repository';
import { FollowRepository } from '../repositories/follow.repository';

@Injectable()
export class GetUserStatsUseCase {
  constructor(
    private readonly orderRepository: PrismaOrderRepository, // Concrete implementation
    private readonly followRepository: FollowRepository,     // Concrete implementation
  ) {}
}
```

> [!IMPORTANT]
> To comply with the Dependency Inversion Principle, Use Cases must inject abstract interfaces or abstract repository classes defined in the domain layer. The implementation is mapped at module bootstrap (`PrismaOrderRepository` bound to `OrderRepository`).

---

## 4. Nested `api/` Folder Structure

A structural inconsistency was found across several modules. Instead of organizing controllers, DTOs, and services directly under their module folders, there are nested `api/` directories:
- `nest-backend/src/modules/auth/api`
- `nest-backend/src/modules/chat/api`
- `nest-backend/src/modules/products/api`
- `nest-backend/src/modules/reviews/api`

This fragmentation breaks the domain-driven modularity layout followed by the rest of the codebase (e.g., `users`, `orders`, `social`, `stories`).

---

## 5. Bypassing `EitherInterceptor` via Manual Exception Throwing

The `EitherInterceptor` is a response interceptor designed to process the `Either` monad wrapper. If a use case returns a `Left(AppError)`, the interceptor formats the error and throws an appropriate HTTP status. If a `Right(value)` is returned, it extracts the success payload.

However, services like `AuthService` and `CategoryService` intercept the usecase output, unpack it manually, and throw exceptions directly. This throws errors outside of the interceptor pipeline:

- **In `AuthService`:**
  [auth.service.ts:L41-L42](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/auth/auth.service.ts#L41-L42)
  ```typescript
  const result = await this.registerUseCase.execute(input);
  if (result.isLeft()) throw result.value;
  ```
- **In `CategoryService`:**
  [category.service.ts:L14-L15](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/category/category.service.ts#L14-L15)
  ```typescript
  const result = await this.listCategoriesUseCase.execute();
  if (isLeft(result)) throw result.value;
  ```

This manual unpacking and throwing forces the controllers that consume these services to act as error-handling middle-layers, which defeats the purpose of the unified `EitherInterceptor`.

---

## 6. DTOs Missing `readonly` Modifiers

The codebase uses transfer and response classes (DTOs) that do not enforce compile-time immutability, lacking the `readonly` modifier.

- **`AuthSessionResponse` example:**
  [auth-response.class.ts:L4-L13](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/auth/dtos/auth-response.class.ts#L4-L13)
  ```typescript
  export class AuthSessionResponse {
    @ApiProperty({ type: UserResponse })
    user: UserResponse; // Should be: readonly user: UserResponse;

    @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...' })
    token: string;      // Should be: readonly token: string;
  }
  ```
- **`UserResponse` example:**
  [user.mapper.ts:L6-L45](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/users/mappers/user.mapper.ts#L6-L45)
  ```typescript
  export class UserResponse {
    id: string;         // Should be: readonly id: string;
    displayName: string;// Should be: readonly displayName: string;
  }
  ```

By making DTO properties writable, we invite potential accidental modifications of transfer data in interceptors or controller-level logic.

---

## 7. Missing `mappers/` Directories

While the `users` module has a clear `mappers/` folder containing data transformation schemas, other modules perform mapper/transformer mapping directly within the use cases or controllers, or lack structured mapping configurations entirely:
- **`social` module:** Lacks a dedicated `mappers/` directory. Formatting is done directly inside repositories or controller handlers.
- **`stories` module:** Lacks a `mappers/` directory, exposing raw structures to the outer layers.
- **`category` module:** Lacks a `mappers/` directory, causing raw Prisma models to be serialized directly into JSON responses.

---

## Remediation Plan

To resolve these layering violations, we recommend:
1. **Refactor `UsersController`:** Introduce appropriate Use Cases (e.g., `GetUserStats`, `UpdateFcmToken`, `FollowUser`, `UnfollowUser`) to encapsulate database actions and keep the controller stateless.
2. **Apply Dependency Inversion:** Define abstract repositories (e.g., `FollowRepository`, `BlockRepository`, `OrderRepository`) in a `domain/repositories` folder and map concrete implementations (e.g., `PrismaOrderRepository`) as NestJS providers using custom provider tokens.
3. **Harmonize Folder Structure:** Relocate nested `api/` folders up to the root module namespaces and create standard folders: `usecases/`, `mappers/`, `repositories/`, `dtos/`.
4. **Standardize `Either` Responses:** Modify `AuthService` and `CategoryService` methods to return `Either<AppError, T>` and return these directly from the controller so the `EitherInterceptor` processes them.
5. **Add `readonly` Modifiers:** Refactor all DTO classes to use `readonly` keywords.
