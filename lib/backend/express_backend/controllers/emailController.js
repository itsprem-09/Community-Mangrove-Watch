const { validationResult } = require('express-validator');
const {
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
  sendEmail
} = require('../services/emailService');
const { asyncHandler } = require('../utils/asyncHandler');

/**
 * Test email configuration
 */
const testEmail = asyncHandler(async (req, res) => {
  try {
    const isValid = await testEmailConfiguration();
    
    if (isValid) {
      res.json({
        success: true,
        message: 'Email configuration is valid and working'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Email configuration test failed'
      });
    }
  } catch (error) {
    console.error('Email test error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to test email configuration',
      error: error.message
    });
  }
});

/**
 * Send test email to verify setup
 */
const sendTestEmail = asyncHandler(async (req, res) => {
  try {
    const { to, subject, message } = req.body;
    
    if (!to || !subject || !message) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: to, subject, message'
      });
    }

    const mailOptions = {
      from: process.env.EMAIL_USER || 'notifications@mangrove-watch.org',
      to: to,
      subject: subject,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
          <h2 style="color: #4a7c59; text-align: center;">Test Email</h2>
          <p>${message}</p>
          <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
            This is a test email from Mangrove Watch backend system.
          </p>
        </div>
      `
    };

    const result = await sendEmail(mailOptions);
    
    if (result) {
      res.json({
        success: true,
        message: 'Test email sent successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send test email'
      });
    }
  } catch (error) {
    console.error('Send test email error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send test email',
      error: error.message
    });
  }
});

/**
 * Send member registration notification
 */
const notifyMemberRegistration = asyncHandler(async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const memberData = req.body;
    const result = await sendMemberRegistrationEmail(memberData);
    
    if (result) {
      res.json({
        success: true,
        message: 'Member registration notification sent successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send member registration notification'
      });
    }
  } catch (error) {
    console.error('Member registration notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send member registration notification',
      error: error.message
    });
  }
});


/**
 * Send incident report notification
 */
const notifyIncidentReport = asyncHandler(async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { incident, user } = req.body;
    const result = await sendIncidentReportEmail(incident, user);
    
    if (result) {
      res.json({
        success: true,
        message: 'Incident report notification sent successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send incident report notification'
      });
    }
  } catch (error) {
    console.error('Incident report notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send incident report notification',
      error: error.message
    });
  }
});

/**
 * Send welcome email to user
 */
const sendUserWelcomeEmail = asyncHandler(async (req, res) => {
  try {
    const userData = req.body;
    const result = await sendWelcomeEmail(userData);
    
    if (result) {
      res.json({
        success: true,
        message: 'Welcome email sent successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send welcome email'
      });
    }
  } catch (error) {
    console.error('Welcome email error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send welcome email',
      error: error.message
    });
  }
});

/**
 * Send system alert
 */
const sendAlert = asyncHandler(async (req, res) => {
  try {
    const { alertType, message, data } = req.body;
    
    if (!alertType || !message) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: alertType, message'
      });
    }

    const result = await sendSystemAlert(alertType, message, data);
    
    if (result) {
      res.json({
        success: true,
        message: 'System alert sent successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send system alert'
      });
    }
  } catch (error) {
    console.error('System alert error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send system alert',
      error: error.message
    });
  }
});

/**
 * Send direct message to user
 */
const sendDirectMessage = asyncHandler(async (req, res) => {
  try {
    const { recipientEmail, subject, message, options } = req.body;
    
    if (!recipientEmail || !subject || !message) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: recipientEmail, subject, message'
      });
    }

    const result = await sendDirectUserMessage(recipientEmail, subject, message, options || {});
    
    if (result) {
      res.json({
        success: true,
        message: 'Direct message sent successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send direct message'
      });
    }
  } catch (error) {
    console.error('Direct message error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send direct message',
      error: error.message
    });
  }
});

/**
 * Send bulk emails to multiple users
 */
const sendBulkMessages = asyncHandler(async (req, res) => {
  try {
    const { recipients, subject, message, options } = req.body;
    
    if (!recipients || !Array.isArray(recipients) || recipients.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Recipients must be a non-empty array of email addresses'
      });
    }
    
    if (!subject || !message) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: subject, message'
      });
    }

    const results = await sendBulkEmails(recipients, subject, message, options || {});
    const successCount = results.filter(r => r.success).length;
    
    res.json({
      success: true,
      message: `Bulk emails sent: ${successCount}/${recipients.length} successful`,
      results: results
    });
  } catch (error) {
    console.error('Bulk email error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send bulk emails',
      error: error.message
    });
  }
});

/**
 * Send mangrove monitoring notification
 */
const notifyMangroveMonitoring = asyncHandler(async (req, res) => {
  try {
    const { report, user } = req.body;
    
    if (!report || !user) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: report, user'
      });
    }

    const result = await sendMangroveMonitoringEmail(report, user);
    
    if (result) {
      res.json({
        success: true,
        message: 'Mangrove monitoring notification sent successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send mangrove monitoring notification'
      });
    }
  } catch (error) {
    console.error('Mangrove monitoring notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send mangrove monitoring notification',
      error: error.message
    });
  }
});

/**
 * Send conservation activity notification
 */
const notifyConservationActivity = asyncHandler(async (req, res) => {
  try {
    const { activity, organizer, recipients } = req.body;
    
    if (!activity || !organizer) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: activity, organizer'
      });
    }

    const result = await sendConservationActivityEmail(activity, organizer, recipients || []);
    
    if (result) {
      res.json({
        success: true,
        message: 'Conservation activity notification sent successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send conservation activity notification'
      });
    }
  } catch (error) {
    console.error('Conservation activity notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send conservation activity notification',
      error: error.message
    });
  }
});

/**
 * Send incident status update to user
 */
const updateIncidentStatus = asyncHandler(async (req, res) => {
  try {
    const { incident, status, userEmail, adminMessage } = req.body;
    
    if (!incident || !status || !userEmail) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: incident, status, userEmail'
      });
    }

    const result = await sendIncidentStatusUpdate(incident, status, userEmail, adminMessage || '');
    
    if (result) {
      res.json({
        success: true,
        message: 'Incident status update sent successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send incident status update'
      });
    }
  } catch (error) {
    console.error('Incident status update error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send incident status update',
      error: error.message
    });
  }
});

/**
 * Send emergency alert
 */
const sendEmergencyNotification = asyncHandler(async (req, res) => {
  try {
    const { alert, location, recipients } = req.body;
    
    if (!alert || !location) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: alert, location'
      });
    }

    const result = await sendEmergencyAlert(alert, location, recipients || []);
    
    if (result) {
      res.json({
        success: true,
        message: 'Emergency alert sent successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send emergency alert'
      });
    }
  } catch (error) {
    console.error('Emergency alert error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send emergency alert',
      error: error.message
    });
  }
});

module.exports = {
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
};
