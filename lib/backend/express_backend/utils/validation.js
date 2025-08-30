const { body, param, query } = require('express-validator');

/**
 * Validation rules for file uploads
 */
const uploadValidation = [
  body('description')
    .optional()
    .isString()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Description must be less than 500 characters'),
  body('tags')
    .optional()
    .isString()
    .withMessage('Tags must be a comma-separated string'),
  body('location')
    .optional()
    .isJSON()
    .withMessage('Location must be valid JSON'),
  body('isPublic')
    .optional()
    .isBoolean()
    .withMessage('isPublic must be a boolean'),
  body('analyzeImmediate')
    .optional()
    .isBoolean()
    .withMessage('analyzeImmediate must be a boolean')
];

/**
 * Validation rules for getting uploads
 */
const getUploadsValidation = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  query('uploadType')
    .optional()
    .isIn(['incidents', 'profiles', 'general'])
    .withMessage('Invalid upload type')
];

/**
 * Validation rules for upload ID parameter
 */
const uploadIdValidation = [
  param('id')
    .isMongoId()
    .withMessage('Invalid upload ID')
];

/**
 * Validation rules for updating upload metadata
 */
const updateUploadValidation = [
  param('id')
    .isMongoId()
    .withMessage('Invalid upload ID'),
  body('description')
    .optional()
    .isString()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Description must be less than 500 characters'),
  body('tags')
    .optional()
    .isArray()
    .withMessage('Tags must be an array'),
  body('location')
    .optional()
    .isObject()
    .withMessage('Location must be an object'),
  body('isPublic')
    .optional()
    .isBoolean()
    .withMessage('isPublic must be a boolean')
];

/**
 * Check if file is an image
 * @param {Object} file - Multer file object
 * @returns {Boolean} - True if file is an image
 */
const isImageFile = (file) => {
  const allowedTypes = process.env.ALLOWED_FILE_TYPES?.split(',') || [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp'
  ];
  return allowedTypes.includes(file.mimetype);
};

/**
 * Check file size
 * @param {Object} file - Multer file object
 * @returns {Boolean} - True if file size is acceptable
 */
const isValidFileSize = (file) => {
  const maxSize = parseInt(process.env.MAX_FILE_SIZE) || 10485760; // 10MB default
  return file.size <= maxSize;
};

/**
 * Validate email format
 * @param {String} email - Email to validate
 * @returns {Boolean} - True if valid email
 */
const validateEmail = (email) => {
  const emailRegex = /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/;
  return emailRegex.test(email);
};

/**
 * Validate registration data
 * @param {Object} data - Registration data
 * @returns {String|null} - Error message or null if valid
 */
const validateRegistration = (data) => {
  const { name, email, password, role } = data;

  if (!name || name.trim().length < 2) {
    return 'Name must be at least 2 characters long';
  }

  if (!email || !validateEmail(email)) {
    return 'Please provide a valid email address';
  }

  if (!password || password.length < 6) {
    return 'Password must be at least 6 characters long';
  }

  const allowedRoles = ['citizen', 'ngo', 'government', 'researcher', 'admin'];
  if (role && !allowedRoles.includes(role)) {
    return `Role must be one of: ${allowedRoles.join(', ')}`;
  }

  return null;
};

/**
 * Validate login data
 * @param {Object} data - Login data
 * @returns {String|null} - Error message or null if valid
 */
const validateLogin = (data) => {
  const { email, password } = data;

  if (!email || !validateEmail(email)) {
    return 'Please provide a valid email address';
  }

  if (!password) {
    return 'Password is required';
  }

  return null;
};

module.exports = {
  uploadValidation,
  getUploadsValidation,
  uploadIdValidation,
  updateUploadValidation,
  isImageFile,
  isValidFileSize,
  validateEmail,
  validateRegistration,
  validateLogin
};
