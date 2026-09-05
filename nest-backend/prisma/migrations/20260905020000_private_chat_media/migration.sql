-- Chat attachments and conversation backgrounds are no longer served from the
-- public /uploads static root. They move to /media, which requires a valid
-- access token. Files must be moved on disk from uploads/<context>/ to
-- private-uploads/<context>/ alongside this migration.

UPDATE "ChatMessage"
SET "attachmentUrl" = REPLACE("attachmentUrl", '/uploads/chat/', '/media/chat/')
WHERE "attachmentUrl" LIKE '/uploads/chat/%';

UPDATE "DirectMessage"
SET "attachmentUrl" = REPLACE("attachmentUrl", '/uploads/chat/', '/media/chat/')
WHERE "attachmentUrl" LIKE '/uploads/chat/%';

UPDATE "ConversationPreference"
SET "backgroundUrl" = REPLACE("backgroundUrl", '/uploads/background/', '/media/background/')
WHERE "backgroundUrl" LIKE '/uploads/background/%';
