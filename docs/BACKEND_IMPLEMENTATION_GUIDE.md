# Guia de implementação da arquitetura do backend

Receitas concretas baseadas em [ADR 0004](adr/0004-selective-modular-backend-architecture.md), [ADR 0005](adr/0005-module-template-public-api-uow-events.md) e código atual. Futuro não significa autorizado: confira [plano](BACKEND_ARCHITECTURE_PLAN.md) e [hardening](HARDENING_PLAN.md).

## 1. Selecione a fronteira pela regra

- **Tier A — estado/dinheiro:** entity para regra de estado significativa; port quando a fronteira justifica. Não substitui `updateMany` condicional/unique/claims/locks.
- **Tier B — CRUD/configuração:** repository concreto local é permitido; output plain e limitado, sem entity/port/mapper que apenas replique Prisma.
- **Tier C — leitura pesada:** selecione diretamente uma projeção tipada para a query. Não carregue aggregate/entity se a leitura é uma projeção.

Não crie layers vazias nem mova providers/arquivos por simetria antes de o gate cobrir a dependência pretendida.

## 2. Tier B: preservar `Either` e projetar a saída

### Exemplo: leitura de Category

O contrato existente é `RepositoryResponse` → `Either<AppError, { category: CategoryOutput }>`; ausência continua `NotFoundError('Categoria')`. Não devolva `Promise<CategoryOutput | null>` ao controller.

Adicione `CategoryOutput` ao arquivo `nest-backend/src/modules/category/types/category.types.ts`; preserve o `CategoryWithChildren` usado pela listagem:

```ts
import { Category } from '@prisma/client';

export type CategoryWithChildren = Category & {
  children: CategoryWithChildren[];
};

export type CategoryOutput = {
  id: string;
  name: string;
  slug: string;
  parentId: string | null;
  createdAt: Date;
  updatedAt: Date;
};
```

Repositório próprio, em `data/repositories/category-database.repository.ts`. Código completo abaixo mantém `findAll`/`buildTree` para o endpoint de listagem e adiciona `findById` com seis campos plain. Use o helper existente `repositoryResponse` para erro de persistência:

```ts
import { Injectable } from '@nestjs/common';
import { Category } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { CategoryOutput, CategoryWithChildren } from '../../types/category.types';

@Injectable()
export class CategoryDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(): RepositoryResponse<CategoryWithChildren[]> {
    return repositoryResponse(async () => {
      const categories = await this.prisma.category.findMany({ orderBy: { name: 'asc' } });
      return this.buildTree(categories);
    }, 'Erro ao listar categorias');
  }

  async findById(id: string): RepositoryResponse<CategoryOutput | null> {
    return repositoryResponse(
      () => this.prisma.category.findUnique({
        where: { id },
        select: {
          id: true,
          name: true,
          slug: true,
          parentId: true,
          createdAt: true,
          updatedAt: true,
        },
      }),
      'Erro ao buscar categoria',
    );
  }

  private buildTree(categories: Category[]): CategoryWithChildren[] {
    const byId = new Map<string, CategoryWithChildren>(
      categories.map((category) => [category.id, { ...category, children: [] }]),
    );
    const roots: CategoryWithChildren[] = [];
    for (const category of categories) {
      const node = byId.get(category.id)!;
      const parent = category.parentId ? byId.get(category.parentId) : undefined;
      if (parent) parent.children.push(node);
      else roots.push(node);
    }
    return roots;
  }
}
```

O use case conserva o output envelope e o erro esperado:

```ts
import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { CategoryOutput } from '../types/category.types';
import { CategoryDatabaseRepository } from '../data/repositories/category-database.repository';

@Injectable()
export class GetCategoryUseCase {
  constructor(private readonly categoryRepository: CategoryDatabaseRepository) {}

  async execute(id: string): Promise<Either<AppError, { category: CategoryOutput }>> {
    const result = await this.categoryRepository.findById(id);
    if (result.isLeft()) return left(result.value);
    if (!result.value) return left(new NotFoundError('Categoria'));
    return right({ category: result.value });
  }
}
```

No controller, preserve `ParseUUIDPipe`, `GetPublic` e `unwrap`. O endpoint de listagem também faz parte do contrato; não o remova ao alterar `findOne`:

```ts
import { Controller, Param, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetPublic } from '@/shared/decorators';
import { unwrap } from '@/shared/http/unwrap';
import { ListCategoriesUseCase } from './usecases/list-categories.usecase';
import { GetCategoryUseCase } from './usecases/get-category.usecase';

@ApiTags('Categories')
@Controller('categories')
export class CategoryController {
  constructor(
    private readonly listCategoriesUseCase: ListCategoriesUseCase,
    private readonly getCategoryUseCase: GetCategoryUseCase,
  ) {}

  @GetPublic('List all categories')
  async findAll() {
    return unwrap(await this.listCategoriesUseCase.execute());
  }

  @GetPublic(':id', {
    summary: 'Get category by ID',
    params: [{ name: 'id', description: 'Category UUID' }],
    errors: [{ status: 404, description: 'Category not found' }],
  })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return unwrap(await this.getCategoryUseCase.execute(id));
  }
}
```

O tipo plain não vaza Prisma; `findAll`/tree e provider único permanecem. Preserve shape HTTP, UUID pipe, 404 e `unwrap`.

## 3. Port existente: não invente token ou método paralelo

O port existente é `UserLookupRepository`, uma classe abstrata que já funciona como token Nest, com `findById(id): RepositoryResponse<UserLookupRecord | null>`. O output `UserLookupRecord` contém somente `id`. Reuse esses contratos; não acrescente `Symbol`, interface duplicada ou método `findIdentityById`.

Binding já existente no `UsersModule` (mantenha o alias, não registre uma segunda instância):

```ts
import { Provider } from '@nestjs/common';
import { UserLookupRepository } from './domain/repositories/user-lookup.repository';
import { UserDatabaseRepository } from './data/repositories/user-database.repository';

const userLookupProviders: Provider[] = [
  { provide: UserLookupRepository, useExisting: UserDatabaseRepository },
];
```

O `UsersModule` atual importa `AuthModule`; `AuthUseCasesModule` fornece/exporta `UserDatabaseRepository`. Portanto, esse alias resolve a instância importada e **não** registra a classe novamente. Não adicione `UserDatabaseRepository` à lista de providers de Users: isso criaria outro provider/instância. A futura mudança de ownership exige decisão P3/DA-04; este exemplo não a implementa.

Consumers existentes `ListFollowersUseCase` e `ListFollowingUseCase` já usam o port. Preserve o mesmo `findById`, `Either` e regra de erro. Exemplo de classe implementada em `users/usecases/list-followers.usecase.ts`:

```ts
import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { FollowRepository } from '../domain/repositories/follow.repository';
import { UserLookupRepository } from '../domain/repositories/user-lookup.repository';
import { toUserBrief } from '../dtos/user-response.class';

@Injectable()
export class ListFollowersUseCase {
  constructor(
    private readonly followRepository: FollowRepository,
    private readonly userRepository: UserLookupRepository,
  ) {}

  async execute(input: { userId: string; limit: number; offset: number; verifyUser?: boolean }): Promise<Either<AppError, { users: ReturnType<typeof toUserBrief>[]; total: number; limit: number; offset: number }>> {
    if (input.verifyUser) {
      const profileResult = await this.userRepository.findById(input.userId);
      if (profileResult.isLeft()) return left(profileResult.value);
      if (!profileResult.value) return left(new NotFoundError('Usuário'));
    }
    const [usersResult, totalResult] = await Promise.all([
      this.followRepository.getFollowers(input.userId, input.limit, input.offset),
      this.followRepository.getFollowersCount(input.userId),
    ]);
    if (usersResult.isLeft()) return left(usersResult.value);
    if (totalResult.isLeft()) return left(totalResult.value);
    return right({ users: usersResult.value.map(toUserBrief), total: totalResult.value, limit: input.limit, offset: input.offset });
  }
}
```

Preserve essa validação, duas consultas, paginação, contagem, mapeamento e `Either`; não reduza o fluxo a lookup pass-through.

### API pública de Users e estado de ownership

P3 aprova Users como owner, mas não está concluído: source está em `users/data`; Auth ainda registra o provider; Users registra alias e importa Auth. DA-04 decide API/DI sem ciclo; não usar `forwardRef`.

Alvo de superfície pública estreita em `modules/users/index.ts`, depois da decisão de composição:

```ts
export { UsersModule } from './users.module';
export { UserLookupRepository } from './domain/repositories/user-lookup.repository';
export type { UserLookupRecord } from './domain/repositories/user-lookup.repository';
```

Hoje `users/index.ts` ainda exporta o concrete repository e não exporta módulo/record. É exceção de transição; não remova antes de migrar consumers/binding e testar boot/fluxos. Não reexporte `data/` em massa.

Use módulos reais e APIs exportadas; o binding atual não prova ownership efetivo.

## 4. Superfície entre módulos

Controller → use case; application pode usar repository concreto Tier B local; módulo consumidor importa o módulo dono e símbolos deliberadamente exportados por `index.ts`. Não importe `data/`, `usecases/` ou `services/` internos de outro módulo nem use `export *` para esconder deep import. O gate vê imports/reexports diretos nos paths configurados, não cadeia transitiva de barrels, ciclos gerais ou toda pasta `application`. Valide o checker antes de inferir enforcement.

## 5. Transações ALS com o client direto

Decisão vigente: métodos curtos `@Transactional()` via DI usam `TransactionHost<TransactionalAdapterPrisma>.tx`. Sem proxy, `@InjectTransaction`, facade, UoW ou TxContext. `SharedModule` é único owner do Prisma/CLS.

Este é o código real da operação `executeWithdrawal` de `DisputeDatabaseRepository`, incluindo assinatura e as duas escritas na ordem atual. Imports correspondem aos packages e enums do módulo:

```ts
import { Injectable } from '@nestjs/common';
import { DisputeStatus, EscrowStatus, OrderStatus } from '@prisma/client';
import { Transactional, TransactionHost } from '@nestjs-cls/transactional';
import { TransactionalAdapterPrisma } from '@nestjs-cls/transactional-adapter-prisma';

@Injectable()
export class DisputeDatabaseRepository {
  constructor(
    private readonly txHost: TransactionHost<TransactionalAdapterPrisma>,
  ) {}

  @Transactional()
  async executeWithdrawal(disputeId: string, orderId: string): Promise<void> {
    await this.txHost.tx.dispute.update({
      where: { id: disputeId },
      data: { status: DisputeStatus.CANCELLED, resolvedAt: new Date() },
    });

    await this.txHost.tx.order.update({
      where: { id: orderId },
      data: { status: OrderStatus.DELIVERED, escrowStatus: EscrowStatus.HELD },
    });
  }
}
```

O enum correto é `CANCELLED`, não `WITHDRAWN`; ambas as escritas e sua ordem preservam a operação. O bloco não substitui a classe completa.

### Rollback: exception precisa atravessar o método decorado

Rollback exige rejeição escapando do span. Não retorne `Left` nem envolva a escrita em `repositoryResponse`: ambos resolvem a Promise e podem commitar.

No `WithdrawDisputeUseCase` atual, falha/ausência de `findById`, autorização e `canWithdraw` são classificadas antes do método decorado (`Left` do repository, `NotFoundError`, `UnauthorizedError`, `BadRequestError`). `executeWithdrawal` é então aguardado, sem catch genérico; falha de persistência escapa e segue o filtro HTTP existente. Mantenha essa ordem. Não acrescente catch/mapeamento genérico para converter falha transacional em `Left` ou HTTP 400.

### Configuração Nest e visibilidade do Prisma em teste

Na aplicação, `SharedModule` fornece Prisma e o plugin usa esse token. Reuse `buildTransactionContext` já existente em `dispute.integration-spec.ts`; ele cria o `FakePrismaModule`, configura o plugin sem proxy e retorna módulo/repository/host:

```ts
import { Module } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import { ClsModule } from 'nestjs-cls';
import { ClsPluginTransactional } from '@nestjs-cls/transactional';
import { TransactionHost } from '@nestjs-cls/transactional';
import { TransactionalAdapterPrisma } from '@nestjs-cls/transactional-adapter-prisma';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { prisma } from '../../../../test/setup-integration';
import { DisputeDatabaseRepository } from '../data/repositories/dispute-database.repository';

async function buildTransactionContext(prismaClient: PrismaClient = prisma) {
  @Module({ providers: [{ provide: PrismaService, useValue: prismaClient }], exports: [PrismaService] })
  class FakePrismaModule {}

  const module = await Test.createTestingModule({
    imports: [ClsModule.forRoot({
      global: true,
      plugins: [new ClsPluginTransactional({
        adapter: new TransactionalAdapterPrisma({ prismaInjectionToken: PrismaService }),
        imports: [FakePrismaModule],
      })],
    })],
    providers: [DisputeDatabaseRepository, { provide: PrismaService, useValue: prismaClient }],
  }).compile();

  return {
    module,
    repository: module.get(DisputeDatabaseRepository),
    transactionHost: module.get(TransactionHost<TransactionalAdapterPrisma>),
  };
}
```

Esse é o helper real do integration spec; usa o `prisma` real de `test/setup-integration`. Não duplique helper nem use mock para alegar rollback. O helper sozinho não é evidência; não rode `db:sync`/seed fora do fluxo guardado.

### Integração real: falha na segunda escrita e readback

O cenário mínimo de rollback de `executeWithdrawal` prepara disputa e pedido reais, permite a primeira escrita e força a segunda a falhar usando um `orderId` inexistente. Depois, faz readback fora da transação e verifica que a disputa continuou `OPEN`. Um mock que executa callback não demonstra isso.

No `dispute.integration-spec.ts`, use o `seed()` menor do `describe('WithdrawDisputeUseCase')`, não o fixture financeiro mais pesado de Resolve. A fixture cria pedido `DISPUTED/HELD` e disputa `OPEN`; o teste abaixo corresponde ao caso atual e exige P2025 mais snapshots completos inalterados:

```ts
it('rolls back dispute update when restoring an unknown order fails', async () => {
  const { order, dispute } = await seed();
  const { module, repository } = await buildTransactionContext();

  try {
    const disputeBefore = await prisma.dispute.findUniqueOrThrow({ where: { id: dispute.id } });
    const orderBefore = await prisma.order.findUniqueOrThrow({ where: { id: order.id } });
    await expect(repository.executeWithdrawal(dispute.id, 'missing-order-for-rollback'))
      .rejects.toMatchObject({ code: 'P2025' });
    expect(await prisma.dispute.findUniqueOrThrow({ where: { id: dispute.id } })).toEqual(disputeBefore);
    expect(await prisma.order.findUniqueOrThrow({ where: { id: order.id } })).toEqual(orderBefore);
  } finally {
    await module.close();
  }
});
```

Esse teste existe; evidência, gates e limites atuais estão no [relatório](test-runs/2026-10-18/backend-infra/REPORT.md). O padrão não autoriza outras fatias.

### Isolamento ALS concorrente

Tester verificou transações reais simultâneas, clients distintos, commit de um scope e rollback do outro. O estado dos focused/final gates fica centralizado no [relatório](test-runs/2026-10-18/backend-infra/REPORT.md). Sequencial ou `Promise.all` sem readback/fake sem `$transaction` não prova ALS.

## 6. Notificações: política por caller

Continue chamando `NotificationService` diretamente. A política é do caller: `await` propagado quando o caller depende da conclusão; ou best-effort quando o contrato existente captura/observa falha. Não mude política de erro durante refactor. Não introduza event bus, `DomainEvents` ou outbox sem ADR/autorização próprios.

Padrões completos com a assinatura real de `NotificationService.notifyOrderStatus`. Copie apenas a chamada para o caller existente; não crie helper/caller novo. O primeiro aguarda e propaga:

```ts
import { Logger } from '@nestjs/common';
// Coloque este padrão dentro do módulo notifications, junto ao service.
import { NotificationService } from './notification.service';

export async function awaitedPattern(
  notifications: NotificationService,
  userId: string,
  orderId: string,
  status: string,
): Promise<void> {
  await notifications.notifyOrderStatus(userId, orderId, status);
}

export async function bestEffortPattern(
  notifications: NotificationService,
  logger: Logger,
  userId: string,
  orderId: string,
  status: string,
): Promise<void> {
  await notifications.notifyOrderStatus(userId, orderId, status).catch((error: unknown) => {
    logger.warn(
      `Order notification failed for ${orderId}: ${error instanceof Error ? error.message : String(error)}`,
    );
  });
}
```

Best-effort observa/loga rejeição. Esse import relativo só serve a código dentro do módulo notifications. O deep import `@/modules/notifications/services/notification.service` usado por consumers externos é legado, não API alvo; antes de alterar um módulo externo, resolver/exportar a API pública de Notifications. Trocar awaited por best-effort exige aprovação e teste de falha.

## 7. Guardrails financeiros e de persistência

Banco e provider externo não participam da mesma transação. O exemplo withdrawal cobre apenas duas escritas locais; não modela refund Stripe, claims, reconciliação ou recuperação. Em cancel/refund, preserve autenticação, reserva/claim, chamada externa, persistência do resultado e recuperação conforme o fluxo existente. Centavos, idempotency, optimistic guards, ordem, response/error/status e política de notificação não mudam como efeito colateral de organização. Infra P5 não autoriza novas fatias: checkout, payout, webhook, expiration e orders/cancel precisam de go específico.

Não deduza performance pela query ou crie índices por reflexo: busca tem OR, privacidade antes do limite, ranking e `limit + 1`. Meça query inteira com volume/SLO conhecido; `pg_trgm` não indexa automaticamente `regexp_split_to_table` e B-tree não é automaticamente compatível com ILIKE/collation. Ver hipóteses detalhadas no plano.

## 8. Sequência de trabalho para outra fatia

1. Leia ADRs, status/gates e `FEATURE_TRUTH.md`; depois abra a implementação, DI, callers, controller e testes reais.
2. Preserve saída, `Either`/`AppError`, `unwrap`/`EitherInterceptor`, status, privacidade e query/claim order antes de alterar estrutura.
3. Para spans transacionais, não capture falha como `Left` dentro do método; prove rollback/readback e isolamento conforme a fatia.
4. Leia `test-audit`, use fixture autorizada e diferencie unit, integração, HTTP/E2E, provider runtime e performance.
5. Rode gates de `AGENTS.md`/package.json e registre revisão, dirty state, ambiente seguro, comandos, resultados e limites. Não conclua com base em gate parcial ou regra de fronteira mais ampla que o checker real.

## Referências externas e internas

- NestJS, [custom providers — alias `useExisting`](https://docs.nestjs.com/fundamentals/custom-providers): alias aponta para provider já registrado; não cria outro provider via `useClass`.
- NestJS, [modules](https://docs.nestjs.com/modules): provider precisa ser exportado pelo módulo dono para consumo de módulos que o importam.
- NestJS CLS, [Transactional plugin](https://github.com/papooch/nestjs-cls/blob/main/docs/docs/06_plugins/01_available-plugins/01-transactional/index.md): configuração de plugin, `TransactionHost` e comportamento commit/rollback; conferir versão instalada antes de copiar opções.
- [ADR 0004](adr/0004-selective-modular-backend-architecture.md), [ADR 0005](adr/0005-module-template-public-api-uow-events.md), [plano de arquitetura](BACKEND_ARCHITECTURE_PLAN.md), [hardening plan](HARDENING_PLAN.md) e [AGENTS.md](../AGENTS.md).
