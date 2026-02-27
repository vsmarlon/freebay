export interface PostEntity {
  id: string;
  content: string | null;
  imageUrl: string | null;
  type: 'PRODUCT' | 'REGULAR';
  userId: string;
  likesCount: number;
  commentsCount: number;
  sharesCount: number;
  createdAt: Date;
  updatedAt: Date;
  user?: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
    reputationScore: number;
    totalReviews: number;
  };
  product?: {
    id: string;
    title: string;
    description: string;
    price: number;
    condition: string;
  } | null;
}

export interface CommentEntity {
  id: string;
  content: string;
  userId: string;
  postId: string;
  createdAt: Date;
  user?: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
  };
}

export interface LikeEntity {
  id: string;
  userId: string;
  postId: string;
  createdAt: Date;
}

export interface FollowEntity {
  id: string;
  followerId: string;
  followingId: string;
  createdAt: Date;
}
