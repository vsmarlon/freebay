export interface ChatMessageEntity {
  id: string;
  orderId: string;
  senderId: string;
  content: string;
  readAt: Date | null;
  createdAt: Date;
}
