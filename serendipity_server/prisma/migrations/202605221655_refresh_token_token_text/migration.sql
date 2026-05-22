-- Align production schema with Prisma model: refresh token JWTs can exceed 255 chars.
ALTER TABLE "refresh_tokens"
ALTER COLUMN "token" TYPE TEXT;
