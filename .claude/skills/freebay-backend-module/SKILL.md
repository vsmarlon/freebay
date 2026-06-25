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
├── repositories/             # concrete Prisma*Repository (no I*Repository interfaces)
│   └── <feature>.repository.ts
├── usecases/                 # one class per file, returns Either<AppError, Output>
│   ├── create-<entity>.usecase.ts
│   └── *.spec.ts             # colocated test
├── mappers/                  # Prisma model → API response function
│   └── <entity>.mapper.ts
└── guards/                   # (optional) module-specific Nest guards
```

## Step by step

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
import { PrismaMyEntityRepository } from '../repositories/my-entity.repository';

export class GetMyEntityUseCase {
  constructor(private readonly repo: PrismaMyEntityRepository) {}

  async execute(id: string): Promise<Either<AppError, Output>> {
    const entity = await this.repo.findById(id);
    if (!entity) return left(new NotFoundError('MyEntity'));
    return right({ entity });
  }
}
```

### 3. Repository (`repositories/`)

Concrete class, injected directly (no interface). Use Prisma generated types.

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PrismaMyEntityRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string) {
    return this.prisma.myEntity.findUnique({ where: { id } });
  }

  async create(data: Prisma.MyEntityCreateInput) {
    return this.prisma.myEntity.create({ data });
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
  providers: [MyEntityController, CreateMyEntityUseCase, PrismaMyEntityRepository],
})
export class MyEntityModule {}
```

Then import `MyEntityModule` in `src/app.module.ts`.

### 7. Test (`*.spec.ts`)

```typescript
describe('CreateMyEntityUseCase', () => {
  let sut: CreateMyEntityUseCase;
  let mockRepo: jest.Mocked<PrismaMyEntityRepository>;

  beforeEach(async () => {
    mockRepo = { create: jest.fn() } as any;
    sut = new CreateMyEntityUseCase(mockRepo);
  });

  it('should create entity', async () => {
    mockRepo.create.mockResolvedValue({ id: '1', name: 'Test' });
    const result = await sut.execute({ name: 'Test' });
    expect(result.isRight()).toBe(true);
  });
});
```

## References

- Clean exemplar modules: `modules/reviews/`, `modules/favorites/`
- Cents-as-Int rule: all monetary fields in Prisma are `Int` (see `schema.prisma`)
- Path alias `@/` maps to `src/`
- Standard guards: `JwtAuthGuard`, `NonGuestGuard`, `@Roles()`, `@Public()`
