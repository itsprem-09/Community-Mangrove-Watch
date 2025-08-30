# Community Mangrove Watch

A comprehensive Flutter application for community-driven mangrove conservation with Python/Express backend, MongoDB database, and AI-powered analysis using Google Earth Engine and Gemini API.

## 🌿 Features

### Core Functionality
- **Incident Reporting**: Report mangrove destruction, pollution, and other threats with geotagged photos
- **AI Image Analysis**: Use Gemini API to analyze uploaded images for mangrove detection
- **Satellite Monitoring**: Integrate Google Earth Engine for satellite-based mangrove health analysis
- **Gamification**: Points, badges, and leaderboards to encourage community participation
- **Real-time Maps**: Interactive maps showing incidents and mangrove areas
- **Admin Dashboard**: Tools for NGOs and government agencies to verify reports

### AI & Technology Stack
- **Frontend**: Flutter with BLoC state management
- **Backend**: Python FastAPI + Express.js
- **Database**: MongoDB with optimized schemas
- **AI/ML**: 
  - Google Earth Engine for satellite data analysis
  - Gemini API for image recognition
  - Custom ML model adapted from GreenRoots repository
  - TensorFlow/scikit-learn for mangrove coverage prediction

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
├── lib/
│   ├── main.dart                 # Flutter app entry point
│   ├── core/
│   │   ├── app_router.dart       # Navigation routing
│   │   └── theme.dart            # App theme configuration
│   ├── models/                   # Data models
│   ├── screens/                  # UI screens
│   ├── services/                 # API and business logic
│   ├── widgets/                  # Reusable UI components
│   └── backend/                  # Backend services
│       ├── python_backend/       # FastAPI server
│       ├── express_backend/      # Express.js file server
│       ├── .env.example          # Environment template
│       ├── start_python_backend.py
│       └── start_express_backend.js
├── assets/
│   ├── images/                   # App images
│   └── icons/                    # App icons
├── GreenRoots/                   # ML models and scripts
├── pubspec.yaml                  # Flutter dependencies
├── setup.ps1                     # Master setup script
└── README.md                     # This file
```

## 🔧 Troubleshooting

### Common Issues

**1. Python Dependencies Fail to Install**
- Ensure you have Visual Studio Build Tools installed on Windows
- Try installing dependencies individually: `pip install fastapi uvicorn`
- Use a virtual environment: `python -m venv env && env\Scripts\activate`

**2. Flutter Build Issues**
- Run `flutter clean && flutter pub get`
- Ensure Flutter SDK is properly installed: `flutter doctor`
- Check your Flutter SDK version: `flutter --version`

**3. Backend Connection Issues**
- Verify both backends are running on correct ports (8000, 3000)
- Check firewall settings
- Ensure MongoDB is running if using local instance

**4. API Key Issues**
- Double-check your .env file has correct API keys
- Verify Google Earth Engine authentication
- Test Gemini API key separately

### Quick Commands

```bash
# Check Flutter setup
flutter doctor

# Clean and rebuild Flutter project
flutter clean && flutter pub get

# Check Python packages
pip list

# Check Node.js packages
npm list --depth=0

# Test backend endpoints
curl http://localhost:8000/health
curl http://localhost:3000/health
```

## 📞 Support

For support, create an issue in this repository.

---

**Together, let's protect our mangrove forests! 🌿**
