import multer from 'multer';
import path from 'path';
import crypto from 'crypto';
import fs from 'fs';
import { AppError } from './errorHandler';
import { ErrorCode } from '../types/errors';

const AVATARS_DIR = path.join(process.cwd(), 'uploads', 'avatars');

if (!fs.existsSync(AVATARS_DIR)) {
  fs.mkdirSync(AVATARS_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, AVATARS_DIR);
  },
  filename: (req, file, cb) => {
    const userId = req.user!.userId;
    const ext = path.extname(file.originalname).toLowerCase();
    const hash = crypto.randomBytes(8).toString('hex');
    cb(null, `${userId}-${hash}${ext}`);
  },
});

const fileFilter = (
  _req: Express.Request,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback
): void => {
  const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new AppError('只支持 JPEG、PNG、WebP 格式的图片', ErrorCode.INVALID_REQUEST));
  }
};

/**
 * 头像上传中间件
 *
 * 调用者：user.routes.ts POST /avatar
 *
 * 限制：
 * - 文件类型：JPEG、PNG、WebP
 * - 文件大小：5MB
 * - 字段名：avatar
 */
export const uploadAvatarMiddleware = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
}).single('avatar');
