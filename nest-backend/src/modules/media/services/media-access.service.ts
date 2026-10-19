import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrivateUploadContext } from '@/shared/utils/file.utils';
import { storyAudienceWhere } from '@/modules/stories/data/repositories/story-database.repository';
import { postVisibilityWhere } from '@/modules/social/data/repositories/post-query-helpers';
import { commentVisibilityWhere } from '@/modules/social/types/social.types';
import { createHash, timingSafeEqual } from 'crypto';

@Injectable()
export class MediaAccessService {
  constructor(private readonly prisma: PrismaService) {}

  async canRead(
    userId: string,
    context: PrivateUploadContext,
    filename: string,
    openingKey?: string,
  ): Promise<boolean> {
    const url = `/media/${context}/${filename}`;

    if (context === 'story') {
      const story = await this.prisma.story.findFirst({
        where: {
          imageUrl: { in: [url, `/uploads/story/${filename}`] },
          deletedAt: null,
          AND: [
            storyAudienceWhere(userId),
            { OR: [{ expiresAt: { gt: new Date() } }, { highlightItems: { some: {} } }] },
          ],
        },
        select: { id: true },
      });
      return story !== null;
    }

    if (context === 'privatepost') {
      const post = await this.prisma.post.findFirst({
        where: { imageUrl: url, deletedAt: null, AND: [postVisibilityWhere(userId)] },
        select: { id: true },
      });
      return post !== null;
    }

    if (context === 'comment') {
      const media = await this.prisma.commentMedia.findFirst({
        where: {
          url,
          comment: { is: {
            deletedAt: null,
            AND: [
              commentVisibilityWhere(userId),
              { post: { deletedAt: null, AND: [postVisibilityWhere(userId)] } },
              { user: { blocksGiven: { none: { blockedId: userId } }, blocksReceived: { none: { blockerId: userId } } } },
            ],
          } },
        },
        select: { ownerId: true, comment: { select: { userId: true } } },
      });
      return media !== null && media.ownerId === media.comment.userId;
    }

    if (context === 'background') {
      const preference = await this.prisma.conversationPreference.findFirst({
        where: { userId, backgroundUrl: url },
        select: { id: true },
      });
      return preference !== null;
    }

    const directMessage = await this.prisma.directMessage.findFirst({
      where: { attachmentUrl: url },
      select: {
        deletedAt: true,
        viewOnce: true,
        readAt: true,
        viewOnceOpeningHash: true,
        viewOnceClosedAt: true,
        senderId: true,
        conversation: { select: { user1Id: true, user2Id: true } },
      },
    });

    if (directMessage) {
      const { conversation } = directMessage;
      const isParticipant =
        conversation.user1Id === userId || conversation.user2Id === userId;
      return isParticipant && this._payloadStillVisible(directMessage, userId, openingKey);
    }

    const chatMessage = await this.prisma.chatMessage.findFirst({
      where: { attachmentUrl: url },
      select: {
        deletedAt: true,
        viewOnce: true,
        readAt: true,
        viewOnceOpeningHash: true,
        viewOnceClosedAt: true,
        senderId: true,
        order: { select: { buyerId: true, sellerId: true } },
      },
    });

    if (chatMessage) {
      const { order } = chatMessage;
      const isParticipant = order.buyerId === userId || order.sellerId === userId;
      return isParticipant && this._payloadStillVisible(chatMessage, userId, openingKey);
    }

    return false;
  }

  private _payloadStillVisible(
    message: {
      deletedAt: Date | null;
      viewOnce: boolean;
      readAt: Date | null;
      senderId: string;
      viewOnceOpeningHash: string | null;
      viewOnceClosedAt: Date | null;
    },
    userId: string,
    openingKey?: string,
  ): boolean {
    if (message.deletedAt !== null) return false;
    if (message.viewOnce) {
      if (message.senderId === userId || message.readAt === null || message.viewOnceClosedAt !== null || !openingKey) return false;
      if (!/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(openingKey)) return false;
      const actualHash = createHash('sha256').update(openingKey).digest();
      if (!message.viewOnceOpeningHash || !/^[0-9a-f]{64}$/.test(message.viewOnceOpeningHash)) return false;
      return timingSafeEqual(Buffer.from(message.viewOnceOpeningHash, 'hex'), actualHash);
    }
    if (message.senderId === userId) return true;
    return true;
  }
}
