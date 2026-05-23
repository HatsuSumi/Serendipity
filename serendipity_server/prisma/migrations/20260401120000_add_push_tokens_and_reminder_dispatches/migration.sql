-- CreateTable
CREATE TABLE "push_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" VARCHAR(20) NOT NULL,
    "timezone" VARCHAR(64) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_used_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "invalidated_at" TIMESTAMP(3),
    "invalid_reason" VARCHAR(255),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "push_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "check_in_reminder_dispatches" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "push_token_id" TEXT NOT NULL,
    "reminder_date" DATE NOT NULL,
    "status" VARCHAR(20) NOT NULL,
    "provider" VARCHAR(20) NOT NULL,
    "failure_reason" VARCHAR(255),
    "sent_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "check_in_reminder_dispatches_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "push_tokens_token_key" ON "push_tokens"("token");

-- CreateIndex
CREATE INDEX "push_tokens_user_id_idx" ON "push_tokens"("user_id");

-- CreateIndex
CREATE INDEX "push_tokens_user_id_is_active_idx" ON "push_tokens"("user_id", "is_active");

-- CreateIndex
CREATE INDEX "push_tokens_timezone_is_active_idx" ON "push_tokens"("timezone", "is_active");

-- CreateIndex
CREATE UNIQUE INDEX "check_in_reminder_dispatches_push_token_id_reminder_date_key" ON "check_in_reminder_dispatches"("push_token_id", "reminder_date");

-- CreateIndex
CREATE INDEX "check_in_reminder_dispatches_user_id_reminder_date_idx" ON "check_in_reminder_dispatches"("user_id", "reminder_date");

-- CreateIndex
CREATE INDEX "check_in_reminder_dispatches_status_reminder_date_idx" ON "check_in_reminder_dispatches"("status", "reminder_date");

-- AddForeignKey
ALTER TABLE "push_tokens" ADD CONSTRAINT "push_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_in_reminder_dispatches" ADD CONSTRAINT "check_in_reminder_dispatches_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_in_reminder_dispatches" ADD CONSTRAINT "check_in_reminder_dispatches_push_token_id_fkey" FOREIGN KEY ("push_token_id") REFERENCES "push_tokens"("id") ON DELETE CASCADE ON UPDATE CASCADE;

