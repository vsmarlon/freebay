import { Prisma, StoryAudience, StoryMediaType } from "@prisma/client";
import { StoryTextBlock } from "../dtos/stories.dto";

export const storyWithViewsValidator =
  Prisma.validator<Prisma.StoryDefaultArgs>()({
    include: {
      user: { select: { id: true, displayName: true, avatarUrl: true } },
      _count: { select: { views: true } },
    },
  });

export type StoryWithViews = Prisma.StoryGetPayload<
  typeof storyWithViewsValidator
>;

export const highlightPayload = Prisma.validator<Prisma.StoryHighlightDefaultArgs>()({
  include: {
    user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
    stories: {
      orderBy: { position: 'asc' },
      include: { story: true },
    },
  },
});

export type HighlightPayload = Prisma.StoryHighlightGetPayload<typeof highlightPayload>;

export const storyCreatePayloadValidator =
  Prisma.validator<Prisma.StoryDefaultArgs>()({
    include: {
      user: {
        select: {
          id: true,
          displayName: true,
          avatarUrl: true,
          isVerified: true,
        },
      },
    },
  });

export type StoryCreatePayload = Prisma.StoryGetPayload<
  typeof storyCreatePayloadValidator
>;

export interface StoryBrief {
  id: string;
  imageUrl: string;
  mediaType: StoryMediaType;
  audience: StoryAudience;
  caption: string | null;
  textBlocks: StoryTextBlock[];
  createdAt: Date;
  expiresAt: Date;
  user: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
  };
}

export type CreateStoryInput = Prisma.StoryCreateInput;
