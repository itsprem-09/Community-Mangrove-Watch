const { validationResult } = require('express-validator');
const axios = require('axios');
const FormData = require('form-data');
const uploadService = require('../services/uploadService');
const { sendUploadNotificationEmail, sendIncidentReportEmail } = require('../services/emailService');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Upload incident image
 */
const uploadIncidentImage = asyncHandler(async (req, res) => {
  // Check for validation errors
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array()
    });
  }

  if (!req.file) {
    return res.status(400).json({ error: 'No image file provided' });
  }

  try {
    const metadata = {
      description: req.body.description,
      location: req.body.location ? JSON.parse(req.body.location) : null,
      tags: req.body.tags ? req.body.tags.split(',').map(tag => tag.trim()) : [],
      isPublic: req.body.isPublic === 'true'
    };

    const result = await uploadService.uploadImageToCloud(
      req.file,
      'incidents',
      req.user.id,
      metadata
    );

    let response = {
      success: true,
      upload: result.upload,
      imageUrl: result.cloudinaryData.secure_url,
      publicId: result.cloudinaryData.public_id
    };

    // Optionally send to Python backend for immediate analysis
    if (req.body.analyzeImmediate === 'true') {
      try {
        const formData = new FormData();
        formData.append('image', req.file.buffer, {
          filename: req.file.originalname,
          contentType: req.file.mimetype
        });

        const analysisResponse = await axios.post(
          `${process.env.PYTHON_BACKEND_URL}/analyze-image`,
          formData,
          {
            headers: {
              ...formData.getHeaders(),
              'Authorization': req.headers['authorization']
            },
            timeout: 30000 // 30 seconds timeout
          }
        );

        // Update upload record with analysis results
        await uploadService.updateUploadMetadata(
          result.upload._id,
          req.user.id,
          {
            ...metadata,
            analysis: {
              processed: true,
              results: analysisResponse.data,
              processedAt: new Date()
            }
          }
        );

        response.analysis = analysisResponse.data;
      } catch (error) {
        console.error('Analysis failed:', error.message);
        response.analysis = null;
        response.analysisError = 'Analysis failed but image uploaded successfully';
      }
    }

    // Send email notification for incident uploads (asynchronously)
    if (req.body.notifyAdmins !== 'false') {
      try {
        const User = require('../models/User');
        const user = await User.findById(req.user.id);
        
        // Send upload notification
        sendUploadNotificationEmail(result.upload, user).catch(err => {
          console.error('Email notification failed:', err);
        });

        // If it's an incident with location/description, also send incident report
        if (metadata.description || metadata.location) {
          const incidentData = {
            _id: result.upload._id,
            title: metadata.description || 'Environmental Incident',
            description: metadata.description,
            location: metadata.location,
            imageUrl: result.cloudinaryData.secure_url,
            severity: req.body.severity || 'medium',
            createdAt: result.upload.createdAt
          };
          
          sendIncidentReportEmail(incidentData, user).catch(err => {
            console.error('Incident email notification failed:', err);
          });
        }
      } catch (emailError) {
        console.error('Email notification setup failed:', emailError);
      }
    }

    res.json(response);
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Upload profile image
 */
const uploadProfileImage = asyncHandler(async (req, res) => {
  // Check for validation errors
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array()
    });
  }

  if (!req.file) {
    return res.status(400).json({ error: 'No image file provided' });
  }

  try {
    const metadata = {
      description: 'Profile image',
      isPublic: req.body.isPublic === 'true'
    };

    const result = await uploadService.uploadImageToCloud(
      req.file,
      'profiles',
      req.user.id,
      metadata
    );

    res.json({
      success: true,
      upload: result.upload,
      imageUrl: result.cloudinaryData.secure_url,
      publicId: result.cloudinaryData.public_id
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get user's uploads
 */
const getUserUploads = asyncHandler(async (req, res) => {
  try {
    const { uploadType, page = 1, limit = 10 } = req.query;
    
    const result = await uploadService.getUserUploads(
      req.user.id,
      uploadType,
      parseInt(page),
      parseInt(limit)
    );

    res.json({
      success: true,
      ...result
    });
  } catch (error) {
    console.error('Fetch uploads error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get upload by ID
 */
const getUploadById = asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    
    const upload = await uploadService.getUploadById(id, req.user.id);

    res.json({
      success: true,
      upload
    });
  } catch (error) {
    console.error('Fetch upload error:', error);
    res.status(404).json({ error: error.message });
  }
});

/**
 * Delete upload
 */
const deleteUpload = asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await uploadService.deleteUploadedImage(id, req.user.id);

    res.json(result);
  } catch (error) {
    console.error('Delete upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Update upload metadata
 */
const updateUploadMetadata = asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const upload = await uploadService.updateUploadMetadata(id, req.user.id, updateData);

    res.json({
      success: true,
      upload
    });
  } catch (error) {
    console.error('Update upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = {
  uploadIncidentImage,
  uploadProfileImage,
  getUserUploads,
  getUploadById,
  deleteUpload,
  updateUploadMetadata
};
