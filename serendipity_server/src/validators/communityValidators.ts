import { body } from 'express-validator';

// 发布社区帖子验证规则
export const createCommunityPostValidation = [
  body('id')
    .isUUID()
    .withMessage('Invalid post ID format'),
  
  body('recordId')
    .isUUID()
    .withMessage('Invalid record ID format'),
  
  body('timestamp')
    .isISO8601()
    .withMessage('Invalid timestamp format, must be ISO 8601'),
  
  body('address')
    .optional()
    .isString()
    .withMessage('Address must be a string'),
  
  body('placeName')
    .optional()
    .isString()
    .withMessage('Place name must be a string'),
  
  body('placeType')
    .optional()
    .isString()
    .withMessage('Place type must be a string'),
  
  body('cityName')
    .optional()
    .isString()
    .withMessage('City name must be a string'),
  
  body('description')
    .optional()
    .isString()
    .withMessage('Description must be a string'),
  
  body('tags')
    .isArray()
    .withMessage('Tags must be an array'),
  
  body('tags.*.tag')
    .isString()
    .withMessage('Tag must be a string'),
  
  body('tags.*.note')
    .optional()
    .isString()
    .withMessage('Tag note must be a string'),
  
  body('status')
    .isString()
    .notEmpty()
    .withMessage('Status is required'),
  
  body('publishedAt')
    .optional()
    .isISO8601()
    .withMessage('Invalid publishedAt format, must be ISO 8601'),
];

