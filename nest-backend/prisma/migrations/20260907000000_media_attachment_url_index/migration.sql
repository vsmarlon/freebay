-- The /media route now resolves the owning message by attachmentUrl on every
-- fetch to authorize the requester, so both columns need an index.
CREATE INDEX "DirectMessage_attachmentUrl_idx" ON "DirectMessage"("attachmentUrl");
CREATE INDEX "ChatMessage_attachmentUrl_idx" ON "ChatMessage"("attachmentUrl");
