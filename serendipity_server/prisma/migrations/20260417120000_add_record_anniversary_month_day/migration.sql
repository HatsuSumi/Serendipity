-- Add anniversary month/day fields to records
ALTER TABLE "records"
ADD COLUMN "anniversary_month" INTEGER,
ADD COLUMN "anniversary_day" INTEGER;

UPDATE "records"
SET
  "anniversary_month" = EXTRACT(MONTH FROM "timestamp")::int,
  "anniversary_day" = EXTRACT(DAY FROM "timestamp")::int;

ALTER TABLE "records"
ALTER COLUMN "anniversary_month" SET NOT NULL,
ALTER COLUMN "anniversary_day" SET NOT NULL;

CREATE INDEX "records_anniversary_month_anniversary_day_idx"
ON "records"("anniversary_month", "anniversary_day");

