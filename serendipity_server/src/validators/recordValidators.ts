import { body, query } from 'express-validator';

// 位置验证
const locationValidation = [
  body('location').isObject().withMessage('Location must be an object'),
  body('location.latitude')
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be between -90 and 90'),
  body('location.longitude')
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be between -180 and 180'),
  body('location.address')
    .optional()
    .isString()
    .withMessage('Address must be a string'),
  body('location.placeName')
    .optional()
    .isString()
    .withMessage('Place name must be a string'),
  body('location.placeType')
    .optional()
    .isString()
    .withMessage('Place type must be a string'),
];

// 标签验证
const tagsValidation = [
  body('tags').isArray().withMessage('Tags must be an array'),
  body('tags.*.tag')
    .isString()
    .notEmpty()
    .withMessage('Tag name is required'),
  body('tags.*.note')
    .optional()
    .isString()
    .isLength({ max: 50 })
    .withMessage('Tag note must be at most 50 characters'),
];

// 创建记录验证
export const createRecordValidation = [
  body('id').isUUID().withMessage('ID must be a valid UUID'),
  body('timestamp').isISO8601().withMessage('Timestamp must be a valid date'),
  ...locationValidation,
  body('description')
    .optional()
    .isString()
    .isLength({ max: 500 })
    .withMessage('Description must be at most 500 characters'),
  ...tagsValidation,
  body('emotion').optional().isString().withMessage('Emotion must be a string'),
  body('status')
    .isString()
    .notEmpty()
    .withMessage('Status is required'),
  body('storyLineId')
    .optional()
    .isUUID()
    .withMessage('StoryLine ID must be a valid UUID'),
  body('ifReencounter')
    .optional()
    .isString()
    .withMessage('If reencounter must be a string'),
  body('conversationStarter')
    .optional()
    .isString()
    .isLength({ max: 500 })
    .withMessage('Conversation starter must be at most 500 characters'),
  body('backgroundMusic')
    .optional()
    .isString()
    .withMessage('Background music must be a string'),
  body('weather').isArray().withMessage('Weather must be an array'),
  body('weather.*').isString().withMessage('Weather item must be a string'),
  body('isPinned').isBoolean().withMessage('Is pinned must be a boolean'),
  body('createdAt').isISO8601().withMessage('Created at must be a valid date'),
  body('updatedAt').isISO8601().withMessage('Updated at must be a valid date'),
];

// 批量创建记录验证
export const batchCreateRecordsValidation = [
  body('records').isArray().withMessage('Records must be an array'),
  body('records.*.id').isUUID().withMessage('ID must be a valid UUID'),
  body('records.*.timestamp')
    .isISO8601()
    .withMessage('Timestamp must be a valid date'),
  body('records.*.status')
    .isString()
    .notEmpty()
    .withMessage('Status is required'),
];

// 更新记录验证
export const updateRecordValidation = [
  body('timestamp')
    .optional()
    .isISO8601()
    .withMessage('Timestamp must be a valid date'),
  body('location').optional().isObject().withMessage('Location must be an object'),
  body('description')
    .optional()
    .isString()
    .isLength({ max: 500 })
    .withMessage('Description must be at most 500 characters'),
  body('tags').optional().isArray().withMessage('Tags must be an array'),
  body('emotion').optional().isString().withMessage('Emotion must be a string'),
  body('status').optional().isString().withMessage('Status must be a string'),
  body('storyLineId')
    .optional()
    .isUUID()
    .withMessage('StoryLine ID must be a valid UUID'),
  body('ifReencounter')
    .optional()
    .isString()
    .withMessage('If reencounter must be a string'),
  body('conversationStarter')
    .optional()
    .isString()
    .isLength({ max: 500 })
    .withMessage('Conversation starter must be at most 500 characters'),
  body('backgroundMusic')
    .optional()
    .isString()
    .withMessage('Background music must be a string'),
  body('weather').optional().isArray().withMessage('Weather must be an array'),
  body('isPinned')
    .optional()
    .isBoolean()
    .withMessage('Is pinned must be a boolean'),
  body('updatedAt').isISO8601().withMessage('Updated at must be a valid date'),
];

// 获取记录查询验证
export const getRecordsQueryValidation = [
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

