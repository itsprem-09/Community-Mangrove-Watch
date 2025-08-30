const jwt = require('jsonwebtoken');

/**
 * Middleware to authenticate JWT tokens
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ 
      error: 'Access token required',
      message: 'Please provide a valid authorization token'
    });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ 
        error: 'Invalid or expired token',
        message: 'The provided token is either invalid or has expired'
      });
    }
    req.user = user;
    next();
  });
};

/**
 * Middleware to optionally authenticate JWT tokens
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    req.user = null;
    return next();
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      req.user = null;
    } else {
      req.user = user;
    }
    next();
  });
};

/**
 * Generate JWT token for user
 * @param {Object} payload - User data to include in token
 * @param {String} expiresIn - Token expiration time
 * @returns {String} - JWT token
 */
const generateToken = (payload, expiresIn = process.env.JWT_EXPIRES_IN || '7d') => {
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn });
};

module.exports = {
  authenticateToken,
  optionalAuth,
  generateToken
};
