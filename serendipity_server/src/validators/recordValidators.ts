import { body, query } from 'express-validator';

// 位置验证
const locationValidation = [
  body('location').isObject().withMessage('位置必须是对象'),
  body('location.latitude')
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage('纬度必须在-90到90之间'),
  body('location.longitude')
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage('经度必须在-180到180之间'),
  body('location.address')
    .optional()
    .isString()
    .withMessage('地址必须是字符串'),
  body('location.placeName')
    .optional()
    .isString()
    .withMessage('地点名称必须是字符串'),
  body('location.placeType')
    .optional()
    .isString()
    .withMessage('地点类型必须是字符串'),
];

// 标签验证
const tagsValidation = [
  body('tags').isArray().withMessage('标签必须是数组'),
  body('tags.*.tag')
    .isString()
    .notEmpty()
    .withMessage('标签名称不能为空'),
  body('tags.*.note')
    .optional()
    .isString()
    .isLength({ max: 50 })
    .withMessage('标签备注最多50个字符'),
];

// 创建记录验证
export const createRecordValidation = [
  body('id').isUUID().withMessage('ID必须是有效的UUID'),
  body('timestamp').isISO8601().withMessage('时间戳必须是有效的日期'),
  ...locationValidation,
  body('description')
    .optional()
    .isString()
    .isLength({ max: 500 })
    .withMessage('描述最多500个字符'),
  ...tagsValidation,
  body('emotion').optional().isString().withMessage('情绪必须是字符串'),
  body('status')
    .isString()
    .notEmpty()
    .withMessage('状态不能为空'),
  body('storyLineId')
    .optional()
    .isUUID()
    .withMessage('故事线ID必须是有效的UUID'),
  body('ifReencounter')
    .optional()
    .isString()
    .withMessage('如果再遇必须是字符串'),
  body('conversationStarter')
    .optional()
    .isString()
    .isLength({ max: 500 })
    .withMessage('对话开场白最多500个字符'),
  body('backgroundMusic')
    .optional()
    .isString()
    .withMessage('背景音乐必须是字符串'),
  body('weather').isArray().withMessage('天气必须是数组'),
  body('weather.*').isString().withMessage('天气项必须是字符串'),
  body('isPinned').isBoolean().withMessage('是否置顶必须是布尔值'),
  body('createdAt').isISO8601().withMessage('创建时间必须是有效的日期'),
  body('updatedAt').isISO8601().withMessage('更新时间必须是有效的日期'),
];

// 批量创建记录验证
export const batchCreateRecordsValidation = [
  body('records').isArray().withMessage('记录必须是数组'),
  body('records.*.id').isUUID().withMessage('ID必须是有效的UUID'),
  body('records.*.timestamp')
    .isISO8601()
    .withMessage('时间戳必须是有效的日期'),
  body('records.*.status')
    .isString()
    .notEmpty()
    .withMessage('状态不能为空'),
];

// 更新记录验证
export const updateRecordValidation = [
  body('timestamp')
    .optional()
    .isISO8601()
    .withMessage('时间戳必须是有效的日期'),
  body('location').optional().isObject().withMessage('位置必须是对象'),
  body('description')
    .optional()
    .isString()
    .isLength({ max: 500 })
    .withMessage('描述最多500个字符'),
  body('tags').optional().isArray().withMessage('标签必须是数组'),
  body('emotion').optional().isString().withMessage('情绪必须是字符串'),
  body('status').optional().isString().withMessage('状态必须是字符串'),
  body('storyLineId')
    .optional()
    .isUUID()
    .withMessage('故事线ID必须是有效的UUID'),
  body('ifReencounter')
    .optional()
    .isString()
    .withMessage('如果再遇必须是字符串'),
  body('conversationStarter')
    .optional()
    .isString()
    .isLength({ max: 500 })
    .withMessage('对话开场白最多500个字符'),
  body('backgroundMusic')
    .optional()
    .isString()
    .withMessage('背景音乐必须是字符串'),
  body('weather').optional().isArray().withMessage('天气必须是数组'),
  body('isPinned')
    .optional()
    .isBoolean()
    .withMessage('是否置顶必须是布尔值'),
  body('updatedAt').isISO8601().withMessage('更新时间必须是有效的日期'),
];

// 获取记录查询验证
export const getRecordsQueryValidation = [
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

