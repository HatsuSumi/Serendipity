import { Router } from 'express';
import { RecordController } from '../controllers/recordController';
import { authMiddleware } from '../middlewares/auth';
import { validateRequest } from '../utils/validation';
import {
  createRecordValidation,
  batchCreateRecordsValidation,
  updateRecordValidation,
  getRecordsQueryValidation,
} from '../validators/recordValidators';

export const createRecordRoutes = (
  recordController: RecordController
): Router => {
  const router = Router();

  // 所有路由都需要认证
  router.use(authMiddleware);

  // 创建记录
  router.post(
    '/',
    createRecordValidation,
    validateRequest,
    recordController.createRecord
  );

  // 批量上传记录
  router.post(
    '/batch',
    batchCreateRecordsValidation,
    validateRequest,
    recordController.batchCreateRecords
  );

  // 获取记录列表（支持增量同步）
  router.get(
    '/',
    getRecordsQueryValidation,
    validateRequest,
    recordController.getRecords
  );

  // 更新记录
  router.put(
    '/:id',
    updateRecordValidation,
    validateRequest,
    recordController.updateRecord
  );

  // 删除记录
  router.delete('/:id', recordController.deleteRecord);

  return router;
};

