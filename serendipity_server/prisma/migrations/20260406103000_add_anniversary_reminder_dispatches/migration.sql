-- CreateTable
CREATE TABLE "anniversary_reminder_dispatches" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "push_token_id" TEXT NOT NULL,
    "record_id" TEXT NOT NULL,
    "reminder_date" DATE NOT NULL,
    "status" VARCHAR(20) NOT NULL,
    "provider" VARCHAR(20) NOT NULL,
    "failure_reason" VARCHAR(255),
    "sent_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "anniversary_reminder_dispatches_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "anniversary_reminder_dispatches_push_token_id_record_id_reminder_date_key" ON "anniversary_reminder_dispatches"("push_token_id", "record_id", "reminder_date");

-- CreateIndex
CREATE INDEX "anniversary_reminder_dispatches_user_id_reminder_date_idx" ON "anniversary_reminder_dispatches"("user_id", "reminder_date");

-- CreateIndex
CREATE INDEX "anniversary_reminder_dispatches_record_id_reminder_date_idx" ON "anniversary_reminder_dispatches"("record_id", "reminder_date");

-- CreateIndex
CREATE INDEX "anniversary_reminder_dispatches_status_reminder_date_idx" ON "anniversary_reminder_dispatches"("status", "reminder_date");

-- AddForeignKey
ALTER TABLE "anniversary_reminder_dispatches" ADD CONSTRAINT "anniversary_reminder_dispatches_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "anniversary_reminder_dispatches" ADD CONSTRAINT "anniversary_reminder_dispatches_push_token_id_fkey" FOREIGN KEY ("push_token_id") REFERENCES "push_tokens"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "anniversary_reminder_dispatches" ADD CONSTRAINT "anniversary_reminder_dispatches_record_id_fkey" FOREIGN KEY ("record_id") REFERENCES "records"("id") ON DELETE CASCADE ON UPDATE CASCADE;


