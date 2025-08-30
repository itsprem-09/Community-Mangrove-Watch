# Mangrove Watch Express Backend

A modular Express.js backend server with Cloudinary integration for image uploads, MongoDB for data persistence, and Nodemailer for email notifications.

## 🏗️ Project Structure

```
express-backend/
├── config/
│   ├── cloudinary.js      # Cloudinary configuration and utilities
│   ├── constants.js       # Application constants
│   └── database.js        # MongoDB connection setup
├── controllers/
│   ├── emailController.js # Email-related business logic
│   └── uploadController.js # Upload-related business logic
├── middleware/
│   ├── auth.js            # JWT authentication middleware
│   └── upload.js          # Multer configuration for file uploads
├── models/
│   ├── Upload.js          # Upload metadata model
│   └── User.js            # User model with authentication
├── routes/
│   ├── emailRoutes.js     # Email-related API routes
│   ├── healthRoutes.js    # Health check routes
│   └── uploadRoutes.js    # Upload-related API routes
├── scripts/
│   └── setup.js           # Environment setup script
├── services/
│   ├── emailService.js    # Email service with Nodemailer
│   └── uploadService.js   # Upload business logic and Cloudinary integration
├── utils/
│   ├── asyncHandler.js    # Async error handling utility
│   ├── emailTemplates.js  # Email templates for notifications
│   └── validation.js      # Request validation utilities
├── .env.example           # Environment variables template
├── package.json           # Dependencies and scripts
└── server.js              # Main application entry point
```

## 🚀 Setup Instructions

### Quick Setup

**Run the automated setup script:**
```bash
npm run setup
```

This will:
- Copy `.env.example` to `.env`
- Install dependencies if needed
- Create necessary directories
- Display configuration requirements

### Manual Setup

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   ```

3. **Configure environment variables in `.env`:**
   - Set up MongoDB connection string
   - Add Cloudinary credentials (cloud name, API key, API secret)
   - Configure SMTP settings for email notifications
   - Configure JWT secret
   - Set other required variables

4. **Start the server:**
   ```bash
   # Development mode with auto-reload
   npm run dev
   
   # Production mode
   npm start
   ```

## 🔧 Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `PORT` | Server port | No | 5000 |
| `NODE_ENV` | Environment mode | No | development |
| `MONGODB_URI` | MongoDB connection string | Yes | - |
| `JWT_SECRET` | JWT signing secret | Yes | - |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name | Yes | - |
| `CLOUDINARY_API_KEY` | Cloudinary API key | Yes | - |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret | Yes | - |
| `SMTP_HOST` | SMTP server host | Yes | smtp.gmail.com |
| `SMTP_PORT` | SMTP server port | Yes | 587 |
| `SMTP_SECURE` | Use SSL/TLS | No | false |
| `SMTP_USER` | SMTP username/email | Yes | - |
| `SMTP_PASS` | SMTP password/app password | Yes | - |
| `ADMIN_EMAIL` | Admin email for notifications | Yes | - |
| `FROM_EMAIL` | From email address | No | noreply@mangrovewatch.org |
| `SYSTEM_EMAIL` | System email address | No | system@mangrovewatch.org |
| `FRONTEND_URL` | Frontend application URL | No | http://localhost:3000 |
| `BACKEND_URL` | Backend application URL | No | http://localhost:5000 |
| `PYTHON_BACKEND_URL` | Python backend URL | No | http://localhost:8000 |
| `MAX_FILE_SIZE` | Maximum file size in bytes | No | 10485760 |
| `ALLOWED_FILE_TYPES` | Comma-separated allowed MIME types | No | image/jpeg,image/png,image/gif,image/webp |
| `CORS_ORIGINS` | CORS allowed origins | No | http://localhost:3000 |
| `SESSION_SECRET` | Session secret | Yes | - |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window in ms | No | 900000 |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | No | 100 |

## 📋 API Endpoints

### Upload Endpoints
- `POST /upload/incident-image` - Upload incident image
- `POST /upload/profile-image` - Upload profile image
- `GET /upload/user-uploads` - Get user's uploads (paginated)
- `GET /upload/:id` - Get specific upload by ID
- `PUT /upload/:id` - Update upload metadata
- `DELETE /upload/:id` - Delete upload

### Email Endpoints
- `POST /email/test` - Test email configuration
- `POST /email/member-registration` - Send member registration notification
- `POST /email/youth-registration` - Send youth registration notification
- `POST /email/nomination` - Send nomination notification
- `POST /email/incident-report` - Send incident report notification
- `POST /email/upload-notification` - Send upload notification
- `POST /email/welcome` - Send welcome email to user
- `POST /email/password-reset` - Send password reset email
- `POST /email/analysis-complete` - Send analysis completion notification
- `POST /email/system-alert` - Send system alert to admins

### Health Check
- `GET /health` - Server health status

### Image Optimization
- `GET /image/:publicId` - Get optimized image from Cloudinary

### Proxy
- `/api/*` - Proxied to Python backend

## 🔒 Authentication

All upload endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

## 📁 File Upload Features

- **Cloud Storage**: Images are stored in Cloudinary, not local filesystem
- **Database Metadata**: Upload metadata is stored in MongoDB
- **Image Optimization**: Automatic optimization and format conversion
- **Multiple Upload Types**: Support for incidents, profiles, and general uploads
- **File Validation**: Type and size validation
- **Security**: Rate limiting, CORS, XSS protection, and sanitization

## 📧 Email Service Features

- **Nodemailer Integration**: Professional email sending with SMTP support
- **Template System**: Comprehensive HTML email templates for all notification types
- **Async Processing**: Non-blocking email sending with error handling
- **Admin Notifications**: Automatic notifications for new registrations, uploads, and incidents
- **User Notifications**: Welcome emails, password resets, and analysis completion alerts
- **System Alerts**: Critical system notifications for administrators
- **Testing Support**: Built-in email configuration testing

### Supported Email Types
- Member registration notifications
- Youth program registration notifications
- Nomination notifications
- Incident report alerts
- Upload notifications
- Welcome emails for new users
- Password reset emails
- Analysis completion notifications
- System alerts and warnings

### Email Configuration

Configure SMTP settings in your `.env` file:
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_specific_password

ADMIN_EMAIL=admin@mangrovewatch.org
FROM_EMAIL=noreply@mangrovewatch.org
SYSTEM_EMAIL=system@mangrovewatch.org
```

**For Gmail users:**
1. Enable 2-factor authentication
2. Generate an app-specific password
3. Use the app password as `SMTP_PASS`

## 🖼️ Image Processing

The system uses Cloudinary for:
- Automatic image optimization
- Format conversion (WebP, AVIF when supported)
- Responsive image delivery
- Image transformations (resize, crop, etc.)
- CDN delivery for fast loading

## 📊 Database Models

### User Model
- Authentication with bcrypt
- Profile image integration
- Role-based access control

### Upload Model
- File metadata storage
- Cloudinary integration
- Analysis results tracking
- User association

## 🛠️ Development

### Available Scripts
- `npm run setup` - Run automated environment setup
- `npm run dev` - Start development server with auto-reload
- `npm start` - Start production server
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint issues automatically

### Testing
The backend includes comprehensive error handling and validation for:
- File upload validation
- Authentication verification
- Database operations
- Cloudinary integration
- Proxy functionality

## 🔧 Migration from Local Storage

The new system automatically handles:
- Image uploads to Cloudinary instead of local storage
- Metadata storage in MongoDB
- URL generation for cloud-hosted images
- Optimized image delivery

No manual migration is needed for new uploads. The system is backward compatible through the proxy functionality.
