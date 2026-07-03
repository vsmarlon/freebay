# QQPAG Backend Architecture — Reference for Freebay

> **Purpose:** This document captures the definitive architectural patterns from the QQPAG_APP NestJS monorepo so they can be mirrored faithfully in Freebay.  
> **Source codebase:** `QQPAG_APP/bff/` — NestJS 11 monorepo with Clean Architecture in newer modules  
> **Target:** Freebay NestJS backend  
> **Rule:** Do NOT break the patterns established here. Every deviation must be intentional and documented.

---

## Table of Contents

1. [Architecture Layers](#1-architecture-layers)
2. [The Either Monad (Domain Level)](#2-the-either-monad-domain-level)
3. [ResponseEntity (HTTP Boundary)](#3-responseentity-http-boundary)
4. [Module Structure — 3-Tier Aggregation](#4-module-structure--3-tier-aggregation)
5. [Complete Synchronous Flow Trace](#5-complete-synchronous-flow-trace)
6. [The Async Flow (RabbitMQ)](#6-the-async-flow-rabbitmq)
7. [Domain Entities & Models](#7-domain-entities--models)
8. [Repositories — Abstract Contract + Implementation](#8-repositories--abstract-contract--implementation)
9. [Usecases](#9-usecases)
10. [Services (API Layer Orchestrator)](#10-services-api-layer-orchestrator)
11. [Controllers](#11-controllers)
12. [Infrastructure Layer](#12-infrastructure-layer)
13. [Naming Conventions](#13-naming-conventions)
14. [Anti-patterns to Avoid](#14-anti-patterns-to-avoid)
15. [Pattern Rules (Strict)](#15-pattern-rules-strict)

---

## 1. Architecture Layers

The canonical layered architecture (from `qq-push` and `device-telemetry`):

```
┌─────────────────────────────────────────────────────┐
│                    HTTP Request                      │
└──────────────────┬──────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────┐
│  api/              Controller + Service              │
│  (routes, validation, HTTP boundary)                 │
├─────────────────────────────────────────────────────┤
│  usecases/         Business logic orchestration       │
│  (orchestrates domain operations, single purpose)    │
├─────────────────────────────────────────────────────┤
│  domain/           Domain layer (pure TypeScript)     │
│    entities/       Domain models (extends Entity)     │
│    repositories/   Abstract contracts (interfaces)    │
│    enum/           Enumerations                       │
├─────────────────────────────────────────────────────┤
│  data/             Data layer (infrastructure)        │
│    repositories/   Oracle implementations             │
├─────────────────────────────────────────────────────┤
│  @consumers/       RabbitMQ consumers (async)         │
│  @schedules/       Cron jobs                          │
│  @shared/          Firebase, SMS, DB, interceptors    │
└─────────────────────────────────────────────────────┘
```

**Dependency rule:** `domain/` knows about NOTHING. `data/` implements `domain/`. `usecases/` depends on `domain/` and `data/` (via DI). `api/` depends on `usecases/`. Dependencies point INWARD.

### Two Paradigms Coexisting (DO NOT REPLICATE THE OLD ONE)

| Aspect | Old MVC (90% of codebase) | ✅ Clean Architecture (mirror this) |
|--------|--------------------------|--------------------------------------|
| **Layer count** | 2: Controller → Service | 4: Controller → Service → Usecase → Repository |
| **DB access** | Service calls OracleService directly | Repository (abstract) → Data Repository (implement) |
| **Return type** | `ResponseEntity` (simple) | `RepositoryResponse<T>` (Either monad) |
| **Error handling** | `try/catch` returning `ResponseEntity.error()` | `left(Failure)` / `right(value)` via Either |
| **Entities** | Plain classes or `class-validator` DTOs | Domain entities extending `Entity` with `static create()` factory |
| **Found in** | `bff/src/app/cadastro/`, `login/`, `home/`, `recpag/` | `bff/api/qq-push/`, `bff/src/app/device-telemetry/`, `bff/src/app/beneficios-cartao/` |

**STRICT RULE:** Freebay MUST ONLY use the Clean Architecture pattern. Never the old Controller→Service→OracleService pattern.

---

## 2. The Either Monad (Domain Level)

All domain-level operations return an **Either monad** — a discriminated union of `Left<Failure>` or `Right<T>`.

### Type Aliases (from `@verdecard/qq-core`)

| Type Alias | Definition | Used By |
|---|---|---|
| `RepositoryResponse<T>` | `Promise<Either<Failure, T>>` | Repositories, Usecases |
| `UsecaseResponse<T>` | `Promise<Either<Failure, T>>` | Usecases (alias for semantics) |
| `EntityResponse<T>` | `Either<Failure, T>` | Entity static factories (synchonous) |

### Either Implementation

```typescript
// shared/interfaces/either.ts
export type Either<L, R> = Left<L, R> | Right<L, R>;

export class Left<L, R> {
  readonly value: L;
  isLeft(): this is Left<L, R> { return true; }
  isRight(): this is Right<L, R> { return false; }
}

export class Right<L, R> {
  readonly value: R;
  isLeft(): this is Left<L, R> { return false; }
  isRight(): this is Right<L, R> { return true; }
}

export const left = <L, R>(l: L): Either<L, R> => new Left(l);
export const right = <L, R>(r: R): Either<L, R> => new Right(r);
```

### Failure Hierarchy

```
Failure (extends Error)                  — base class
├── GetFailure
├── SaveFailure
├── UpdateFailure
├── DeleteFailure
├── InvalidParameterFailure              — can carry ClassValidationError[]
├── InvalidDataFailure
├── EmptyDataFailure
├── GetListFailure
├── EmptyListFailure
├── NotFoundFailure
├── DuplicatedParameterFailure
├── DuplicatedEntityFailure
├── CreateSignatureFailure
├── CheckSignatureFailure
├── ErrorMessenger                       — carries any error data
├── WalletFailure                        — codigo, msg, fluxo
└── WalletPaymentRequiredAnalysisFailure — rich wallet failure
```

**Usage pattern in a usecase:**

```typescript
const result = await this.repository.findByUser(cpf);
if (result.isLeft()) return left(result.value);  // propagate failure
const user = result.value;                        // unwrap success value
// ... business logic ...
return right(true);
```

**STRICT RULE:** Never throw exceptions for control flow. Every operation that can fail returns an Either. The only exceptions thrown are NestJS `HttpException` (for HTTP-layer concerns like 404, 401) and those are handled by the global `HttpExceptionFilter`.

---

## 3. ResponseEntity (HTTP Boundary)

`ResponseEntity` is a **simpler success/failure wrapper** used ONLY at the HTTP boundary — what Services return to Controllers.

### Implementation

```typescript
export class ResponseEntity {
  private success: boolean;
  private data?: string | Array<any> | any;
  private message?: string | any;
  private error?: string | any;

  isOk(): boolean { return this.success; }
  isError(): boolean { return !this.success; }
  isEmpty(): boolean { ... }
  isNotEmpty(): boolean { return !this.isEmpty(); }
  getData(): any { return this.data; }
  getError(): any { return this.error || this.message; }

  static success(data?) {
    const r = new ResponseEntity();
    r.success = true;
    r.data = data;
    return r;
  }

  static error(message, error?) {
    const r = new ResponseEntity();
    r.success = false;
    r.message = message;
    r.error = error;
    return r;
  }
}
```

### Flow of the Two Return Types

```
Controller returns ResponseEntity (POJO serialized by NestJS)
    ↑
Service unwraps Either → wraps in ResponseEntity
    ↑          ┌──────────────────────────────┐
Usecase returns│  RepositoryResponse<T>        │
  ↑            │  = Promise<Either<Failure,T>> │
  └────────────┴──────────────────────────────┘
Repository returns RepositoryResponse<T>
    ↑
OracleService returns { success, data, message }
```

**Service unwrapping pattern:**

```typescript
public async sendPushOnline(input: PushNotificationInput): Promise<ResponseEntity> {
  try {
    const result = await this.producerPushOnlineUsecase.execute(input);
    if (result.isRight()) return ResponseEntity.success(result.value);
    return ResponseEntity.error(result?.value?.message);
  } catch (err) {
    this.logger.error(err);
    return ResponseEntity.error('Ocorreu um erro ao enviar push');
  }
}
```

**STRICT RULE:** `ResponseEntity` is ONLY used in the Service layer. Usecases and Repositories ALWAYS return `RepositoryResponse<T>` (the Either monad). Never mix them.

---

## 4. Module Structure — 3-Tier Aggregation

### Directory Layout per Feature

```
<feature>/
├── <feature>-main.module.ts          # Tier 1: Aggregates sub-main modules (no controllers/providers)
├── constants/
│   ├── api-config.constantes.ts       # Feature-specific constants
│   └── endpoints.constants.ts         # Endpoint path constants
├── <sub-feature-a>/
│   ├── <sub-feature-a>-main.module.ts # Tier 2: Aggregates versioned modules
│   └── v1/                           # Tier 3: Actual implementation
│       ├── <sub-feature>.controller.ts
│       ├── <sub-feature>.service.ts
│       ├── <sub-feature>.module.ts
│       └── model/
│           ├── <action>.input.ts      # Input DTOs
│           └── <entity>.model.ts      # Response entities
├── <sub-feature-b>/
│   ├── <sub-feature-b>-main.module.ts
│   ├── v1/
│   └── v2/
```

### Clean Architecture Module Layout (for new modules)

```
<feature>/
├── api/                              # HTTP layer
│   ├── <feature>.controller.ts
│   ├── <feature>.service.ts
│   ├── <feature>.module.ts
│   ├── input/
│   │   └── <action>.input.ts         # Request DTOs
│   └── documentation/
│       ├── <feature>.documentation.ts        # Swagger docs
│       └── documentation-api-property-<f>.ts # ApiProperty constants
├── usecases/
│   ├── <usecase-name>/
│   │   ├── <usecase-name>.usecase.ts
│   │   ├── <usecase-name>.usecase.module.ts
│   │   ├── <usecase-name>.usecase.spec.ts
│   │   └── <usecase-name>.dto.ts
├── domain/
│   ├── entities/
│   │   └── <entity-name>.model.ts
│   ├── repositories/
│   │   └── <entity>.repository.ts    # Abstract class
│   └── enum/
│       └── <domain>.enum.ts
├── data/
│   └── repositories/
│       └── <entity>-database.repository.ts  # Oracle implementation
```

### Module Wiring Rules

**Versioned sub-module** (`<feature>.module.ts`):

```typescript
@Module({
  imports: [EmailGlobalModule],           // Shared dependency modules
  controllers: [CadastroResumidoController],
  providers: [CadastroResumidoService, DispositivoService, TokensService], // Services + cross-module services
})
export class CadastroResumidoModuleV8 {}
```

**Aggregator main module** (`<feature>-main.module.ts`):

```typescript
@Module({
  imports: [CadastroResumidoModuleV8, CadastroResumidoModuleV7, CadastroResumidoModuleV6],
})
export class CadastroResumidoMainModule {}
```

**Top-level aggregation:**

```typescript
@Module({
  imports: [CadastroResumidoMainModule, CompletoMainModule, EnderecoMainModule, ..., TokensMainModule],
})
export class CadastroMainModule {}
```

### Usecase Module (DI Binding happens HERE)

This is where the **abstract repository is bound to its concrete implementation:**

```typescript
@Module({
  imports: [SharedModule],
  providers: [
    { provide: NotificationRepository, useClass: NotificationDatabaseRepository },
    SendPushNotificationUsecase,
  ],
  exports: [SendPushNotificationUsecase],
})
export class SendPushNotificationUsecaseModule {}
```

**STRICT RULE:** The `provide/useClass` binding between abstract repository and concrete data implementation MUST happen at the **usecase module level**, never at the domain level and never at the app module level.

---

## 5. Complete Synchronous Flow Trace

```
HTTP POST /api/v1/notifications/push
  Body: { cpf, titulo, message, tipo, codigoAutorizacao, acao, ... }
```

### Layer-by-layer

#### 1. Controller

```typescript
@ApiTags('notifications')
@Controller('notifications')
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Post('push')
  @ApiEndpointDetails(NotificationDocumentation.PUSH)
  async push(@Body() input: PushNotificationInput) {
    return await this.notificationService.sendPushOnline(input);
  }
}
```

**Rules:**
- Route prefix at class level: `@Controller('notifications')`
- Input DTO decorated with `@Body()`
- ALL methods are `async` and return `Promise<ResponseEntity>` (serialized automatically by NestJS)
- Controller NEVER calls usecases or repositories directly — only the Service
- Custom `@ApiEndpointDetails` decorator for Swagger documentation

#### 2. Input DTO

```typescript
export class PushNotificationInput {
  @ApiProperty(DocumentationApiPropertyNotification.CPF)
  readonly cpf?: string;

  @ApiProperty(DocumentationApiPropertyNotification.TITULO)
  readonly titulo?: string;

  @ApiProperty(DocumentationApiPropertyNotification.MESSAGE)
  readonly message?: string;

  @ApiProperty(DocumentationApiPropertyNotification.TIPO)
  readonly tipo?: string;

  @ApiProperty(DocumentationApiPropertyNotification.CODIGO_AUTORIZACAO)
  readonly codigoAutorizacao?: string;

  @ApiProperty(DocumentationApiPropertyNotification.ACAO)
  readonly acao?: string;

  @ApiProperty(DocumentationApiPropertyNotification.TEMPO_VIGENCIA_BOTAO)
  readonly tempoVigenciaBotao?: number;
}
```

**Rules:**
- Properties are `readonly`
- Validation decorators: `@IsNotEmpty()`, `@IsOptional()`, `@IsString()`, `@Length(11, 11)`, `@IsEmail()`, `@ValidateNested()`, etc.
- Swagger via `@ApiProperty()` with centralized constant classes

#### 3. Service

```typescript
@Injectable()
export class NotificationService {
  constructor(
    private readonly producerPushOnlineUsecase: ProducerPushOnlineUsecase,
    private readonly producerPushInterativoUsecase: ProducerPushInterativoUsecase,
    private readonly sendPushFcmUsecase: SendPushFcmUsecase,
    private readonly sendSmsUsecase: SendSmsUsecase,
  ) {}

  public async sendPushOnline(input: PushNotificationInput): Promise<ResponseEntity> {
    try {
      const result = await this.producerPushOnlineUsecase.execute(input);
      if (result.isRight()) return ResponseEntity.success(result.value);
      return ResponseEntity.error(result?.value?.message);
    } catch (err) {
      this.logger.error(err);
      return ResponseEntity.error('Ocorreu um erro ao enviar push');
    }
  }
}
```

**The Service's ONLY job:** Call the usecase, unwrap Either, wrap in ResponseEntity.

#### 4. Usecase

```typescript
@Injectable()
export class ProducerPushOnlineUsecase implements Usecase<boolean> {
  constructor(private readonly publish: PublishUsecase) {}

  public async execute(input: PushNotificationInput): UsecaseResponse<boolean> {
    const push = PushNotificationModel.create(input);
    if (push.isLeft()) return left(push.value);

    await this.publish.call(push.value.toPlain(), RabbitMQConstants.QUEUE_SEND_PUSH_ONLINE);
    return right(true);
  }
}
```

**Rules:**
- Optionally implements `Usecase<T>` interface
- Single `execute()` method always returns `UsecaseResponse<T>` / `RepositoryResponse<T>`
- Creates domain entities via static `create()` factory (returns `EntityResponse<T>`)
- Orchestrates calls to repositories, other usecases, publish, etc.
- If any step returns `Left`, propagate it: `if (result.isLeft()) return left(result.value)`

#### 5. Domain Entity

```typescript
export class PushNotificationModel extends Entity {
  @Expose() @IsOptional() readonly cpf?: string;
  @Expose() @IsOptional() readonly titulo?: string;
  @Expose() @IsOptional() readonly message?: string;
  @Expose() @IsOptional() readonly tipo?: string;
  @Expose() @IsOptional() readonly codigoAutorizacao?: string;
  @Expose() @IsOptional() readonly data?: any;
  @Expose() @IsOptional() readonly acao?: string;
  @Expose() @IsOptional() readonly params?: any;
  @Expose() @IsOptional() readonly tempoVigenciaBotao?: number;
  @Expose() @IsOptional() readonly nomeCampanha?: string;
  @Expose() @IsOptional() readonly link?: string;

  private constructor(props: object) {
    super(props);
  }

  static create(props: object): EntityResponse<PushNotificationModel> {
    try {
      return right(new PushNotificationModel(props));
    } catch (err) {
      return left(err instanceof Failure ? err : new Failure());
    }
  }

  static createArray(props: object[]): EntityResponse<PushNotificationModel[]> {
    try {
      const data: PushNotificationModel[] = [];
      props.map((value) => { data.push(new PushNotificationModel(value)); });
      return right(data);
    } catch (err) {
      return left(err instanceof Failure ? err : new Failure());
    }
  }
}
```

**Rules:**
- Extends `Entity` from shared base
- Constructor is **private** — only called via static factory
- `static create(props)` returns `EntityResponse<T>` (Either monad)
- `static createArray(props[])` for collections
- `@Expose()` from `class-transformer` for serialization control
- `@IsOptional()` from `class-validator`
- Properties are `readonly`

#### 6. Abstract Repository (Domain Contract)

```typescript
export abstract class NotificationRepository {
  abstract findByUser(cpf: string): RepositoryResponse<InfoUserModel>;
  abstract saveMessage(
    cdCc: string, tipo: string, playerId: string, title: string,
    message: string, cdAut: string, responseId: string,
    acao?: string, link?: string, params?: string,
    nomeCampanha?: string, tempoVigenciaBotao?: number,
  ): RepositoryResponse<boolean>;
  abstract findAceiteSms(cpf: string): RepositoryResponse<InfoSmsModel>;
  abstract saveMessageSms(cpf: string, telefone: string, tipo: string, mensagem: string): RepositoryResponse<boolean>;
  abstract isEnviarSmsValorMinimo(cdAut: string): RepositoryResponse<boolean>;
}
```

**Rules:**
- Pure abstract class (can also be an interface)
- All methods return `RepositoryResponse<T>` — typed Either monad
- Located in `domain/repositories/`
- No implementation, no dependencies

#### 7. Data Repository (Oracle Implementation)

```typescript
@Injectable()
export class NotificationDatabaseRepository implements NotificationRepository {
  constructor(private readonly oracleService: OracleService) {}

  async findByUser(cpf: string): RepositoryResponse<InfoUserModel> {
    try {
      const response = await this.oracleService.select({
        query: `SELECT u.cpf, u.cd_cc, u.playerid, ... FROM app.appqq_user u WHERE u.cpf = :taxId`,
        params: { taxId: cpf },
      });
      if (response.isError()) return left(response.getData());
      if (response?.getData()?.length > 0) return InfoUserModel.create(response?.getData()[0]);
      return left(Failures.getFailure('Not found'));
    } catch (e) {
      this.logger.error(e);
      return left(e);
    }
  }

  async saveMessage(cdCc: string, tipo: string, ...): RepositoryResponse<boolean> {
    const response = await this.oracleService.insert({
      query: `INSERT INTO app.appqq_push (...) VALUES (...)`,
      params: { cdCc, tipo, ... },
    });
    if (response?.getData()?.rowsAffected > 0) return right(true);
    return left(Failures.default('Insert failed'));
  }
}
```

**Rules:**
- `@Injectable()` class
- `implements` the abstract repository
- Uses `OracleService` for DB access (raw SQL with `:param` binds)
- Returns domain entities via `Entity.create(response.getData()[0])`
- ALL methods wrapped in `try/catch`, returning `left(Failure)` on error
- Maps OracleService response to Either: `response.isError()` → `left()`, success → `right() | Entity.create()`

---

## 6. The Async Flow (RabbitMQ)

For operations that don't need immediate response, use the **producer-consumer pattern** via RabbitMQ.

### Flow Diagram

```
HTTP Request
  → Controller
    → Service
      → ProducerUsecase (creates entity, publishes to RabbitMQ)
        → PublishUsecase (publishes { id, key, data } to exchange)
          → RabbitMQ Queue
            → Consumer (@RabbitmqConsumer decorator)
              → SendPushNotificationUsecase (core business logic)
                → Repository.findByUser()       [Oracle]
                → FirebaseService.sendPush()     [FCM]
                → Repository.saveMessage()       [Oracle]
                → SmsService.send()              [SMS]
                → Repository.saveMessageSms()    [Oracle]
```

### Producer

```typescript
@Injectable()
export class ProducerPushOnlineUsecase implements Usecase<boolean> {
  constructor(private readonly publish: PublishUsecase) {}

  public async execute(input: PushNotificationInput): UsecaseResponse<boolean> {
    const push = PushNotificationModel.create(input);
    if (push.isLeft()) return left(push.value);

    await this.publish.call(
      push.value.toPlain(),
      RabbitMQConstants.QUEUE_SEND_PUSH_ONLINE,
    );
    return right(true);
  }
}
```

### Publish Usecase

```typescript
@Injectable()
export class PublishUsecase {
  constructor(private readonly rabbimqProducer: RabbitmqProducerService) {}

  public async call(input: any, key: string): UsecaseResponse<void> {
    const result = await this.rabbimqProducer.publish(
      RabbitMQConstants.EXCHANGE_QQ_PUSH,
      {
        id: IdService.getUUID(),
        key: key,
        data: input,
      },
    );
    if (!result) return left(Failures.default('Não foi possível publicar a mensagem.'));
    return right(void 0);
  }
}
```

### Consumer

```typescript
@Injectable()
export class SendPushOnlineConsumer {
  constructor(
    private readonly sendPushNotificationUsecase: SendPushNotificationUsecase,
    private readonly logConsumerService: LogConsumerService,
  ) {}

  @RabbitmqConsumer({ queue: RabbitMQConstants.QUEUE_SEND_PUSH_ONLINE, prefetchCount: 10 })
  async handler(message: PushNotificationDto) {
    const logConsumer = LogConsumer.create(message, RabbitMQConstants.QUEUE_SEND_PUSH_ONLINE);
    try {
      logConsumer.start();
      const result = await this.sendPushNotificationUsecase.execute(message.data);
      logConsumer.end();
      if (result.isLeft()) throw result.value;
      return right(true);
    } catch (e) {
      logConsumer.setError(e);
      return left(Failures.default(e));
    } finally {
      this.logConsumerService.send(logConsumer);
    }
  }
}
```

**Rules:**
- Producer returns `right(true)` immediately after publishing to queue
- Consumer handles all the actual work asynchronously
- Consumer DTO wraps the payload: `{ id: string, data: T }`
- Each consumer has dedicated logging via `LogConsumerService`
- `@RabbitmqConsumer` decorator configures queue binding + prefetch

---

## 7. Domain Entities & Models

### Entity Hierarchy

```typescript
@verdecard/qq-core
  └── Entity (base class)
        ├── PushNotificationModel
        ├── InfoUserModel
        ├── InfoSmsModel
        ├── GetPushModel
        ├── GetBatchControleModel
        ├── GetPushVerdecobModel
        └── PushNotificationInterativoModel
```

### Entity Rules (STRICT)

1. **Extend `Entity`** from the shared base class
2. **Private constructor** — `private constructor(props: object) { super(props); }`
3. **Static `create(props)`** — returns `EntityResponse<T>` (Either)
4. **Static `createArray(props[])`** — returns `EntityResponse<T[]>`
5. **All properties `readonly`**
6. **`@Expose()`** on every property for serialization
7. **`@IsOptional()`** on every property (all optional by default)
8. **No business logic** in entities — they are data holders only (anemic domain model is intentional)

### Input DTOs (Request Validation)

```typescript
export class CadastroResumidoInput {
  @IsNotEmpty({ message: '$property não pode ser nulo.' })
  @IsString({ message: ErrorConstants.INVALID_TYPE_STRING })
  @Length(11, 11, { message: ErrorConstants.INVALID })
  cpf: string;

  @IsNotEmpty({ message: '$property não pode ser nulo.' })
  @IsEmail()
  email: string;

  @IsOptional()
  biometriaAnalise?: boolean = false;

  @ValidateNested()
  deviceResumidoData = new NewDeviceInput();
}
```

**Rules:**
- File naming: `<action>.input.ts` (e.g., `cadastro-resumido.input.ts`, `send-token.input.ts`)
- Validation from `class-validator`: `@IsNotEmpty`, `@IsEmail`, `@IsString`, `@Length`, `@IsOptional`, `@ValidateNested`
- Error messages reference `ErrorConstants` class for consistency
- File naming convention: `*.input.ts` for requests

---

## 8. Repositories — Abstract Contract + Implementation

### Abstract Repository (in `domain/repositories/`)

```typescript
export abstract class NotificationRepository {
  abstract findByUser(cpf: string): RepositoryResponse<InfoUserModel>;
  abstract saveMessage(...): RepositoryResponse<boolean>;
}
```

**File naming:** `<entity>.repository.ts` (e.g., `notification.repository.ts`, `batch.repository.ts`)

### Concrete Implementation (in `data/repositories/`)

```typescript
@Injectable()
export class NotificationDatabaseRepository implements NotificationRepository {
  constructor(private readonly oracleService: OracleService) {}

  async findByUser(cpf: string): RepositoryResponse<InfoUserModel> { ... }
  async saveMessage(...): RepositoryResponse<boolean> { ... }
}
```

**File naming:** `<entity>-database.repository.ts` (e.g., `notification-database.repository.ts`)

### OracleService API (the only DB access method)

```typescript
// SELECT
await this.oracleService
  .select({ query: 'SELECT ... WHERE x = :param', params: { param: value } })
  .toPromise();

// INSERT with RETURNING
await this.oracleService
  .insert({ query: `INSERT INTO ... VALUES (...) RETURNING id INTO :id`,
            params: { id: { out: true, type: 'number' }, ... } })
  .toPromise();

// INSERT ALL (batch)
await this.oracleService
  .insertAll({ query: `INSERT INTO ... VALUES (...)`, params: arrayOfParams })
  .toPromise();

// UPDATE
await this.oracleService
  .update({ query: `UPDATE ... SET ... WHERE ...`, params: { ... } })
  .toPromise();

// EXECUTE (PL/SQL blocks)
await this.oracleService
  .execute({ query: `BEGIN ... END;`, params: { ... } })
  .toPromise();

// Response shape: { success: boolean, data?: any, message?: string }
// Check via: response.isError(), response.getData()
```

**Rules:**
- NO ORMs. All queries are raw SQL with `:param` binding syntax
- All responses are `Observable` — call `.toPromise()` to convert
- Response has `{ success, data, message }` shape — use `.isError()` / `.getData()`

---

## 9. Usecases

### Structure

```typescript
@Injectable()
export class ProducerPushOnlineUsecase implements Usecase<boolean> {
  constructor(private readonly publish: PublishUsecase) {}

  public async execute(input: PushNotificationInput): UsecaseResponse<boolean> {
    const push = PushNotificationModel.create(input);
    if (push.isLeft()) return left(push.value);

    await this.publish.call(push.value.toPlain(), RabbitMQConstants.QUEUE_SEND_PUSH_ONLINE);
    return right(true);
  }
}
```

**File naming:** `<action>.usecase.ts` (e.g., `producer-push-online.usecase.ts`, `send-push-notification.usecase.ts`)

**Directory structure per usecase:**

```
usecases/
  <usecase-name>/
    <usecase-name>.usecase.ts
    <usecase-name>.usecase.module.ts    ← DI wiring + exports
    <usecase-name>.usecase.spec.ts
    <usecase-name>.dto.ts               ← Usecase-specific DTOs (optional)
```

### Usecase Rules (STRICT)

1. **Single `execute()` method** — `public async execute(input?): UsecaseResponse<T>`
2. **Constructor-injected dependencies** — only repositories, other usecases, and domain services
3. **`implements Usecase<T>`** — optional but conventional
4. **Returns `UsecaseResponse<T>`** = `Promise<Either<Failure, T>>`
5. **Propagates errors** — `if (result.isLeft()) return left(result.value)`
6. **Creates domain entities** via static factory: `Entity.create(props)`
7. **No HTTP concerns** — no `ResponseEntity`, no `@Req()`, no headers
8. **Each usecase module** declares its own `provide/useClass` binding for abstract repositories
9. **Thin by design** — one usecase = one business operation

---

## 10. Services (API Layer Orchestrator)

### Role

The Service layer is the **adapter between HTTP and the domain layer**. It:

1. Receives calls from Controllers
2. Delegates to Usecases
3. Unwraps the Either monad (`isRight()` / `isLeft()`)
4. Wraps the result in `ResponseEntity`
5. Handles unexpected errors with `try/catch`

### Implementation

```typescript
@Injectable()
export class NotificationService {
  constructor(
    private readonly producerPushOnlineUsecase: ProducerPushOnlineUsecase,
  ) {}

  public async sendPushOnline(input: PushNotificationInput): Promise<ResponseEntity> {
    try {
      const result = await this.producerPushOnlineUsecase.execute(input);
      if (result.isRight()) return ResponseEntity.success(result.value);
      return ResponseEntity.error(result?.value?.message);
    } catch (err) {
      this.logger.error(err);
      return ResponseEntity.error('Ocorreu um erro ao enviar push');
    }
  }
}
```

**STRICT RULES:**
- Service ONLY calls usecases (never repositories, never OracleService directly)
- Service NEVER returns Either — always `Promise<ResponseEntity>`
- Service wraps all calls in `try/catch` for safety
- Service has minimal logic — it's a transliteration layer
- File naming: `<feature>.service.ts` (e.g., `notification.service.ts`)

---

## 11. Controllers

### Implementation

```typescript
@UseGuards(AuthGuard('jwt'), DeviceGuard, UsersGuard)
@Controller(`${EndpointsConstants.CADASTRO}/resumido/v8`)
export class CadastroResumidoController {
  constructor(private readonly cadastroResumidoService: CadastroResumidoService) {}

  @Post('register')
  register(@Req() req, @Body() body: CadastroResumidoInput, @AppDevice() appDevice: AppDeviceModel) {
    const fraudRulesInfo = {
      cpf: body.cpf,
      data: {
        IP_CAD_APP: req.headers['remote-addr'],
        GEO_REG_CAD_APP: req.headers['geoip-estado'],
        GEO_CID_CAD_APP: req.headers['geoip-regiao'],
      },
    };
    return this.cadastroResumidoService.register(body, fraudRulesInfo);
  }
}
```

**STRICT RULES:**
- `@UseGuards` at class level for authentication/authorization
- Route prefix uses `EndpointsConstants` for maintainability
- Version in route: `v1`, `v2`, ..., `v8`
- Methods are `public` (or `private`), always `async`
- Decorators: `@Post`, `@Get`, `@Body`, `@Req`, `@Param`, `@Cpf`, `@AppDevice`
- Controller delegates EVERYTHING to Service — zero business logic
- Controller may enrich request data (extract headers, transform params) before passing to Service
- Endpoint naming: **camelCase** methods, **kebab-case** routes

---

## 12. Infrastructure Layer

### Authentication & Authorization

```
AuthModuleV1
├── JwtStrategy (passport-jwt)  — validates JWT from Authorization header
├── LocalStrategy (passport-local) — username/password login
├── JwtAuthGuard
├── DeviceGuard — validates device fingerprint
└── UsersGuard — validates user context (status, terms acceptance, blocked)
```

### Crypto Middleware

Applied globally in `main.ts`:
- **Request:** Decrypts incoming encrypted payload (AES/CBC/PKCS7)
- **Response:** Encrypts outgoing response body
- Managed by `CryptoService` from `CryptoModuleV2` (Oracle-backed session store)

### Log Interceptor

Registered as `APP_INTERCEPTOR` or manually:
- Captures request/response/error for every API call
- Sends structured logs to RabbitMQ → consumed → persisted to Postgres
- Generates `x-log-id` correlation ID if missing

### Global Exception Filter

```typescript
app.useGlobalFilters(new HttpExceptionFilter());
```

Handles:
- `HttpException` → returns structured error response
- `AxiosError` → wraps upstream service errors
- Unknown errors → 500 with generic message

### Oracle Database Module

```
OracleDatabaseModule (via @verdecard/qq-core or custom)
├── NodeOracleService — low-level oracledb pool (connection pool, metrics, caching)
└── OracleService — high-level API (select, insert, update, delete, execute, insertAll)
```

- Connection pool configured via YAML (`config/{env}.yml`)
- Pool metrics collected every 10s (connections in use, open, idle, queue, max connections)
- Session callback resets Oracle package state per session
- Query results automatically camelCased via `Captalize.camelKeys()`

---

## 13. Naming Conventions

| Artifact | Convention | Example |
|---|---|---|
| **Module files** | `{feature}-main.module.ts`, `{feature}.module.ts` | `cadastro-main.module.ts`, `cadastro-resumido.module.ts` |
| **Controller files** | `{feature}.controller.ts` | `cadastro-resumido.controller.ts` |
| **Service files** | `{feature}.service.ts` | `cadastro-resumido.service.ts` |
| **Usecase files** | `{action}.usecase.ts` | `producer-push-online.usecase.ts` |
| **Usecase module** | `{action}.usecase.module.ts` | `send-push-notification.usecase.module.ts` |
| **DTO/Input files** | `{action}.input.ts` | `cadastro-resumido.input.ts`, `send-token.input.ts` |
| **Entity/Model files** | `{entity-name}.model.ts` | `push-notification.model.ts`, `info-user.model.ts` |
| **Repository (abstract)** | `{entity}.repository.ts` | `notification.repository.ts` |
| **Repository (impl)** | `{entity}-database.repository.ts` | `notification-database.repository.ts` |
| **Enum files** | `{domain}.enum.ts` | `push-type.enum.ts`, `batch-status.enum.ts` |
| **Constant files** | `{context}.constants.ts` | `endpoints.constants.ts`, `error.constants.ts` |
| **Version folders** | `v1/`, `v2/`, etc. | `completo/v1/`, `resumido/v8/` |
| **Consumer files** | `{event}.consumer.ts` | `send-push-online.consumer.ts` |
| **Schedule files** | `{action}-schedule.ts` | `send-push-carga-schedule.ts` |
| **Class naming** | PascalCase, feature prefix | `CadastroResumidoService`, `SendPushNotificationUsecase` |
| **Endpoints** | kebab-case, prefixed with domain | `cadastro/resumido/v8/register`, `notifications/push` |
| **Methods** | camelCase | `sendPushOnline()`, `validateIndicationCode()` |
| **Variables** | camelCase | `idTransaction`, `typeCadastroForm` |
| **Folder naming** | singular, kebab-case | `cadastro/`, `resumido/`, `endereco/`, `model/` |

---

## 14. Testing Strategy — Effect-TS, NOT Jest Mocks

All new tests MUST use **Effect-TS** (`effect` package) for dependency composition instead of Jest mocks (`jest.mock`, `useValue`, `mockResolvedValue`).

### Rationale

| Concern | Jest mocks (❌ BANNED) | Effect-TS (✅ REQUIRED) |
|---------|----------------------|------------------------|
| **Dep composition** | `Test.createTestingModule` + `useValue` mocks — compiles but doesn't exercise real behavior | `Layer.merge(LivePrisma, TestNotifications)` — typed, explicit, composable |
| **Deterministic time** | `jest.useFakeTimers` — flaky, doesn't compose | `TestClock.adjust("48 hours")` — advance virtual time exactly, assert boundaries |
| **Error channels** | `Either<AppError, T>` (manual assertions) | `Effect<T, E, R>` — adds `R` (requirements) so deps are tracked at the type level |
| **Structured concurrency** | ad-hoc `Promise.all` | `Effect.all` with interruption, supervision, retry policies |
| **Real DB testing** | mocks return hardcoded values, never exercise Prisma | Live Layer connects to test DB, exercises real queries, FKs, transactions |

### How to write Effect-TS tests

```typescript
import { Effect, TestClock, Layer } from 'effect';
import { assert, describe, it } from '...';

it('should reject open dispute after 48h window', async () => {
  const program = Effect.gen(function* () {
    const prisma = yield* PrismaTag;
    // seed order with deliveryConfirmedAt = now - 48h01m
    yield* prisma.order.create({ ... });
    // advance clock past boundary
    yield* TestClock.adjust("48 hours 1 minute");
    // execute
    const result = yield* Effect.promise(() =>
      openDisputeUseCase.execute({ orderId, userId, reason })
    );
    // assert
    assert.ok(isLeft(result));
  });

  await Effect.runPromise(
    program.pipe(
      Effect.provide(Layer.merge(LivePrismaLayer, TestNotificationsLayer))
    )
  );
});
```

**Pattern reference:** See `src/modules/disputes/effect-harness/` for the full implementation (Context.Tag definitions, LivePrismaLayer, TestNotificationsLayer, TestClock usage).

### Migration rule

- **Unit tests** that only verify pure business logic (e.g., entity creation, validation rules) may still use plain Jest.
- **Integration tests** and tests that touch a repository, database, time, or side effects MUST use Effect-TS.
- The `disputes/effect-harness/` pattern (tags.ts, live layer, test layer) is the canonical reference — reuse it, don't reinvent it.

---

## 15. Strict Typing — NO `any` Allowed

Every `any` in an abstract repository, data repository, usecase, or service is a bug waiting to happen. The `@prisma/client` generates full TypeScript types for every model, every include, every select. Use them.

### ❌ BANNED

```typescript
// BANNED — lazy, loses all type safety
abstract findById(id: string): RepositoryResponse<any>;
```

### ✅ REQUIRED

```typescript
// REQUIRED — use Prisma-generated types
abstract findById(id: string): RepositoryResponse<User | null>;
abstract findWithIncludes(id: string): RepositoryResponse<Prisma.UserGetPayload<{ include: { posts: true } }> | null>;
```

### For complex includes

Extract a type alias:

```typescript
type AdminDashboardUser = Prisma.UserGetPayload<{
  include: {
    posts: { select: { id: true, title: true } };
    _count: { select: { followers: true } };
  };
}>;
```

### Rules

| # | Rule | Violation = |
|---|------|-------------|
| 1 | Abstract repository methods NEVER return `any` | ❌ Reject PR |
| 2 | Data repository methods use same concrete type as abstract | ❌ Reject PR |
| 3 | Usecase parameters and return values are fully typed (no `any`) | ❌ Reject PR |
| 4 | Service methods use DTO types or Prisma types (never `any`) | ❌ Reject PR |
| 5 | Complex repository types go in `types/<name>.types.ts` (imported, not top-level in repository file) | ❌ Reject PR |
| 6 | Test mocks use `jest.Mocked<Partial<AbstractRepo>>`, not `as any` | ❌ Reject PR |

---

## 16. Anti-patterns to Avoid

These are patterns found in the old MVC codebase that must NOT be replicated in Freebay:

### ❌ Service calls OracleService directly
```typescript
// BAD — old pattern, do NOT replicate
@Injectable()
export class CompletoService {
  constructor(private db: OracleService) {}
  async save(input: any) {
    const result = await this.db.select({...}).toPromise();
    return ResponseEntity.success(result.data);
  }
}
```
**✅ DO THIS:**
```typescript
// GOOD — usecase delegates to abstract repository
@Injectable()
export class SaveCompletoUsecase {
  constructor(private readonly repository: CompletoRepository) {}
  async execute(input: CompletoInput): UsecaseResponse<CompletoOutput> {
    const result = await this.repository.save(input);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
```

### ❌ ResponseEntity in usecases or repositories
```typescript
// BAD — ResponseEntity belongs at HTTP boundary only
async findByUser(cpf: string): Promise<ResponseEntity> { ... }
```
**✅ DO THIS:**
```typescript
async findByUser(cpf: string): RepositoryResponse<InfoUserModel> { ... }
```

### ❌ Business logic in controllers
```typescript
// BAD — controller should only route and call service
@Post()
save(@Body() input: any) {
  if (!input.cpf) return ResponseEntity.error('CPF required');
  // more business logic...
  return this.service.save(input);
}
```

### ❌ Throwing exceptions for expected failures
```typescript
// BAD — expected failures should return left(Failure)
throw new NotFoundException('User not found');
```
**✅ DO THIS:**
```typescript
return left(Failures.getFailure('User not found'));
// Only throw for truly exceptional/unexpected errors
```

### ❌ Direct DB queries in usecases
```typescript
// BAD — usecases should not know about DB
@Injectable()
export class MyUsecase {
  constructor(private db: OracleService) {} // WRONG — inject repository interface
}
```

### ❌ Fat services that mix HTTP and domain logic
```typescript
// BAD — service doing too much
async save(input: any) {
  const result = await this.db.select(...).toPromise(); // DB access
  const transformed = this.transform(result); // domain logic
  return ResponseEntity.success(transformed); // HTTP wrapping
}
```

### ❌ Mixed return types
```typescript
// BAD — sometimes returns ResponseEntity, sometimes throws, sometimes raw object
async save(input: any) {
  if (!input.cpf) throw new BadRequestException();
  if (input.cpf === '000') return { error: 'blocked' };
  return ResponseEntity.success({ ok: true });
}
```

---

## 15. Pattern Rules (Strict)

These rules are **not negotiable**. Every file in Freebay must follow them.

### Layer Enforcement

| # | Rule | Violation = |
|---|---|---|
| 1 | Controller calls Service only (never Usecase/Repository directly) | ❌ Reject PR |
| 2 | Service calls Usecase only (never Repository/OracleService directly) | ❌ Reject PR |
| 3 | Usecase calls Repository (abstract interface) only | ❌ Reject PR |
| 4 | Repository implementation (data/) calls OracleService only | ❌ Reject PR |
| 5 | Domain layer has ZERO imports from api/, data/, or usecases/ | ❌ Reject PR |

### Return Type Enforcement

| # | Rule | Violation = |
|---|---|---|
| 6 | Repository returns `RepositoryResponse<T>` (Either monad) | ❌ Reject PR |
| 7 | Usecase returns `UsecaseResponse<T>` / `RepositoryResponse<T>` (Either) | ❌ Reject PR |
| 8 | Service returns `Promise<ResponseEntity>` (NEVER Either) | ❌ Reject PR |
| 9 | Entity static factories return `EntityResponse<T>` (Either) | ❌ Reject PR |

### Module Structure

| # | Rule | Violation = |
|---|---|---|
| 10 | Abstract repository ↔ concrete impl binding: only in UsecaseModule | ❌ Reject PR |
| 11 | UsecaseModule: `{ provide: AbstractRepo, useClass: ConcreteRepo }` | ❌ Reject PR |
| 12 | UsecaseModule: exports the Usecase (not the Repository) | ❌ Reject PR |
| 13 | MainModule: pure aggregator (no controllers/providers) | ❌ Reject PR |
| 14 | Each Usecase gets its own module file | ❌ Reject PR |

### Entity/Model

| # | Rule | Violation = |
|---|---|---|
| 15 | Entity constructor is private | ❌ Reject PR |
| 16 | Entity has `static create(props): EntityResponse<T>` | ❌ Reject PR |
| 17 | Entity properties are `readonly` | ❌ Reject PR |
| 18 | Entity extends `Entity` base class | ❌ Reject PR |
| 19 | Input DTOs use `class-validator` decorators | ❌ Reject PR |
| 20 | Input DTO properties are `readonly` | ❌ Reject PR |

### Async

| # | Rule | Violation = |
|---|---|---|
| 21 | Producer → async boundary → Consumer pattern for non-critical operations | ❌ Reject PR |
| 22 | Consumer has logging via LogConsumerService or equivalent | ❌ Reject PR |
| 23 | Prefetch count configured on consumer (recommended: 10) | ❌ Reject PR |

### Error Handling

| # | Rule | Violation = |
|---|---|---|
| 24 | Expected failures return `left(Failure)` — never throw | ❌ Reject PR |
| 25 | Unexpected errors caught in `try/catch` → `left(Failures.default(...))` | ❌ Reject PR |
| 26 | Global ExceptionFilter handles HttpException + unknown errors | ❌ Reject PR |

### General

| # | Rule | Violation = |
|---|---|---|
| 27 | SQL queries use `:param` binding syntax (never string interpolation) | ❌ Reject PR |
| 28 | Input validation via `class-validator`, never manual `if` checks | ❌ Reject PR |
| 29 | Every public method on Service has `try/catch` | ❌ Reject PR |
| 30 | All files follow the Naming Conventions table (Section 13) | ❌ Reject PR |

---

## Appendix A: Key Directories Reference (QQPAG_APP)

| Path | Purpose |
|---|---|
| `bff/src/app/` | Main BFF — 27 domain modules |
| `bff/src/shared/core/` | Auth, OracleService, Crypto, Device, Users, ResponseEntity, guards |
| `bff/src/shared/services/` | 42 internal/external service integrations |
| `bff/src/shared/errors/` | Failure hierarchy, exception classes |
| `bff/src/shared/middlewares/` | Crypto middleware |
| `bff/src/shared/validators/` | CPF/CNPJ validators |
| `bff/api/qq-push/src/` | **Primary reference** — Clean Architecture with usecases, abstract repos, entities, Either monad |
| `bff/api/qq-push/src/domain/` | Entities, abstract repositories, enums |
| `bff/api/qq-push/src/data/repositories/` | Oracle implementations |
| `bff/api/qq-push/src/usecases/` | All usecases (publish, send-push-notification, batch, notification) |
| `bff/api/qq-push/src/api/` | Controllers + Services + Input DTOs |
| `bff/api/qq-push/src/@consumers/` | RabbitMQ consumers |
| `bff/api/qq-push/src/@schedules/` | 14 cron schedules |
| `bff/api/qq-push/src/@shared/` | Firebase, SMS, Oracle module, interceptors, Swagger, constants |
| `bff/src/app/device-telemetry/` | **Secondary reference** — uses Either monad + gateways in main BFF |

## Appendix B: QQPAG Stack Versions

| Technology | Version |
|---|---|
| NestJS | 11.1.19 |
| TypeScript | 5.9.2 |
| Oracle DB Driver | oracledb 6.9.0 |
| PostgreSQL Driver | pg 8.16.3 |
| Redis | ioredis 5.7.0 |
| RabbitMQ | via @nestjs/microservices 11.1.19 |
| Auth | Passport (JWT 4.0.1, Local 1.0.0) |
| Validation | class-validator 0.14.2, class-transformer 0.5.1 |
| Config | YAML via configyml (internal VerdeCard package) |
| Internal Lib | @verdecard/qq-core 1.1.9 |
| Observability | dd-trace 5.96.0 (Datadog APM) |

---

*Document generated from analysis of `QQPAG_APP/bff/` — NestJS monorepo with Clean Architecture modules.*
