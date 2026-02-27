import { Router } from 'express';
import { StoryLineController } from '../controllers/storyLineController';
import { authMiddleware } from '../middlewares/auth';
import { validateRequest } from '../utils/validation';
import {
  createStoryLineValidation,
  batchCreateStoryLinesValidation,
  updateStoryLineValidation,
  getStoryLinesQueryValidation,
} from '../validators/storyLineValidators';

export const createStoryLineRoutes = (
  storyLineController: StoryLineController
): Router => {
  const router = Router();

  // 所有路由都需要认证
  router.use(authMiddleware);

  // 创建故事线
  router.post(
    '/',
    createStoryLineValidation,
    validateRequest,
    storyLineController.createStoryLine
  );

  // 批量上传故事线
  router.post(
    '/batch',
    batchCreateStoryLinesValidation,
    validateRequest,
    storyLineController.batchCreateStoryLines
  );

  // 获取故事线列表（支持增量同步）
  router.get(
    '/',
    getStoryLinesQueryValidation,
    validateRequest,
    storyLineController.getStoryLines
  );

  // 更新故事线
  router.put(
    '/:id',
    updateStoryLineValidation,
    validateRequest,
    storyLineController.updateStoryLine
  );

  // 删除故事线
  router.delete('/:id', storyLineController.deleteStoryLine);

  return router;
};

