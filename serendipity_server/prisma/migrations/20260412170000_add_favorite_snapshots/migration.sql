-- AlterTable
ALTER TABLE "favorites"
ADD COLUMN "post_snapshot" JSONB,
ADD COLUMN "record_snapshot" JSONB;

