# 🌿 Community Mangrove Watch

[![Flutter](https://img.shields.io/badge/Flutter-3.6.1+-02569B?logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.8+-3776AB?logo=python)](https://python.org)
[![Node.js](https://img.shields.io/badge/Node.js-16+-339933?logo=node.js)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-4.4+-47A248?logo=mongodb)](https://mongodb.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A comprehensive cross-platform mobile application built with Flutter that empowers communities to monitor, report, and protect mangrove ecosystems through AI-powered image analysis, satellite monitoring, and gamified conservation efforts.

> **Protecting Mangroves, One Report at a Time** 🌊

## 📱 Screenshots

*Coming Soon - App screenshots will be added here*

## ✨ Key Features

### 🚨 Community Reporting
- **Incident Documentation**: Report mangrove destruction, pollution, illegal activities, and environmental threats
- **Geotagged Evidence**: Capture location-aware photos with GPS coordinates
- **Real-time Submissions**: Instant incident reporting with offline capability
- **Photo Verification**: AI-powered image analysis to verify mangrove-related content

### 🤖 AI-Powered Analysis
- **Smart Image Recognition**: Google Gemini AI analyzes uploaded photos for mangrove identification
- **Satellite Monitoring**: Google Earth Engine integration for large-scale ecosystem monitoring
- **Predictive Analytics**: Machine learning models predict mangrove health trends
- **NDVI Analysis**: Vegetation health assessment using satellite data

### 🎮 Gamification & Engagement
- **Points System**: Earn points for verified reports and conservation activities
- **Achievement Badges**: Unlock badges for different types of contributions
- **Community Leaderboard**: Friendly competition to encourage participation
- **Progress Tracking**: Personal dashboard showing conservation impact

### 🗺️ Interactive Mapping
- **Real-time Heat Maps**: Visualize incident density across regions
- **Satellite Overlays**: Compare current vs. historical mangrove coverage
- **Cluster Visualization**: Group nearby incidents for better overview
- **Custom Map Layers**: Toggle between different data visualizations

### 👨‍💼 Admin & Verification
- **Admin Dashboard**: Comprehensive tools for NGOs and government agencies
- **Report Verification**: Multi-step verification process for incident authenticity
- **Data Analytics**: Detailed insights and reporting for conservation efforts
- **User Management**: Role-based access control and user administration

## 🏗️ Architecture Overview

### System Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │────│   Express.js     │────│   Cloudinary    │
│   (Frontend)    │    │   (File Server)  │    │  (Image Store)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │
         │              ┌──────────────────┐
         └──────────────│   Python FastAPI │
                        │   (AI Backend)   │
                        └──────────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                       │                        │
┌──────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   MongoDB    │    │  Google Earth    │    │   Google Gemini  │
│  (Database)  │    │    Engine        │    │   AI (Vision)    │
└──────────────┘    └──────────────────┘    └──────────────────┘
```

### Technology Stack

#### 📱 Frontend (Flutter)
- **Framework**: Flutter 3.6.1+ with Dart SDK
- **State Management**: BLoC pattern with Provider
- **Navigation**: GoRouter for declarative routing
- **UI**: Material Design with custom theming
- **Responsive Design**: ScreenUtil for cross-device compatibility
- **Local Storage**: Hive for offline data persistence
- **Networking**: HTTP/Dio for API communication

#### 🔧 Backend Services

**Python FastAPI Backend** (Port 8000)
- **Framework**: FastAPI with async/await support
- **AI/ML**: Google Gemini AI, scikit-learn, TensorFlow
- **Satellite Data**: Google Earth Engine integration
- **Authentication**: JWT tokens with secure password hashing
- **Database**: Motor (async MongoDB driver)

**Express.js Backend** (Port 5000)
- **Framework**: Express.js with security middleware
- **File Processing**: Multer with Cloudinary integration
- **Security**: Helmet, CORS, XSS protection, rate limiting
- **Validation**: Express-validator for input sanitization
- **Email**: Nodemailer for notifications

#### 🗄️ Database & Storage
- **Primary Database**: MongoDB for document storage
- **Image Storage**: Cloudinary for optimized image delivery
- **Local Cache**: Hive for offline Flutter data
- **Authentication**: JWT-based stateless authentication

#### 🌐 Third-Party Integrations
- **Google Earth Engine**: Satellite imagery and analysis
- **Google Gemini AI**: Advanced image recognition
- **Google Maps**: Interactive mapping and geocoding
- **Cloudinary**: Image optimization and CDN
- **Firebase**: Push notifications (optional)

## 📋 Prerequisites

Before setting up the project, ensure you have the following installed:

### Required Software
- **Flutter SDK**: Version 3.6.1 or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Python**: Version 3.8 or higher ([Download Python](https://python.org/downloads/))
- **Node.js**: Version 16 or higher ([Download Node.js](https://nodejs.org/))
- **MongoDB**: Local installation or cloud access ([MongoDB Community](https://www.mongodb.com/try/download/community))
- **Git**: For version control ([Download Git](https://git-scm.com/))

### Required API Keys & Accounts
1. **Google Earth Engine**: [Sign up for GEE](https://earthengine.google.com/signup/)
2. **Google Gemini AI**: [Get API key](https://makersuite.google.com/app/apikey)
3. **Google Maps API**: [Google Cloud Console](https://console.cloud.google.com/)
4. **Cloudinary Account**: [Sign up](https://cloudinary.com/users/register/free)
5. **MongoDB**: Local or [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)

### Verify Installation
```powershell
# Check Flutter
flutter doctor

# Check Python
python --version
pip --version

# Check Node.js
node --version
npm --version

# Check MongoDB (if local)
mongod --version
```

## 🛠️ Installation & Setup

### Step 1: Clone the Repository
```bash
git clone https://github.com/your-username/mangrove-watch.git
cd mangrove
```

### Step 2: Setup Environment Variables

1. **Copy the environment template:**
```bash
cp lib/backend/.env.example lib/backend/.env
```

2. **Configure your API keys in `lib/backend/.env`:**
```bash
# Google Services
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
GEE_PROJECT_ID=your_google_earth_engine_project_id

# Database
MONGODB_URI=mongodb://localhost:27017/mangrove_watch

# Cloudinary (Image Storage)
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# Security
JWT_SECRET=your_super_secret_jwt_key_change_in_production
```

### Step 3: Google Earth Engine Authentication

1. **Install Google Earth Engine Python API:**
```bash
pip install earthengine-api
```

2. **Authenticate with Google Earth Engine:**
```bash
earthengine authenticate
```

3. **Initialize in Python (run this once):**
```python
import ee
ee.Authenticate()  # Follow the browser authentication
ee.Initialize(project='your-gee-project-id')
```

### Step 4: Install Dependencies

#### Flutter Dependencies
```bash
# Install Flutter packages
flutter pub get

# Create required asset directories
mkdir -p assets/images assets/icons assets/models
```

#### Python Backend Dependencies
```bash
cd lib/backend/python_backend

# Create virtual environment (recommended)
python -m venv venv

# Activate virtual environment
# Windows
venv\Scripts\activate
# Linux/macOS
source venv/bin/activate

# Install requirements
pip install -r requirements.txt

cd ../../../
```

#### Express.js Backend Dependencies
```bash
cd lib/backend/express_backend
npm install
cd ../../../
```

### Step 5: Database Setup

#### Option A: Local MongoDB
```bash
# Start MongoDB service
# Windows
net start MongoDB

# Linux
sudo systemctl start mongod

# macOS
brew services start mongodb-community
```

#### Option B: MongoDB Atlas (Cloud)
1. Create a MongoDB Atlas account
2. Create a new cluster
3. Get your connection string
4. Update `MONGODB_URI` in your `.env` file

### Step 6: Initialize the Application

1. **Start the Python Backend:**
```bash
python lib/backend/start_python_backend.py
```
✅ API Documentation: http://localhost:8000/docs

2. **Start the Express Backend:**
```bash
node lib/backend/start_express_backend.js
```
✅ File Upload Service: http://localhost:5000

3. **Run the Flutter App:**
```bash
flutter run
```

### Step 7: Verify Setup

**Test Backend Health:**
```bash
# Test Python backend
curl http://localhost:8000/health

# Test Express backend
curl http://localhost:5000/health
```

**Expected Response:**
```json
{"status": "healthy", "timestamp": "2024-01-30T10:30:00Z"}
```

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.6.1+)
- Python 3.8+
- Node.js 16+
- MongoDB (local or cloud)
- Google Earth Engine account
- Gemini API key
- Google Maps API key

### Option 1: Automated Setup (Windows)

**Run the master setup script:**
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

This script will:
- ✅ Check prerequisites (Flutter, Python, Node.js)
- ✅ Create required asset directories
- ✅ Install Flutter dependencies
- ✅ Setup .env file from example
- ✅ Install Python backend dependencies
- ✅ Install Express backend dependencies
- ✅ Verify project structure

### Option 2: Manual Setup

#### 1. Setup Project
```bash
git clone <your-repo-url>
cd mangrove
flutter pub get
```

#### 2. Create Required Directories
```bash
# Windows PowerShell
New-Item -ItemType Directory -Path "assets\images" -Force
New-Item -ItemType Directory -Path "assets\icons" -Force

# Linux/macOS
mkdir -p assets/images assets/icons
```

#### 3. Setup API Keys
```bash
# Copy environment file
cp lib/backend/.env.example lib/backend/.env

# Edit .env file with your API keys:
# - GEMINI_API_KEY=your-gemini-api-key
# - GOOGLE_MAPS_API_KEY=your-google-maps-api-key
# - GEE_PROJECT_ID=your-gee-project-id
# - MONGODB_URL=mongodb://localhost:27017
```

#### 4. Install Backend Dependencies

**Python Backend:**
```bash
cd lib/backend/python_backend
pip install -r requirements.txt
cd ../../../
```

**Express Backend:**
```bash
cd lib/backend/express_backend
npm install
cd ../../../
```

### 🚀 Running the Application

#### Start Backend Services

**Terminal 1 - Python Backend:**
```bash
python lib/backend/start_python_backend.py
```
API will be available at: http://localhost:8000
Docs available at: http://localhost:8000/docs

**Terminal 2 - Express Backend:**
```bash
node lib/backend/start_express_backend.js
```
File upload service available at: http://localhost:3000

**Terminal 3 - Flutter App:**
```bash
flutter run
```

## 📁 Project Structure

```
mangrove/
├── 📱 lib/                       # Flutter application source code
│   ├── main.dart                 # Application entry point with BLoC setup
│   ├── 🎯 core/                  # Core application configuration
│   │   ├── app_router.dart       # GoRouter navigation setup
│   │   └── theme.dart            # Material Design theme configuration
│   ├── 📊 blocs/                 # BLoC state management
│   │   ├── auth/                 # Authentication state management
│   │   ├── report/               # Incident reporting state
│   │   ├── leaderboard/          # Gamification state
│   │   └── image_analysis/       # AI analysis state
│   ├── 📋 models/                # Data models and DTOs
│   │   ├── user.dart             # User model and authentication
│   │   ├── incident_report.dart  # Incident report structure
│   │   └── location_result.dart  # Location and geocoding models
│   ├── 🖥️ screens/               # Application screens/pages
│   │   ├── splash_screen.dart    # Loading and initialization
│   │   ├── auth/                 # Login and registration
│   │   ├── dashboard/            # Main dashboard and analytics
│   │   ├── reporting/            # Incident reporting flow
│   │   ├── maps/                 # Interactive mapping
│   │   └── profile/              # User profile and settings
│   ├── 🔧 services/              # Business logic and API clients
│   │   ├── api_service.dart      # HTTP client configuration
│   │   ├── auth_service.dart     # Authentication service
│   │   ├── gee_service.dart      # Google Earth Engine integration
│   │   ├── location_service.dart # GPS and geocoding
│   │   └── onnx_model_service.dart # Local ML model inference
│   ├── 🧩 widgets/               # Reusable UI components
│   │   ├── dashboard_card.dart   # Dashboard analytics cards
│   │   ├── loading_overlay.dart  # Loading states
│   │   └── responsive_text.dart  # Responsive typography
│   └── 🔗 backend/               # Backend services
│       ├── 🐍 python_backend/    # FastAPI AI backend
│       │   ├── main.py           # FastAPI application
│       │   ├── requirements.txt  # Python dependencies
│       │   ├── models/           # Pydantic models
│       │   ├── services/         # AI and ML services
│       │   ├── database/         # MongoDB integration
│       │   └── config/           # Configuration management
│       ├── 🟢 express_backend/   # Express.js file server
│       │   ├── server.js         # Express application
│       │   ├── package.json      # Node.js dependencies
│       │   ├── routes/           # API route handlers
│       │   ├── middleware/       # Custom middleware
│       │   ├── config/           # Database and Cloudinary config
│       │   └── utils/            # Utility functions
│       ├── .env.example          # Environment variables template
│       ├── start_python_backend.py # Python backend launcher
│       └── start_express_backend.js # Express backend launcher
├── 🖼️ assets/                   # Static assets
│   ├── images/                   # Application images and logos
│   ├── icons/                    # Custom icons and graphics
│   └── models/                   # ML model files (ONNX/TensorFlow)
├── 🧠 GreenRoots/                # Adapted ML model repository
│   ├── scripts/                  # Python utilities and launchers
│   ├── requirements.txt          # Additional ML dependencies
│   └── README.md                 # GreenRoots model documentation
├── 🧪 test/                      # Flutter widget and unit tests
├── 🌐 web/                       # Web platform support
├── 📄 pubspec.yaml               # Flutter project configuration
├── 📄 analysis_options.yaml      # Dart analysis configuration
├── 📄 dev_setup.md              # Development setup guide
└── 📄 README.md                  # This documentation
```

## 🔌 API Documentation

### Python FastAPI Backend (Port 8000)

#### Authentication Endpoints
```http
POST /auth/register              # User registration
POST /auth/login                 # User authentication
GET  /auth/me                    # Get current user profile
```

#### Incident Management
```http
POST /incidents                  # Create new incident report
GET  /incidents                  # List incidents with pagination
GET  /incidents/{id}             # Get specific incident details
PUT  /incidents/{id}             # Update incident (admin only)
DELETE /incidents/{id}           # Delete incident (admin only)
```

#### AI Analysis
```http
POST /analyze-image              # Gemini AI image analysis
POST /predict-mangrove           # ML model prediction
GET  /satellite-analysis         # Google Earth Engine analysis
POST /batch-analysis             # Bulk image processing
```

#### Gamification
```http
GET  /leaderboard                # Community leaderboard
GET  /user/points                # User points and badges
POST /user/achievements          # Update user achievements
```

### Express.js Backend (Port 5000)

#### File Management
```http
POST /upload/incident-image      # Upload incident photos
GET  /image/{publicId}           # Optimized image delivery
DELETE /upload/{publicId}        # Delete uploaded image
```

#### User Management
```http
POST /auth/register              # User registration (backup)
POST /auth/login                 # User login (backup)
GET  /user/profile               # User profile management
PUT  /user/profile               # Update user profile
```

#### Communication
```http
POST /email/notification         # Send email notifications
POST /email/verification         # Email verification
GET  /health                     # Service health check
```

### 📡 Example API Usage

#### Submit Incident Report
```bash
curl -X POST http://localhost:8000/incidents \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "type": "destruction",
    "title": "Illegal mangrove clearing",
    "description": "Large area of mangroves cleared for development",
    "location": {
      "latitude": 25.2048,
      "longitude": 55.2708,
      "address": "Dubai, UAE"
    },
    "severity": "high",
    "images": ["cloudinary_image_id_1", "cloudinary_image_id_2"]
  }'
```

#### Upload Image for Analysis
```bash
curl -X POST http://localhost:5000/upload/incident-image \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "image=@path/to/mangrove-photo.jpg" \
  -F "incident_id=12345"
```

#### Get AI Image Analysis
```bash
curl -X POST http://localhost:8000/analyze-image \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "image_url": "https://res.cloudinary.com/your-cloud/image/upload/v1234567890/sample.jpg",
    "analysis_type": "mangrove_detection"
  }'
```

## 🔧 Troubleshooting

### Development Environment Issues

#### **Flutter Issues**

**Problem**: `flutter doctor` shows issues
```bash
# Solutions:
flutter doctor --android-licenses  # Accept Android licenses
flutter config --android-sdk /path/to/android-sdk
flutter upgrade                     # Update Flutter SDK
```

**Problem**: Build failures or dependency conflicts
```bash
# Clean and rebuild
flutter clean
rm pubspec.lock
flutter pub get
flutter pub upgrade

# For Android build issues
cd android && ./gradlew clean && cd ..
```

#### **Python Backend Issues**

**Problem**: Package installation failures
```bash
# Create isolated environment
python -m venv mangrove_env
mangrove_env\Scripts\activate  # Windows
source mangrove_env/bin/activate  # Linux/macOS

# Upgrade pip and install
python -m pip install --upgrade pip
pip install -r requirements.txt
```

**Problem**: Google Earth Engine authentication issues
```bash
# Re-authenticate
earthengine authenticate --force

# Test authentication
python -c "import ee; ee.Initialize(project='YOUR_PROJECT_ID'); print('GEE authenticated successfully')"
```

#### **Express Backend Issues**

**Problem**: npm install failures
```bash
# Clear npm cache
npm cache clean --force

# Delete node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Use yarn as alternative
yarn install
```

#### **Network & Connectivity Issues**

**Problem**: Android emulator can't reach backend

The app automatically handles different network configurations:
- **Android Emulator**: Uses `10.0.2.2` to reach host machine
- **iOS Simulator**: Uses `localhost` directly
- **Physical Devices**: Uses your machine's IP address

```bash
# Test connectivity from emulator
adb shell
curl http://10.0.2.2:8000/health
curl http://10.0.2.2:5000/health
```

**Problem**: Firewall blocking connections
```powershell
# Windows - Allow ports through firewall
netsh advfirewall firewall add rule name="Flutter Backend" dir=in action=allow protocol=TCP localport=8000
netsh advfirewall firewall add rule name="Express Backend" dir=in action=allow protocol=TCP localport=5000
```

#### **Database Issues**

**Problem**: MongoDB connection failures
```bash
# Check MongoDB status
# Windows
net start MongoDB
sc query MongoDB

# Linux
sudo systemctl status mongod
sudo systemctl start mongod

# Test connection
mongo --eval "db.runCommand({connectionStatus: 1})"
```

### Platform-Specific Setup

#### **Android Development**
```bash
# Install Android Studio and SDK
# Accept all licenses
flutter doctor --android-licenses

# Enable developer options on device
# Enable USB debugging
# Run: flutter devices
```

#### **iOS Development (macOS only)**
```bash
# Install Xcode from App Store
# Install Xcode command line tools
xcode-select --install

# Install CocoaPods
sudo gem install cocoapods
cd ios && pod install
```

### Performance Optimization

#### **App Performance**
```bash
# Build optimized APK
flutter build apk --release --split-per-abi

# Profile app performance
flutter run --profile

# Analyze bundle size
flutter build apk --analyze-size
```

#### **Backend Performance**
```bash
# Use production ASGI server
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker

# Enable MongoDB indexing
# Add indexes in your MongoDB setup
```

## 🚀 Deployment

### Production Environment Setup

#### **Environment Variables for Production**
```bash
# Security
JWT_SECRET=your_256_bit_secret_key
NODE_ENV=production
PYTHON_ENV=production

# Database
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/mangrove_prod

# CORS (restrict origins)
CORS_ORIGINS=https://your-domain.com,https://admin.your-domain.com

# SSL and Security
FORCE_HTTPS=true
TRUST_PROXY=true
```

#### **Docker Deployment** (Optional)

**Create Docker Compose file:**
```yaml
version: '3.8'
services:
  python-backend:
    build: ./lib/backend/python_backend
    ports:
      - "8000:8000"
    environment:
      - MONGODB_URI=${MONGODB_URI}
      - GEMINI_API_KEY=${GEMINI_API_KEY}
    depends_on:
      - mongodb
  
  express-backend:
    build: ./lib/backend/express_backend
    ports:
      - "5000:5000"
    environment:
      - MONGODB_URI=${MONGODB_URI}
      - CLOUDINARY_CLOUD_NAME=${CLOUDINARY_CLOUD_NAME}
    depends_on:
      - mongodb
  
  mongodb:
    image: mongo:5
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db

volumes:
  mongodb_data:
```

#### **Mobile App Distribution**

**Android (Google Play Store):**
```bash
# Generate release APK
flutter build apk --release

# Generate App Bundle (recommended)
flutter build appbundle --release
```

**iOS (App Store):**
```bash
# Build for iOS
flutter build ios --release

# Archive in Xcode for App Store submission
```

## 📊 Key Metrics & Analytics

### Application Metrics
- **Incident Reports**: Track number of submitted and verified reports
- **User Engagement**: Monitor daily/monthly active users
- **Geographic Coverage**: Analyze report distribution across regions
- **AI Accuracy**: Monitor Gemini AI and ML model performance
- **Response Time**: Track backend API response times

### Conservation Impact
- **Mangrove Area Monitoring**: Track changes in mangrove coverage
- **Threat Detection**: Identify high-risk areas requiring attention
- **Community Growth**: Monitor user acquisition and retention
- **Verification Rate**: Track admin verification efficiency

## 👥 Contributing

We welcome contributions from the community! Here's how you can help:

### 🛠️ Development Workflow

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
   - Follow the existing code style and patterns
   - Add tests for new functionality
   - Update documentation as needed
4. **Commit your changes**
   ```bash
   git commit -m "feat: add amazing new feature"
   ```
5. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Open a Pull Request**

### 📋 Development Guidelines

#### **Code Style**
- **Flutter/Dart**: Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- **Python**: Follow PEP 8 with Black formatter
- **JavaScript**: Follow Airbnb style guide
- **Git Commits**: Use [Conventional Commits](https://www.conventionalcommits.org/)

#### **Testing Requirements**
```bash
# Flutter tests
flutter test
flutter test integration_test/

# Python tests
cd lib/backend/python_backend
pytest tests/

# JavaScript tests
cd lib/backend/express_backend
npm test
```

#### **Documentation Standards**
- Add inline documentation for complex functions
- Update README for any new features or setup changes
- Include API documentation for new endpoints
- Add example usage for new functionality

### 🌟 Areas for Contribution

#### **High Priority**
- 📱 **Mobile UI/UX**: Improve responsive design and accessibility
- 🤖 **AI Enhancement**: Improve image analysis accuracy
- 🗺️ **Mapping Features**: Add new visualization layers
- 🔒 **Security**: Enhance authentication and data protection
- 📊 **Analytics**: Add more detailed reporting features

#### **Medium Priority**
- 🌍 **Internationalization**: Add support for multiple languages
- 📧 **Notifications**: Implement push notifications
- 📊 **Dashboard**: Enhanced admin analytics
- 🧩 **Testing**: Increase test coverage
- 📄 **Documentation**: API documentation improvements

#### **Nice to Have**
- 🎮 **Gamification**: New achievement systems
- 📱 **Progressive Web App**: PWA support
- 🔄 **Real-time Updates**: WebSocket integration
- 🛠️ **DevOps**: CI/CD pipeline improvements
- 🌐 **Web Version**: Full web application

## 📈 Project Roadmap

### Version 1.0 (Current) - Core Functionality
- ✅ Incident reporting with photo upload
- ✅ Basic AI image analysis with Gemini
- ✅ User authentication and profiles
- ✅ Interactive maps with incident visualization
- ✅ Basic gamification (points, leaderboards)

### Version 1.1 - Enhanced AI
- 🔄 Advanced ML models for mangrove detection
- 🔄 Google Earth Engine satellite monitoring
- 🔄 Batch image processing
- 🔄 Predictive analytics for mangrove health

### Version 1.2 - Community Features
- 📅 Social features and community forums
- 📅 Advanced gamification with badges
- 📅 Collaborative verification system
- 📅 NGO and government integration tools

### Version 2.0 - Enterprise & Scale
- 📅 Multi-language support
- 📅 Advanced analytics dashboard
- 📅 API for third-party integrations
- 📅 Real-time collaborative mapping

## 🌍 Environment & Configuration

### Development vs Production

| Feature | Development | Production |
|---------|-------------|------------|
| **Database** | Local MongoDB | MongoDB Atlas |
| **Image Storage** | Local/Cloudinary | Cloudinary CDN |
| **Authentication** | Simple JWT | JWT + OAuth |
| **Logging** | Console | Structured logging |
| **Error Handling** | Detailed errors | Generic errors |
| **CORS** | Allow all origins | Restricted origins |
| **SSL** | Optional | Required |

### Environment Configuration Examples

#### **Development (.env)**
```bash
NODE_ENV=development
PYTHON_ENV=development
DEBUG=true
LOG_LEVEL=debug
CORS_ORIGINS=*
MONGODB_URI=mongodb://localhost:27017/mangrove_dev
```

#### **Production (.env)**
```bash
NODE_ENV=production
PYTHON_ENV=production
DEBUG=false
LOG_LEVEL=info
CORS_ORIGINS=https://mangrove-watch.org
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/mangrove_prod
FORCE_HTTPS=true
```

## 🛡️ Security Considerations

### Authentication & Authorization
- **JWT Tokens**: Secure token-based authentication
- **Password Hashing**: bcrypt with salt rounds
- **Role-Based Access**: Admin, moderator, and user roles
- **API Rate Limiting**: Prevent abuse and DDoS attacks

### Data Protection
- **Input Validation**: Comprehensive input sanitization
- **XSS Protection**: Cross-site scripting prevention
- **SQL Injection**: NoSQL injection prevention
- **CORS Policy**: Restricted cross-origin requests
- **File Upload Security**: Image validation and size limits

### Privacy
- **Data Minimization**: Collect only necessary user data
- **Anonymization**: Option for anonymous incident reporting
- **GDPR Compliance**: User data deletion and export capabilities
- **Location Privacy**: Configurable location precision

## 📊 Testing

### Automated Testing

#### **Flutter Tests**
```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widgets/

# Integration tests
flutter test integration_test/

# Test coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

#### **Backend Tests**
```bash
# Python backend tests
cd lib/backend/python_backend
pytest tests/ -v --cov=.

# Express backend tests
cd lib/backend/express_backend
npm test
npm run test:coverage
```

### Manual Testing Checklist

#### **Core Functionality**
- ☐ User registration and login
- ☐ Incident report submission with photos
- ☐ GPS location tagging
- ☐ Image upload and processing
- ☐ Map visualization of incidents
- ☐ Leaderboard and points system

#### **Cross-Platform Testing**
- ☐ Android (Physical device + Emulator)
- ☐ iOS (Physical device + Simulator)
- ☐ Web (Chrome, Firefox, Safari)
- ☐ Desktop (Windows, macOS, Linux)

## 📞 Support & Community

### Getting Help

- **🐛 Bug Reports**: [Create an issue](https://github.com/your-username/mangrove-watch/issues/new?template=bug_report.md)
- **✨ Feature Requests**: [Request a feature](https://github.com/your-username/mangrove-watch/issues/new?template=feature_request.md)
- **❓ Questions**: [Start a discussion](https://github.com/your-username/mangrove-watch/discussions)
- **💬 Chat**: Join our community Discord (link coming soon)

### Documentation

- **📚 API Docs**: http://localhost:8000/docs (when running locally)
- **🔧 Development Guide**: `dev_setup.md`
- **🧠 AI Model Details**: `GreenRoots/README.md`
- **📊 Analytics**: Built-in dashboard at `/admin`

### Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/). By participating, you agree to uphold this code.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses
- **Flutter**: BSD 3-Clause License
- **Google Earth Engine**: Google Terms of Service
- **Gemini AI**: Google AI Terms of Service
- **Cloudinary**: Cloudinary Terms of Service
- **GreenRoots Model**: MIT License (adapted)

## 🙏 Acknowledgments

- **GreenRoots Team**: For the foundational ML model and satellite analysis
- **Google Earth Engine**: For satellite imagery and analysis tools
- **Google AI**: For the Gemini vision API
- **Flutter Team**: For the amazing cross-platform framework
- **MongoDB**: For the flexible document database
- **Cloudinary**: For image optimization and delivery
- **Open Source Community**: For the countless libraries and tools

## 🌟 Project Status

- **Development Status**: 🟢 Active Development
- **Version**: 1.0.0
- **Last Updated**: January 2025
- **Maintainers**: Open for community maintainers
- **Contributing**: 🟢 Accepting contributions

---

## 🌊 Why Mangroves Matter

Mangrove forests are among the most productive and important ecosystems on Earth:

- **🌊 Climate Protection**: Absorb 3-5x more carbon than tropical rainforests
- **🚪️ Coastal Defense**: Protect coastlines from storms and erosion
- **🐟 Biodiversity**: Support 75% of tropical fish species at some point in their lifecycle
- **🏡 Community Support**: Provide livelihoods for millions of people worldwide
- **💧 Water Quality**: Filter pollutants and improve water quality

**Together, let's protect our mangrove forests for future generations! 🌿🌍**

---

*Built with ❤️ for environmental conservation*
