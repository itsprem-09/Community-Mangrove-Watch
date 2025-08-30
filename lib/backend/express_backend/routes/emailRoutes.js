const express = require('express');
const { body } = require('express-validator');
const router = express.Router();

const { authenticateToken } = require('../middleware/auth');
const {
  testEmail,
  sendTestEmail,
  notifyMemberRegistration,
  notifyIncidentReport,
  sendUserWelcomeEmail,
  sendAlert,
  sendDirectMessage,
  sendBulkMessages,
  notifyMangroveMonitoring,
  notifyConservationActivity,
  updateIncidentStatus,
  sendEmergencyNotification
} = require('../controllers/emailController');

// Email validation rules
const emailValidation = [
  body('to')
    .isEmail()
    .withMessage('Valid email address is required'),
  body('subject')
    .notEmpty()
    .trim()
    .isLength({ min: 1, max: 200 })
    .withMessage('Subject is required and must be less than 200 characters'),
  body('message')
    .notEmpty()
    .trim()
    .isLength({ min: 1, max: 5000 })
    .withMessage('Message is required and must be less than 5000 characters')
];

// Member registration validation
const memberValidation = [
  body('name')
    .notEmpty()
    .trim()
    .withMessage('Name is required'),
  body('phoneNumber')
    .optional()
    .isMobilePhone()
    .withMessage('Valid phone number is required'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Valid email address is required')
];

// Direct message validation
const directMessageValidation = [
  body('recipientEmail')
    .isEmail()
    .withMessage('Valid recipient email is required'),
  body('subject')
    .notEmpty()
    .trim()
    .withMessage('Subject is required'),
  body('message')
    .notEmpty()
    .trim()
    .withMessage('Message is required')
];

// Bulk email validation
const bulkEmailValidation = [
  body('recipients')
    .isArray({ min: 1 })
    .withMessage('Recipients must be a non-empty array'),
  body('recipients.*')
    .isEmail()
    .withMessage('All recipients must be valid email addresses'),
  body('subject')
    .notEmpty()
    .trim()
    .withMessage('Subject is required'),
  body('message')
    .notEmpty()
    .trim()
    .withMessage('Message is required')
];

// System alert validation
const alertValidation = [
  body('alertType')
    .notEmpty()
    .trim()
    .withMessage('Alert type is required'),
  body('message')
    .notEmpty()
    .trim()
    .withMessage('Alert message is required')
];

// Test email configuration (admin only)
router.get('/test-config', authenticateToken, testEmail);

// Send test email (admin only)
router.post(
  '/test',
  authenticateToken,
  emailValidation,
  sendTestEmail
);

// Notification endpoints (can be called by other services)
router.post(
  '/notify/member-registration',
  memberValidation,
  notifyMemberRegistration
);

router.post(
  '/notify/incident-report',
  [
    body('incident').isObject().withMessage('Incident data is required'),
    body('user').isObject().withMessage('User data is required')
  ],
  notifyIncidentReport
);

// Mangrove-specific notification endpoints
router.post(
  '/notify/mangrove-monitoring',
  [
    body('report').isObject().withMessage('Report data is required'),
    body('user').isObject().withMessage('User data is required')
  ],
  notifyMangroveMonitoring
);

router.post(
  '/notify/conservation-activity',
  [
    body('activity').isObject().withMessage('Activity data is required'),
    body('organizer').isObject().withMessage('Organizer data is required')
  ],
  notifyConservationActivity
);

// User communication endpoints
router.post(
  '/direct',
  authenticateToken,
  directMessageValidation,
  sendDirectMessage
);

router.post(
  '/bulk',
  authenticateToken,
  bulkEmailValidation,
  sendBulkMessages
);

router.post(
  '/incident-status',
  authenticateToken,
  [
    body('incident').isObject().withMessage('Incident data is required'),
    body('status').notEmpty().trim().withMessage('Status is required'),
    body('userEmail').isEmail().withMessage('Valid user email is required')
  ],
  updateIncidentStatus
);

router.post(
  '/emergency',
  authenticateToken,
  [
    body('alert').isObject().withMessage('Alert data is required'),
    body('location').isObject().withMessage('Location data is required')
  ],
  sendEmergencyNotification
);

// Welcome email (for user registration)
router.post(
  '/welcome',
  [
    body('firstName').notEmpty().trim().withMessage('First name is required'),
    body('lastName').notEmpty().trim().withMessage('Last name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('username').notEmpty().trim().withMessage('Username is required')
  ],
  sendUserWelcomeEmail
);

// System alerts (admin only)
router.post(
  '/alert',
  authenticateToken,
  alertValidation,
  sendAlert
);

module.exports = router;
