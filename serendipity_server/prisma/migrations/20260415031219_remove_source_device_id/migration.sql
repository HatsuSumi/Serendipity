/*
  Warnings:

  - You are about to drop the column `source_device_id` on the `records` table. All the data in the column will be lost.
  - You are about to drop the column `source_device_id` on the `story_lines` table. All the data in the column will be lost.

*/
-- DropIndex
DROP INDEX "records_source_device_id_idx";

-- DropIndex
DROP INDEX "records_user_id_source_device_id_updated_at_idx";

-- DropIndex
DROP INDEX "story_lines_source_device_id_idx";

-- DropIndex
DROP INDEX "story_lines_user_id_source_device_id_updated_at_idx";

-- AlterTable
ALTER TABLE "records" DROP COLUMN "source_device_id";

-- AlterTable
ALTER TABLE "refresh_tokens" ALTER COLUMN "device_id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "story_lines" DROP COLUMN "source_device_id";
