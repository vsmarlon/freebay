import { prisma } from '../prisma/client';
import { IStoryRepository } from '@/domain/repositories';
import { StoryEntity } from '@/domain/entities';

export class PrismaStoryRepository implements IStoryRepository {
  async createStory(userId: string, imageUrl: string): Promise<StoryEntity> {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    const story = await prisma.story.create({
      data: {
        userId,
        imageUrl,
        expiresAt,
      },
      include: { user: true },
    });

    return {
      id: story.id,
      userId: story.userId,
      imageUrl: story.imageUrl,
      expiresAt: story.expiresAt,
      createdAt: story.createdAt,
      user: {
        id: story.user.id,
        displayName: story.user.displayName,
        avatarUrl: story.user.avatarUrl,
        isVerified: story.user.isVerified,
      },
      isViewed: false,
    };
  }

  async getStories(userId: string): Promise<{ stories: StoryEntity[]; userHasStory: boolean }> {
    // Get IDs of users that the current user follows
    const following = await prisma.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });

    const followingIds = following.map((f) => f.followingId);

    // Include the current user's stories too
    const userIds = [...followingIds, userId];

    const userStories = await prisma.story.findMany({
      where: {
        expiresAt: { gt: new Date() },
        userId: { in: userIds },
      },
      include: {
        user: true,
        views: {
          where: { viewerId: userId },
          select: { id: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const stories: StoryEntity[] = userStories.map((story) => ({
      id: story.id,
      userId: story.userId,
      imageUrl: story.imageUrl,
      expiresAt: story.expiresAt,
      createdAt: story.createdAt,
      user: {
        id: story.user.id,
        displayName: story.user.displayName,
        avatarUrl: story.user.avatarUrl,
        isVerified: story.user.isVerified,
      },
      isViewed: story.views.length > 0,
    }));

    const userHasStory = await prisma.story.findFirst({
      where: {
        userId,
        expiresAt: { gt: new Date() },
      },
    });

    return { stories, userHasStory: !!userHasStory };
  }

  async getUserStories(userId: string, viewerId: string): Promise<StoryEntity[]> {
    const stories = await prisma.story.findMany({
      where: {
        userId,
        expiresAt: { gt: new Date() },
      },
      include: {
        user: true,
        views: {
          where: { viewerId },
          select: { id: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return stories.map((story) => ({
      id: story.id,
      userId: story.userId,
      imageUrl: story.imageUrl,
      expiresAt: story.expiresAt,
      createdAt: story.createdAt,
      user: {
        id: story.user.id,
        displayName: story.user.displayName,
        avatarUrl: story.user.avatarUrl,
        isVerified: story.user.isVerified,
      },
      isViewed: story.views.length > 0,
    }));
  }

  async deleteStory(storyId: string, userId: string): Promise<void> {
    await prisma.story.deleteMany({
      where: {
        id: storyId,
        userId,
      },
    });
  }

  async viewStory(storyId: string, viewerId: string): Promise<void> {
    await prisma.storyView.create({
      data: {
        storyId,
        viewerId,
      },
    });
  }
}
