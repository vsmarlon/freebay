import { Injectable } from '@nestjs/common';
import { PrismaStoryRepository } from '../repositories/social.repository';

@Injectable()
export class GetUserStoriesUseCase {
  constructor(private storyRepository: PrismaStoryRepository) {}

  async execute(userId: string) {
    const stories = await this.storyRepository.findByUserId(userId);
    return stories.filter(s => s.expiresAt > new Date()).map(story => ({
      id: story.id,
      imageUrl: story.imageUrl,
      createdAt: story.createdAt,
      expiresAt: story.expiresAt,
    }));
  }
}
