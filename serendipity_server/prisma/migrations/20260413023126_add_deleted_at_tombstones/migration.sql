-- AlterTable
ALTER TABLE "records" ADD COLUMN     "deleted_at" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "story_lines" ADD COLUMN     "deleted_at" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "records_deleted_at_idx" ON "records"("deleted_at");

-- CreateIndex
CREATE INDEX "story_lines_deleted_at_idx" ON "story_lines"("deleted_at");

-- RenameIndex
ALTER INDEX "anniversary_reminder_dispatches_push_token_id_record_id_reminde" RENAME TO "anniversary_reminder_dispatches_push_token_id_record_id_rem_key";
