-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT,
    "phone_number" TEXT,
    "password_hash" TEXT NOT NULL,
    "auth_provider" VARCHAR(20) NOT NULL DEFAULT 'email',
    "recovery_key" TEXT,
    "display_name" VARCHAR(100),
    "avatar_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "last_login_at" TIMESTAMP(3),

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "records" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "location" JSONB NOT NULL,
    "description" TEXT,
    "tags" JSONB NOT NULL DEFAULT '[]',
    "emotion" VARCHAR(50),
    "status" VARCHAR(50) NOT NULL,
    "story_line_id" TEXT,
    "if_reencounter" TEXT,
    "conversation_starter" TEXT,
    "background_music" VARCHAR(255),
    "weather" JSONB NOT NULL DEFAULT '[]',
    "is_pinned" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "story_lines" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "record_ids" JSONB NOT NULL DEFAULT '[]',
    "is_pinned" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "story_lines_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "community_posts" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "record_id" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "address" TEXT,
    "place_name" TEXT,
    "place_type" VARCHAR(50),
    "province" VARCHAR(50),
    "city" VARCHAR(100),
    "area" VARCHAR(100),
    "description" TEXT,
    "tags" JSONB NOT NULL DEFAULT '[]',
    "status" VARCHAR(50) NOT NULL,
    "published_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "community_posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "memberships" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "tier" VARCHAR(50) NOT NULL DEFAULT 'free',
    "status" VARCHAR(50) NOT NULL DEFAULT 'inactive',
    "started_at" TIMESTAMP(3),
    "expires_at" TIMESTAMP(3),
    "monthly_amount" INTEGER,
    "auto_renew" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "memberships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "token" VARCHAR(255) NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "verification_codes" (
    "id" TEXT NOT NULL,
    "type" VARCHAR(20) NOT NULL,
    "target" VARCHAR(255) NOT NULL,
    "code" VARCHAR(10) NOT NULL,
    "purpose" VARCHAR(50) NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "used" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "verification_codes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_settings" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "theme" VARCHAR(50) NOT NULL DEFAULT 'light',
    "page_transition" VARCHAR(50) NOT NULL DEFAULT 'slide_from_right',
    "dialog_animation" VARCHAR(50) NOT NULL DEFAULT 'fade_in',
    "notifications" JSONB NOT NULL DEFAULT '{"checkInReminder": true, "achievementUnlocked": true, "checkInReminderTime": "20:00"}',
    "check_in" JSONB NOT NULL DEFAULT '{"confettiEnabled": true, "vibrationEnabled": true}',
    "has_seen_community_intro" BOOLEAN NOT NULL DEFAULT false,
    "has_seen_publish_warning" BOOLEAN NOT NULL DEFAULT false,
    "has_seen_favorites_intro" BOOLEAN NOT NULL DEFAULT false,
    "hide_publish_warning" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "check_ins" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "checked_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "check_ins_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "favorites" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "post_id" TEXT,
    "record_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "favorites_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "achievement_unlocks" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "achievement_id" VARCHAR(255) NOT NULL,
    "unlocked_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "achievement_unlocks_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_number_key" ON "users"("phone_number");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_phone_number_idx" ON "users"("phone_number");

-- CreateIndex
CREATE INDEX "records_user_id_idx" ON "records"("user_id");

-- CreateIndex
CREATE INDEX "records_updated_at_idx" ON "records"("updated_at");

-- CreateIndex
CREATE INDEX "records_story_line_id_idx" ON "records"("story_line_id");

-- CreateIndex
CREATE INDEX "records_timestamp_idx" ON "records"("timestamp");

-- CreateIndex
CREATE INDEX "records_user_id_updated_at_idx" ON "records"("user_id", "updated_at");

-- CreateIndex
CREATE INDEX "story_lines_user_id_idx" ON "story_lines"("user_id");

-- CreateIndex
CREATE INDEX "story_lines_updated_at_idx" ON "story_lines"("updated_at");

-- CreateIndex
CREATE INDEX "story_lines_user_id_updated_at_idx" ON "story_lines"("user_id", "updated_at");

-- CreateIndex
CREATE INDEX "community_posts_published_at_idx" ON "community_posts"("published_at" DESC);

-- CreateIndex
CREATE INDEX "community_posts_user_id_idx" ON "community_posts"("user_id");

-- CreateIndex
CREATE INDEX "community_posts_province_idx" ON "community_posts"("province");

-- CreateIndex
CREATE INDEX "community_posts_city_idx" ON "community_posts"("city");

-- CreateIndex
CREATE INDEX "community_posts_area_idx" ON "community_posts"("area");

-- CreateIndex
CREATE INDEX "community_posts_place_type_idx" ON "community_posts"("place_type");

-- CreateIndex
CREATE INDEX "community_posts_status_idx" ON "community_posts"("status");

-- CreateIndex
CREATE INDEX "community_posts_user_id_published_at_idx" ON "community_posts"("user_id", "published_at" DESC);

-- CreateIndex
CREATE INDEX "community_posts_province_city_published_at_idx" ON "community_posts"("province", "city", "published_at" DESC);

-- CreateIndex
CREATE INDEX "community_posts_city_area_published_at_idx" ON "community_posts"("city", "area", "published_at" DESC);

-- CreateIndex
CREATE INDEX "community_posts_place_type_status_published_at_idx" ON "community_posts"("place_type", "status", "published_at" DESC);

-- CreateIndex
CREATE INDEX "community_posts_tags_idx" ON "community_posts" USING GIN ("tags");

-- CreateIndex
CREATE UNIQUE INDEX "memberships_user_id_key" ON "memberships"("user_id");

-- CreateIndex
CREATE INDEX "memberships_user_id_idx" ON "memberships"("user_id");

-- CreateIndex
CREATE INDEX "memberships_expires_at_idx" ON "memberships"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_key" ON "refresh_tokens"("token");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");

-- CreateIndex
CREATE INDEX "refresh_tokens_token_idx" ON "refresh_tokens"("token");

-- CreateIndex
CREATE INDEX "refresh_tokens_expires_at_idx" ON "refresh_tokens"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_user_id_expires_at_key" ON "refresh_tokens"("user_id", "expires_at");

-- CreateIndex
CREATE INDEX "verification_codes_target_idx" ON "verification_codes"("target");

-- CreateIndex
CREATE INDEX "verification_codes_expires_at_idx" ON "verification_codes"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "user_settings_user_id_key" ON "user_settings"("user_id");

-- CreateIndex
CREATE INDEX "user_settings_user_id_idx" ON "user_settings"("user_id");

-- CreateIndex
CREATE INDEX "check_ins_user_id_idx" ON "check_ins"("user_id");

-- CreateIndex
CREATE INDEX "check_ins_date_idx" ON "check_ins"("date");

-- CreateIndex
CREATE UNIQUE INDEX "check_ins_user_id_date_key" ON "check_ins"("user_id", "date");

-- CreateIndex
CREATE INDEX "favorites_user_id_idx" ON "favorites"("user_id");

-- CreateIndex
CREATE INDEX "favorites_post_id_idx" ON "favorites"("post_id");

-- CreateIndex
CREATE INDEX "favorites_record_id_idx" ON "favorites"("record_id");

-- CreateIndex
CREATE UNIQUE INDEX "favorites_user_id_post_id_key" ON "favorites"("user_id", "post_id");

-- CreateIndex
CREATE UNIQUE INDEX "favorites_user_id_record_id_key" ON "favorites"("user_id", "record_id");

-- CreateIndex
CREATE INDEX "achievement_unlocks_user_id_idx" ON "achievement_unlocks"("user_id");

-- CreateIndex
CREATE INDEX "achievement_unlocks_achievement_id_idx" ON "achievement_unlocks"("achievement_id");

-- CreateIndex
CREATE UNIQUE INDEX "achievement_unlocks_user_id_achievement_id_key" ON "achievement_unlocks"("user_id", "achievement_id");

-- AddForeignKey
ALTER TABLE "records" ADD CONSTRAINT "records_story_line_id_fkey" FOREIGN KEY ("story_line_id") REFERENCES "story_lines"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "records" ADD CONSTRAINT "records_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "story_lines" ADD CONSTRAINT "story_lines_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_posts" ADD CONSTRAINT "community_posts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_settings" ADD CONSTRAINT "user_settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_ins" ADD CONSTRAINT "check_ins_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favorites" ADD CONSTRAINT "favorites_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "achievement_unlocks" ADD CONSTRAINT "achievement_unlocks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
