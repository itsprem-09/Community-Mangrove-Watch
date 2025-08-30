/**
 * Email templates for various notifications
 */

/**
 * Member registration email template
 * @param {Object} member - Member data
 * @returns {Object} - Email content with subject and HTML
 */
const memberRegistrationTemplate = (member) => ({
  subject: `New Member Registration: ${member.name}`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #4a7c59; text-align: center;">New Member Registration</h2>
      <p>A new member has registered with the following details:</p>
      
      <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <p><strong>Name:</strong> ${member.name}</p>
        <p><strong>Application ID:</strong> ${member.applicationId || 'Not generated'}</p>
        <p><strong>Phone Number:</strong> ${member.phoneNumber || member.mobile || 'Not provided'}</p>
        <p><strong>Email:</strong> ${member.email || 'Not provided'}</p>
        <p><strong>Location:</strong> ${member.village || ''}, ${member.district || ''}, ${member.state || ''}</p>
        <p><strong>Member Type:</strong> ${member.membershipType || 'General Member'}</p>
        <p><strong>Registration Date:</strong> ${new Date(member.createdAt).toLocaleString()}</p>
      </div>
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrovewatch.org/admin'}" 
          style="background-color: #4a7c59; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          View in Admin Panel
        </a>
      </div>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        This is an automated notification from Mangrove Watch Registration System.
      </p>
    </div>
  `
});


/**
 * Incident report notification email template
 * @param {Object} incident - Incident data
 * @param {Object} user - User who reported the incident
 * @returns {Object} - Email content with subject and HTML
 */
const incidentReportTemplate = (incident, user) => ({
  subject: `New Incident Report: ${incident.title || 'Environmental Incident'}`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #d9534f; text-align: center;">New Environmental Incident Reported</h2>
      <p>A new environmental incident has been reported through the Mangrove Watch app:</p>
      
      <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <p><strong>Incident ID:</strong> ${incident._id || 'Not generated'}</p>
        <p><strong>Title:</strong> ${incident.title || 'Environmental Incident'}</p>
        <p><strong>Description:</strong> ${incident.description || 'Not provided'}</p>
        <p><strong>Severity:</strong> ${incident.severity || 'Not specified'}</p>
        <p><strong>Location:</strong> ${incident.location?.address || 'Not provided'}</p>
        <p><strong>Coordinates:</strong> ${incident.location?.latitude || 'N/A'}, ${incident.location?.longitude || 'N/A'}</p>
        <p><strong>Reported By:</strong> ${user?.firstName} ${user?.lastName} (${user?.email})</p>
        <p><strong>Report Date:</strong> ${new Date(incident.createdAt).toLocaleString()}</p>
        ${incident.imageUrl ? `<p><strong>Image:</strong> <a href="${incident.imageUrl}">View Image</a></p>` : ''}
      </div>
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrovewatch.org/admin'}" 
          style="background-color: #d9534f; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          View Incident Details
        </a>
      </div>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        This is an automated notification from Mangrove Watch Incident Reporting System.
      </p>
    </div>
  `
});

/**
 * Upload notification email template
 * @param {Object} upload - Upload data
 * @param {Object} user - User who uploaded
 * @returns {Object} - Email content with subject and HTML
 */
const uploadNotificationTemplate = (upload, user) => ({
  subject: `New Upload: ${upload.uploadType} by ${user.firstName} ${user.lastName}`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #4a7c59; text-align: center;">New File Upload</h2>
      <p>A new file has been uploaded to the Mangrove Watch system:</p>
      
      <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <p><strong>Upload ID:</strong> ${upload._id}</p>
        <p><strong>File Name:</strong> ${upload.originalName}</p>
        <p><strong>Upload Type:</strong> ${upload.uploadType}</p>
        <p><strong>File Size:</strong> ${upload.formattedSize || (upload.size / 1024 / 1024).toFixed(2) + ' MB'}</p>
        <p><strong>Uploaded By:</strong> ${user.firstName} ${user.lastName} (${user.email})</p>
        <p><strong>Upload Date:</strong> ${new Date(upload.createdAt).toLocaleString()}</p>
        ${upload.metadata?.description ? `<p><strong>Description:</strong> ${upload.metadata.description}</p>` : ''}
        ${upload.cloudinary?.secureUrl ? `<p><strong>Image:</strong> <a href="${upload.cloudinary.secureUrl}">View Image</a></p>` : ''}
      </div>
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrovewatch.org/admin'}" 
          style="background-color: #4a7c59; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          View Upload Details
        </a>
      </div>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        This is an automated notification from Mangrove Watch Upload System.
      </p>
    </div>
  `
});

/**
 * Welcome email template for new users
 * @param {Object} user - User data
 * @returns {Object} - Email content with subject and HTML
 */
const welcomeEmailTemplate = (user) => ({
  subject: `Welcome to Mangrove Watch, ${user.firstName}!`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #4a7c59; text-align: center;">Welcome to Mangrove Watch!</h2>
      <p>Dear ${user.firstName} ${user.lastName},</p>
      
      <p>Thank you for joining the Mangrove Watch community! We're excited to have you as part of our mission to protect and monitor mangrove ecosystems.</p>
      
      <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <h3 style="color: #4a7c59;">Your Account Details:</h3>
        <p><strong>Username:</strong> ${user.username}</p>
        <p><strong>Email:</strong> ${user.email}</p>
        <p><strong>Registration Date:</strong> ${new Date(user.createdAt).toLocaleString()}</p>
      </div>
      
      <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <h3 style="color: #4a7c59;">What's Next?</h3>
        <ul>
          <li>Download the Mangrove Watch mobile app</li>
          <li>Start reporting environmental incidents</li>
          <li>Upload images for mangrove monitoring</li>
          <li>Join our community of environmental guardians</li>
        </ul>
      </div>
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrovewatch.org'}" 
          style="background-color: #4a7c59; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          Get Started
        </a>
      </div>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        This is an automated welcome email from Mangrove Watch. If you didn't create this account, please contact our support team.
      </p>
    </div>
  `
});

/**
 * Password reset email template
 * @param {Object} user - User data
 * @param {String} resetToken - Password reset token
 * @returns {Object} - Email content with subject and HTML
 */
const passwordResetTemplate = (user, resetToken) => ({
  subject: 'Password Reset Request - Mangrove Watch',
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #4a7c59; text-align: center;">Password Reset Request</h2>
      <p>Dear ${user.firstName} ${user.lastName},</p>
      
      <p>You have requested to reset your password for your Mangrove Watch account. Click the button below to reset your password:</p>
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrovewatch.org'}/reset-password?token=${resetToken}" 
          style="background-color: #4a7c59; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
          Reset Password
        </a>
      </div>
      
      <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin-top: 20px; border-left: 4px solid #ffc107;">
        <p style="margin: 0;"><strong>Security Notice:</strong></p>
        <ul style="margin: 10px 0 0 20px;">
          <li>This link will expire in 24 hours</li>
          <li>If you didn't request this reset, please ignore this email</li>
          <li>Your password will remain unchanged unless you complete the reset process</li>
        </ul>
      </div>
      
      <p style="margin-top: 20px;">If the button doesn't work, copy and paste this link into your browser:</p>
      <p style="word-break: break-all; color: #4a7c59;">${process.env.ADMIN_URL || 'https://mangrovewatch.org'}/reset-password?token=${resetToken}</p>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        This is an automated security email from Mangrove Watch. Do not reply to this email.
      </p>
    </div>
  `
});

/**
 * Analysis completion notification template
 * @param {Object} upload - Upload data with analysis results
 * @param {Object} user - User data
 * @returns {Object} - Email content with subject and HTML
 */
const analysisCompleteTemplate = (upload, user) => ({
  subject: `Analysis Complete: ${upload.originalName}`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #4a7c59; text-align: center;">Image Analysis Complete</h2>
      <p>Dear ${user.firstName} ${user.lastName},</p>
      
      <p>The analysis of your uploaded image has been completed. Here are the results:</p>
      
      <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <p><strong>File Name:</strong> ${upload.originalName}</p>
        <p><strong>Upload Date:</strong> ${new Date(upload.createdAt).toLocaleString()}</p>
        <p><strong>Analysis Date:</strong> ${new Date(upload.analysis?.processedAt).toLocaleString()}</p>
        <p><strong>Upload Type:</strong> ${upload.uploadType}</p>
        ${upload.cloudinary?.secureUrl ? `<p><strong>Image:</strong> <a href="${upload.cloudinary.secureUrl}">View Image</a></p>` : ''}
      </div>
      
      <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <h3 style="color: #4a7c59; margin-top: 0;">Analysis Results:</h3>
        <p>${upload.analysis?.results?.summary || 'Analysis results are available in your dashboard.'}</p>
      </div>
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrovewatch.org'}/dashboard" 
          style="background-color: #4a7c59; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          View Full Results
        </a>
      </div>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        This is an automated notification from Mangrove Watch Analysis System.
      </p>
    </div>
  `
});

/**
 * System alert email template
 * @param {String} alertType - Type of alert
 * @param {String} message - Alert message
 * @param {Object} data - Additional alert data
 * @returns {Object} - Email content with subject and HTML
 */
const systemAlertTemplate = (alertType, message, data = {}) => ({
  subject: `System Alert: ${alertType}`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #d9534f; text-align: center;">System Alert</h2>
      
      <div style="background-color: #f2dede; padding: 15px; border-radius: 5px; margin-top: 20px; border-left: 4px solid #d9534f;">
        <p><strong>Alert Type:</strong> ${alertType}</p>
        <p><strong>Message:</strong> ${message}</p>
        <p><strong>Timestamp:</strong> ${new Date().toLocaleString()}</p>
        ${data.details ? `<p><strong>Details:</strong> ${data.details}</p>` : ''}
      </div>
      
      ${data.action ? `
      <div style="margin-top: 20px; text-align: center;">
        <a href="${data.actionUrl || process.env.ADMIN_URL}" 
          style="background-color: #d9534f; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          ${data.action}
        </a>
      </div>
      ` : ''}
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        This is an automated system alert from Mangrove Watch. Please take appropriate action if required.
      </p>
    </div>
  `
});

/**
 * Mangrove monitoring report email template
 * @param {Object} report - Monitoring report data
 * @param {Object} user - User who submitted the report
 * @returns {Object} - Email content with subject and HTML
 */
const mangroveMonitoringTemplate = (report, user) => ({
  subject: `New Mangrove Monitoring Report: ${report.location?.address || 'Location Unknown'}`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #2e7d32; text-align: center;">🌿 New Mangrove Monitoring Report</h2>
      <p>A new mangrove monitoring report has been submitted through the Mangrove Watch app:</p>
      
      <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <p><strong>Report ID:</strong> ${report._id || 'Not generated'}</p>
        <p><strong>Location:</strong> ${report.location?.address || 'Not provided'}</p>
        <p><strong>Coordinates:</strong> ${report.location?.latitude || 'N/A'}, ${report.location?.longitude || 'N/A'}</p>
        <p><strong>Mangrove Health:</strong> ${report.mangroveHealth || 'Not assessed'}</p>
        <p><strong>Coverage Estimate:</strong> ${report.coveragePercentage || 'N/A'}%</p>
        <p><strong>Species Observed:</strong> ${report.speciesObserved?.join(', ') || 'Not specified'}</p>
        <p><strong>Water Quality:</strong> ${report.waterQuality || 'Not assessed'}</p>
        <p><strong>Threats Identified:</strong> ${report.threats?.join(', ') || 'None reported'}</p>
        <p><strong>Reported By:</strong> ${user?.firstName} ${user?.lastName} (${user?.email})</p>
        <p><strong>Report Date:</strong> ${new Date(report.createdAt).toLocaleString()}</p>
        ${report.imageUrl ? `<p><strong>Images:</strong> <a href="${report.imageUrl}">View Images</a></p>` : ''}
      </div>
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrove-watch.org/admin'}" 
          style="background-color: #2e7d32; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          View Report Details
        </a>
      </div>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        This is an automated notification from Mangrove Watch Monitoring System.
      </p>
    </div>
  `
});

/**
 * Conservation activity notification template
 * @param {Object} activity - Activity data
 * @param {Object} user - User who organized the activity
 * @returns {Object} - Email content with subject and HTML
 */
const conservationActivityTemplate = (activity, user) => ({
  subject: `New Conservation Activity: ${activity.title}`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #2e7d32; text-align: center;">🌱 New Conservation Activity</h2>
      <p>A new conservation activity has been organized in your area:</p>
      
      <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <p><strong>Activity:</strong> ${activity.title}</p>
        <p><strong>Description:</strong> ${activity.description || 'Not provided'}</p>
        <p><strong>Date & Time:</strong> ${new Date(activity.dateTime).toLocaleString()}</p>
        <p><strong>Location:</strong> ${activity.location?.address || 'Not provided'}</p>
        <p><strong>Duration:</strong> ${activity.duration || 'Not specified'}</p>
        <p><strong>Participants Needed:</strong> ${activity.maxParticipants || 'Unlimited'}</p>
        <p><strong>Organized By:</strong> ${user?.firstName} ${user?.lastName}</p>
        <p><strong>Contact:</strong> ${user?.email || 'Contact through app'}</p>
      </div>
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrove-watch.org'}/activities/${activity._id}" 
          style="background-color: #2e7d32; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          Join Activity
        </a>
      </div>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        This is an automated notification from Mangrove Watch Community Activities.
      </p>
    </div>
  `
});

/**
 * User notification for incident status update
 * @param {Object} incident - Incident data
 * @param {String} status - New status
 * @param {String} adminMessage - Message from admin
 * @returns {Object} - Email content with subject and HTML
 */
const incidentStatusUpdateTemplate = (incident, status, adminMessage = '') => ({
  subject: `Incident Report Update: ${incident.title || 'Your Report'}`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #4a7c59; text-align: center;">Incident Report Status Update</h2>
      <p>Your incident report has been updated:</p>
      
      <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <p><strong>Incident:</strong> ${incident.title || 'Environmental Incident'}</p>
        <p><strong>Report ID:</strong> ${incident._id}</p>
        <p><strong>New Status:</strong> <span style="color: ${status === 'verified' ? '#28a745' : status === 'rejected' ? '#dc3545' : '#ffc107'}; font-weight: bold;">${status.toUpperCase()}</span></p>
        <p><strong>Location:</strong> ${incident.location?.address || 'Not provided'}</p>
        <p><strong>Original Report Date:</strong> ${new Date(incident.createdAt).toLocaleString()}</p>
        <p><strong>Last Updated:</strong> ${new Date().toLocaleString()}</p>
      </div>
      
      ${adminMessage ? `
      <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <h3 style="color: #2e7d32; margin-top: 0;">Admin Message:</h3>
        <p>${adminMessage}</p>
      </div>
      ` : ''}
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrove-watch.org'}/incidents/${incident._id}" 
          style="background-color: #4a7c59; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          View Report Details
        </a>
      </div>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        Thank you for your contribution to mangrove conservation! This is an automated notification from Mangrove Watch.
      </p>
    </div>
  `
});

/**
 * Weekly mangrove health digest template
 * @param {Object} digestData - Weekly digest data
 * @param {Object} user - User receiving the digest
 * @returns {Object} - Email content with subject and HTML
 */
const weeklyDigestTemplate = (digestData, user) => ({
  subject: `Weekly Mangrove Watch Digest - ${new Date().toLocaleDateString()}`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #2e7d32; text-align: center;">🌿 Weekly Mangrove Watch Digest</h2>
      <p>Dear ${user.firstName},</p>
      
      <p>Here's your weekly summary of mangrove conservation activities in your area:</p>
      
      <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <h3 style="color: #2e7d32; margin-top: 0;">This Week's Impact</h3>
        <p><strong>📍 Incidents Reported:</strong> ${digestData.newIncidents || 0}</p>
        <p><strong>📊 Reports Verified:</strong> ${digestData.verifiedReports || 0}</p>
        <p><strong>🏆 Community Points Earned:</strong> ${digestData.communityPoints || 0}</p>
        <p><strong>🌱 Conservation Activities:</strong> ${digestData.activities || 0}</p>
        <p><strong>👥 New Community Members:</strong> ${digestData.newMembers || 0}</p>
      </div>
      
      ${digestData.featuredActivity ? `
      <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin-top: 20px; border-left: 4px solid #ffc107;">
        <h3 style="color: #856404; margin-top: 0;">🌟 Featured Activity</h3>
        <p><strong>${digestData.featuredActivity.title}</strong></p>
        <p>${digestData.featuredActivity.description}</p>
        <p><small>Location: ${digestData.featuredActivity.location}</small></p>
      </div>
      ` : ''}
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrove-watch.org'}/dashboard" 
          style="background-color: #2e7d32; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-right: 10px;">
          View Dashboard
        </a>
        <a href="${process.env.ADMIN_URL || 'https://mangrove-watch.org'}/report" 
          style="background-color: #4a7c59; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          Report Incident
        </a>
      </div>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        Together, we're making a difference! This is your weekly digest from Mangrove Watch.
      </p>
    </div>
  `
});

/**
 * User achievement notification template
 * @param {Object} achievement - Achievement data
 * @param {Object} user - User who earned the achievement
 * @returns {Object} - Email content with subject and HTML
 */
const achievementUnlockedTemplate = (achievement, user) => ({
  subject: `🏆 Achievement Unlocked: ${achievement.title}`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #ff6f00; text-align: center;">🏆 Achievement Unlocked!</h2>
      <p>Congratulations ${user.firstName}!</p>
      
      <div style="background-color: #fff8e1; padding: 20px; border-radius: 5px; margin-top: 20px; text-align: center; border: 2px solid #ff6f00;">
        <div style="font-size: 48px; margin-bottom: 10px;">${achievement.icon || '🌿'}</div>
        <h3 style="color: #ff6f00; margin: 10px 0;">${achievement.title}</h3>
        <p style="font-style: italic; margin: 0;">${achievement.description}</p>
      </div>
      
      <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin-top: 20px;">
        <h3 style="color: #2e7d32; margin-top: 0;">Your Progress</h3>
        <p><strong>Points Earned:</strong> +${achievement.points || 0}</p>
        <p><strong>Total Points:</strong> ${user.totalPoints || 0}</p>
        <p><strong>Community Rank:</strong> ${user.rank || 'Guardian'}</p>
        <p><strong>Reports Submitted:</strong> ${user.reportsCount || 0}</p>
      </div>
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrove-watch.org'}/profile" 
          style="background-color: #ff6f00; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          View Profile
        </a>
      </div>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        Keep up the great work protecting our mangroves! This is an automated notification from Mangrove Watch.
      </p>
    </div>
  `
});

/**
 * Emergency alert template for critical mangrove threats
 * @param {Object} alert - Alert data
 * @param {Object} location - Location data
 * @returns {Object} - Email content with subject and HTML
 */
const emergencyAlertTemplate = (alert, location) => ({
  subject: `🚨 URGENT: Mangrove Emergency Alert - ${location.name || 'Area Alert'}`,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #dc3545; border-radius: 5px;">
      <h2 style="color: #dc3545; text-align: center;">🚨 EMERGENCY MANGROVE ALERT</h2>
      
      <div style="background-color: #f8d7da; padding: 20px; border-radius: 5px; margin-top: 20px; border: 2px solid #dc3545;">
        <h3 style="color: #721c24; margin-top: 0; text-align: center;">IMMEDIATE ACTION REQUIRED</h3>
        <p><strong>Alert Type:</strong> ${alert.type}</p>
        <p><strong>Threat Level:</strong> <span style="color: #dc3545; font-weight: bold;">${alert.severity || 'HIGH'}</span></p>
        <p><strong>Location:</strong> ${location.address || location.name}</p>
        <p><strong>Description:</strong> ${alert.description}</p>
        <p><strong>Time:</strong> ${new Date(alert.timestamp).toLocaleString()}</p>
      </div>
      
      <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin-top: 20px; border-left: 4px solid #ffc107;">
        <h3 style="color: #856404; margin-top: 0;">Recommended Actions:</h3>
        <ul style="margin: 10px 0 0 20px;">
          <li>Report to local environmental authorities</li>
          <li>Document evidence if safe to do so</li>
          <li>Contact emergency services if immediate danger</li>
          <li>Share this alert with local community</li>
        </ul>
      </div>
      
      <div style="margin-top: 20px; text-align: center;">
        <a href="${process.env.ADMIN_URL || 'https://mangrove-watch.org'}/emergency/${alert._id}" 
          style="background-color: #dc3545; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold;">
          VIEW EMERGENCY DETAILS
        </a>
      </div>
      
      <p style="margin-top: 30px; font-size: 12px; color: #777; text-align: center;">
        This is an urgent automated alert from Mangrove Watch Emergency System. Please take immediate action.
      </p>
    </div>
  `
});

/**
 * Direct user message template
 * @param {String} recipientEmail - User's email
 * @param {String} subject - Email subject
 * @param {String} message - Message content
 * @param {Object} options - Additional options
 * @returns {Object} - Email content with subject and HTML
 */
const directUserMessageTemplate = (recipientEmail, subject, message, options = {}) => ({
  subject: subject,
  html: `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <div style="text-align: center; margin-bottom: 20px;">
        <img src="${options.logoUrl || 'https://mangrove-watch.org/logo.png'}" alt="Mangrove Watch" style="max-height: 60px;">
        <h2 style="color: #2e7d32; margin: 10px 0;">Mangrove Watch</h2>
      </div>
      
      <div style="background-color: #f9f9f9; padding: 20px; border-radius: 5px; margin-top: 20px;">
        ${message.split('\n').map(paragraph => `<p>${paragraph}</p>`).join('')}
      </div>
      
      ${options.actionButton ? `
      <div style="margin-top: 20px; text-align: center;">
        <a href="${options.actionUrl}" 
          style="background-color: #2e7d32; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          ${options.actionButton}
        </a>
      </div>
      ` : ''}
      
      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
        <p style="font-size: 12px; color: #777; text-align: center; margin: 0;">
          This email was sent to ${recipientEmail} by the Mangrove Watch team.<br>
          Together, we're protecting our mangrove ecosystems! 🌿
        </p>
      </div>
    </div>
  `
});

module.exports = {
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
};
