import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrivateUploadContext } from '@/shared/utils/file.utils';
import { storyAudienceWhere } from '@/modules/stories/data/repositories/story-database.repository';
import { postVisibilityWhere } from '@/modules/social/data/repositories/post-query-helpers';

const VIEW_ONCE_FETCH_GRACE_MS = 5 * 60 * 1000;

@Injectable()
export class MediaAccessService {
  constructor(private readonly prisma: PrismaService) {}

  async canRead(
    userId: string,
    context: PrivateUploadContext,
    filename: string,
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
        senderId: true,
        conversation: { select: { user1Id: true, user2Id: true } },
      },
    });

    if (directMessage) {
      const { conversation } = directMessage;
      const isParticipant =
        conversation.user1Id === userId || conversation.user2Id === userId;
      return isParticipant && this._payloadStillVisible(directMessage, userId);
    }

    const chatMessage = await this.prisma.chatMessage.findFirst({
      where: { attachmentUrl: url },
      select: {
        deletedAt: true,
        viewOnce: true,
        readAt: true,
        senderId: true,
        order: { select: { buyerId: true, sellerId: true } },
      },
    });

    if (chatMessage) {
      const { order } = chatMessage;
      const isParticipant = order.buyerId === userId || order.sellerId === userId;
      return isParticipant && this._payloadStillVisible(chatMessage, userId);
    }

    return false;
  }

  private _payloadStillVisible(
    message: {
      deletedAt: Date | null;
      viewOnce: boolean;
      readAt: Date | null;
      senderId: string;
    },
    userId: string,
  ): boolean {
    if (message.deletedAt !== null) return false;
    if (message.senderId === userId) return true;
    if (!message.viewOnce || message.readAt === null) return true;

    // ponytail: the read that reveals a view-once message returns its URL in the
    // same response, so the fetch has to be allowed to land. Grace window instead
    // of a hard cutoff; swap for a one-shot signed URL if that is too generous.
    return Date.now() - message.readAt.getTime() <= VIEW_ONCE_FETCH_GRACE_MS;
  }
}
