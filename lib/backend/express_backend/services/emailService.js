const nodemailer = require('nodemailer');
const asyncHandler = require('express-async-handler');
const {
  memberRegistrationTemplate,
  incidentReportTemplate,
  uploadNotificationTemplate,
  welcomeEmailTemplate,
  passwordResetTemplate,
  analysisCompleteTemplate,
  systemAlertTemplate,
  mangroveMonitoringTemplate,
  conservationActivityTemplate,
  incidentStatusUpdateTemplate,
  weeklyDigestTemplate,
  achievementUnlockedTemplate,
  emergencyAlertTemplate,
  directUserMessageTemplate
} = require('../utils/emailTemplates');

// Configure email transporter
const transporter = nodemailer.createTransport({
  service: process.env.EMAIL_SERVICE || 'gmail',
  auth: {
    user: process.env.EMAIL_USER || 'notifications@mangrove-watch.org',
    pass: process.env.EMAIL_PASS || 'your-app-password-here'
  }
});

// Admin email recipients
const ADMIN_EMAILS = process.env.ADMIN_EMAIL ? 
  [process.env.ADMIN_EMAIL] : 
  ['admin@mangrovewatch.org'];

// From email address
const FROM_EMAIL = process.env.EMAIL_USER || 'notifications@mangrove-watch.org';

/**
 * Send email using the configured transporter
 * @param {Object} mailOptions - Email options
 * @returns {Promise<Boolean>} - Success status
 */
const sendEmail = async (mailOptions) => {
  try {
    await transporter.sendMail(mailOptions);
    console.log('Email sent successfully to:', mailOptions.to);
    return true;
  } catch (error) {
    console.error('Error sending email:', error);
    return false;
  }
};

/**
 * Send member registration notification
 * @param {Object} member - Member data
 * @returns {Promise<Boolean>} - Success status
 */
const sendMemberRegistrationEmail = asyncHandler(async (member) => {
  try {
    const emailContent = memberRegistrationTemplate(member);
    const mailOptions = {
      from: FROM_EMAIL,
      to: ADMIN_EMAILS,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Member registration email sent successfully');
    }
    return result;
  } catch (error) {
    console.error('Error sending member registration email:', error);
    return false;
  }
});


/**
 * Send incident report notification
 * @param {Object} incident - Incident data
 * @param {Object} user - User who reported the incident
 * @returns {Promise<Boolean>} - Success status
 */
const sendIncidentReportEmail = asyncHandler(async (incident, user) => {
  try {
    const emailContent = incidentReportTemplate(incident, user);
    const mailOptions = {
      from: FROM_EMAIL,
      to: ADMIN_EMAILS,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Incident report email sent successfully');
    }
    return result;
  } catch (error) {
    console.error('Error sending incident report email:', error);
    return false;
  }
});

/**
 * Send upload notification to admins
 * @param {Object} upload - Upload data
 * @param {Object} user - User who uploaded
 * @returns {Promise<Boolean>} - Success status
 */
const sendUploadNotificationEmail = asyncHandler(async (upload, user) => {
  try {
    const emailContent = uploadNotificationTemplate(upload, user);
    const mailOptions = {
      from: FROM_EMAIL,
      to: ADMIN_EMAILS,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Upload notification email sent successfully');
    }
    return result;
  } catch (error) {
    console.error('Error sending upload notification email:', error);
    return false;
  }
});

/**
 * Send welcome email to new user
 * @param {Object} user - User data
 * @returns {Promise<Boolean>} - Success status
 */
const sendWelcomeEmail = asyncHandler(async (user) => {
  try {
    const emailContent = welcomeEmailTemplate(user);
    const mailOptions = {
      from: FROM_EMAIL,
      to: user.email,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Welcome email sent successfully to:', user.email);
    }
    return result;
  } catch (error) {
    console.error('Error sending welcome email:', error);
    return false;
  }
});

/**
 * Send password reset email
 * @param {Object} user - User data
 * @param {String} resetToken - Password reset token
 * @returns {Promise<Boolean>} - Success status
 */
const sendPasswordResetEmail = asyncHandler(async (user, resetToken) => {
  try {
    const emailContent = passwordResetTemplate(user, resetToken);
    const mailOptions = {
      from: FROM_EMAIL,
      to: user.email,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Password reset email sent successfully to:', user.email);
    }
    return result;
  } catch (error) {
    console.error('Error sending password reset email:', error);
    return false;
  }
});

/**
 * Send analysis completion notification to user
 * @param {Object} upload - Upload data with analysis results
 * @param {Object} user - User data
 * @returns {Promise<Boolean>} - Success status
 */
const sendAnalysisCompleteEmail = asyncHandler(async (upload, user) => {
  try {
    const emailContent = analysisCompleteTemplate(upload, user);
    const mailOptions = {
      from: FROM_EMAIL,
      to: user.email,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Analysis completion email sent successfully to:', user.email);
    }
    return result;
  } catch (error) {
    console.error('Error sending analysis completion email:', error);
    return false;
  }
});

/**
 * Send system alert to admins
 * @param {String} alertType - Type of alert
 * @param {String} message - Alert message
 * @param {Object} data - Additional alert data
 * @returns {Promise<Boolean>} - Success status
 */
const sendSystemAlert = asyncHandler(async (alertType, message, data = {}) => {
  try {
    const emailContent = systemAlertTemplate(alertType, message, data);
    const mailOptions = {
      from: FROM_EMAIL,
      to: ADMIN_EMAILS,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('System alert email sent successfully');
    }
    return result;
  } catch (error) {
    console.error('Error sending system alert email:', error);
    return false;
  }
});

/**
 * Send mangrove monitoring report notification
 * @param {Object} report - Monitoring report data
 * @param {Object} user - User who submitted the report
 * @returns {Promise<Boolean>} - Success status
 */
const sendMangroveMonitoringEmail = asyncHandler(async (report, user) => {
  try {
    const emailContent = mangroveMonitoringTemplate(report, user);
    const mailOptions = {
      from: FROM_EMAIL,
      to: ADMIN_EMAILS,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Mangrove monitoring email sent successfully');
    }
    return result;
  } catch (error) {
    console.error('Error sending mangrove monitoring email:', error);
    return false;
  }
});

/**
 * Send conservation activity notification
 * @param {Object} activity - Activity data
 * @param {Object} organizer - User who organized the activity
 * @param {Array} recipients - List of user emails to notify
 * @returns {Promise<Boolean>} - Success status
 */
const sendConservationActivityEmail = asyncHandler(async (activity, organizer, recipients = []) => {
  try {
    const emailContent = conservationActivityTemplate(activity, organizer);
    const recipientList = recipients.length > 0 ? recipients : ADMIN_EMAILS;
    
    const mailOptions = {
      from: FROM_EMAIL,
      to: recipientList,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Conservation activity email sent successfully');
    }
    return result;
  } catch (error) {
    console.error('Error sending conservation activity email:', error);
    return false;
  }
});

/**
 * Send incident status update to user
 * @param {Object} incident - Incident data
 * @param {String} status - New status
 * @param {String} userEmail - User's email address
 * @param {String} adminMessage - Optional message from admin
 * @returns {Promise<Boolean>} - Success status
 */
const sendIncidentStatusUpdate = asyncHandler(async (incident, status, userEmail, adminMessage = '') => {
  try {
    const emailContent = incidentStatusUpdateTemplate(incident, status, adminMessage);
    const mailOptions = {
      from: FROM_EMAIL,
      to: userEmail,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Incident status update email sent successfully to:', userEmail);
    }
    return result;
  } catch (error) {
    console.error('Error sending incident status update email:', error);
    return false;
  }
});

/**
 * Send weekly digest to user
 * @param {Object} digestData - Weekly digest data
 * @param {Object} user - User data
 * @returns {Promise<Boolean>} - Success status
 */
const sendWeeklyDigest = asyncHandler(async (digestData, user) => {
  try {
    const emailContent = weeklyDigestTemplate(digestData, user);
    const mailOptions = {
      from: FROM_EMAIL,
      to: user.email,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Weekly digest email sent successfully to:', user.email);
    }
    return result;
  } catch (error) {
    console.error('Error sending weekly digest email:', error);
    return false;
  }
});

/**
 * Send achievement notification to user
 * @param {Object} achievement - Achievement data
 * @param {Object} user - User who earned the achievement
 * @returns {Promise<Boolean>} - Success status
 */
const sendAchievementNotification = asyncHandler(async (achievement, user) => {
  try {
    const emailContent = achievementUnlockedTemplate(achievement, user);
    const mailOptions = {
      from: FROM_EMAIL,
      to: user.email,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Achievement notification email sent successfully to:', user.email);
    }
    return result;
  } catch (error) {
    console.error('Error sending achievement notification email:', error);
    return false;
  }
});

/**
 * Send emergency alert to multiple recipients
 * @param {Object} alert - Alert data
 * @param {Object} location - Location data
 * @param {Array} recipients - List of email addresses
 * @returns {Promise<Boolean>} - Success status
 */
const sendEmergencyAlert = asyncHandler(async (alert, location, recipients = []) => {
  try {
    const emailContent = emergencyAlertTemplate(alert, location);
    const recipientList = recipients.length > 0 ? recipients : ADMIN_EMAILS;
    
    const mailOptions = {
      from: FROM_EMAIL,
      to: recipientList,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Emergency alert email sent successfully');
    }
    return result;
  } catch (error) {
    console.error('Error sending emergency alert email:', error);
    return false;
  }
});

/**
 * Send direct message to user
 * @param {String} recipientEmail - User's email address
 * @param {String} subject - Email subject
 * @param {String} message - Message content
 * @param {Object} options - Additional options (actionButton, actionUrl, logoUrl)
 * @returns {Promise<Boolean>} - Success status
 */
const sendDirectUserMessage = asyncHandler(async (recipientEmail, subject, message, options = {}) => {
  try {
    const emailContent = directUserMessageTemplate(recipientEmail, subject, message, options);
    const mailOptions = {
      from: FROM_EMAIL,
      to: recipientEmail,
      subject: emailContent.subject,
      html: emailContent.html
    };

    const result = await sendEmail(mailOptions);
    if (result) {
      console.log('Direct user message sent successfully to:', recipientEmail);
    }
    return result;
  } catch (error) {
    console.error('Error sending direct user message:', error);
    return false;
  }
});

/**
 * Send bulk emails to multiple users
 * @param {Array} recipients - Array of email addresses
 * @param {String} subject - Email subject
 * @param {String} message - Message content
 * @param {Object} options - Additional options
 * @returns {Promise<Array>} - Array of success status for each email
 */
const sendBulkEmails = asyncHandler(async (recipients, subject, message, options = {}) => {
  try {
    const results = [];
    
    for (const email of recipients) {
      const result = await sendDirectUserMessage(email, subject, message, options);
      results.push({ email, success: result });
      
      // Add small delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    console.log(`Bulk email sent to ${recipients.length} recipients`);
    return results;
  } catch (error) {
    console.error('Error sending bulk emails:', error);
    return [];
  }
});

/**
 * Test email configuration
 * @returns {Promise<Boolean>} - Success status
 */
const testEmailConfiguration = async () => {
  try {
    await transporter.verify();
    console.log('Email configuration is valid');
    return true;
  } catch (error) {
    console.error('Email configuration error:', error);
    return false;
  }
};

module.exports = {
  sendEmail,
  sendMemberRegistrationEmail,
  sendIncidentReportEmail,
  sendUploadNotificationEmail,
  sendWelcomeEmail,
  sendPasswordResetEmail,
  sendAnalysisCompleteEmail,
  sendSystemAlert,
  sendMangroveMonitoringEmail,
  sendConservationActivityEmail,
  sendIncidentStatusUpdate,
  sendWeeklyDigest,
  sendAchievementNotification,
  sendEmergencyAlert,
  sendDirectUserMessage,
  sendBulkEmails,
  testEmailConfiguration,
  transporter
};
