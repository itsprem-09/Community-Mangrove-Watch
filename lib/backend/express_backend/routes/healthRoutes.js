const express = require('express');
const router = express.Router();
const { isConnected } = require('../config/database');

/**
 * Health check endpoint
 */
router.get('/', (req, res) => {
  const healthStatus = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'Express Backend Server',
    version: process.env.npm_package_version || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    services: {
      database: {
        status: isConnected() ? 'connected' : 'disconnected',
        type: 'MongoDB'
      },
      cloudinary: {
        status: process.env.CLOUDINARY_CLOUD_NAME ? 'configured' : 'not configured'
      },
      pythonBackend: {
        url: process.env.PYTHON_BACKEND_URL || 'http://localhost:8000'
      }
    }
  };

  res.json(healthStatus);
});

/**
 * Detailed health check for monitoring
 */
router.get('/detailed', (req, res) => {
  const detailed = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'Express Backend Server',
    version: process.env.npm_package_version || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    uptime: {
      seconds: process.uptime(),
      human: formatUptime(process.uptime())
    },
    memory: {
      ...process.memoryUsage(),
      formatted: formatMemory(process.memoryUsage())
    },
    cpu: process.cpuUsage(),
    platform: {
      os: process.platform,
      arch: process.arch,
      node: process.version
    },
    services: {
      database: {
        status: isConnected() ? 'connected' : 'disconnected',
        type: 'MongoDB',
        uri: process.env.MONGODB_URI ? 'configured' : 'not configured'
      },
      cloudinary: {
        status: process.env.CLOUDINARY_CLOUD_NAME ? 'configured' : 'not configured',
        cloudName: process.env.CLOUDINARY_CLOUD_NAME || 'not set'
      },
      pythonBackend: {
        url: process.env.PYTHON_BACKEND_URL || 'http://localhost:8000',
        configured: !!process.env.PYTHON_BACKEND_URL
      }
    },
    security: {
      cors: process.env.CORS_ORIGIN || 'http://localhost:3000',
      rateLimit: {
        windowMs: process.env.RATE_LIMIT_WINDOW_MS || 900000,
        maxRequests: process.env.RATE_LIMIT_MAX_REQUESTS || 100
      },
      fileUpload: {
        maxSize: process.env.MAX_FILE_SIZE || 10485760,
        allowedTypes: process.env.ALLOWED_FILE_TYPES || 'image/jpeg,image/png,image/gif,image/webp'
      }
    }
  };

  res.json(detailed);
});

/**
 * Format uptime in human readable format
 */
function formatUptime(uptimeSeconds) {
  const days = Math.floor(uptimeSeconds / (24 * 60 * 60));
  const hours = Math.floor((uptimeSeconds % (24 * 60 * 60)) / (60 * 60));
  const minutes = Math.floor((uptimeSeconds % (60 * 60)) / 60);
  const seconds = Math.floor(uptimeSeconds % 60);
  
  return `${days}d ${hours}h ${minutes}m ${seconds}s`;
}

/**
 * Format memory usage in human readable format
 */
function formatMemory(memoryUsage) {
  const formatBytes = (bytes) => {
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    if (bytes === 0) return '0 Bytes';
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
  };

  return {
    rss: formatBytes(memoryUsage.rss),
    heapUsed: formatBytes(memoryUsage.heapUsed),
    heapTotal: formatBytes(memoryUsage.heapTotal),
    external: formatBytes(memoryUsage.external)
  };
}

module.exports = router;
