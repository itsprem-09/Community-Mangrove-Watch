const multer = require('multer');
const { isImageFile, isValidFileSize } = require('../utils/validation');

// Configure multer for memory storage (we'll upload to Cloudinary)
const storage = multer.memoryStorage();

const upload = multer({
  storage: storage,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10485760, // 10MB default
  },
  fileFilter: (req, file, cb) => {
    // Check if file is an image
    if (!isImageFile(file)) {
      return cb(new Error('Only image files are allowed'), false);
    }

    // Check file size (additional check)
    if (!isValidFileSize(file)) {
      return cb(new Error('File size exceeds the allowed limit'), false);
    }

    cb(null, true);
  }
});

/**
 * Middleware to set upload type for incidents
 */
const setIncidentUploadType = (req, res, next) => {
  req.uploadType = 'incidents';
  next();
};

/**
 * Middleware to set upload type for profiles
 */
const setProfileUploadType = (req, res, next) => {
  req.uploadType = 'profiles';
  next();
};

/**
 * Middleware to set upload type for general uploads
 */
const setGeneralUploadType = (req, res, next) => {
  req.uploadType = 'general';
  next();
};

module.exports = {
  upload,
  setIncidentUploadType,
  setProfileUploadType,
  setGeneralUploadType
};
