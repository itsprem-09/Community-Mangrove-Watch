const mongoose = require('mongoose');

const uploadSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  originalName: {
    type: String,
    required: true
  },
  filename: {
    type: String,
    required: true
  },
  mimetype: {
    type: String,
    required: true
  },
  size: {
    type: Number,
    required: true
  },
  uploadType: {
    type: String,
    enum: ['incidents', 'profiles', 'general'],
    required: true
  },
  cloudinary: {
    publicId: {
      type: String,
      required: true
    },
    url: {
      type: String,
      required: true
    },
    secureUrl: {
      type: String,
      required: true
    },
    format: String,
    width: Number,
    height: Number,
    bytes: Number,
    resourceType: String
  },
  metadata: {
    location: {
      latitude: Number,
      longitude: Number,
      address: String
    },
    tags: [String],
    description: String,
    isPublic: {
      type: Boolean,
      default: false
    }
  },
  analysis: {
    processed: {
      type: Boolean,
      default: false
    },
    results: mongoose.Schema.Types.Mixed,
    processedAt: Date,
    error: String
  }
}, {
  timestamps: true
});

// Index for performance
uploadSchema.index({ user: 1, createdAt: -1 });
uploadSchema.index({ uploadType: 1 });
uploadSchema.index({ 'cloudinary.publicId': 1 });
uploadSchema.index({ 'analysis.processed': 1 });

// Virtual for getting formatted file size
uploadSchema.virtual('formattedSize').get(function() {
  const bytes = this.size;
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
});

// Method to get optimized image URL with transformations
uploadSchema.methods.getOptimizedUrl = function(transformations = {}) {
  const { cloudinary } = require('../config/cloudinary');
  return cloudinary.url(this.cloudinary.publicId, {
    quality: 'auto',
    fetch_format: 'auto',
    ...transformations
  });
};

// Static method to find uploads by type
uploadSchema.statics.findByType = function(uploadType, userId = null) {
  const query = { uploadType };
  if (userId) query.user = userId;
  return this.find(query).populate('user', 'username firstName lastName');
};

// Static method to get user's uploads
uploadSchema.statics.getUserUploads = function(userId, uploadType = null) {
  const query = { user: userId };
  if (uploadType) query.uploadType = uploadType;
  return this.find(query).sort({ createdAt: -1 });
};

module.exports = mongoose.model('Upload', uploadSchema);
