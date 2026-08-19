import { Prisma } from '@prisma/client';

export const storyWithViewsValidator = Prisma.validator<Prisma.StoryDefaultArgs>()({
  include: {
    user: { select: { id: true, displayName: true, avatarUrl: true } },
    _count: { select: { views: true } },
  },
});

export type StoryWithViews = Prisma.StoryGetPayload<typeof storyWithViewsValidator>;

export const storyCreatePayloadValidator = Prisma.validator<Prisma.StoryDefaultArgs>()({
  include: {
    user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
  },
});

export type StoryCreatePayload = Prisma.StoryGetPayload<typeof storyCreatePayloadValidator>;

export interface StoryBrief {
  id: string;
  imageUrl: string;
  createdAt: Date;
  expiresAt: Date;
}

export type CreateStoryInput = Prisma.StoryCreateInput;
