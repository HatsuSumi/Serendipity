-- AlterTable
ALTER TABLE "check_ins" ADD COLUMN     "deleted_at" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "check_ins_deleted_at_idx" ON "check_ins"("deleted_at");

-- CreateIndex
CREATE INDEX "check_ins_user_id_updated_at_idx" ON "check_ins"("user_id", "updated_at");
