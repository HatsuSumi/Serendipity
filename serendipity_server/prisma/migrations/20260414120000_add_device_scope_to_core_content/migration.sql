-- Add device scoping to refresh tokens and core content
ALTER TABLE "records"
ADD COLUMN "source_device_id" VARCHAR(128) NOT NULL DEFAULT 'legacy';

ALTER TABLE "story_lines"
ADD COLUMN "source_device_id" VARCHAR(128) NOT NULL DEFAULT 'legacy';

ALTER TABLE "refresh_tokens"
ADD COLUMN "device_id" VARCHAR(128) NOT NULL DEFAULT 'legacy';

CREATE INDEX "records_source_device_id_idx" ON "records"("source_device_id");
CREATE INDEX "records_user_id_source_device_id_updated_at_idx" ON "records"("user_id", "source_device_id", "updated_at");

CREATE INDEX "story_lines_source_device_id_idx" ON "story_lines"("source_device_id");
CREATE INDEX "story_lines_user_id_source_device_id_updated_at_idx" ON "story_lines"("user_id", "source_device_id", "updated_at");

CREATE UNIQUE INDEX "refresh_tokens_user_id_device_id_key" ON "refresh_tokens"("user_id", "device_id");
CREATE INDEX "refresh_tokens_device_id_idx" ON "refresh_tokens"("device_id");

