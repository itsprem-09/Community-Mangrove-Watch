const { v2: cloudinary } = require('cloudinary');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true
});

/**
 * Upload image to Cloudinary
 * @param {Buffer} fileBuffer - Image file buffer
 * @param {Object} options - Upload options
 * @returns {Promise<Object>} - Cloudinary upload result
 */
const uploadImage = async (fileBuffer, options = {}) => {
  try {
    const defaultOptions = {
      resource_type: 'image',
      quality: 'auto',
      fetch_format: 'auto',
      ...options
    };

    return new Promise((resolve, reject) => {
      cloudinary.uploader.upload_stream(
        defaultOptions,
        (error, result) => {
          if (error) {
            reject(error);
          } else {
            resolve(result);
          }
        }
      ).end(fileBuffer);
    });
  } catch (error) {
    throw new Error(`Cloudinary upload failed: ${error.message}`);
  }
};

/**
 * Delete image from Cloudinary
 * @param {String} publicId - Cloudinary public ID
 * @returns {Promise<Object>} - Deletion result
 */
const deleteImage = async (publicId) => {
  try {
    return await cloudinary.uploader.destroy(publicId);
  } catch (error) {
    throw new Error(`Cloudinary deletion failed: ${error.message}`);
  }
};

/**
 * Generate optimized image URL
 * @param {String} publicId - Cloudinary public ID
 * @param {Object} transformations - Image transformations
 * @returns {String} - Optimized image URL
 */
const getOptimizedImageUrl = (publicId, transformations = {}) => {
  try {
    const defaultTransformations = {
      quality: 'auto',
      fetch_format: 'auto',
      ...transformations
    };

    return cloudinary.url(publicId, defaultTransformations);
  } catch (error) {
    throw new Error(`Failed to generate image URL: ${error.message}`);
  }
};

module.exports = {
  cloudinary,
  uploadImage,
  deleteImage,
  getOptimizedImageUrl
};
