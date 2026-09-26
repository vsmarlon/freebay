---
name: freebay-backend-module
description: Use when scaffolding or modifying a NestJS feature module in the Freebay backend — enforces vertical-module structure, class-validator DTOs, Either monad use cases, concrete Prisma repositories, and colocated specs.
---

# Freebay Backend Module Scaffold

## Module structure

Every feature module follows the same layout:

```
src/modules/<feature>/
├── <feature>.module.ts       # @Module({ providers: [controller, usecases, repositories] })
├── <feature>.controller.ts   # routes + @ApiDoc() + Either response shaping
├── dtos/                     # class-validator + @nestjs/swagger (NOT Zod)
│   ├── <feature>.dto.ts
│   └── <feature>-response.class.ts
├── domain/
│   └── repositories/         # abstract Repository classes
│       └── <feature>.repository.ts
├── data/
│   └── repositories/         # concrete Prisma*Repository implementations
│       └── <feature>-database.repository.ts
├── usecases/                 # one class per file, returns Either<AppError, Output>
│   ├── create-<entity>.usecase.ts
│   └── *.spec.ts             # colocated test
├── mappers/                  # Prisma model → API response function
│   └── <entity>.mapper.ts
└── guards/                   # (optional) module-specific Nest guards
```

## Step by step

Before implementation, follow [AGENTS.md — Testing: TDD and E2E first](../../../AGENTS.md#testing-tdd-and-e2e-first). Select the real behavioral boundary and observe RED before changing production code.

### 1. DTOs (`dtos/`)

Use **class-validator** decorators + `@ApiProperty` from `@nestjs/swagger`. Never Zod.

```typescript
import { IsString, MinLength, IsOptional, IsInt, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateMyEntityDTO {
  @ApiProperty({ example: 'Example name', minLength: 2 })
  @IsString()
  @MinLength(2)
  name: string;

  @ApiPropertyOptional({ example: 100 })
  @IsOptional()
  @IsInt()
  @Min(0)
  amount?: number;
}
```

### 2. Use cases (`usecases/`)

**One class per file.** Return `Either<AppError, Output>`. Never `throw` for expected business errors.

```typescript
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { MyEntityRepository } from '../domain/repositories/my-entity.repository';

export class GetMyEntityUseCase {
  constructor(private readonly repo: MyEntityRepository) {}

  async execute(id: string): Promise<Either<AppError, Output>> {
    const entity = await this.repo.findById(id);
    if (!entity) return left(new NotFoundError('MyEntity'));
    return right({ entity });
  }
}
```

### 3. Repository (`domain/repositories/` & `data/repositories/`)

Define the abstract class in `domain/repositories/` (returning `RepositoryResponse<T, F = Failure>`), and the concrete implementation in `data/repositories/`. Wrap each Prisma operation with the standalone `repositoryResponse(operation, errorMessage?, logger?)` adapter from `shared/infra/prisma/repository-response.ts`.

> **Rule**: Backend repositories **MUST ONLY call the database** (via Prisma or transactions). They never call external HTTP endpoints.

```typescript
// domain/repositories/my-entity.repository.ts
import { RepositoryResponse } from '@/shared/core/either';

export abstract class MyEntityRepository {
  abstract findById(id: string): RepositoryResponse<MyEntity | null>;
  abstract create(data: Prisma.MyEntityCreateInput): RepositoryResponse<MyEntity>;
}

// data/repositories/my-entity-database.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { Prisma, MyEntity } from '@prisma/client';
import { MyEntityRepository } from '../../domain/repositories/my-entity.repository';

@Injectable()
export class PrismaMyEntityRepository implements MyEntityRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string) {
    return repositoryResponse(() => this.prisma.myEntity.findUnique({ where: { id } }));
  }

  async create(data: Prisma.MyEntityCreateInput) {
    return repositoryResponse(() => this.prisma.myEntity.create({ data }));
  }
}
```

### 4. Mapper (`mappers/`)

Pure function: Prisma model → API response. Never expose sensitive fields.

```typescript
import { MyEntity } from '@prisma/client';

export class MyEntityResponse {
  id: string;
  name: string;
  amount: number;
  createdAt: Date;
}

export function toMyEntityResponse(entity: MyEntity): MyEntityResponse {
  return {
    id: entity.id,
    name: entity.name,
    amount: entity.amount,
    createdAt: entity.createdAt,
  };
}
```

### 5. Controller

Canonical Either response shape (see `CLAUDE.md` for full convention):

```typescript
@Post()
@HttpCode(HttpStatus.CREATED)
@ApiDoc({ summary: '…', bodyType: CreateMyEntityDTO, responseStatus: 201, auth: true })
async create(@CurrentUser() user: AuthUser, @Body() body: CreateMyEntityDTO) {
  const result = await this.createUseCase.execute({ userId: user.userId, ...body });
  if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
  return result.value;
}
```

### 6. Module wiring (`*.module.ts`)

```typescript
@Module({
  controllers: [MyEntityController],
  providers: [
    MyEntityController,
    CreateMyEntityUseCase,
    PrismaMyEntityRepository,
    { provide: MyEntityRepository, useExisting: PrismaMyEntityRepository },
  ],
})
export class MyEntityModule {}
```

### 7. Verify the behavioral slice

Rerun the test that was RED before implementation, then the relevant existing gates from `AGENTS.md`. Finish with the repeatable evidence required by that policy. Repository mocks cannot verify database columns, constraints, transactions, or query behavior.

---
