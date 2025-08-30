const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss');
const hpp = require('hpp');
const morgan = require('morgan');
const { createProxyMiddleware } = require('http-proxy-middleware');

// Load environment variables from parent backend directory
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

// Import configurations and middleware
const { connectDB } = require('./config/database');
const uploadRoutes = require('./routes/uploadRoutes');
const healthRoutes = require('./routes/healthRoutes');
const emailRoutes = require('./routes/emailRoutes');
const authRoutes = require('./routes/authRoutes');

const app = express();
const PORT = process.env.PORT || 5000;
const PYTHON_BACKEND_URL = process.env.PYTHON_BACKEND_URL || 'http://localhost:8000';

// Connect to database
connectDB();

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false
});
app.use(limiter);

// CORS configuration - Allow all origins for development (Flutter mobile apps)
const corsOptions = {
  origin: (origin, callback) => {
    // Always allow requests with no origin (like mobile apps, curl requests, Postman)
    if (!origin) {
      console.log('[CORS] Allowing request with no origin (mobile app/tool)');
      return callback(null, true);
    }
    
    // If CORS_ORIGINS is set to '*', allow all origins
    if (process.env.CORS_ORIGINS === '*') {
      console.log(`[CORS] Allowing all origins (wildcard configured)`);
      return callback(null, true);
    }
    
    // In development, allow all origins
    if (process.env.NODE_ENV === 'development') {
      console.log(`[CORS] Allowing origin in development: ${origin}`);
      return callback(null, true);
    }
    
    // Otherwise, check if origin is in allowed list
    const allowedOrigins = process.env.CORS_ORIGINS ? 
      process.env.CORS_ORIGINS.split(',') : ['http://localhost:3000'];
    
    if (allowedOrigins.includes(origin)) {
      console.log(`[CORS] Allowing configured origin: ${origin}`);
      return callback(null, true);
    }
    
    console.log(`[CORS] Rejecting origin: ${origin}`);
    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
  exposedHeaders: ['Content-Length', 'X-Request-Id'],
  maxAge: 86400, // 24 hours
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// Compression middleware
app.use(compression());

// Body parsing middleware
app.use(express.json({ 
  limit: '50mb',
  verify: (req, res, buf) => {
    req.rawBody = buf;
  }
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

// Proxy specific API requests to Python backend (excluding auth)
const pythonBackendProxy = createProxyMiddleware({
  target: PYTHON_BACKEND_URL,
  changeOrigin: true,
  pathRewrite: {
    '^/api': '', // Remove /api prefix when forwarding to Python backend
  },
  onError: (err, req, res) => {
    console.error('Proxy error:', err.message);
    res.status(503).json({ 
      error: 'Backend service unavailable',
      message: 'Python backend is not responding'
    });
  },
  onProxyReq: (proxyReq, req, res) => {
    // Forward authorization headers
    if (req.headers.authorization) {
      proxyReq.setHeader('Authorization', req.headers.authorization);
    }
  }
});

// Only proxy non-auth endpoints to Python backend
app.use('/api/incidents', pythonBackendProxy);
app.use('/api/analyze-image', pythonBackendProxy);
app.use('/api/predict-mangrove', pythonBackendProxy);
app.use('/api/gee', pythonBackendProxy);
app.use('/api/ml', pythonBackendProxy);

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

// Start server - Listen on all interfaces (0.0.0.0) for physical device access
const server = app.listen(PORT, '0.0.0.0', () => {
  const os = require('os');
  const networkInterfaces = os.networkInterfaces();
  const addresses = [];
  
  for (const [name, interfaces] of Object.entries(networkInterfaces)) {
    for (const iface of interfaces) {
      if (iface.family === 'IPv4' && !iface.internal) {
        addresses.push(`  - ${name}: http://${iface.address}:${PORT}`);
      }
    }
  }
  
  console.log(`Express server running on 0.0.0.0:${PORT}`);
  console.log(`Server accessible at:`);
  console.log(`  - Localhost: http://localhost:${PORT}`);
  if (addresses.length > 0) {
    console.log(`Network addresses:`);
    addresses.forEach(addr => console.log(addr));
  }
  console.log(`Proxying API requests to: ${PYTHON_BACKEND_URL}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`CORS enabled for: ${process.env.CORS_ORIGINS || 'all origins in development'}`);
  console.log(`Cloudinary configured: ${process.env.CLOUDINARY_CLOUD_NAME ? 'Yes' : 'No'}`);
  console.log(`MongoDB connection: Attempting to connect...`);
});

module.exports = app;
