const express = require('express');
const router = express.Router();

const { authenticateToken } = require('../middleware/auth');
const { 
  upload, 
  setIncidentUploadType, 
  setProfileUploadType 
} = require('../middleware/upload');
const {
  uploadValidation,
  getUploadsValidation,
  uploadIdValidation,
  updateUploadValidation
} = require('../utils/validation');
const {
  uploadIncidentImage,
  uploadProfileImage,
  getUserUploads,
  getUploadById,
  deleteUpload,
  updateUploadMetadata
} = require('../controllers/uploadController');

// Upload routes
router.post(
  '/incident-image',
  authenticateToken,
  setIncidentUploadType,
  upload.single('image'),
  uploadValidation,
  uploadIncidentImage
);

router.post(
  '/profile-image',
  authenticateToken,
  setProfileUploadType,
  upload.single('image'),
  uploadValidation,
  uploadProfileImage
);

// Get user uploads
router.get(
  '/user-uploads',
  authenticateToken,
  getUploadsValidation,
  getUserUploads
);

// Get specific upload
router.get(
  '/:id',
  authenticateToken,
  uploadIdValidation,
  getUploadById
);

// Update upload metadata
router.put(
  '/:id',
  authenticateToken,
  updateUploadValidation,
  updateUploadMetadata
);

// Delete upload
router.delete(
  '/:id',
  authenticateToken,
  uploadIdValidation,
  deleteUpload
);

module.exports = router;
