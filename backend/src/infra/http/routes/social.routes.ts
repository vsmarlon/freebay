import { FastifyInstance } from 'fastify';
import { SocialController } from '@/presentation/controllers';
import {
  PrismaPostRepository,
  PrismaStoryRepository,
  PrismaLikeRepository,
  PrismaCommentRepository,
} from '@/infra/database/repositories';
import { authGuard, requireNonGuest } from '@/presentation/middlewares/auth-guard';

export async function socialRoutes(app: FastifyInstance) {
  const postRepository = new PrismaPostRepository();
  const storyRepository = new PrismaStoryRepository();
  const likeRepository = new PrismaLikeRepository();
  const commentRepository = new PrismaCommentRepository();
  const controller = new SocialController(
    postRepository,
    storyRepository,
    likeRepository,
    commentRepository,
  );

  // Feed
  app.get<{ Querystring: { cursor?: string; limit?: string } }>('/feed', (req, reply) =>
    controller.getFeed(req, reply),
  );

  // Posts
  app.get<{ Params: { id: string } }>('/posts/:id', (req, reply) =>
    controller.getPostById(req, reply),
  );
  app.post<{ Body: { content?: string; imageUrl?: string; type: 'PRODUCT' | 'REGULAR' } }>(
    '/posts',
    { preHandler: [authGuard, requireNonGuest] },
    (req, reply) => controller.createPost(req, reply),
  );

  // Likes
  app.post<{ Params: { id: string } }>(
    '/posts/:id/like',
    { preHandler: [authGuard, requireNonGuest] },
    (req, reply) => controller.like(req, reply),
  );
  app.delete<{ Params: { id: string } }>(
    '/posts/:id/like',
    { preHandler: [authGuard, requireNonGuest] },
    (req, reply) => controller.unlike(req, reply),
  );

  // Comments
  app.post<{ Params: { id: string } }>(
    '/posts/:id/comments',
    { preHandler: [authGuard, requireNonGuest] },
    (req, reply) => controller.comment(req, reply),
  );
  app.get<{ Params: { id: string }; Querystring: { cursor?: string; limit?: string } }>(
    '/posts/:id/comments',
    (req, reply) => controller.getComments(req, reply),
  );

  // Stories
  app.get('/stories', (req, reply) => controller.getStories(req, reply));
  app.get<{ Params: { userId: string } }>('/stories/user/:userId', (req, reply) =>
    controller.getUserStories(req, reply),
  );
  app.post<{ Body: { imageBase64: string } }>(
    '/stories',
    { preHandler: [authGuard, requireNonGuest] },
    (req, reply) => controller.createStory(req, reply),
  );
  app.delete<{ Params: { id: string } }>(
    '/stories/:id',
    { preHandler: [authGuard] },
    (req, reply) => controller.deleteStory(req, reply),
  );
  app.post<{ Params: { id: string } }>('/stories/:id/view', (req, reply) =>
    controller.viewStory(req, reply),
  );
}
