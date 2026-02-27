import { body, query } from 'express-validator';

// 创建故事线验证
export const createStoryLineValidation = [
  body('id').isUUID().withMessage('ID must be a valid UUID'),
  body('name')
    .isString()
    .notEmpty()
    .isLength({ max: 255 })
    .withMessage('Name is required and must be at most 255 characters'),
  body('recordIds').isArray().withMessage('Record IDs must be an array'),
  body('recordIds.*')
    .isUUID()
    .withMessage('Each record ID must be a valid UUID'),
  body('createdAt').isISO8601().withMessage('Created at must be a valid date'),
  body('updatedAt').isISO8601().withMessage('Updated at must be a valid date'),
];

// 批量创建故事线验证
export const batchCreateStoryLinesValidation = [
  body('storylines').isArray().withMessage('Storylines must be an array'),
  body('storylines.*.id').isUUID().withMessage('ID must be a valid UUID'),
  body('storylines.*.name')
    .isString()
    .notEmpty()
    .withMessage('Name is required'),
  body('storylines.*.recordIds')
    .isArray()
    .withMessage('Record IDs must be an array'),
];

// 更新故事线验证
export const updateStoryLineValidation = [
  body('name')
    .optional()
    .isString()
    .notEmpty()
    .isLength({ max: 255 })
    .withMessage('Name must be at most 255 characters'),
  body('recordIds')
    .optional()
    .isArray()
    .withMessage('Record IDs must be an array'),
  body('recordIds.*')
    .optional()
    .isUUID()
    .withMessage('Each record ID must be a valid UUID'),
  body('updatedAt').isISO8601().withMessage('Updated at must be a valid date'),
];

// 获取故事线查询验证
export const getStoryLinesQueryValidation = [
  query('lastSyncTime')
    .optional()
    .isISO8601()
    .withMessage('Last sync time must be a valid date'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 1000 })
    .withMessage('Limit must be between 1 and 1000'),
  query('offset')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Offset must be a non-negative integer'),
];

