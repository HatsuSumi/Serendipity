import { body, query } from 'express-validator';

// 创建故事线验证
export const createStoryLineValidation = [
  body('id').isUUID().withMessage('ID必须是有效的UUID'),
  body('name')
    .isString()
    .notEmpty()
    .isLength({ max: 255 })
    .withMessage('名称不能为空且最多255个字符'),
  body('recordIds').isArray().withMessage('记录ID必须是数组'),
  body('recordIds.*')
    .isUUID()
    .withMessage('每个记录ID必须是有效的UUID'),
  body('createdAt').isISO8601().withMessage('创建时间必须是有效的日期'),
  body('updatedAt').isISO8601().withMessage('更新时间必须是有效的日期'),
];

// 批量创建故事线验证
export const batchCreateStoryLinesValidation = [
  body('storylines').isArray().withMessage('故事线必须是数组'),
  body('storylines.*.id').isUUID().withMessage('ID必须是有效的UUID'),
  body('storylines.*.name')
    .isString()
    .notEmpty()
    .withMessage('名称不能为空'),
  body('storylines.*.recordIds')
    .isArray()
    .withMessage('记录ID必须是数组'),
];

// 更新故事线验证
export const updateStoryLineValidation = [
  body('name')
    .optional()
    .isString()
    .notEmpty()
    .isLength({ max: 255 })
    .withMessage('名称最多255个字符'),
  body('recordIds')
    .optional()
    .isArray()
    .withMessage('记录ID必须是数组'),
  body('recordIds.*')
    .optional()
    .isUUID()
    .withMessage('每个记录ID必须是有效的UUID'),
  body('updatedAt').isISO8601().withMessage('更新时间必须是有效的日期'),
];

// 获取故事线查询验证
export const getStoryLinesQueryValidation = [
  query('lastSyncTime')
    .optional()
    .isISO8601()
    .withMessage('最后同步时间必须是有效的日期'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 1000 })
    .withMessage('限制数量必须在1到1000之间'),
  query('offset')
    .optional()
    .isInt({ min: 0 })
    .withMessage('偏移量必须是非负整数'),
];

