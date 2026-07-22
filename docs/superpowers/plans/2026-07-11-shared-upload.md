# Shared Upload Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a single `POST /uploads?context=<context>` endpoint that saves files to disk under `uploads/<context>/` and returns a relative URL; serve those files as static assets; expose a Flutter `UploadService` that any feature can call.

**Architecture:** A new NestJS `UploadModule` uses multer disk storage — filename is UUID + extension, destination subfolder is driven by the `context` query param. `ServeStaticModule` mounts the `uploads/` directory at `/uploads`. Flutter's `UploadService` sends a multipart POST via Dio and returns the relative path on success.

**Tech Stack:** `@nestjs/platform-express` (multer built-in), `@nestjs/serve-static`, Dio multipart (Flutter)

## Global Constraints
- Store only the relative path (e.g. `/uploads/chat/abc.jpg`) in DB — never a full URL
- File size limit: 10 MB per upload
- Accepted MIME types: `image/jpeg`, `image/png`, `image/gif`, `image/webp`
- Valid context values: `chat`, `background`, `post`, `avatar`
- Filenames: UUID v4 + original extension — never use the client-provided filename
- Backend commands run from `nest-backend/`; Flutter from `frontend/` using `fvm flutter`
- `flutter analyze` must exit with zero issues after every Flutter task
- One class per usecase file (CLAUDE.md rule)

---

## File Map

**Create:**
- `nest-backend/src/modules/upload/upload.module.ts`
- `nest-backend/src/modules/upload/upload.controller.ts`
- `nest-backend/src/modules/upload/upload.controller.spec.ts`
- `nest-backend/.gitignore` — add `uploads/` entry (or update if it exists)
- `nest-backend/uploads/.gitkeep` — keeps folder in repo without contents
- `frontend/lib/shared/services/upload_service.dart`
- `frontend/test/shared/services/upload_service_test.dart`

**Modify:**
- `nest-backend/src/app.module.ts` — import `ServeStaticModule` + `UploadModule`
- `nest-backend/package.json` — add `@nestjs/serve-static`

---

## Task 1: Backend — Install dependency and configure static serving

**Files:**
- Modify: `nest-backend/package.json`
- Modify: `nest-backend/src/app.module.ts`

**Interfaces:**
- Produces: `/uploads/<context>/<filename>` served as static files at that URL path

- [ ] **Step 1: Install `@nestjs/serve-static`**

```bash
cd nest-backend && npm install @nestjs/serve-static
```

Expected: resolves without error, package appears in `dependencies`.

- [ ] **Step 2: Add `ServeStaticModule` to `app.module.ts`**

Add this import at the top of `app.module.ts`:
```typescript
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
```

Add inside `imports: [...]` array (before the feature modules):
```typescript
ServeStaticModule.forRoot({
  rootPath: join(__dirname, '..', '..', 'uploads'),
  serveRoot: '/uploads',
  serveStaticOptions: { index: false },
}),
```

- [ ] **Step 3: Create the uploads folder and gitkeep**

```bash
mkdir -p nest-backend/uploads
touch nest-backend/uploads/.gitkeep
```

Add to `nest-backend/.gitignore` (check if it already has an uploads entry first):
```
uploads/*
!uploads/.gitkeep
```

- [ ] **Step 4: Verify server starts**

```bash
cd nest-backend && npm run build
```

Expected: build succeeds with no errors.

- [ ] **Step 5: Commit**

```bash
git add nest-backend/src/app.module.ts nest-backend/package.json nest-backend/package-lock.json nest-backend/uploads/.gitkeep nest-backend/.gitignore
git commit -m "feat(upload): add ServeStaticModule for /uploads static serving"
```

---

## Task 2: Backend — Upload controller + multer disk storage

**Files:**
- Create: `nest-backend/src/modules/upload/upload.module.ts`
- Create: `nest-backend/src/modules/upload/upload.controller.ts`
- Create: `nest-backend/src/modules/upload/upload.controller.spec.ts`
- Modify: `nest-backend/src/app.module.ts` — add `UploadModule` to imports

**Interfaces:**
- Produces: `POST /uploads?context=<context>` — accepts `multipart/form-data` field `file`, returns `{ success: true, data: { url: string } }` (relative path)

- [ ] **Step 1: Write the failing test**

Create `nest-backend/src/modules/upload/upload.controller.spec.ts`:
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { UploadController } from './upload.controller';

describe('UploadController', () => {
  let sut: UploadController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UploadController],
    }).compile();
    sut = module.get<UploadController>(UploadController);
  });

  it('returns relative url when file is provided', () => {
    const file = {
      filename: 'abc123.jpg',
      mimetype: 'image/jpeg',
    } as Express.Multer.File;

    const result = sut.upload(file, 'chat');

    expect(result).toEqual({ url: '/uploads/chat/abc123.jpg' });
  });

  it('throws BadRequestException when no file', () => {
    expect(() => sut.upload(undefined as any, 'chat')).toThrow(BadRequestException);
  });

  it('throws BadRequestException for invalid context', () => {
    const file = { filename: 'abc.jpg' } as Express.Multer.File;
    expect(() => sut.upload(file, 'invalid')).toThrow(BadRequestException);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd nest-backend && npx jest src/modules/upload/upload.controller.spec.ts --no-coverage
```

Expected: FAIL — `UploadController` not found.

- [ ] **Step 3: Create `upload.controller.ts`**

```typescript
import {
  Controller,
  Post,
  Query,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { mkdirSync } from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { ApiTags } from '@nestjs/swagger';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

const VALID_CONTEXTS = ['chat', 'background', 'post', 'avatar'] as const;
const VALID_MIMETYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const MAX_SIZE = 10 * 1024 * 1024; // 10 MB

@ApiTags('Upload')
@Controller('uploads')
@UseGuards(JwtAuthGuard)
export class UploadController {
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiDoc({ summary: 'Upload a file to disk', auth: true, responseStatus: 201 })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (req, _file, cb) => {
          const context = (req.query.context as string) || 'misc';
          const dir = join(process.cwd(), 'uploads', context);
          mkdirSync(dir, { recursive: true });
          cb(null, dir);
        },
        filename: (_req, file, cb) => {
          const ext = extname(file.originalname).toLowerCase() || '.jpg';
          cb(null, `${uuidv4()}${ext}`);
        },
      }),
      limits: { fileSize: MAX_SIZE },
      fileFilter: (_req, file, cb) => {
        cb(null, VALID_MIMETYPES.includes(file.mimetype));
      },
    }),
  )
  upload(
    @UploadedFile() file: Express.Multer.File,
    @Query('context') context: string,
  ): { url: string } {
    if (!file) {
      throw new BadRequestException('Arquivo ausente ou tipo não permitido (aceitos: jpeg, png, gif, webp)');
    }
    if (!VALID_CONTEXTS.includes(context as any)) {
      throw new BadRequestException(`Context inválido. Use: ${VALID_CONTEXTS.join(', ')}`);
    }
    return { url: `/uploads/${context}/${file.filename}` };
  }
}
```

- [ ] **Step 4: Create `upload.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { UploadController } from './upload.controller';
import { AuthModule } from '@/modules/auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [UploadController],
})
export class UploadModule {}
```

- [ ] **Step 5: Register `UploadModule` in `app.module.ts`**

Add to `imports` array after `ServeStaticModule`:
```typescript
import { UploadModule } from './modules/upload/upload.module';
// ...
UploadModule,
```

- [ ] **Step 6: Run test to verify it passes**

```bash
cd nest-backend && npx jest src/modules/upload/upload.controller.spec.ts --no-coverage
```

Expected: PASS — 3 tests passing.

- [ ] **Step 7: Typecheck**

```bash
cd nest-backend && npx tsc --noEmit
```

Expected: zero errors.

- [ ] **Step 8: Commit**

```bash
git add nest-backend/src/modules/upload/ nest-backend/src/app.module.ts
git commit -m "feat(upload): add POST /uploads endpoint with multer disk storage"
```

---

## Task 3: Frontend — UploadService

**Files:**
- Create: `frontend/lib/shared/services/upload_service.dart`
- Create: `frontend/test/shared/services/upload_service_test.dart`

**Interfaces:**
- Produces: `UploadService.uploadFile(File file, String context) → Future<Either<Failure, String>>` — returns the relative path on success (e.g. `/uploads/chat/abc.jpg`)
- Consumed by: chat image send flow (Plan B), background image change (existing flow to be updated)

- [ ] **Step 1: Write the failing test**

Create `frontend/test/shared/services/upload_service_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/services/upload_service.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('UploadService', () {
    test('returns relative path on success', () async {
      // This test verifies the URL parsing logic only.
      // Integration with HttpClient is tested manually.
      expect(UploadService.relativePathFromResponse({'url': '/uploads/chat/abc.jpg'}), '/uploads/chat/abc.jpg');
    });

    test('returns null for missing url key', () {
      expect(UploadService.relativePathFromResponse({}), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd frontend && fvm flutter test test/shared/services/upload_service_test.dart
```

Expected: FAIL — `UploadService` not found.

- [ ] **Step 3: Create `upload_service.dart`**

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' show basename;
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/services/http_client.dart';

class UploadService {
  static Future<Either<Failure, String>> uploadFile(
    File file,
    String context,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: basename(file.path),
        ),
      });
      final response = await HttpClient.instance.post(
        '/uploads?context=$context',
        data: formData,
      );
      if (response.statusCode == 201 && response.data != null) {
        final url = relativePathFromResponse(
          response.data['data'] as Map<String, dynamic>,
        );
        if (url == null) return const Left(ServerFailure('URL inválida na resposta'));
        return Right(url);
      }
      return const Left(ServerFailure('Falha ao enviar arquivo'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        return const Left(ServerFailure('Arquivo muito grande. Máximo: 10 MB'));
      }
      return const Left(ServerFailure('Erro de conexão ao enviar arquivo'));
    } catch (_) {
      return const Left(ServerFailure('Erro ao enviar arquivo'));
    }
  }

  static String? relativePathFromResponse(Map<String, dynamic> data) {
    final url = data['url'];
    return url is String ? url : null;
  }
}
```

- [ ] **Step 4: Add `path` package to `pubspec.yaml` if missing**

Check `pubspec.yaml` — if `path:` is not listed under `dependencies`, add it:
```yaml
  path: ^1.9.0
```

Then run:
```bash
cd frontend && fvm flutter pub get
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd frontend && fvm flutter test test/shared/services/upload_service_test.dart
```

Expected: PASS — 2 tests passing.

- [ ] **Step 6: Flutter analyze**

```bash
cd frontend && fvm flutter analyze
```

Expected: zero issues.

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/shared/services/upload_service.dart frontend/test/shared/services/upload_service_test.dart frontend/pubspec.yaml frontend/pubspec.lock
git commit -m "feat(upload): add Flutter UploadService with multipart Dio upload"
```
