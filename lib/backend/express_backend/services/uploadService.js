const { uploadImage, deleteImage } = require('../config/cloudinary');
const Upload = require('../models/Upload');
const User = require('../models/User');

/**
 * Upload image to Cloudinary and save metadata to database
 * @param {Object} file - Multer file object
 * @param {String} uploadType - Type of upload (incidents, profiles, general)
 * @param {String} userId - User ID
 * @param {Object} metadata - Additional metadata
 * @returns {Promise<Object>} - Upload result
 */
const uploadImageToCloud = async (file, uploadType, userId, metadata = {}) => {
  try {
    // Upload to Cloudinary
    const cloudinaryResult = await uploadImage(file.buffer, {
      folder: `mangrove-watch/${uploadType}`,
      public_id: `${uploadType}_${userId}_${Date.now()}`,
      resource_type: 'image',
      quality: 'auto',
      fetch_format: 'auto'
    });

    // Save upload metadata to database
    const uploadRecord = new Upload({
      user: userId,
      originalName: file.originalname,
      filename: file.filename || file.originalname,
      mimetype: file.mimetype,
      size: file.size,
      uploadType,
      cloudinary: {
        publicId: cloudinaryResult.public_id,
        url: cloudinaryResult.url,
        secureUrl: cloudinaryResult.secure_url,
        format: cloudinaryResult.format,
        width: cloudinaryResult.width,
        height: cloudinaryResult.height,
        bytes: cloudinaryResult.bytes,
        resourceType: cloudinaryResult.resource_type
      },
      metadata: {
        ...metadata,
        uploadedAt: new Date()
      }
    });

    await uploadRecord.save();

    // Update user profile image if it's a profile upload
    if (uploadType === 'profiles') {
      await User.findByIdAndUpdate(userId, {
        profileImage: {
          publicId: cloudinaryResult.public_id,
          url: cloudinaryResult.secure_url,
          originalName: file.originalname
        }
      });
    }

    return {
      success: true,
      upload: uploadRecord,
      cloudinaryData: cloudinaryResult
    };
  } catch (error) {
    throw new Error(`Upload failed: ${error.message}`);
  }
};

/**
 * Delete image from Cloudinary and database
 * @param {String} uploadId - Upload document ID
 * @param {String} userId - User ID (for authorization)
 * @returns {Promise<Object>} - Deletion result
 */
const deleteUploadedImage = async (uploadId, userId) => {
  try {
    const upload = await Upload.findOne({ _id: uploadId, user: userId });
    
    if (!upload) {
      throw new Error('Upload not found or unauthorized');
    }

    // Delete from Cloudinary
    await deleteImage(upload.cloudinary.publicId);

    // Remove from database
    await Upload.findByIdAndDelete(uploadId);

    // If it was a profile image, update user record
    if (upload.uploadType === 'profiles') {
      await User.findByIdAndUpdate(userId, {
        $unset: { profileImage: 1 }
      });
    }

    return {
      success: true,
      message: 'Image deleted successfully'
    };
  } catch (error) {
    throw new Error(`Deletion failed: ${error.message}`);
  }
};

/**
 * Get user's uploads with pagination
 * @param {String} userId - User ID
 * @param {String} uploadType - Optional upload type filter
 * @param {Number} page - Page number
 * @param {Number} limit - Items per page
 * @returns {Promise<Object>} - Paginated uploads
 */
const getUserUploads = async (userId, uploadType = null, page = 1, limit = 10) => {
  try {
    const query = { user: userId };
    if (uploadType) query.uploadType = uploadType;

    const skip = (page - 1) * limit;
    
    const [uploads, total] = await Promise.all([
      Upload.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('user', 'username firstName lastName'),
      Upload.countDocuments(query)
    ]);

    return {
      uploads,
      pagination: {
        current: page,
        total: Math.ceil(total / limit),
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1,
        count: uploads.length,
        totalCount: total
      }
    };
  } catch (error) {
    throw new Error(`Failed to fetch uploads: ${error.message}`);
  }
};

/**
 * Update upload metadata
 * @param {String} uploadId - Upload document ID
 * @param {String} userId - User ID (for authorization)
 * @param {Object} updateData - Data to update
 * @returns {Promise<Object>} - Updated upload
 */
const updateUploadMetadata = async (uploadId, userId, updateData) => {
  try {
    const upload = await Upload.findOneAndUpdate(
      { _id: uploadId, user: userId },
      { $set: { metadata: { ...updateData } } },
      { new: true, runValidators: true }
    ).populate('user', 'username firstName lastName');

    if (!upload) {
      throw new Error('Upload not found or unauthorized');
    }

    return upload;
  } catch (error) {
    throw new Error(`Failed to update upload: ${error.message}`);
  }
};

/**
 * Get upload by ID
 * @param {String} uploadId - Upload document ID
 * @param {String} userId - User ID (for authorization, optional)
 * @returns {Promise<Object>} - Upload document
 */
const getUploadById = async (uploadId, userId = null) => {
  try {
    const query = { _id: uploadId };
    if (userId) query.user = userId;

    const upload = await Upload.findOne(query).populate('user', 'username firstName lastName');
    
    if (!upload) {
      throw new Error('Upload not found');
    }

    return upload;
  } catch (error) {
    throw new Error(`Failed to fetch upload: ${error.message}`);
  }
};

module.exports = {
  uploadImageToCloud,
  deleteUploadedImage,
  getUserUploads,
  updateUploadMetadata,
  getUploadById
};
