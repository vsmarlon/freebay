# Chat Premium Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Prerequisite:** `2026-07-11-shared-upload.md` must be completed first — this plan uses `UploadService` and `POST /uploads`.

**Goal:** Upgrade both chat types (DirectMessage and ChatMessage/order) with images, GIFs, link previews, location sharing with an embedded map, product card sharing, reply-to-message, typing indicator, message unsend, read receipts display, message reactions (6 emojis, real-time), and online/last-seen status.

**Architecture:** Schema migrations bring `ChatMessage` to parity with `DirectMessage`. A new `OgScraperService` runs synchronously (3 s timeout) on send when content contains a URL and stores OG data in `message.metadata`. A new `MessageReaction` model handles reactions. The existing Socket.IO gateway on `/chat` is extended with typing, online, reaction, and delete events. Flutter adds new message bubble variants, an attachment bottom sheet, a location picker page using `flutter_map`, and a reactions overlay.

**Tech Stack:** NestJS, Prisma/PostgreSQL, Socket.IO, `open-graph-scraper` (npm), Flutter, `flutter_map ^7`, `latlong2 ^0.9`, `geolocator ^12`, `permission_handler ^11`

## Global Constraints
- 0 px border radius on all new Flutter widgets — no exceptions
- No standard shadows — depth via tonal surface shifts only
- Animations: 150ms, `Curves.linear`
- `flutter analyze` must exit zero issues after every Flutter task
- `npx tsc --noEmit` must pass after every backend task
- One class per usecase file
- All monetary/coord values: `replyToId` is nullable on both message models
- Reaction emoji set (in order): `['❤️', '😂', '😮', '😢', '😡', '👍']`
- Deleted messages show placeholder text `'Mensagem apagada'` — content is not recoverable client-side
- OG scrape timeout: 3000 ms — if it times out, message is saved without metadata
- Use `Either<AppError, void>` for usecases that return no data
- Backend commands from `nest-backend/`; Flutter from `frontend/` with `fvm flutter`

---

## File Map

**Backend — Create:**
- `nest-backend/src/modules/chat/services/og-scraper.service.ts`
- `nest-backend/src/modules/chat/services/og-scraper.service.spec.ts`
- `nest-backend/src/modules/chat/usecases/toggle-reaction.usecase.ts`
- `nest-backend/src/modules/chat/usecases/toggle-reaction.usecase.spec.ts`
- `nest-backend/src/modules/chat/usecases/delete-message.usecase.ts`
- `nest-backend/src/modules/chat/usecases/delete-message.usecase.spec.ts`

**Backend — Modify:**
- `nest-backend/prisma/schema.prisma` — schema upgrades
- `nest-backend/src/modules/chat/usecases/send-message.usecase.ts` — add type, attachmentUrl, replyToId, OG detection
- `nest-backend/src/modules/chat/chat.gateway.ts` — add typing_stop, online/offline, reaction, delete_message events
- `nest-backend/src/modules/chat/chat.controller.ts` — add PATCH delete, POST reaction endpoints
- `nest-backend/src/modules/chat/dtos/chat.dto.ts` — extend types
- `nest-backend/src/modules/chat/usecases/chat-usecases.module.ts` — register new usecases + services

**Frontend — Create:**
- `frontend/lib/features/chat/data/entities/message_entity.dart`
- `frontend/lib/features/chat/data/entities/message_entity.freezed.dart` (generated)
- `frontend/lib/features/chat/data/entities/message_entity.g.dart` (generated)
- `frontend/lib/features/chat/data/entities/message_reaction_entity.dart`
- `frontend/lib/features/chat/data/entities/og_metadata_entity.dart`
- `frontend/lib/features/chat/presentation/widgets/attachment_bottom_sheet.dart`
- `frontend/lib/features/chat/presentation/pages/location_picker_page.dart`
- `frontend/lib/features/chat/presentation/widgets/image_message_bubble.dart`
- `frontend/lib/features/chat/presentation/widgets/location_message_bubble.dart`
- `frontend/lib/features/chat/presentation/widgets/link_preview_card.dart`
- `frontend/lib/features/chat/presentation/widgets/product_card_bubble.dart`
- `frontend/lib/features/chat/presentation/widgets/reply_preview_banner.dart`
- `frontend/lib/features/chat/presentation/widgets/reaction_picker_overlay.dart`
- `frontend/lib/features/chat/presentation/widgets/reaction_bar.dart`
- `frontend/lib/features/chat/presentation/widgets/who_reacted_sheet.dart`
- `frontend/lib/features/chat/presentation/widgets/typing_indicator_bubble.dart`

**Frontend — Modify:**
- `frontend/lib/features/chat/presentation/widgets/message_bubble.dart` — orchestrate by type + add reactions/reply strip
- `frontend/lib/features/chat/presentation/pages/chat_conversation_page.dart` — attach bottom sheet, swipe-to-reply, typing events, online status
- `frontend/lib/features/chat/presentation/widgets/chat_header.dart` — online/last-seen line
- `frontend/lib/features/chat/data/repositories/chat_repository.dart` — new methods
- `frontend/lib/features/chat/domain/repositories/i_chat_repository.dart` — new method signatures
- `frontend/pubspec.yaml` — add `flutter_map`, `latlong2`, `geolocator`, `permission_handler`

---

## Task 1: Schema Migrations

**Files:**
- Modify: `nest-backend/prisma/schema.prisma`

**Interfaces:**
- Produces: `DirectMessage.replyToId?`, `DirectMessage.deletedAt?`, `DirectMessage.reactions[]`
- Produces: `ChatMessage.type`, `ChatMessage.attachmentUrl?`, `ChatMessage.metadata?`, `ChatMessage.deliveredAt?`, `ChatMessage.replyToId?`, `ChatMessage.deletedAt?`, `ChatMessage.reactions[]`, `ChatMessage.content` nullable
- Produces: `User.lastSeenAt?`
- Produces: new `MessageReaction` model

- [ ] **Step 1: Edit `schema.prisma` — add `lastSeenAt` to `User`**

Find the `model User` block. Add after the existing fields (before the relations):
```prisma
lastSeenAt    DateTime?
```

- [ ] **Step 2: Upgrade `DirectMessage` model**

The `DirectMessage` model already has `type`, `attachmentUrl`, `metadata`, `deliveredAt`, `readAt`. Add the missing fields and relations inside the model:
```prisma
  replyToId      String?
  deletedAt      DateTime?

  replyTo        DirectMessage?   @relation("DmReplies", fields: [replyToId], references: [id], onDelete: SetNull)
  replies        DirectMessage[]  @relation("DmReplies")
  reactions      MessageReaction[]
```

- [ ] **Step 3: Upgrade `ChatMessage` model**

Replace the entire `ChatMessage` model with:
```prisma
model ChatMessage {
  id            String      @id @default(uuid())
  orderId       String
  senderId      String
  content       String?
  type          MessageType @default(TEXT)
  attachmentUrl String?
  metadata      Json?
  deliveredAt   DateTime?
  readAt        DateTime?
  replyToId     String?
  deletedAt     DateTime?
  createdAt     DateTime    @default(now())

  order    Order          @relation(fields: [orderId], references: [id], onDelete: Cascade)
  sender   User           @relation(fields: [senderId], references: [id], onDelete: Cascade)
  replyTo  ChatMessage?   @relation("CmReplies", fields: [replyToId], references: [id], onDelete: SetNull)
  replies  ChatMessage[]  @relation("CmReplies")
  reactions MessageReaction[]
  reportedChatMsgReports Report[] @relation("ReportedChatMsgReports")

  @@index([orderId, createdAt])
}
```

- [ ] **Step 4: Add `MessageReaction` model**

Add after the `DirectMessage` model:
```prisma
model MessageReaction {
  id              String   @id @default(uuid())
  emoji           String
  userId          String
  directMessageId String?
  chatMessageId   String?
  createdAt       DateTime @default(now())

  user          User            @relation(fields: [userId], references: [id], onDelete: Cascade)
  directMessage DirectMessage?  @relation(fields: [directMessageId], references: [id], onDelete: Cascade)
  chatMessage   ChatMessage?    @relation(fields: [chatMessageId], references: [id], onDelete: Cascade)

  @@unique([userId, directMessageId])
  @@unique([userId, chatMessageId])
  @@index([directMessageId])
  @@index([chatMessageId])
}
```

- [ ] **Step 5: Add `MessageReaction` relation to `User` model**

Inside `model User`, add to relations:
```prisma
  messageReactions MessageReaction[]
```

- [ ] **Step 6: Run migration**

```bash
cd nest-backend && npm run prisma:migrate
```

When prompted for migration name, enter: `chat_premium_features`

Expected: migration applied, Prisma client regenerated.

- [ ] **Step 7: Regenerate client**

```bash
cd nest-backend && npm run prisma:generate
```

Expected: no errors.

- [ ] **Step 8: Typecheck**

```bash
cd nest-backend && npx tsc --noEmit
```

Fix any type errors before proceeding (likely `ChatMessage.content` now nullable — update any code that assumed non-null).

- [ ] **Step 9: Commit**

```bash
git add nest-backend/prisma/ nest-backend/src/
git commit -m "feat(chat): schema migration — ChatMessage parity, MessageReaction, User.lastSeenAt, reply/delete fields"
```

---

## Task 2: OG Scraper Service

**Files:**
- Create: `nest-backend/src/modules/chat/services/og-scraper.service.ts`
- Create: `nest-backend/src/modules/chat/services/og-scraper.service.spec.ts`

**Interfaces:**
- Produces: `OgScraperService.scrape(url: string): Promise<OgMetadata | null>`
- Consumed by: `SendMessageUseCase` (Task 3)

```typescript
// OgMetadata shape stored in DirectMessage.metadata / ChatMessage.metadata
interface OgMetadata {
  title: string | null;
  description: string | null;
  imageUrl: string | null;
  siteName: string | null;
  url: string;
}
```

- [ ] **Step 1: Install `open-graph-scraper`**

```bash
cd nest-backend && npm install open-graph-scraper && npm install --save-dev @types/open-graph-scraper
```

Expected: installs cleanly.

- [ ] **Step 2: Write the failing test**

Create `nest-backend/src/modules/chat/services/og-scraper.service.spec.ts`:
```typescript
import { OgScraperService } from './og-scraper.service';

describe('OgScraperService', () => {
  let sut: OgScraperService;

  beforeEach(() => {
    sut = new OgScraperService();
  });

  describe('extractFirstUrl', () => {
    it('returns first URL found in a string', () => {
      expect(sut.extractFirstUrl('check https://example.com out')).toBe('https://example.com');
    });

    it('returns null when no URL present', () => {
      expect(sut.extractFirstUrl('no url here')).toBeNull();
    });

    it('returns null for empty string', () => {
      expect(sut.extractFirstUrl('')).toBeNull();
    });
  });
});
```

- [ ] **Step 3: Run test to verify it fails**

```bash
cd nest-backend && npx jest src/modules/chat/services/og-scraper.service.spec.ts --no-coverage
```

Expected: FAIL — `OgScraperService` not found.

- [ ] **Step 4: Create `og-scraper.service.ts`**

```typescript
import { Injectable } from '@nestjs/common';
import ogs from 'open-graph-scraper';

export interface OgMetadata {
  title: string | null;
  description: string | null;
  imageUrl: string | null;
  siteName: string | null;
  url: string;
}

const URL_REGEX = /https?:\/\/[^\s]+/;
const SCRAPE_TIMEOUT_MS = 3000;

@Injectable()
export class OgScraperService {
  extractFirstUrl(text: string): string | null {
    const match = text.match(URL_REGEX);
    return match ? match[0] : null;
  }

  async scrape(url: string): Promise<OgMetadata | null> {
    try {
      const result = await Promise.race([
        ogs({ url, timeout: SCRAPE_TIMEOUT_MS }),
        new Promise<null>((resolve) => setTimeout(() => resolve(null), SCRAPE_TIMEOUT_MS + 500)),
      ]);
      if (!result || 'error' in result) return null;
      const { result: data } = result as Awaited<ReturnType<typeof ogs>>;
      return {
        title: (data as any).ogTitle ?? null,
        description: (data as any).ogDescription ?? null,
        imageUrl: (data as any).ogImage?.[0]?.url ?? null,
        siteName: (data as any).ogSiteName ?? null,
        url,
      };
    } catch {
      return null;
    }
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd nest-backend && npx jest src/modules/chat/services/og-scraper.service.spec.ts --no-coverage
```

Expected: PASS — 3 tests passing.

- [ ] **Step 6: Typecheck**

```bash
cd nest-backend && npx tsc --noEmit
```

Expected: zero errors.

- [ ] **Step 7: Commit**

```bash
git add nest-backend/src/modules/chat/services/og-scraper.service.ts nest-backend/src/modules/chat/services/og-scraper.service.spec.ts nest-backend/package.json nest-backend/package-lock.json
git commit -m "feat(chat): add OgScraperService with URL detection and 3s timeout"
```

---

## Task 3: Extend SendMessageUseCase

**Files:**
- Modify: `nest-backend/src/modules/chat/usecases/send-message.usecase.ts`
- Modify: `nest-backend/src/modules/chat/dtos/chat.dto.ts`

**Interfaces:**
- `SendMessageInput` grows: `type?: MessageType`, `attachmentUrl?: string`, `replyToId?: string`
- `SendMessageOutput` grows: `type: string`, `attachmentUrl: string | null`, `metadata: any | null`, `replyToId: string | null`
- OG scraping triggered automatically when `type === 'TEXT'` and content contains a URL

- [ ] **Step 1: Update `SendMessageInput` and `SendMessageOutput` in `chat.dto.ts`**

Find the `SendMessageInput` interface and update:
```typescript
export interface SendMessageInput {
  senderId: string;
  conversationId: string;
  content?: string;
  type?: 'TEXT' | 'IMAGE' | 'GIF' | 'LOCATION' | 'PRODUCT_CARD';
  attachmentUrl?: string;
  replyToId?: string;
  metadata?: Record<string, unknown>;
}
```

Find the `SendMessageOutput` interface and update:
```typescript
export interface SendMessageOutput {
  id: string;
  conversationId: string;
  senderId: string;
  content: string | null;
  type: string;
  attachmentUrl: string | null;
  metadata: Record<string, unknown> | null;
  replyToId: string | null;
  createdAt: Date;
}
```

Also update `SendMessageDTO`:
```typescript
export class SendMessageDTO {
  @ApiProperty({ example: 'Olá!', required: false })
  @IsString()
  @IsOptional()
  @SanitizeText()
  readonly content?: string;

  @ApiProperty({ enum: ['TEXT', 'IMAGE', 'GIF', 'LOCATION', 'PRODUCT_CARD'], default: 'TEXT', required: false })
  @IsString()
  @IsOptional()
  readonly type?: string;

  @ApiProperty({ example: '/uploads/chat/abc.jpg', required: false })
  @IsString()
  @IsOptional()
  readonly attachmentUrl?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  readonly replyToId?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  readonly metadata?: Record<string, unknown>;
}
```

- [ ] **Step 2: Rewrite `send-message.usecase.ts`**

```typescript
import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { BlockRepository } from '@/modules/users/domain/repositories/block.repository';
import { OgScraperService } from '../services/og-scraper.service';
import { SendMessageInput, SendMessageOutput } from '../dtos/chat.dto';

@Injectable()
export class SendMessageUseCase {
  constructor(
    private readonly conversationRepository: ConversationRepository,
    private readonly blockRepository: BlockRepository,
    private readonly ogScraper: OgScraperService,
  ) {}

  async execute(input: SendMessageInput): Promise<Either<AppError, SendMessageOutput>> {
    const conversationResult = await this.conversationRepository.findDirectConversationById(input.conversationId);
    if (isLeft(conversationResult)) return left(conversationResult.value);
    const conversation = conversationResult.value;
    if (!conversation) return left(new NotFoundError('Conversation'));

    if (conversation.status === 'PENDING') {
      const isParticipant = conversation.user1Id === input.senderId || conversation.user2Id === input.senderId;
      if (!isParticipant) return left(new BadRequestError('Conversation is pending acceptance'));
    }

    const otherUserId = conversation.user1Id === input.senderId ? conversation.user2Id : conversation.user1Id;
    const [isBlockedResult, isBlockedByOtherResult] = await Promise.all([
      this.blockRepository.isBlocked(input.senderId, otherUserId),
      this.blockRepository.isBlocked(otherUserId, input.senderId),
    ]);
    if (isBlockedResult.isLeft()) return left(isBlockedResult.value);
    if (isBlockedByOtherResult.isLeft()) return left(isBlockedByOtherResult.value);
    if (isBlockedResult.value) return left(new ForbiddenError('Você bloqueou este usuário'));
    if (isBlockedByOtherResult.value) return left(new ForbiddenError('Você foi bloqueado por este usuário'));

    const messageType = (input.type ?? 'TEXT') as any;
    let metadata: Record<string, unknown> | null = input.metadata ?? null;

    if (messageType === 'TEXT' && input.content) {
      const url = this.ogScraper.extractFirstUrl(input.content);
      if (url) {
        const og = await this.ogScraper.scrape(url);
        if (og) metadata = og as unknown as Record<string, unknown>;
      }
    }

    const messageResult = await this.conversationRepository.createDirectMessage({
      conversation: { connect: { id: input.conversationId } },
      sender: { connect: { id: input.senderId } },
      content: input.content ?? null,
      type: messageType,
      attachmentUrl: input.attachmentUrl ?? null,
      metadata: metadata ?? undefined,
      replyToId: input.replyToId ?? null,
    }, true);
    if (isLeft(messageResult)) return left(messageResult.value);

    await this.conversationRepository.updateDirectConversation(input.conversationId, { lastMessageAt: new Date() });

    const msg = messageResult.value;
    return right({
      id: msg.id,
      conversationId: msg.conversationId,
      senderId: msg.senderId,
      content: msg.content ?? null,
      type: msg.type,
      attachmentUrl: msg.attachmentUrl ?? null,
      metadata: (msg.metadata as Record<string, unknown>) ?? null,
      replyToId: msg.replyToId ?? null,
      createdAt: msg.createdAt,
    });
  }
}
```

- [ ] **Step 3: Register `OgScraperService` in `chat-usecases.module.ts`**

Open `nest-backend/src/modules/chat/usecases/chat-usecases.module.ts`, add `OgScraperService` to `providers`:
```typescript
import { OgScraperService } from '../services/og-scraper.service';
// ...
providers: [
  OgScraperService,
  // ... existing providers
],
```

- [ ] **Step 4: Typecheck**

```bash
cd nest-backend && npx tsc --noEmit
```

Expected: zero errors.

- [ ] **Step 5: Run existing send-message spec**

```bash
cd nest-backend && npx jest src/modules/chat/usecases/send-message.usecase.spec.ts --no-coverage
```

Fix any failures caused by the new `OgScraperService` dependency (add it to the mock providers as `{ provide: OgScraperService, useValue: { extractFirstUrl: jest.fn().mockReturnValue(null), scrape: jest.fn() } }`).

- [ ] **Step 6: Commit**

```bash
git add nest-backend/src/modules/chat/
git commit -m "feat(chat): extend SendMessageUseCase with type, attachmentUrl, replyToId, OG metadata"
```

---

## Task 4: Delete Message Usecase

**Files:**
- Create: `nest-backend/src/modules/chat/usecases/delete-message.usecase.ts`
- Create: `nest-backend/src/modules/chat/usecases/delete-message.usecase.spec.ts`

**Interfaces:**
- Produces: `DeleteMessageUseCase.execute({ messageId, userId, conversationId }): Promise<Either<AppError, void>>`
- Sets `deletedAt = now()` on the message; only the sender can delete

- [ ] **Step 1: Write the failing test**

Create `nest-backend/src/modules/chat/usecases/delete-message.usecase.spec.ts`:
```typescript
import { DeleteMessageUseCase } from './delete-message.usecase';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { right, left } from '@/shared/core/either';
import { ForbiddenError, NotFoundError } from '@/shared/core/errors';

const mockRepo = {
  findDirectMessageById: jest.fn(),
  softDeleteDirectMessage: jest.fn(),
};

describe('DeleteMessageUseCase', () => {
  let sut: DeleteMessageUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    sut = new DeleteMessageUseCase(mockRepo as unknown as ConversationRepository);
  });

  it('returns void on success', async () => {
    mockRepo.findDirectMessageById.mockResolvedValue(right({ id: 'msg1', senderId: 'user1', deletedAt: null }));
    mockRepo.softDeleteDirectMessage.mockResolvedValue(right(undefined));

    const result = await sut.execute({ messageId: 'msg1', userId: 'user1', conversationId: 'conv1' });

    expect(result.isRight()).toBe(true);
  });

  it('returns ForbiddenError when user is not the sender', async () => {
    mockRepo.findDirectMessageById.mockResolvedValue(right({ id: 'msg1', senderId: 'user2', deletedAt: null }));

    const result = await sut.execute({ messageId: 'msg1', userId: 'user1', conversationId: 'conv1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('returns NotFoundError when message not found', async () => {
    mockRepo.findDirectMessageById.mockResolvedValue(right(null));

    const result = await sut.execute({ messageId: 'msg1', userId: 'user1', conversationId: 'conv1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd nest-backend && npx jest src/modules/chat/usecases/delete-message.usecase.spec.ts --no-coverage
```

Expected: FAIL.

- [ ] **Step 3: Add `findDirectMessageById` and `softDeleteDirectMessage` to `ConversationRepository`**

Open `nest-backend/src/modules/chat/domain/repositories/conversation.repository.ts`, add:
```typescript
abstract findDirectMessageById(id: string): RepositoryResponse<DirectMessage | null>;
abstract softDeleteDirectMessage(id: string): RepositoryResponse<void>;
```

Implement in `nest-backend/src/modules/chat/data/repositories/conversation-database.repository.ts`:
```typescript
async findDirectMessageById(id: string): RepositoryResponse<DirectMessage | null> {
  try {
    const msg = await this.prisma.directMessage.findUnique({ where: { id } });
    return right(msg);
  } catch (e) {
    return left(new DatabaseError('findDirectMessageById'));
  }
}

async softDeleteDirectMessage(id: string): RepositoryResponse<void> {
  try {
    await this.prisma.directMessage.update({ where: { id }, data: { deletedAt: new Date() } });
    return right(undefined);
  } catch (e) {
    return left(new DatabaseError('softDeleteDirectMessage'));
  }
}
```

- [ ] **Step 4: Create `delete-message.usecase.ts`**

```typescript
import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationRepository } from '../domain/repositories/conversation.repository';

@Injectable()
export class DeleteMessageUseCase {
  constructor(private readonly conversationRepository: ConversationRepository) {}

  async execute(input: {
    messageId: string;
    userId: string;
    conversationId: string;
  }): Promise<Either<AppError, void>> {
    const msgResult = await this.conversationRepository.findDirectMessageById(input.messageId);
    if (isLeft(msgResult)) return left(msgResult.value);
    const msg = msgResult.value;
    if (!msg) return left(new NotFoundError('Message'));
    if (msg.senderId !== input.userId) return left(new ForbiddenError('Você só pode apagar suas próprias mensagens'));

    const deleteResult = await this.conversationRepository.softDeleteDirectMessage(input.messageId);
    if (isLeft(deleteResult)) return left(deleteResult.value);

    return right(undefined);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd nest-backend && npx jest src/modules/chat/usecases/delete-message.usecase.spec.ts --no-coverage
```

Expected: PASS — 3 tests passing.

- [ ] **Step 6: Register in `chat-usecases.module.ts`** — add `DeleteMessageUseCase` to providers.

- [ ] **Step 7: Typecheck + commit**

```bash
cd nest-backend && npx tsc --noEmit
git add nest-backend/src/modules/chat/
git commit -m "feat(chat): add DeleteMessageUseCase (soft-delete, sender-only)"
```

---

## Task 5: Toggle Reaction Usecase

**Files:**
- Create: `nest-backend/src/modules/chat/usecases/toggle-reaction.usecase.ts`
- Create: `nest-backend/src/modules/chat/usecases/toggle-reaction.usecase.spec.ts`

**Interfaces:**
- Produces: `ToggleReactionUseCase.execute({ userId, messageId, emoji, messageModel: 'DIRECT' | 'ORDER' }): Promise<Either<AppError, { reactions: ReactionSummary[] }>>`
- `ReactionSummary = { emoji: string; count: number; userIds: string[] }`
- If user has same emoji on message: remove it. If different emoji: replace. If no reaction: add.

- [ ] **Step 1: Write the failing test**

Create `nest-backend/src/modules/chat/usecases/toggle-reaction.usecase.spec.ts`:
```typescript
import { ToggleReactionUseCase } from './toggle-reaction.usecase';
import { right } from '@/shared/core/either';

const VALID_EMOJIS = ['❤️', '😂', '😮', '😢', '😡', '👍'];

const mockRepo = {
  findReactionByUserAndMessage: jest.fn(),
  upsertReaction: jest.fn(),
  deleteReaction: jest.fn(),
  getReactionsForMessage: jest.fn(),
};

describe('ToggleReactionUseCase', () => {
  let sut: ToggleReactionUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    sut = new ToggleReactionUseCase(mockRepo as any);
  });

  it('adds reaction when user has none', async () => {
    mockRepo.findReactionByUserAndMessage.mockResolvedValue(right(null));
    mockRepo.upsertReaction.mockResolvedValue(right(undefined));
    mockRepo.getReactionsForMessage.mockResolvedValue(right([{ emoji: '❤️', userId: 'u1' }]));

    const result = await sut.execute({ userId: 'u1', messageId: 'm1', emoji: '❤️', messageModel: 'DIRECT' });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.upsertReaction).toHaveBeenCalled();
  });

  it('removes reaction when user taps same emoji again', async () => {
    mockRepo.findReactionByUserAndMessage.mockResolvedValue(right({ id: 'r1', emoji: '❤️' }));
    mockRepo.deleteReaction.mockResolvedValue(right(undefined));
    mockRepo.getReactionsForMessage.mockResolvedValue(right([]));

    const result = await sut.execute({ userId: 'u1', messageId: 'm1', emoji: '❤️', messageModel: 'DIRECT' });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.deleteReaction).toHaveBeenCalledWith('r1');
  });

  it('rejects invalid emoji', async () => {
    const result = await sut.execute({ userId: 'u1', messageId: 'm1', emoji: '🥳', messageModel: 'DIRECT' });
    expect(result.isLeft()).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd nest-backend && npx jest src/modules/chat/usecases/toggle-reaction.usecase.spec.ts --no-coverage
```

Expected: FAIL.

- [ ] **Step 3: Add reaction repo methods to `ConversationRepository`**

In `conversation.repository.ts` add:
```typescript
abstract findReactionByUserAndMessage(userId: string, messageId: string, model: 'DIRECT' | 'ORDER'): RepositoryResponse<MessageReaction | null>;
abstract upsertReaction(data: { userId: string; messageId: string; emoji: string; model: 'DIRECT' | 'ORDER' }): RepositoryResponse<void>;
abstract deleteReaction(reactionId: string): RepositoryResponse<void>;
abstract getReactionsForMessage(messageId: string, model: 'DIRECT' | 'ORDER'): RepositoryResponse<{ emoji: string; userId: string }[]>;
```

Implement in `conversation-database.repository.ts` using Prisma `messageReaction` queries.

- [ ] **Step 4: Create `toggle-reaction.usecase.ts`**

```typescript
import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { ConversationRepository } from '../domain/repositories/conversation.repository';

const VALID_EMOJIS = ['❤️', '😂', '😮', '😢', '😡', '👍'];

export interface ReactionSummary {
  emoji: string;
  count: number;
  userIds: string[];
}

@Injectable()
export class ToggleReactionUseCase {
  constructor(private readonly conversationRepository: ConversationRepository) {}

  async execute(input: {
    userId: string;
    messageId: string;
    emoji: string;
    messageModel: 'DIRECT' | 'ORDER';
  }): Promise<Either<AppError, { reactions: ReactionSummary[] }>> {
    if (!VALID_EMOJIS.includes(input.emoji)) {
      return left(new BadRequestError(`Emoji inválido. Permitidos: ${VALID_EMOJIS.join(' ')}`));
    }

    const existing = await this.conversationRepository.findReactionByUserAndMessage(
      input.userId, input.messageId, input.messageModel,
    );
    if (isLeft(existing)) return left(existing.value);

    if (existing.value && existing.value.emoji === input.emoji) {
      const del = await this.conversationRepository.deleteReaction(existing.value.id);
      if (isLeft(del)) return left(del.value);
    } else {
      const upsert = await this.conversationRepository.upsertReaction({
        userId: input.userId,
        messageId: input.messageId,
        emoji: input.emoji,
        model: input.messageModel,
      });
      if (isLeft(upsert)) return left(upsert.value);
    }

    const allResult = await this.conversationRepository.getReactionsForMessage(input.messageId, input.messageModel);
    if (isLeft(allResult)) return left(allResult.value);

    const grouped = VALID_EMOJIS.reduce<ReactionSummary[]>((acc, emoji) => {
      const matching = allResult.value.filter((r) => r.emoji === emoji);
      if (matching.length > 0) {
        acc.push({ emoji, count: matching.length, userIds: matching.map((r) => r.userId) });
      }
      return acc;
    }, []);

    return right({ reactions: grouped });
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd nest-backend && npx jest src/modules/chat/usecases/toggle-reaction.usecase.spec.ts --no-coverage
```

Expected: PASS — 3 tests passing.

- [ ] **Step 6: Register in `chat-usecases.module.ts`** — add `ToggleReactionUseCase`.

- [ ] **Step 7: Typecheck + commit**

```bash
cd nest-backend && npx tsc --noEmit
git add nest-backend/src/modules/chat/
git commit -m "feat(chat): add ToggleReactionUseCase (6 emojis, toggle semantics)"
```

---

## Task 6: Extend Chat Gateway + Controller

**Files:**
- Modify: `nest-backend/src/modules/chat/chat.gateway.ts`
- Modify: `nest-backend/src/modules/chat/chat.controller.ts`

**Interfaces:**
- Gateway emits: `typing_stop`, `user_online`, `user_offline`, `message_deleted`, `reaction_updated`
- Gateway subscribes: `typing_stop`, `delete_message`, `toggle_reaction`
- Controller adds: `DELETE /chat/conversations/:convId/messages/:msgId`, `POST /chat/conversations/:convId/messages/:msgId/react`

- [ ] **Step 1: Add `typing_stop`, online/offline, and `connectedUsers` user-id tracking to gateway**

In `chat.gateway.ts`, the `connectedUsers` map stores `socket.id → user`. Add a reverse map `userSockets = new Map<string, string>()` (userId → socketId) so we can broadcast to a specific user.

Update `handleConnection`:
```typescript
this.connectedUsers.set(client.id, { userId: payload.userId, email: payload.email });
this.userSockets.set(payload.userId, client.id);
// Broadcast online status to all rooms the user is in
client.broadcast.emit('user_online', { userId: payload.userId, lastSeenAt: null });
// Persist lastSeenAt via repo (inject UserRepository or call directly via prisma)
```

Update `handleDisconnect`:
```typescript
const user = this.connectedUsers.get(client.id);
if (user) {
  this.userSockets.delete(user.userId);
  const now = new Date();
  client.broadcast.emit('user_offline', { userId: user.userId, lastSeenAt: now.toISOString() });
  // update User.lastSeenAt via repo
}
this.connectedUsers.delete(client.id);
```

- [ ] **Step 2: Add `typing_stop` event handler**

```typescript
@SubscribeMessage('typing_stop')
handleTypingStop(
  @ConnectedSocket() client: Socket,
  @MessageBody() data: { conversationId: string },
) {
  const user = this.connectedUsers.get(client.id);
  if (!user) return;
  client.to(`conversation:${data.conversationId}`).emit('user_stopped_typing', { userId: user.userId });
}
```

- [ ] **Step 3: Add `delete_message` event handler**

```typescript
@SubscribeMessage('delete_message')
async handleDeleteMessage(
  @ConnectedSocket() client: Socket,
  @MessageBody() data: { conversationId: string; messageId: string },
) {
  const user = this.connectedUsers.get(client.id);
  if (!user) return { error: 'Unauthorized' };

  const result = await this.deleteMessageUseCase.execute({
    messageId: data.messageId,
    userId: user.userId,
    conversationId: data.conversationId,
  });
  if (result.isLeft()) return { error: result.value.message };

  this.server.to(`conversation:${data.conversationId}`).emit('message_deleted', { messageId: data.messageId });
  return { event: 'message_deleted' };
}
```

- [ ] **Step 4: Add `toggle_reaction` event handler**

```typescript
@SubscribeMessage('toggle_reaction')
async handleToggleReaction(
  @ConnectedSocket() client: Socket,
  @MessageBody() data: { conversationId: string; messageId: string; emoji: string },
) {
  const user = this.connectedUsers.get(client.id);
  if (!user) return { error: 'Unauthorized' };

  const result = await this.toggleReactionUseCase.execute({
    userId: user.userId,
    messageId: data.messageId,
    emoji: data.emoji,
    messageModel: 'DIRECT',
  });
  if (result.isLeft()) return { error: result.value.message };

  this.server.to(`conversation:${data.conversationId}`).emit('reaction_updated', {
    messageId: data.messageId,
    reactions: result.value.reactions,
  });
  return { event: 'reaction_updated', data: result.value };
}
```

- [ ] **Step 5: Inject `DeleteMessageUseCase` and `ToggleReactionUseCase` into `ChatGateway` constructor**

Add them to the constructor parameters and update the module providers.

- [ ] **Step 6: Add REST endpoints in `chat.controller.ts`**

```typescript
@Delete('conversations/:convId/messages/:msgId')
@HttpCode(HttpStatus.OK)
@ApiBearerAuth()
@ApiDoc({ summary: 'Soft-delete a message (sender only)', auth: true })
async deleteMessage(
  @Param('convId') convId: string,
  @Param('msgId') msgId: string,
  @CurrentUser() user: AuthUser,
) {
  const result = await this.chatService.deleteMessage(user.userId, msgId, convId);
  if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
  return result.value;
}

@Post('conversations/:convId/messages/:msgId/react')
@HttpCode(HttpStatus.OK)
@ApiBearerAuth()
@ApiDoc({ summary: 'Toggle a reaction on a message', auth: true })
async reactToMessage(
  @Param('convId') convId: string,
  @Param('msgId') msgId: string,
  @Body() body: { emoji: string },
  @CurrentUser() user: AuthUser,
) {
  const result = await this.chatService.toggleReaction(user.userId, msgId, body.emoji, 'DIRECT');
  if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
  return result.value;
}
```

- [ ] **Step 7: Wire through `ChatService` in `api/chat.service.ts`** — add `deleteMessage` and `toggleReaction` methods that call the respective usecases.

- [ ] **Step 8: Typecheck**

```bash
cd nest-backend && npx tsc --noEmit
```

- [ ] **Step 9: Commit**

```bash
git add nest-backend/src/modules/chat/
git commit -m "feat(chat): extend gateway with typing_stop, online/offline, delete, reaction events"
```

---

## Task 7: Flutter — Message Entity + Repository Methods

**Files:**
- Create: `frontend/lib/features/chat/data/entities/message_entity.dart`
- Create: `frontend/lib/features/chat/data/entities/og_metadata_entity.dart`
- Create: `frontend/lib/features/chat/data/entities/message_reaction_entity.dart`
- Modify: `frontend/lib/features/chat/domain/repositories/i_chat_repository.dart`
- Modify: `frontend/lib/features/chat/data/repositories/chat_repository.dart`

**Interfaces:**
- Produces: `MessageEntity` with `id, conversationId, senderId, content?, type, attachmentUrl?, metadata (OgMetadata?), replyToId?, replyTo (MessageEntity?), reactions (List<MessageReactionEntity>), deletedAt?, createdAt, readAt?, deliveredAt?`
- Produces: `IChatRepository.sendRichMessage(...)`, `IChatRepository.deleteMessage(...)`, `IChatRepository.reactToMessage(...)`

- [ ] **Step 1: Create `og_metadata_entity.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'og_metadata_entity.freezed.dart';
part 'og_metadata_entity.g.dart';

@freezed
abstract class OgMetadataEntity with _$OgMetadataEntity {
  const factory OgMetadataEntity({
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
    required String url,
  }) = _OgMetadataEntity;

  factory OgMetadataEntity.fromJson(Map<String, dynamic> json) =>
      _$OgMetadataEntityFromJson(json);
}
```

- [ ] **Step 2: Create `message_reaction_entity.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_reaction_entity.freezed.dart';
part 'message_reaction_entity.g.dart';

@freezed
abstract class MessageReactionEntity with _$MessageReactionEntity {
  const factory MessageReactionEntity({
    required String emoji,
    required int count,
    required List<String> userIds,
  }) = _MessageReactionEntity;

  factory MessageReactionEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageReactionEntityFromJson(json);
}
```

- [ ] **Step 3: Create `message_entity.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'og_metadata_entity.dart';
import 'message_reaction_entity.dart';

part 'message_entity.freezed.dart';
part 'message_entity.g.dart';

OgMetadataEntity? _ogFromJson(Map<String, dynamic>? json) =>
    json == null ? null : OgMetadataEntity.fromJson(json);

Map<String, dynamic>? _ogToJson(OgMetadataEntity? e) => e?.toJson();

@freezed
abstract class MessageEntity with _$MessageEntity {
  const factory MessageEntity({
    required String id,
    required String conversationId,
    required String senderId,
    String? content,
    @Default('TEXT') String type,
    String? attachmentUrl,
    @JsonKey(fromJson: _ogFromJson, toJson: _ogToJson) OgMetadataEntity? metadata,
    String? replyToId,
    MessageEntity? replyTo,
    @Default([]) List<MessageReactionEntity> reactions,
    DateTime? deletedAt,
    DateTime? readAt,
    DateTime? deliveredAt,
    required DateTime createdAt,
  }) = _MessageEntity;

  factory MessageEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageEntityFromJson(json);
}
```

- [ ] **Step 4: Run codegen**

```bash
cd frontend && fvm flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: generates `*.freezed.dart` and `*.g.dart` for all three entities.

- [ ] **Step 5: Add new methods to `i_chat_repository.dart`**

```dart
Future<Either<Failure, MessageEntity>> sendRichMessage({
  required String conversationId,
  String? content,
  String type,
  String? attachmentUrl,
  String? replyToId,
});
Future<Either<Failure, void>> deleteMessage(String conversationId, String messageId);
Future<Either<Failure, List<MessageReactionEntity>>> reactToMessage(
  String conversationId,
  String messageId,
  String emoji,
);
```

- [ ] **Step 6: Implement new methods in `chat_repository.dart`**

```dart
@override
Future<Either<Failure, MessageEntity>> sendRichMessage({
  required String conversationId,
  String? content,
  String type = 'TEXT',
  String? attachmentUrl,
  String? replyToId,
}) async {
  try {
    final response = await HttpClient.instance.post(
      '/chat/conversations/$conversationId/messages',
      data: {
        if (content != null) 'content': content,
        'type': type,
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        if (replyToId != null) 'replyToId': replyToId,
      },
    );
    if (response.statusCode == 201 && response.data != null) {
      return Right(MessageEntity.fromJson(response.data['data'] as Map<String, dynamic>));
    }
    return const Left(ServerFailure('Falha ao enviar mensagem'));
  } catch (_) {
    return const Left(ServerFailure('Erro de conexão'));
  }
}

@override
Future<Either<Failure, void>> deleteMessage(String conversationId, String messageId) async {
  try {
    await HttpClient.instance.delete('/chat/conversations/$conversationId/messages/$messageId');
    return const Right(null);
  } catch (_) {
    return const Left(ServerFailure('Erro ao apagar mensagem'));
  }
}

@override
Future<Either<Failure, List<MessageReactionEntity>>> reactToMessage(
  String conversationId, String messageId, String emoji,
) async {
  try {
    final response = await HttpClient.instance.post(
      '/chat/conversations/$conversationId/messages/$messageId/react',
      data: {'emoji': emoji},
    );
    if (response.statusCode == 200 && response.data != null) {
      final list = response.data['data']['reactions'] as List;
      return Right(list.map((e) => MessageReactionEntity.fromJson(e as Map<String, dynamic>)).toList());
    }
    return const Left(ServerFailure('Falha ao reagir'));
  } catch (_) {
    return const Left(ServerFailure('Erro de conexão'));
  }
}
```

- [ ] **Step 7: Flutter analyze**

```bash
cd frontend && fvm flutter analyze
```

Expected: zero issues.

- [ ] **Step 8: Commit**

```bash
git add frontend/lib/features/chat/data/entities/ frontend/lib/features/chat/data/repositories/ frontend/lib/features/chat/domain/repositories/
git commit -m "feat(chat): add MessageEntity, OgMetadataEntity, MessageReactionEntity + rich repo methods"
```

---

## Task 8: Message Bubble Rework

**Files:**
- Modify: `frontend/lib/features/chat/presentation/widgets/message_bubble.dart`
- Create: `frontend/lib/features/chat/presentation/widgets/image_message_bubble.dart`
- Create: `frontend/lib/features/chat/presentation/widgets/link_preview_card.dart`
- Create: `frontend/lib/features/chat/presentation/widgets/location_message_bubble.dart`
- Create: `frontend/lib/features/chat/presentation/widgets/reply_preview_banner.dart`
- Create: `frontend/lib/features/chat/presentation/widgets/reaction_bar.dart`

**Interfaces:**
- `MessageBubble` now receives a `MessageEntity` and routes to the correct sub-widget by `type`
- Reactions bar shows below the bubble when `reactions` is non-empty
- Reply preview appears above the bubble content when `replyTo` is set

- [ ] **Step 1: Add `flutter_map` and location packages to `pubspec.yaml`**

```yaml
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  geolocator: ^13.0.2
  permission_handler: ^11.4.0
```

```bash
cd frontend && fvm flutter pub get
```

- [ ] **Step 2: Create `reply_preview_banner.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';

class ReplyPreviewBanner extends StatelessWidget {
  final MessageEntity replyTo;
  final bool isMe;

  const ReplyPreviewBanner({super.key, required this.replyTo, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final label = replyTo.deletedAt != null ? 'Mensagem apagada' : (replyTo.content ?? '📎 Anexo');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isMe ? AppColors.onPrimary.withValues(alpha: 0.6) : AppColors.primaryContainer,
            width: 3,
          ),
        ),
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.3)
            : AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          color: isMe ? AppColors.onPrimary.withValues(alpha: 0.8) : AppColors.outline,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `reaction_bar.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';

class ReactionBar extends StatelessWidget {
  final List<MessageReactionEntity> reactions;
  final void Function(String emoji) onTap;
  final void Function(String emoji) onLongPress;

  const ReactionBar({
    super.key,
    required this.reactions,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: reactions.map((r) => GestureDetector(
          onTap: () => onTap(r.emoji),
          onLongPress: () => onLongPress(r.emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: AppColors.surfaceContainerHighest,
            child: Text(
              '${r.emoji} ${r.count}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        )).toList(),
      ),
    );
  }
}
```

- [ ] **Step 4: Create `image_message_bubble.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/shared/services/http_client.dart';

class ImageMessageBubble extends StatelessWidget {
  final String relativePath;
  final double maxWidth;

  const ImageMessageBubble({super.key, required this.relativePath, this.maxWidth = 240});

  @override
  Widget build(BuildContext context) {
    final fullUrl = '${HttpClient.baseUrl}$relativePath';
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: CachedNetworkImage(
        imageUrl: fullUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
        errorWidget: (_, __, ___) => const SizedBox(height: 80, child: Center(child: Icon(Icons.broken_image))),
      ),
    );
  }
}
```

> Note: `HttpClient.baseUrl` must be a static getter that returns the configured base URL (e.g. `http://192.168.x.x:3000`). Add it if it doesn't exist.

- [ ] **Step 5: Create `link_preview_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/features/chat/data/entities/og_metadata_entity.dart';

class LinkPreviewCard extends StatelessWidget {
  final OgMetadataEntity metadata;
  final bool isMe;

  const LinkPreviewCard({super.key, required this.metadata, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceContainerLowest;
    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata.imageUrl != null)
            CachedNetworkImage(
              imageUrl: metadata.imageUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metadata.siteName != null)
                  Text(metadata.siteName!.toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppTypography.headlineFontFamily,
                        fontSize: 10,
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.w700,
                      )),
                if (metadata.title != null)
                  Text(metadata.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )),
                if (metadata.description != null)
                  Text(metadata.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Create `location_message_bubble.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';

class LocationMessageBubble extends StatelessWidget {
  final double lat;
  final double lng;
  final String? address;

  const LocationMessageBubble({super.key, required this.lat, required this.lng, this.address});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          width: 240,
          child: FlutterMap(
            options: MapOptions(initialCenter: point, initialZoom: 15, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              MarkerLayer(markers: [
                Marker(
                  point: point,
                  child: const Icon(Icons.location_pin, color: AppColors.primaryContainer, size: 32),
                ),
              ]),
            ],
          ),
        ),
        if (address != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(address!,
                style: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 12, color: AppColors.outline)),
          ),
      ],
    );
  }
}
```

- [ ] **Step 7: Rewrite `message_bubble.dart` to orchestrate by type**

Replace `MessageBubble` to accept a `MessageEntity` and dispatch to sub-widgets:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'image_message_bubble.dart';
import 'link_preview_card.dart';
import 'location_message_bubble.dart';
import 'reply_preview_banner.dart';
import 'reaction_bar.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool isDark;
  final bool isConsecutive;
  final Color accentColor;
  final void Function(MessageEntity) onReactionTap;
  final void Function(String emoji) onReactionLongPress;
  final void Function(MessageEntity) onSwipeToReply;
  final void Function(MessageEntity) onLongPressMessage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isDark,
    this.isConsecutive = false,
    this.accentColor = AppColors.primaryContainer,
    required this.onReactionTap,
    required this.onReactionLongPress,
    required this.onSwipeToReply,
    required this.onLongPressMessage,
  });

  bool get _isDeleted => message.deletedAt != null;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);
    final bubbleColor = isMe
        ? accentColor
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceContainerLow);

    return GestureDetector(
      onLongPress: () => onLongPressMessage(message),
      child: Dismissible(
        key: Key('swipe_${message.id}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          onSwipeToReply(message);
          return false;
        },
        background: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.reply, color: AppColors.primaryContainer),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: isConsecutive ? 2 : 8),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Container(
                      color: bubbleColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.replyTo != null)
                            ReplyPreviewBanner(replyTo: message.replyTo!, isMe: isMe),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: _buildContent(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 2, left: isMe ? 0 : 4, right: isMe ? 4 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Text(timeStr, style: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 11, color: context.textSecondary)),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      _ReadStatusIcon(isRead: message.readAt != null, isDelivered: message.deliveredAt != null),
                    ],
                  ],
                ),
              ),
              if (message.reactions.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: isMe ? 0 : 4, right: isMe ? 4 : 0),
                  child: ReactionBar(
                    reactions: message.reactions,
                    onTap: (_) => onReactionTap(message),
                    onLongPress: onReactionLongPress,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isDeleted) {
      return Text('Mensagem apagada',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: isMe ? AppColors.onPrimary.withValues(alpha: 0.6) : AppColors.outline,
          ));
    }
    switch (message.type) {
      case 'IMAGE':
      case 'GIF':
        return ImageMessageBubble(relativePath: message.attachmentUrl!);
      case 'LOCATION':
        final meta = message.metadata;
        final lat = (meta?.toJson()['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (meta?.toJson()['lng'] as num?)?.toDouble() ?? 0.0;
        final address = meta?.toJson()['address'] as String?;
        return LocationMessageBubble(lat: lat, lng: lng, address: address);
      case 'PRODUCT_CARD':
        // Product card — metadata contains product details
        return _ProductCardContent(metadata: message.metadata?.toJson());
      default:
        // TEXT — show link preview if metadata present
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.content != null)
              Text(message.content!,
                  style: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 14,
                      color: isMe ? AppColors.onPrimary : (context.isDark ? AppColors.white : AppColors.darkGray))),
            if (message.metadata != null) ...[
              const SizedBox(height: 8),
              LinkPreviewCard(metadata: message.metadata!, isMe: isMe),
            ],
          ],
        );
    }
  }
}

class _ProductCardContent extends StatelessWidget {
  final Map<String, dynamic>? metadata;
  const _ProductCardContent({this.metadata});

  @override
  Widget build(BuildContext context) {
    if (metadata == null) return const Text('Produto');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(metadata!['title'] as String? ?? 'Produto',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        if (metadata!['price'] != null)
          Text('R\$ ${(metadata!['price'] as num) / 100}',
              style: const TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ReadStatusIcon extends StatelessWidget {
  final bool isRead;
  final bool isDelivered;
  const _ReadStatusIcon({required this.isRead, required this.isDelivered});

  @override
  Widget build(BuildContext context) {
    if (isRead) return const Icon(Icons.done_all, size: 14, color: AppColors.primaryContainer);
    if (isDelivered) return Icon(Icons.done_all, size: 14, color: context.textSecondary);
    return Icon(Icons.done, size: 14, color: context.textSecondary);
  }
}
```

- [ ] **Step 8: Flutter analyze**

```bash
cd frontend && fvm flutter analyze
```

Fix all issues before committing.

- [ ] **Step 9: Commit**

```bash
git add frontend/lib/features/chat/presentation/widgets/
git commit -m "feat(chat): rework MessageBubble — type routing, reply preview, reaction bar, read ticks"
```

---

## Task 9: Attachment Bottom Sheet + Image/GIF Upload Flow

**Files:**
- Create: `frontend/lib/features/chat/presentation/widgets/attachment_bottom_sheet.dart`
- Modify: `frontend/lib/features/chat/presentation/pages/chat_conversation_page.dart`

**Interfaces:**
- `showAttachmentSheet(context, { onImage, onGif, onLocation, onProduct })` — shows brutalist bottom sheet with 4 tile options
- On image/GIF tap: opens gallery, uploads via `UploadService`, then calls `sendRichMessage` with `type: IMAGE` or `GIF` and `attachmentUrl`

- [ ] **Step 1: Create `attachment_bottom_sheet.dart`**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/shared/services/upload_service.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

Future<void> showAttachmentSheet(
  BuildContext context, {
  required void Function(String uploadedUrl, String type) onMediaReady,
  required void Function() onLocationTap,
  required void Function() onProductTap,
  required void Function(String errorMessage) onError,
}) {
  return showBrutalistSheet(
    context: context,
    title: 'ADICIONAR',
    builder: (ctx) => _AttachmentSheetBody(
      onMediaReady: onMediaReady,
      onLocationTap: () { Navigator.pop(ctx); onLocationTap(); },
      onProductTap: () { Navigator.pop(ctx); onProductTap(); },
      onError: onError,
      onClose: () => Navigator.pop(ctx),
    ),
  );
}

class _AttachmentSheetBody extends StatefulWidget {
  final void Function(String url, String type) onMediaReady;
  final VoidCallback onLocationTap;
  final VoidCallback onProductTap;
  final void Function(String) onError;
  final VoidCallback onClose;

  const _AttachmentSheetBody({
    required this.onMediaReady,
    required this.onLocationTap,
    required this.onProductTap,
    required this.onError,
    required this.onClose,
  });

  @override
  State<_AttachmentSheetBody> createState() => _AttachmentSheetBodyState();
}

class _AttachmentSheetBodyState extends State<_AttachmentSheetBody> {
  bool _uploading = false;

  Future<void> _pick(bool isGif) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: isGif ? 100 : 80);
    if (picked == null) return;
    widget.onClose();

    setState(() => _uploading = true);
    final result = await UploadService.uploadFile(File(picked.path), 'chat');
    setState(() => _uploading = false);

    result.fold(
      (failure) => widget.onError(failure.message),
      (url) {
        final type = picked.path.toLowerCase().endsWith('.gif') ? 'GIF' : 'IMAGE';
        widget.onMediaReady(url, type);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uploading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tile(Icons.image_outlined, 'IMAGEM / GIF', () => _pick(false)),
        _tile(Icons.location_on_outlined, 'LOCALIZAÇÃO', widget.onLocationTap),
        _tile(Icons.shopping_bag_outlined, 'PRODUTO', widget.onProductTap),
      ],
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      color: Colors.transparent,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryContainer, size: 22),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontFamily: AppTypography.headlineFontFamily, fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 2: Wire into `chat_conversation_page.dart`**

Add a `+` button to the input bar that calls `showAttachmentSheet`. On `onMediaReady`, call `ref.read(chatProvider.notifier).sendRichMessage(type: type, attachmentUrl: url)`. On error, show `AppSnackbar.error`. The existing text send button continues to call `sendMessage` with `type: 'TEXT'`.

Also wire the snackbar for `PayloadTooLargeError` from `UploadService` — the `DioException` 413 handler in `UploadService` already returns `ServerFailure('Arquivo muito grande. Máximo: 10 MB')`, so this is handled automatically via `onError`.

- [ ] **Step 3: Flutter analyze + commit**

```bash
cd frontend && fvm flutter analyze
git add frontend/lib/features/chat/
git commit -m "feat(chat): attachment bottom sheet — image/GIF upload with 10MB snackbar guard"
```

---

## Task 10: Location Picker Page

**Files:**
- Create: `frontend/lib/features/chat/presentation/pages/location_picker_page.dart`

**Interfaces:**
- Navigates to full-screen page with `flutter_map`, pin starts at current GPS position
- User can drag the pin; "Enviar localização" button sends `{ lat, lng, address }` back as `pop` result
- On return, `chat_conversation_page.dart` calls `sendRichMessage(type: 'LOCATION', metadata: { lat, lng, address })`

- [ ] **Step 1: Create `location_picker_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/page_header.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng? _pinPosition;
  bool _loading = true;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      setState(() => _loading = false);
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    final latLng = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _pinPosition = latLng;
      _loading = false;
    });
    _mapController.move(latLng, 15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PageHeader(text: 'LOCALIZAÇÃO'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _pinPosition ?? const LatLng(-15.7942, -47.8822),
                          initialZoom: 15,
                          onTap: (_, point) => setState(() => _pinPosition = point),
                        ),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                          if (_pinPosition != null)
                            MarkerLayer(markers: [
                              Marker(
                                point: _pinPosition!,
                                child: const Icon(Icons.location_pin, color: AppColors.primaryContainer, size: 40),
                              ),
                            ]),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          padding: const EdgeInsets.all(16),
                          child: AppButton(
                            label: 'Enviar localização',
                            onPressed: _pinPosition == null ? null : () => Navigator.pop(context, {
                              'lat': _pinPosition!.latitude,
                              'lng': _pinPosition!.longitude,
                              'address': null,
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire from `chat_conversation_page.dart`**

In the `onLocationTap` handler from the attachment sheet:
```dart
final result = await Navigator.push<Map<String, dynamic>>(
  context,
  MaterialPageRoute(builder: (_) => const LocationPickerPage()),
);
if (result != null) {
  ref.read(chatProvider.notifier).sendRichMessage(
    conversationId: widget.conversationId,
    type: 'LOCATION',
    metadata: result,
  );
}
```

- [ ] **Step 3: Add location permissions to Android/iOS manifests**

`android/app/src/main/AndroidManifest.xml` — add before `<application>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

`ios/Runner/Info.plist` — add:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Para compartilhar sua localização no chat</string>
```

- [ ] **Step 4: Flutter analyze + commit**

```bash
cd frontend && fvm flutter analyze
git add frontend/lib/features/chat/presentation/pages/location_picker_page.dart frontend/android/ frontend/ios/
git commit -m "feat(chat): location picker page with flutter_map drag-to-pick + GPS start position"
```

---

## Task 11: Reaction Picker Overlay + Who-Reacted Sheet

**Files:**
- Create: `frontend/lib/features/chat/presentation/widgets/reaction_picker_overlay.dart`
- Create: `frontend/lib/features/chat/presentation/widgets/who_reacted_sheet.dart`

**Interfaces:**
- `ReactionPickerOverlay` — appears on long-press of a bubble, shows the 6 emojis in a brutalist row
- `WhoReactedSheet` — appears on tap of a reaction chip, shows per-emoji tabs with user lists

- [ ] **Step 1: Create `reaction_picker_overlay.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';

const kReactionEmojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];

class ReactionPickerOverlay extends StatelessWidget {
  final void Function(String emoji) onSelect;

  const ReactionPickerOverlay({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: kReactionEmojis.map((emoji) => GestureDetector(
          onTap: () {
            Navigator.pop(context);
            onSelect(emoji);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
        )).toList(),
      ),
    );
  }
}

void showReactionPicker(BuildContext context, void Function(String) onSelect) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ReactionPickerOverlay(onSelect: onSelect),
  );
}
```

- [ ] **Step 2: Create `who_reacted_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';
import 'reaction_picker_overlay.dart';

class WhoReactedSheet extends StatefulWidget {
  final List<MessageReactionEntity> reactions;
  final String initialEmoji;

  const WhoReactedSheet({super.key, required this.reactions, required this.initialEmoji});

  @override
  State<WhoReactedSheet> createState() => _WhoReactedSheetState();
}

class _WhoReactedSheetState extends State<WhoReactedSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialEmoji;
  }

  @override
  Widget build(BuildContext context) {
    final activeReactions = widget.reactions.where((r) => r.count > 0).toList();
    final current = activeReactions.firstWhere((r) => r.emoji == _selected, orElse: () => activeReactions.first);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji tab row
          Row(
            children: activeReactions.map((r) => GestureDetector(
              onTap: () => setState(() => _selected = r.emoji),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: _selected == r.emoji ? AppColors.surfaceContainerHighest : Colors.transparent,
                child: Text('${r.emoji} ${r.count}', style: const TextStyle(fontSize: 16)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          // User list — shows userIds for now; fetch display names from cache if available
          ...current.userIds.map((uid) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Container(width: 36, height: 36, color: AppColors.surfaceContainerHighest,
                  child: const Icon(Icons.person, color: AppColors.mediumGray, size: 20)),
              const SizedBox(width: 12),
              Text(uid, style: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 13)),
            ]),
          )),
        ],
      ),
    );
  }
}
```

> Note: the `userIds` shown here are raw IDs — in a follow-up, resolve to display names via the users cache.

- [ ] **Step 3: Wire both into `chat_conversation_page.dart`**

- On `onLongPressMessage`: call `showReactionPicker(context, (emoji) => ref.read(chatProvider.notifier).toggleReaction(message.id, emoji))`
- On reaction chip `onLongPress`: call `showModalBottomSheet` with `WhoReactedSheet(reactions: message.reactions, initialEmoji: emoji)`
- On reaction chip `onTap`: same as long-press reaction picker

- [ ] **Step 4: Flutter analyze + commit**

```bash
cd frontend && fvm flutter analyze
git add frontend/lib/features/chat/presentation/widgets/reaction_picker_overlay.dart frontend/lib/features/chat/presentation/widgets/who_reacted_sheet.dart frontend/lib/features/chat/presentation/pages/
git commit -m "feat(chat): reaction picker overlay + who-reacted sheet"
```

---

## Task 12: Typing Indicator + Online Status

**Files:**
- Create: `frontend/lib/features/chat/presentation/widgets/typing_indicator_bubble.dart`
- Modify: `frontend/lib/features/chat/presentation/pages/chat_conversation_page.dart`
- Modify: `frontend/lib/features/chat/presentation/widgets/chat_header.dart`

**Interfaces:**
- Frontend emits `typing` on text change (debounced 500ms), `typing_stop` on 2s idle
- Listens `user_typing` → shows typing bubble; `user_stopped_typing` → hides it
- Listens `user_online` / `user_offline` → updates header subtitle

- [ ] **Step 1: Create `typing_indicator_bubble.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';

class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final offset = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
            final opacity = (offset < 0.5 ? offset * 2 : (1 - offset) * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  color: AppColors.primaryContainer,
                ),
              ),
            );
          },
        )),
      ),
    );
  }
}
```

- [ ] **Step 2: Wire typing events in `chat_conversation_page.dart`**

```dart
// In _inputController listener (add alongside existing onChanged):
Timer? _typingDebounce;

void _onTextChanged(String _) {
  _socket.emit('typing', {'conversationId': widget.conversationId});
  _typingDebounce?.cancel();
  _typingDebounce = Timer(const Duration(seconds: 2), () {
    _socket.emit('typing_stop', {'conversationId': widget.conversationId});
  });
}
```

Listen to `user_typing` → `setState(() => _otherUserTyping = true)`.
Listen to `user_stopped_typing` → `setState(() => _otherUserTyping = false)`.

Show `TypingIndicatorBubble()` at the bottom of the message list when `_otherUserTyping == true`.

- [ ] **Step 3: Update `chat_header.dart` for online/last-seen**

Add a subtitle line below the user name:
```dart
// Online status subtitle
Text(
  _isOnline ? 'Online agora' : _lastSeenLabel,
  style: TextStyle(fontSize: 12, color: AppColors.outline),
)
```

`_lastSeenLabel` formats `lastSeenAt` as "Visto há X minutos/horas".

Listen to `user_online` / `user_offline` events in the conversation page and pass the status down via a Riverpod provider or `setState`.

- [ ] **Step 4: Flutter analyze + commit**

```bash
cd frontend && fvm flutter analyze
git add frontend/lib/features/chat/
git commit -m "feat(chat): typing indicator bubble, typing_stop debounce, online/last-seen header"
```
