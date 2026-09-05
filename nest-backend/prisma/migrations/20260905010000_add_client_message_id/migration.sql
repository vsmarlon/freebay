-- AlterTable
ALTER TABLE "DirectMessage" ADD COLUMN "clientMessageId" TEXT;

-- AlterTable
ALTER TABLE "ChatMessage" ADD COLUMN "clientMessageId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "DirectMessage_conversationId_clientMessageId_key" ON "DirectMessage"("conversationId", "clientMessageId");

-- CreateIndex
CREATE UNIQUE INDEX "ChatMessage_orderId_clientMessageId_key" ON "ChatMessage"("orderId", "clientMessageId");
