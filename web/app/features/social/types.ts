export type PostType = 'REGULAR' | 'PRODUCT';
export type PostAudience = 'EVERYONE' | 'CLOSE_FRIENDS';
export type PostMediaType = 'IMAGE' | 'VIDEO';
export type PostMediaItem = {
  id: string;
  url: string;
  thumbnailUrl: string | null;
  type: PostMediaType;
  altText: string | null;
  blurHash?: string;
  order: number;
};
export type FeedType = 'explore' | 'following';
export type ContentFilter = 'all' | 'social' | 'selling';
export type TimelineKind = 'post' | 'repost' | 'product' | 'all';
export type ProfileTimelineKind = 'posts' | 'reposts' | 'products';
export type ReportTargetType =
  | 'USER'
  | 'POST'
  | 'CONVERSATION'
  | 'MESSAGE'
  | 'ORDER_CHAT'
  | 'CHAT_MESSAGE';
export type ReportReason =
  | 'FALSE_ADVERTISING'
  | 'SPAM'
  | 'FRAUD'
  | 'NUDITY'
  | 'HARASSMENT'
  | 'OTHER'
  | 'FAKE_ACCOUNT'
  | 'IMPERSONATING'
  | 'BLACKMAIL';

export type SocialUser = {
  id: string;
  displayName: string;
  username?: string | null;
  avatarUrl?: string | null;
  isVerified?: boolean;
};
export type ProductInfo = {
  id: string;
  title: string;
  description: string;
  price: number;
  condition: string;
  images?: { url: string }[];
};
export type Post = {
  id: string;
  userId: string;
  content: string | null;
  media: PostMediaItem[];
  type: PostType;
  audience: PostAudience;
  likesCount: number;
  commentsCount: number;
  sharesCount: number;
  isLiked: boolean;
  isSaved: boolean;
  hasReposted: boolean;
  createdAt: string;
  user: SocialUser;
  product?: ProductInfo | null;
  repostId?: string | null;
  repostedAt?: string | null;
  repostedBy?: SocialUser | null;
  isReposted?: boolean;
};
export type TimelineEntry = {
  post: Post;
  repostId: string | null;
  repostedAt: string | null;
  repostedBy: SocialUser | null;
  isReposted: boolean;
  sharesCount: number;
};
export type CursorPage<T> = { items: T[]; hasMore: boolean; nextCursor?: string | null };
export type FeedPage = { posts: Post[]; hasMore: boolean; nextCursor?: string | null };
/** Wire shape of the post-level like/repost mutation endpoints: { success, data: { active, count } }. */
export type MutationState = { active: boolean; count: number };
/** Wire shape of the save/unsave endpoints (no denormalized counter to report). */
export type SaveMutationState = { active: boolean };
/** Wire shape of POST /social/posts/:id/comments (CreateCommentOutput). */
export type CreatedComment = Pick<Comment, 'id' | 'postId' | 'userId' | 'content' | 'createdAt'> & {
  commentsCount: number;
};
export type Comment = {
  id: string;
  postId: string;
  userId: string;
  content: string;
  parentId?: string | null;
  createdAt: string;
  likesCount: number;
  isLiked: boolean;
  isHidden: boolean;
  user?: SocialUser;
  replies: Comment[];
};

export function canApproveComment(
  comment: Comment,
  postOwnerId: string,
  viewerId: string,
  parentIsHidden: boolean,
): boolean {
  return postOwnerId === viewerId && comment.isHidden && !parentIsHidden;
}
