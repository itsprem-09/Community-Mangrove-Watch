// Application constants
const APP_CONSTANTS = {
  // Upload types
  UPLOAD_TYPES: {
    INCIDENTS: 'incidents',
    PROFILES: 'profiles',
    GENERAL: 'general'
  },

  // User roles
  USER_ROLES: {
    USER: 'user',
    ADMIN: 'admin',
    MODERATOR: 'moderator'
  },

  // File constraints
  FILE_CONSTRAINTS: {
    MAX_SIZE: 10 * 1024 * 1024, // 10MB
    ALLOWED_TYPES: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
    ALLOWED_EXTENSIONS: ['.jpg', '.jpeg', '.png', '.gif', '.webp']
  },

  // Pagination defaults
  PAGINATION: {
    DEFAULT_PAGE: 1,
    DEFAULT_LIMIT: 10,
    MAX_LIMIT: 100
  },

  // JWT
  JWT: {
    DEFAULT_EXPIRES_IN: '7d'
  },

  // Rate limiting
  RATE_LIMIT: {
    WINDOW_MS: 15 * 60 * 1000, // 15 minutes
    MAX_REQUESTS: 100
  },

  // HTTP Status codes
  HTTP_STATUS: {
    OK: 200,
    CREATED: 201,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    CONFLICT: 409,
    INTERNAL_SERVER_ERROR: 500,
    SERVICE_UNAVAILABLE: 503
  }
};

module.exports = APP_CONSTANTS;
