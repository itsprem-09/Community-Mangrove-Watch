const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss');
const hpp = require('hpp');
const morgan = require('morgan');

// Load environment variables from parent backend directory
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

// Import configurations and middleware
const { connectDB } = require('./config/database');
const uploadRoutes = require('./routes/uploadRoutes');
const healthRoutes = require('./routes/healthRoutes');
const emailRoutes = require('./routes/emailRoutes');
const authRoutes = require('./routes/authRoutes');
const incidentRoutes = require('./routes/incidentRoutes');
const predictionRoutes = require('./routes/predictionRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// Connect to database
connectDB();

// Minimal security middleware - allow cross-origin requests
app.use(helmet({
  crossOriginResourcePolicy: false, // Disable to allow all cross-origin requests
  contentSecurityPolicy: false, // Disable CSP that might block connections
}));

// CORS configuration - Allow all origins with explicit wildcard
const corsOptions = {
  origin: '*', // Explicitly allow all origins
  credentials: false, // Note: credentials must be false when origin is '*'
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// Compression middleware
app.use(compression());

// Body parsing middleware
app.use(express.json({ 
  limit: '50mb'
  // Temporarily disabled raw body verification to fix JSON parsing issues
  // verify: (req, res, buf) => {
  //   req.rawBody = buf;
  // }
}));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Data sanitization against NoSQL query injection
app.use(mongoSanitize());

// Data sanitization against XSS
app.use((req, res, next) => {
  if (req.body) {
    for (let key in req.body) {
      if (typeof req.body[key] === 'string') {
        req.body[key] = xss(req.body[key]);
      }
    }
  }
  next();
});

// Prevent parameter pollution
app.use(hpp());

// Logging middleware
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// API Routes
app.use('/health', healthRoutes);
app.use('/upload', uploadRoutes);
app.use('/email', emailRoutes);
app.use('/auth', authRoutes);
app.use('/user', authRoutes); // User profile routes

// Incident and Prediction routes with Python backend integration
app.use('/incidents', incidentRoutes);
app.use('/', predictionRoutes); // Prediction routes handle /predict-mangrove
app.use('/analyze-image', incidentRoutes); // Image analysis route

// Serve optimized images through Cloudinary (no local static serving needed)
app.get('/image/:publicId', (req, res) => {
  const { getOptimizedImageUrl } = require('./config/cloudinary');
  try {
    const { publicId } = req.params;
    const { w, h, q, f } = req.query;
    
    const transformations = {};
    if (w) transformations.width = parseInt(w);
    if (h) transformations.height = parseInt(h);
    if (q) transformations.quality = q;
    if (f) transformations.format = f;
    
    const optimizedUrl = getOptimizedImageUrl(publicId, transformations);
    res.redirect(optimizedUrl);
  } catch (error) {
    res.status(404).json({ error: 'Image not found' });
  }
});


// Global error handling middleware
app.use((error, req, res, next) => {
  console.error('Server error:', error);
  
  // Multer errors
  if (error.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ 
      error: 'File too large', 
      message: 'Maximum file size is 10MB' 
    });
  }
  
  if (error.code === 'LIMIT_UNEXPECTED_FILE') {
    return res.status(400).json({ 
      error: 'Unexpected file field', 
      message: 'Only single image upload is allowed' 
    });
  }

  // Validation errors
  if (error.name === 'ValidationError') {
    return res.status(400).json({
      error: 'Validation Error',
      message: error.message
    });
  }

  // MongoDB errors
  if (error.name === 'MongoError' || error.name === 'MongooseError') {
    return res.status(500).json({
      error: 'Database Error',
      message: 'Database operation failed'
    });
  }

  // JWT errors
  if (error.name === 'JsonWebTokenError') {
    return res.status(401).json({
      error: 'Invalid Token',
      message: 'Authentication failed'
    });
  }

  // Cloudinary errors
  if (error.message && error.message.includes('Cloudinary')) {
    return res.status(500).json({
      error: 'Cloud Storage Error',
      message: 'Failed to process image upload'
    });
  }

  // Default error response
  res.status(error.status || 500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Endpoint not found',
    message: `Cannot ${req.method} ${req.originalUrl}`
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received. Shutting down gracefully...');
  server.close(() => {
    console.log('Process terminated');
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received. Shutting down gracefully...');
  server.close(() => {
    console.log('Process terminated');
  });
});

// Start server - Listen on all interfaces for development (allows Android emulator access)
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Express server running on all interfaces:${PORT}`);
  console.log(`Server accessible at:`);
  console.log(`  - http://localhost:${PORT} (for web/desktop)`);
  console.log(`  - http://10.0.2.2:${PORT} (for Android emulator)`);
  console.log(`  - http://127.0.0.1:${PORT} (local loopback)`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`CORS enabled for: ${process.env.CORS_ORIGINS || 'all origins in development'}`);
  console.log(`Cloudinary configured: ${process.env.CLOUDINARY_CLOUD_NAME ? 'Yes' : 'No'}`);
  console.log(`MongoDB connection: Attempting to connect...`);
});

module.exports = app;
