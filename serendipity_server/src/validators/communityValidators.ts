import { body } from 'express-validator';

// 发布社区帖子验证规则
export const createCommunityPostValidation = [
  body('id')
    .isUUID()
    .withMessage('帖子ID格式不正确'),
  
  body('recordId')
    .isUUID()
    .withMessage('记录ID格式不正确'),
  
  body('timestamp')
    .isISO8601()
    .withMessage('时间戳格式不正确，必须是ISO 8601格式'),
  
  body('address')
    .optional()
    .isString()
    .withMessage('地址必须是字符串'),
  
  body('placeName')
    .optional()
    .isString()
    .withMessage('地点名称必须是字符串'),
  
  body('placeType')
    .optional()
    .isString()
    .withMessage('地点类型必须是字符串'),
  
  body('province')
    .optional()
    .isString()
    .withMessage('省份必须是字符串'),
  
  body('city')
    .optional()
    .isString()
    .withMessage('城市必须是字符串'),
  
  body('area')
    .optional()
    .isString()
    .withMessage('区县必须是字符串'),
  
  body('description')
    .optional()
    .isString()
    .withMessage('描述必须是字符串'),
  
  body('tags')
    .isArray()
    .withMessage('标签必须是数组'),
  
  body('tags.*.tag')
    .isString()
    .withMessage('标签必须是字符串'),
  
  body('tags.*.note')
    .optional()
    .isString()
    .withMessage('标签备注必须是字符串'),
  
  body('status')
    .isString()
    .notEmpty()
    .withMessage('状态不能为空'),
  
  body('publishedAt')
    .optional()
    .isISO8601()
    .withMessage('发布时间格式不正确，必须是ISO 8601格式'),
];

