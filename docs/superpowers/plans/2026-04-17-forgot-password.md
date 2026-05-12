# Forgot Password Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement end-to-end "esqueceu a senha" flow — user submits email, receives a reset link, and resets their password.

**Architecture:** Backend is a NestJS modular monolith (`nest-backend/src/modules/`). Reset tokens are stored in Redis with 15-min TTL (same pattern already used for the JWT blacklist). No new DB table needed. Frontend uses Riverpod + go_router — two new pages (`ForgotPasswordPage`, `ResetPasswordPage`) and new auth service methods.

**Tech Stack:** NestJS · Prisma · Redis · nodemailer (new dep) · Flutter · Riverpod · go_router

---

## File Map

### Backend (new files)
| File | Responsibility |
|---|---|
| `nest-backend/src/shared/infra/email/email.service.ts` | Send email via nodemailer (SMTP config from env) |
| `nest-backend/src/modules/auth/usecases/forgot-password.usecase.ts` | Validate email, generate token, store in Redis, call EmailService |
| `nest-backend/src/modules/auth/usecases/forgot-password.usecase.spec.ts` | Unit tests |
| `nest-backend/src/modules/auth/usecases/reset-password.usecase.ts` | Validate token from Redis, update passwordHash, delete token |
| `nest-backend/src/modules/auth/usecases/reset-password.usecase.spec.ts` | Unit tests |

### Backend (modified files)
| File | Change |
|---|---|
| `nest-backend/src/modules/auth/dtos/auth.dto.ts` | Add `forgotPasswordSchema`, `resetPasswordSchema` |
| `nest-backend/src/modules/auth/auth.controller.ts` | Add `POST /auth/forgot-password` and `POST /auth/reset-password` |
| `nest-backend/src/modules/auth/auth.module.ts` | Register `ForgotPasswordUseCase`, `ResetPasswordUseCase`, `EmailService` |
| `nest-backend/src/shared/shared.module.ts` | Export `EmailService` |
| `nest-backend/.env` + `.env.example` | Add `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`, `APP_URL` |
| `nest-backend/package.json` | Add `nodemailer` + `@types/nodemailer` |

### Frontend (new files)
| File | Responsibility |
|---|---|
| `frontend/lib/features/auth/presentation/pages/forgot_password_page.dart` | Email input form → POST /auth/forgot-password → success state |
| `frontend/lib/features/auth/presentation/pages/reset_password_page.dart` | New password + confirm → POST /auth/reset-password → redirect to login |

### Frontend (modified files)
| File | Change |
|---|---|
| `frontend/lib/shared/services/http_client.dart` | Add `forgotPassword(email)` and `resetPassword(token, password)` methods |
| `frontend/lib/core/router/app_router.dart` | Add `/forgot-password` and `/reset-password` routes |
| `frontend/lib/features/auth/presentation/pages/login_page.dart` | `onTap` on "Esqueceu a senha?" navigates to `/forgot-password` |

---

## Task 1: Install nodemailer

**Files:**
- Modify: `nest-backend/package.json`

- [ ] **Step 1: Install dependencies**

```bash
cd nest-backend
npm install nodemailer
npm install -D @types/nodemailer
```

Expected output: `added N packages`

- [ ] **Step 2: Add env vars to `.env` and `.env.example`**

Add to `nest-backend/.env`:
```
SMTP_HOST=smtp.ethereal.email
SMTP_PORT=587
SMTP_USER=           # fill from ethereal.email account
SMTP_PASS=           # fill from ethereal.email account
SMTP_FROM="Freebay <no-reply@freebay.com>"
APP_URL=http://localhost:3000
```

Add the same keys (blank values) to `.env.example`.

- [ ] **Step 3: Commit**

```bash
git add package.json package-lock.json .env.example
git commit -m "chore: add nodemailer for transactional email"
```

---

## Task 2: EmailService

**Files:**
- Create: `nest-backend/src/shared/infra/email/email.service.ts`
- Modify: `nest-backend/src/shared/shared.module.ts`

- [ ] **Step 1: Create EmailService**

```typescript
// nest-backend/src/shared/infra/email/email.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter;

  constructor(private config: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.config.get('SMTP_HOST'),
      port: Number(this.config.get('SMTP_PORT', '587')),
      auth: {
        user: this.config.get('SMTP_USER'),
        pass: this.config.get('SMTP_PASS'),
      },
    });
  }

  async sendPasswordReset(to: string, token: string): Promise<void> {
    const appUrl = this.config.get('APP_URL', 'http://localhost:3000');
    const resetLink = `${appUrl}/reset-password?token=${token}`;

    const info = await this.transporter.sendMail({
      from: this.config.get('SMTP_FROM', '"Freebay" <no-reply@freebay.com>'),
      to,
      subject: 'Redefinição de senha — Freebay',
      text: `Clique no link para redefinir sua senha:\n\n${resetLink}\n\nO link expira em 15 minutos.\n\nSe você não solicitou isso, ignore este e-mail.`,
      html: `<p>Clique no link abaixo para redefinir sua senha:</p><p><a href="${resetLink}">${resetLink}</a></p><p>O link expira em <strong>15 minutos</strong>.</p><p>Se você não solicitou isso, ignore este e-mail.</p>`,
    });

    this.logger.log(`Password reset email sent to ${to} — messageId: ${info.messageId}`);
  }
}
```

- [ ] **Step 2: Export EmailService from SharedModule**

In `nest-backend/src/shared/shared.module.ts`, add `EmailService` to `providers` and `exports`:

```typescript
import { EmailService } from './infra/email/email.service';

@Global()
@Module({
  // ... existing imports
  providers: [PrismaService, RedisService, EmailService],
  exports: [PrismaService, RedisService, JwtModule, EmailService],
})
export class SharedModule {}
```

- [ ] **Step 3: Verify compile**

```bash
cd nest-backend && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add src/shared/infra/email/email.service.ts src/shared/shared.module.ts
git commit -m "feat: add EmailService for transactional email via nodemailer"
```

---

## Task 3: DTOs

**Files:**
- Modify: `nest-backend/src/modules/auth/dtos/auth.dto.ts`

- [ ] **Step 1: Add Zod schemas**

Append to the existing file:

```typescript
export const forgotPasswordSchema = z.object({
  email: z.string().email(),
});

export const resetPasswordSchema = z.object({
  token: z.string().min(64).max(64),
  password: z.string().min(8).max(100),
});

export type ForgotPasswordDTO = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordDTO = z.infer<typeof resetPasswordSchema>;
```

- [ ] **Step 2: Verify compile**

```bash
cd nest-backend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/modules/auth/dtos/auth.dto.ts
git commit -m "feat: add forgotPassword and resetPassword Zod DTOs"
```

---

## Task 4: ForgotPasswordUseCase + spec

**Files:**
- Create: `nest-backend/src/modules/auth/usecases/forgot-password.usecase.ts`
- Create: `nest-backend/src/modules/auth/usecases/forgot-password.usecase.spec.ts`

- [ ] **Step 1: Write the failing spec first**

```typescript
// nest-backend/src/modules/auth/usecases/forgot-password.usecase.spec.ts
import { ForgotPasswordUseCase } from './forgot-password.usecase';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { EmailService } from '@/shared/infra/email/email.service';

describe('ForgotPasswordUseCase', () => {
  let sut: ForgotPasswordUseCase;
  let userRepository: jest.Mocked<Partial<PrismaUserRepository>>;
  let redisService: jest.Mocked<Partial<RedisService>>;
  let emailService: jest.Mocked<Partial<EmailService>>;

  const mockUser = {
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'User',
    passwordHash: 'hash',
    isGuest: false,
  };

  beforeEach(() => {
    jest.clearAllMocks();
    userRepository = { findByEmail: jest.fn() };
    redisService = { add: jest.fn() };
    emailService = { sendPasswordReset: jest.fn() };

    sut = new ForgotPasswordUseCase(
      userRepository as PrismaUserRepository,
      redisService as RedisService,
      emailService as EmailService,
    );
  });

  it('returns right(void) and sends email when user exists', async () => {
    userRepository.findByEmail = jest.fn().mockResolvedValue(mockUser);
    redisService.add = jest.fn().mockResolvedValue(undefined);
    emailService.sendPasswordReset = jest.fn().mockResolvedValue(undefined);

    const result = await sut.execute({ email: 'user@example.com' });

    expect(result.isRight()).toBe(true);
    expect(redisService.add).toHaveBeenCalledWith(
      expect.stringMatching(/^password_reset:/),
      'user-1',
      900,
    );
    expect(emailService.sendPasswordReset).toHaveBeenCalledWith(
      'user@example.com',
      expect.any(String),
    );
  });

  it('returns right(void) silently when user does NOT exist (no enumeration)', async () => {
    userRepository.findByEmail = jest.fn().mockResolvedValue(null);

    const result = await sut.execute({ email: 'ghost@example.com' });

    expect(result.isRight()).toBe(true);
    expect(emailService.sendPasswordReset).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run spec to verify it fails**

```bash
cd nest-backend && npx jest src/modules/auth/usecases/forgot-password.usecase.spec.ts --no-coverage
```

Expected: FAIL — `Cannot find module './forgot-password.usecase'`

- [ ] **Step 3: Implement ForgotPasswordUseCase**

```typescript
// nest-backend/src/modules/auth/usecases/forgot-password.usecase.ts
import { Injectable } from '@nestjs/common';
import { randomBytes } from 'crypto';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { EmailService } from '@/shared/infra/email/email.service';
import { ForgotPasswordDTO } from '../dtos/auth.dto';

const RESET_TTL_SECONDS = 900; // 15 minutes

@Injectable()
export class ForgotPasswordUseCase {
  constructor(
    private userRepository: PrismaUserRepository,
    private redisService: RedisService,
    private emailService: EmailService,
  ) {}

  async execute(input: ForgotPasswordDTO): Promise<Either<AppError, void>> {
    const user = await this.userRepository.findByEmail(input.email);

    // Always return right to prevent email enumeration
    if (!user || user.isGuest) {
      return right(undefined);
    }

    const token = randomBytes(32).toString('hex'); // 64-char hex
    await this.redisService.add(`password_reset:${token}`, user.id, RESET_TTL_SECONDS);
    await this.emailService.sendPasswordReset(user.email, token);

    return right(undefined);
  }
}
```

- [ ] **Step 4: Run spec to verify it passes**

```bash
cd nest-backend && npx jest src/modules/auth/usecases/forgot-password.usecase.spec.ts --no-coverage
```

Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add src/modules/auth/usecases/forgot-password.usecase.ts \
        src/modules/auth/usecases/forgot-password.usecase.spec.ts
git commit -m "feat: ForgotPasswordUseCase — generate reset token, store in Redis, send email"
```

---

## Task 5: ResetPasswordUseCase + spec

**Files:**
- Create: `nest-backend/src/modules/auth/usecases/reset-password.usecase.ts`
- Create: `nest-backend/src/modules/auth/usecases/reset-password.usecase.spec.ts`

- [ ] **Step 1: Write the failing spec first**

```typescript
// nest-backend/src/modules/auth/usecases/reset-password.usecase.spec.ts
import { ResetPasswordUseCase } from './reset-password.usecase';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { InvalidResetTokenError } from '@/shared/core/errors';

describe('ResetPasswordUseCase', () => {
  let sut: ResetPasswordUseCase;
  let userRepository: jest.Mocked<Partial<PrismaUserRepository>>;
  let redisService: jest.Mocked<Partial<RedisService>>;

  const VALID_TOKEN = 'a'.repeat(64);

  beforeEach(() => {
    jest.clearAllMocks();
    userRepository = { update: jest.fn() };
    redisService = {
      get: jest.fn(),
      del: jest.fn(),
    };

    sut = new ResetPasswordUseCase(
      userRepository as PrismaUserRepository,
      redisService as RedisService,
    );
  });

  it('resets password and deletes token when token is valid', async () => {
    redisService.get = jest.fn().mockResolvedValue('user-1');
    userRepository.update = jest.fn().mockResolvedValue({ id: 'user-1' });
    redisService.del = jest.fn().mockResolvedValue(undefined);

    const result = await sut.execute({ token: VALID_TOKEN, password: 'newpassword123' });

    expect(result.isRight()).toBe(true);
    expect(userRepository.update).toHaveBeenCalledWith(
      'user-1',
      expect.objectContaining({ passwordHash: expect.any(String) }),
    );
    expect(redisService.del).toHaveBeenCalledWith(`password_reset:${VALID_TOKEN}`);
  });

  it('returns left(InvalidResetTokenError) when token not found in Redis', async () => {
    redisService.get = jest.fn().mockResolvedValue(null);

    const result = await sut.execute({ token: VALID_TOKEN, password: 'newpassword123' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(InvalidResetTokenError);
    }
    expect(userRepository.update).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Add `InvalidResetTokenError` to shared errors**

In `nest-backend/src/shared/core/errors.ts` (or wherever `AppError` subclasses live), add:

```typescript
export class InvalidResetTokenError extends AppError {
  constructor() {
    super('INVALID_RESET_TOKEN', 'Token inválido ou expirado', 400);
  }
}
```

- [ ] **Step 3: Check that RedisService has a `get` and `del` method**

```bash
grep -n "get\|del" nest-backend/src/shared/infra/redis/redis.service.ts
```

If `get` or `del` are missing, add them:

```typescript
async get(key: string): Promise<string | null> {
  return this.client.get(key);
}

async del(key: string): Promise<void> {
  await this.client.del(key);
}
```

- [ ] **Step 4: Run spec to verify it fails**

```bash
cd nest-backend && npx jest src/modules/auth/usecases/reset-password.usecase.spec.ts --no-coverage
```

Expected: FAIL — `Cannot find module './reset-password.usecase'`

- [ ] **Step 5: Implement ResetPasswordUseCase**

```typescript
// nest-backend/src/modules/auth/usecases/reset-password.usecase.ts
import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import { AppError, InvalidResetTokenError } from '@/shared/core/errors';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { ResetPasswordDTO } from '../dtos/auth.dto';

@Injectable()
export class ResetPasswordUseCase {
  constructor(
    private userRepository: PrismaUserRepository,
    private redisService: RedisService,
  ) {}

  async execute(input: ResetPasswordDTO): Promise<Either<AppError, void>> {
    const redisKey = `password_reset:${input.token}`;
    const userId = await this.redisService.get(redisKey);

    if (!userId) {
      return left(new InvalidResetTokenError());
    }

    const passwordHash = await bcrypt.hash(input.password, 12);
    await this.userRepository.update(userId, { passwordHash });
    await this.redisService.del(redisKey);

    return right(undefined);
  }
}
```

- [ ] **Step 6: Run spec to verify it passes**

```bash
cd nest-backend && npx jest src/modules/auth/usecases/reset-password.usecase.spec.ts --no-coverage
```

Expected: PASS (2 tests)

- [ ] **Step 7: Commit**

```bash
git add src/modules/auth/usecases/reset-password.usecase.ts \
        src/modules/auth/usecases/reset-password.usecase.spec.ts \
        src/shared/core/errors.ts \
        src/shared/infra/redis/redis.service.ts
git commit -m "feat: ResetPasswordUseCase — validate Redis token, update hash, invalidate token"
```

---

## Task 6: Wire routes into AuthController + AuthModule

**Files:**
- Modify: `nest-backend/src/modules/auth/auth.controller.ts`
- Modify: `nest-backend/src/modules/auth/auth.module.ts`

- [ ] **Step 1: Add imports and inject use cases in AuthController**

Add to the constructor:

```typescript
import { ForgotPasswordUseCase } from './usecases/forgot-password.usecase';
import { ResetPasswordUseCase } from './usecases/reset-password.usecase';
import {
  forgotPasswordSchema,
  resetPasswordSchema,
  ForgotPasswordDTO,
  ResetPasswordDTO,
} from './dtos/auth.dto';
```

Add to constructor parameters:

```typescript
private readonly forgotPasswordUseCase: ForgotPasswordUseCase,
private readonly resetPasswordUseCase: ResetPasswordUseCase,
```

- [ ] **Step 2: Add the two route handlers**

Append inside the `AuthController` class (after `logout`):

```typescript
@Post('forgot-password')
@HttpCode(HttpStatus.OK)
@UsePipes(new ZodValidationPipe(forgotPasswordSchema))
@Public()
async forgotPassword(@Body() body: ForgotPasswordDTO) {
  await this.forgotPasswordUseCase.execute(body);
  // Always 200 — prevents email enumeration
  return { message: 'Se este e-mail estiver cadastrado, você receberá um link em breve.' };
}

@Post('reset-password')
@HttpCode(HttpStatus.OK)
@UsePipes(new ZodValidationPipe(resetPasswordSchema))
@Public()
async resetPassword(@Body() body: ResetPasswordDTO) {
  const result = await this.resetPasswordUseCase.execute(body);
  if (result.isLeft()) {
    const err = result.value;
    return { statusCode: err.statusCode, code: err.code, message: err.message };
  }
  return { message: 'Senha redefinida com sucesso.' };
}
```

- [ ] **Step 3: Register use cases in AuthModule**

In `auth.module.ts`, add to `providers`:

```typescript
import { ForgotPasswordUseCase } from './usecases/forgot-password.usecase';
import { ResetPasswordUseCase } from './usecases/reset-password.usecase';

providers: [
  RegisterUseCase,
  LoginUseCase,
  GuestUseCase,
  ForgotPasswordUseCase,   // ← add
  ResetPasswordUseCase,    // ← add
  PrismaUserRepository,
  JwtStrategy,
  JwtAuthGuard,
],
```

- [ ] **Step 4: Verify compile + full test suite**

```bash
cd nest-backend && npx tsc --noEmit && npx jest --no-coverage
```

Expected: no TS errors, all existing tests pass.

- [ ] **Step 5: Manual smoke test**

```bash
cd nest-backend && npm run start
# In another terminal:
curl -s -X POST http://localhost:3333/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}' | jq
# Expected: {"message":"Se este e-mail estiver cadastrado..."}

curl -s -X POST http://localhost:3333/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{"token":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","password":"newpass123"}' | jq
# Expected: {"statusCode":400,"code":"INVALID_RESET_TOKEN","message":"Token inválido ou expirado"}
```

- [ ] **Step 6: Commit**

```bash
git add src/modules/auth/auth.controller.ts src/modules/auth/auth.module.ts
git commit -m "feat: wire POST /auth/forgot-password and POST /auth/reset-password"
```

---

## Task 7: Frontend — HttpService auth methods

**Files:**
- Modify: `frontend/lib/shared/services/http_client.dart`

- [ ] **Step 1: Add two methods to the HttpService (or auth data service)**

First, find how existing auth calls are made:

```bash
grep -rn "login\|register" frontend/lib/features/auth/data --include="*.dart" -l
```

Open that file and add alongside the existing methods:

```dart
Future<void> forgotPassword(String email) async {
  await _dio.post(
    '/auth/forgot-password',
    data: {'email': email},
  );
}

Future<void> resetPassword(String token, String password) async {
  await _dio.post(
    '/auth/reset-password',
    data: {'token': token, 'password': password},
  );
}
```

- [ ] **Step 2: Verify flutter analyze**

```bash
cd frontend && flutter analyze
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/shared/services/
git commit -m "feat: add forgotPassword and resetPassword auth service methods"
```

---

## Task 8: ForgotPasswordPage

**Files:**
- Create: `frontend/lib/features/auth/presentation/pages/forgot_password_page.dart`

- [ ] **Step 1: Create the page**

```dart
// frontend/lib/features/auth/presentation/pages/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/shared/services/http_client.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await HttpService.instance.forgotPassword(_emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Erro ao enviar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Esqueceu a senha?'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccessState(isDark) : _buildForm(isDark),
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Redefinir senha',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
            style: TextStyle(fontSize: 14, color: AppColors.mediumGray),
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: _emailController,
            label: 'E-mail',
            hint: 'seu@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe seu e-mail';
              if (!v.contains('@') || !v.contains('.')) return 'E-mail inválido';
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          AppButton(label: 'Enviar link', isLoading: _isLoading, onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildSuccessState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.accentGreen),
        const SizedBox(height: 24),
        Text(
          'E-mail enviado',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppColors.white : AppColors.darkGray),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Se este e-mail estiver cadastrado, você receberá um link em breve. Verifique também sua caixa de spam.',
          style: TextStyle(fontSize: 14, color: AppColors.mediumGray),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AppButton(label: 'Voltar ao login', onPressed: () => context.go('/login')),
      ],
    );
  }
}
```

- [ ] **Step 2: flutter analyze**

```bash
cd frontend && flutter analyze
```

> **Note:** If `HttpService.instance` does not exist (i.e., HttpService is Riverpod-injected), adjust the `_submit` method to use the Dio instance that matches the existing pattern in other pages. Check `frontend/lib/features/auth/data/` for how the HTTP call is actually made and mirror that pattern.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/auth/presentation/pages/forgot_password_page.dart
git commit -m "feat: ForgotPasswordPage — email form + sent success state"
```

---

## Task 9: ResetPasswordPage

**Files:**
- Create: `frontend/lib/features/auth/presentation/pages/reset_password_page.dart`

- [ ] **Step 1: Create the page**

```dart
// frontend/lib/features/auth/presentation/pages/reset_password_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/shared/services/http_client.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await HttpService.instance.resetPassword(widget.token, _passwordController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha redefinida com sucesso!')),
        );
        context.go('/login');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Token inválido ou expirado. Solicite um novo link.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Nova senha'), backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Crie uma nova senha',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppColors.white : AppColors.darkGray)),
                const SizedBox(height: 8),
                Text('Escolha uma senha forte com pelo menos 8 caracteres.',
                  style: TextStyle(fontSize: 14, color: AppColors.mediumGray)),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _passwordController,
                  label: 'Nova senha',
                  hint: 'Mínimo 8 caracteres',
                  obscureText: true,
                  showPasswordToggle: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a nova senha';
                    if (v.length < 8) return 'Mínimo 8 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmController,
                  label: 'Confirmar nova senha',
                  hint: 'Repita a nova senha',
                  obscureText: true,
                  showPasswordToggle: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirme a nova senha';
                    if (v != _passwordController.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                AppButton(label: 'Redefinir senha', isLoading: _isLoading, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: flutter analyze**

```bash
cd frontend && flutter analyze
```

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/auth/presentation/pages/reset_password_page.dart
git commit -m "feat: ResetPasswordPage — new password form with token from query param"
```

---

## Task 10: Routes + login_page navigation

**Files:**
- Modify: `frontend/lib/core/router/app_router.dart`
- Modify: `frontend/lib/features/auth/presentation/pages/login_page.dart`

- [ ] **Step 1: Add routes to app_router.dart**

In the `GoRouter` routes list (alongside `/login` and `/register`), add:

```dart
import 'package:freebay/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:freebay/features/auth/presentation/pages/reset_password_page.dart';

GoRoute(
  path: '/forgot-password',
  pageBuilder: (context, state) => _buildPageWithSlideTransition(
    context: context,
    state: state,
    child: const ForgotPasswordPage(),
  ),
),
GoRoute(
  path: '/reset-password',
  pageBuilder: (context, state) {
    final token = state.uri.queryParameters['token'] ?? '';
    return _buildPageWithSlideTransition(
      context: context,
      state: state,
      child: ResetPasswordPage(token: token),
    );
  },
),
```

- [ ] **Step 2: Wire "Esqueceu a senha?" button in login_page.dart**

Find the `onTap: () {}` on the "Esqueceu a senha?" `InkWell` and replace with:

```dart
onTap: () => context.push('/forgot-password'),
```

- [ ] **Step 3: flutter analyze + flutter test**

```bash
cd frontend && flutter analyze && flutter test
```

Expected: No issues found. All tests passed.

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/core/router/app_router.dart \
        frontend/lib/features/auth/presentation/pages/login_page.dart
git commit -m "feat: add /forgot-password and /reset-password routes, wire login button"
```

---

## Self-Review

**Spec coverage:**
- ✅ `POST /auth/forgot-password` — Task 4 + 6
- ✅ `POST /auth/reset-password` — Task 5 + 6
- ✅ Email sending — Task 2
- ✅ Redis token storage with TTL — Task 4
- ✅ Token validation + hash update — Task 5
- ✅ No email enumeration — Task 4 (always returns 200)
- ✅ `ForgotPasswordPage` UI — Task 8
- ✅ `ResetPasswordPage` UI — Task 9
- ✅ Routes wired — Task 10
- ✅ Login button navigates — Task 10
- ✅ Both pages have confirm-password validation — Tasks 8 & 9
- ✅ DTOs validated with Zod — Task 3

**Note on `HttpService.instance`:** Tasks 8 and 9 use `HttpService.instance` as a placeholder. Before executing, check `frontend/lib/shared/services/http_client.dart` to see how other auth pages (`login_page.dart`, `register_page.dart`) call the API — they use `ref.read(authControllerProvider.notifier)`. The `forgotPassword` and `resetPassword` calls should go through the same `AuthController` notifier or a dedicated auth repository, not raw Dio. Adjust Tasks 7–9 to match the actual provider pattern.
