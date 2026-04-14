import { body, query } from 'express-validator';

// 创建故事线验证
export const createStoryLineValidation = [
  body('id').isUUID().withMessage('ID必须是有效的UUID'),
  body('sourceDeviceId')
    .isString()
    .notEmpty()
    .withMessage('来源设备ID不能为空'),
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
  body('isPinned')
    .optional()
    .isBoolean()
    .withMessage('置顶状态必须是布尔值'),
];

// 批量创建故事线验证
export const batchCreateStoryLinesValidation = [
  body('storyLines').isArray().withMessage('故事线必须是数组'),
  body('storyLines.*.id').isUUID().withMessage('ID必须是有效的UUID'),
  body('storyLines.*.sourceDeviceId')
    .isString()
    .notEmpty()
    .withMessage('来源设备ID不能为空'),
  body('storyLines.*.name')
    .isString()
    .notEmpty()
    .withMessage('名称不能为空'),
  body('storyLines.*.recordIds')
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
  body('isPinned')
    .optional()
    .isBoolean()
    .withMessage('置顶状态必须是布尔值'),
  body('updatedAt').isISO8601().withMessage('更新时间必须是有效的日期'),
];

// 获取故事线查询验证
export const getStoryLinesQueryValidation = [
  query('lastSyncTime')
    .optional()
    .isISO8601()
    .withMessage('最后同步时间必须是有效的日期'),
  query('deviceId')
    .optional()
    .isString()
    .notEmpty()
    .withMessage('设备ID不能为空'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 1000 })
    .withMessage('限制数量必须在1到1000之间'),
  query('offset')
    .optional()
    .isInt({ min: 0 })
    .withMessage('偏移量必须是非负整数'),
];

