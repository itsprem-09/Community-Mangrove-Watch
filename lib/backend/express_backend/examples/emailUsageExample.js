/**
 * Email Usage Examples for Mangrove Watch
 * 
 * This file demonstrates how to use the email system to send various types
 * of notifications directly to users and admins.
 */

const {
  sendDirectUserMessage,
  sendBulkEmails,
  sendWelcomeEmail,
  sendIncidentStatusUpdate,
  sendAchievementNotification,
  sendEmergencyAlert,
  sendWeeklyDigest,
  sendMangroveMonitoringEmail,
  sendConservationActivityEmail,
  sendMemberRegistrationEmail,
  sendIncidentReportEmail
} = require('../services/emailService');

// Example usage functions (these are examples, not to be called directly)

/**
 * Example: Send a welcome email to a new user
 */
const exampleWelcomeEmail = async () => {
  const newUser = {
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    email: 'john.doe@example.com',
    createdAt: new Date()
  };

  try {
    await sendWelcomeEmail(newUser);
    console.log('Welcome email sent successfully');
  } catch (error) {
    console.error('Failed to send welcome email:', error);
  }
};

/**
 * Example: Send a direct message to a user
 */
const exampleDirectMessage = async () => {
  const userEmail = 'user@example.com';
  const subject = 'Important Update on Your Mangrove Report';
  const message = `Dear Community Member,

We wanted to update you on the recent mangrove monitoring activities in your area.

Your recent report has been very valuable for our conservation efforts. The data you provided is helping us track the health of mangrove ecosystems in your region.

Thank you for your continued participation in protecting our coastal environments!

Best regards,
The Mangrove Watch Team`;

  const options = {
    actionButton: 'View Your Dashboard',
    actionUrl: 'https://mangrove-watch.org/dashboard'
  };

  try {
    await sendDirectUserMessage(userEmail, subject, message, options);
    console.log('Direct message sent successfully');
  } catch (error) {
    console.error('Failed to send direct message:', error);
  }
};

/**
 * Example: Send bulk emails to community members
 */
const exampleBulkEmail = async () => {
  const recipients = [
    'member1@example.com',
    'member2@example.com',
    'member3@example.com'
  ];

  const subject = 'Monthly Conservation Activity Reminder';
  const message = `Dear Mangrove Watch Community,

This is a reminder about our upcoming monthly conservation activity!

Join us this weekend for a community mangrove planting and monitoring session. Your participation makes a real difference in protecting our coastal ecosystems.

Looking forward to seeing you there!`;

  const options = {
    actionButton: 'RSVP for Activity',
    actionUrl: 'https://mangrove-watch.org/activities/monthly-planting'
  };

  try {
    const results = await sendBulkEmails(recipients, subject, message, options);
    console.log('Bulk emails sent:', results);
  } catch (error) {
    console.error('Failed to send bulk emails:', error);
  }
};

/**
 * Example: Send incident status update to user
 */
const exampleIncidentStatusUpdate = async () => {
  const incident = {
    _id: '507f1f77bcf86cd799439011',
    title: 'Mangrove Destruction at Coastal Area',
    location: {
      address: 'Sundarbans, West Bengal, India'
    },
    createdAt: new Date('2024-01-15')
  };

  const status = 'verified';
  const userEmail = 'reporter@example.com';
  const adminMessage = 'Thank you for your detailed report. We have verified the incident and forwarded it to local authorities. Conservation teams will be deployed to assess the damage.';

  try {
    await sendIncidentStatusUpdate(incident, status, userEmail, adminMessage);
    console.log('Incident status update sent successfully');
  } catch (error) {
    console.error('Failed to send incident status update:', error);
  }
};

/**
 * Example: Send achievement notification
 */
const exampleAchievementNotification = async () => {
  const achievement = {
    title: 'Mangrove Guardian',
    description: 'Submitted 10 verified mangrove monitoring reports',
    icon: '🌿',
    points: 500
  };

  const user = {
    firstName: 'Sarah',
    email: 'sarah@example.com',
    totalPoints: 1250,
    rank: 'Senior Guardian',
    reportsCount: 12
  };

  try {
    await sendAchievementNotification(achievement, user);
    console.log('Achievement notification sent successfully');
  } catch (error) {
    console.error('Failed to send achievement notification:', error);
  }
};

/**
 * Example: Send emergency alert
 */
const exampleEmergencyAlert = async () => {
  const alert = {
    _id: '507f1f77bcf86cd799439012',
    type: 'Mass Mangrove Destruction',
    severity: 'CRITICAL',
    description: 'Large-scale clearing detected in protected mangrove area. Immediate intervention required.',
    timestamp: new Date()
  };

  const location = {
    name: 'Sundarbans Protected Area',
    address: 'Sundarbans, West Bengal, India'
  };

  const recipients = [
    'emergency@mangrove-watch.org',
    'local.authority@forestdept.gov.in',
    'community.leader@example.com'
  ];

  try {
    await sendEmergencyAlert(alert, location, recipients);
    console.log('Emergency alert sent successfully');
  } catch (error) {
    console.error('Failed to send emergency alert:', error);
  }
};

/**
 * Example: Send weekly digest to user
 */
const exampleWeeklyDigest = async () => {
  const digestData = {
    newIncidents: 12,
    verifiedReports: 8,
    communityPoints: 2450,
    activities: 3,
    newMembers: 15,
    featuredActivity: {
      title: 'Community Mangrove Planting Drive',
      description: 'Join us for a massive mangrove restoration effort this Saturday',
      location: 'Coastal Conservation Area, Mumbai'
    }
  };

  const user = {
    firstName: 'Alex',
    email: 'alex@example.com'
  };

  try {
    await sendWeeklyDigest(digestData, user);
    console.log('Weekly digest sent successfully');
  } catch (error) {
    console.error('Failed to send weekly digest:', error);
  }
};

/**
 * Example: Send mangrove monitoring report notification
 */
const exampleMangroveMonitoring = async () => {
  const report = {
    _id: '507f1f77bcf86cd799439013',
    location: {
      address: 'Mangrove Conservation Area, Kerala, India',
      latitude: 9.9312,
      longitude: 76.2673
    },
    mangroveHealth: 'Good',
    coveragePercentage: 85,
    speciesObserved: ['Rhizophora mucronata', 'Avicennia marina'],
    waterQuality: 'Moderate',
    threats: ['Plastic pollution', 'Boat traffic'],
    imageUrl: 'https://cloudinary.com/image123.jpg',
    createdAt: new Date()
  };

  const user = {
    firstName: 'Dr. Priya',
    lastName: 'Sharma',
    email: 'priya.sharma@example.com'
  };

  try {
    await sendMangroveMonitoringEmail(report, user);
    console.log('Mangrove monitoring notification sent successfully');
  } catch (error) {
    console.error('Failed to send mangrove monitoring notification:', error);
  }
};

/**
 * Example: Send conservation activity notification
 */
const exampleConservationActivity = async () => {
  const activity = {
    _id: '507f1f77bcf86cd799439014',
    title: 'Weekend Mangrove Cleanup & Planting',
    description: 'Join our community effort to clean up the coastline and plant new mangrove saplings',
    dateTime: new Date('2024-02-10T09:00:00Z'),
    location: {
      address: 'Mangrove Forest, Goa, India'
    },
    duration: '4 hours',
    maxParticipants: 50
  };

  const organizer = {
    firstName: 'Raj',
    lastName: 'Patel',
    email: 'raj.patel@ngo.org'
  };

  const recipients = [
    'volunteer1@example.com',
    'volunteer2@example.com',
    'community.group@example.com'
  ];

  try {
    await sendConservationActivityEmail(activity, organizer, recipients);
    console.log('Conservation activity notification sent successfully');
  } catch (error) {
    console.error('Failed to send conservation activity notification:', error);
  }
};

// Export examples for reference (don't call these directly)
module.exports = {
  exampleWelcomeEmail,
  exampleDirectMessage,
  exampleBulkEmail,
  exampleIncidentStatusUpdate,
  exampleAchievementNotification,
  exampleEmergencyAlert,
  exampleWeeklyDigest,
  exampleMangroveMonitoring,
  exampleConservationActivity
};

/**
 * Usage Instructions:
 * 
 * 1. Set up your environment variables:
 *    - EMAIL_SERVICE=gmail
 *    - EMAIL_USER=notifications@mangrove-watch.org
 *    - EMAIL_PASS=your-app-password-here
 *    - ADMIN_EMAIL=admin@mangrove-watch.org
 * 
 * 2. Use the email service functions in your controllers:
 *    - Import the functions from '../services/emailService'
 *    - Call them with appropriate data objects
 * 
 * 3. API endpoints are available in emailController.js:
 *    - POST /api/email/direct - Send direct message to user
 *    - POST /api/email/bulk - Send bulk emails
 *    - POST /api/email/monitoring - Notify about mangrove monitoring
 *    - POST /api/email/activity - Notify about conservation activities
 *    - POST /api/email/incident-status - Update incident status
 *    - POST /api/email/emergency - Send emergency alerts
 * 
 * 4. Example API request:
 *    POST /api/email/direct
 *    {
 *      "recipientEmail": "user@example.com",
 *      "subject": "Your Mangrove Report Update",
 *      "message": "Thank you for your valuable contribution...",
 *      "options": {
 *        "actionButton": "View Details",
 *        "actionUrl": "https://mangrove-watch.org/reports/123"
 *      }
 *    }
 */
