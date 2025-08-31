from fastapi import FastAPI, HTTPException, Depends, File, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.errors import DuplicateKeyError
import os
import json
import uvicorn
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
import google.generativeai as genai
from PIL import Image
import io
import base64
import hashlib
import jwt
import tempfile
import shutil
import numpy as np
from sklearn.ensemble import RandomForestRegressor
import joblib
from passlib.context import CryptContext
from dotenv import load_dotenv
from pathlib import Path
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables from parent backend directory
backend_root = Path(__file__).parent.parent
load_dotenv(backend_root / '.env')

from models.user import User, UserCreate, UserLogin, UserResponse
from models.incident import IncidentReport, IncidentCreate, IncidentResponse
from models.prediction import PredictionRequest, PredictionResponse
from services.auth_service import AuthService
from services.gemini_service import GeminiService
from services.gee_service import GoogleEarthEngineService
from services.ml_service import MLModelService
from database.mongodb import Database

# Initialize FastAPI app
app = FastAPI(title="Mangrove Watch AI Backend", version="2.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()

# Database
db = Database()

# Services
auth_service = None  # Will be initialized in startup_event
gemini_service = GeminiService()
gee_service = GoogleEarthEngineService()
ml_service = MLModelService()

@app.on_event("startup")
async def startup_event():
    """Initialize database connection and services"""
    try:
        await db.connect()
        # Initialize auth service with connected database
        global auth_service
        auth_service = AuthService(db)
        
        # Initialize Google Earth Engine with proper credentials
        await gee_service.initialize()
        
        # Load ML model
        await ml_service.load_model()
        
        # Initialize Gemini service
        gemini_service.initialize()
        
        logger.info("All services initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize services: {e}")
        # Continue anyway for development

@app.on_event("shutdown")
async def shutdown_event():
    """Close database connection"""
    await db.disconnect()

# Authentication endpoints
@app.post("/auth/register", response_model=UserResponse)
async def register(user_data: UserCreate):
    """Register a new user"""
    try:
        user = await auth_service.register_user(user_data)
        return UserResponse.from_user(user)
    except DuplicateKeyError:
        raise HTTPException(status_code=400, detail="Email already registered")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/auth/login")
async def login(credentials: UserLogin):
    """Login user and return JWT token"""
    try:
        token = await auth_service.authenticate_user(credentials)
        return {"access_token": token, "token_type": "bearer"}
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid credentials")

# Protected routes
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current authenticated user"""
    try:
        user = await auth_service.get_current_user(credentials.credentials)
        return user
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid token")

# Optional authentication for internal API calls
async def get_current_user_optional(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)):
    """Get current authenticated user or None for internal API calls"""
    if not credentials:
        return None
    try:
        user = await auth_service.get_current_user(credentials.credentials)
        return user
    except:
        return None

# Incident reporting endpoints
@app.post("/incidents")
async def create_incident(
    incident_data: Dict[str, Any],
    current_user: Optional[User] = Depends(get_current_user_optional)
):
    """Create a new incident report"""
    try:
        # Use user ID if authenticated, otherwise use anonymous
        user_id = current_user.id if current_user else "anonymous"
        
        # Process incident data
        incident = {
            "id": str(datetime.now().timestamp()),
            "userId": incident_data.get("userId", user_id),
            "type": incident_data.get("type", "other"),
            "description": incident_data.get("description", ""),
            "location": incident_data.get("location", {}),
            "severity": incident_data.get("severity", "medium"),
            "status": incident_data.get("status", "pending"),
            "timestamp": incident_data.get("timestamp", datetime.now().isoformat()),
            "images": incident_data.get("images", []),
            "title": incident_data.get("title", "Untitled"),
            "reporterName": incident_data.get("reporterName", "Anonymous")
        }
        
        # ML analysis if available
        if ml_service.model_loaded:
            prediction = await ml_service.predict_incident_severity(incident_data)
            incident["mlPrediction"] = prediction.get("severity", "pending")
            incident["confidence"] = prediction.get("confidence", 0)
        
        # Store in database if connected
        if db.is_connected():
            await db.incidents_collection.insert_one(incident)
        
        return incident
    except Exception as e:
        logger.error(f"Error creating incident: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/incidents")
async def get_incidents(
    skip: int = 0,
    limit: int = 50,
    status_filter: Optional[str] = None,
    current_user: Optional[User] = Depends(get_current_user_optional)
):
    """Get list of incidents with pagination and filtering"""
    try:
        # Return empty list if database not connected
        if not db.is_connected():
            return []
            
        query = {}
        if status_filter:
            query["status"] = status_filter
            
        incidents = await db.incidents_collection.find(query).skip(skip).limit(limit).to_list(length=limit)
        return incidents
    except Exception as e:
        logger.error(f"Error fetching incidents: {e}")
        return []  # Return empty list on error

@app.get("/incidents/{incident_id}", response_model=IncidentResponse)
async def get_incident(
    incident_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get specific incident by ID"""
    try:
        incident = await db.get_incident_by_id(incident_id)
        if not incident:
            raise HTTPException(status_code=404, detail="Incident not found")
        return IncidentResponse.from_incident(incident)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Image analysis endpoints
@app.post("/analyze-image")
async def analyze_image_with_gemini(
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Analyze uploaded image using Gemini API for mangrove detection"""
    try:
        # Read image
        image_data = await image.read()
        
        # Analyze with Gemini
        analysis = await gemini_service.analyze_mangrove_image(image_data)
        
        # Update user points for image submission
        await auth_service.add_user_points(current_user.id, 5)
        
        return {
            "prediction": analysis["is_mangrove"],
            "confidence": analysis["confidence"],
            "description": analysis["description"],
            "points_earned": 5
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to analyze image: {str(e)}")

# Mangrove prediction using GEE and ML model
@app.post("/predict-mangrove")
async def predict_mangrove(
    request: Dict[str, Any],
    current_user: Optional[User] = Depends(get_current_user_optional)
):
    """Predict mangrove coverage at given coordinates using satellite data"""
    try:
        # Get satellite data from GEE
        satellite_data = await gee_service.get_satellite_data(
            request.latitude,
            request.longitude,
            request.start_date,
            request.end_date
        )
        
        # Run ML prediction
        prediction = await ml_service.predict_mangrove_coverage(satellite_data)
        
        return PredictionResponse(
            latitude=request.latitude,
            longitude=request.longitude,
            predicted_coverage=prediction["coverage"],
            confidence=prediction["confidence"],
            ndvi_value=prediction["ndvi"],
            prediction_date=datetime.utcnow()
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

# Gamification endpoints
@app.get("/leaderboard")
async def get_leaderboard(
    limit: int = 50,
    current_user: User = Depends(get_current_user)
):
    """Get leaderboard of top contributors"""
    try:
        leaderboard = await db.get_leaderboard(limit)
        return leaderboard
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/user/profile", response_model=UserResponse)
async def get_user_profile(current_user: User = Depends(get_current_user)):
    """Get current user profile with stats"""
    try:
        user_stats = await db.get_user_stats(current_user.id)
        user_response = UserResponse.from_user(current_user)
        user_response.total_reports = user_stats.get("total_reports", 0)
        user_response.verified_reports = user_stats.get("verified_reports", 0)
        user_response.badges = user_stats.get("badges", [])
        return user_response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/user/verify-incident/{incident_id}")
async def verify_incident(
    incident_id: str,
    verification: dict,
    current_user: User = Depends(get_current_user)
):
    """Verify an incident report (admin only)"""
    try:
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        result = await db.verify_incident(incident_id, verification, current_user.id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Analytics endpoints
@app.get("/analytics/dashboard")
async def get_dashboard_analytics(
    current_user: User = Depends(get_current_user)
):
    """Get dashboard analytics data"""
    try:
        analytics = await db.get_dashboard_analytics()
        return analytics
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/analytics/mangrove-trends")
async def get_mangrove_trends(
    latitude: float,
    longitude: float,
    radius_km: float = 10,
    current_user: User = Depends(get_current_user)
):
    """Get mangrove health trends for a specific area"""
    try:
        trends = await gee_service.get_mangrove_trends(latitude, longitude, radius_km)
        return trends
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# New Enhanced Endpoints from reference

# Public endpoint for basic analysis without auth
@app.post("/public/analyze-image")
async def analyze_image_public(image: UploadFile = File(...)):
    """Public endpoint to analyze uploaded image using Gemini Vision API"""
    try:
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as temp_file:
            shutil.copyfileobj(image.file, temp_file)
            temp_file_path = temp_file.name
        
        # Read image for analysis
        with open(temp_file_path, "rb") as img_file:
            img_data = img_file.read()
        
        # Analyze with Gemini
        analysis = await gemini_service.analyze_mangrove_image(img_data)
        
        # Clean up temp file
        os.unlink(temp_file_path)
        
        return {
            "prediction": analysis,
            "status": "success"
        }
        
    except Exception as e:
        # Clean up temp file on error
        if 'temp_file_path' in locals():
            try:
                os.unlink(temp_file_path)
            except:
                pass
        raise HTTPException(status_code=500, detail=f"Error analyzing image: {str(e)}")

# ONNX-based mangrove detection endpoint
@app.post("/predict-mangrove-image")
async def predict_mangrove_image(image: UploadFile = File(...)):
    """Predict if uploaded image contains mangrove using ONNX model"""
    try:
        # Validate image file
        if not image.content_type or not image.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="Invalid image file format")
        
        # Read image data
        image_data = await image.read()
        
        if len(image_data) == 0:
            raise HTTPException(status_code=400, detail="Empty image file")
        
        # Get prediction from ML service using ONNX model
        prediction = await ml_service.predict_mangrove_from_image(image_data)
        
        return {
            "prediction": prediction,
            "status": "success",
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error predicting mangrove from image: {e}")
        raise HTTPException(status_code=500, detail=f"Error analyzing image: {str(e)}")

# Satellite analysis endpoint
@app.get("/satellite-analysis/{lat}/{lng}")
async def get_satellite_analysis(
    lat: float, 
    lng: float,
    current_user: User = Depends(get_current_user)
):
    """Get detailed satellite analysis for a location"""
    try:
        analysis = await gee_service.get_satellite_data(lat, lng)
        
        # Store analysis in database
        analysis_doc = {
            "latitude": lat,
            "longitude": lng,
            "analysis": analysis,
            "timestamp": datetime.utcnow(),
            "user_id": current_user.id
        }
        await db.analytics.insert_one(analysis_doc)
        
        return analysis
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting satellite analysis: {str(e)}")

# Enhanced prediction with storage
@app.post("/predict-mangrove-enhanced")
async def predict_mangrove_enhanced(request: PredictionRequest):
    """Enhanced prediction endpoint with database storage"""
    try:
        # Get satellite data
        satellite_data = await gee_service.get_satellite_data(
            request.latitude,
            request.longitude
        )
        
        # Get ML prediction
        prediction = await ml_service.predict_mangrove_coverage(satellite_data)
        
        # Enhanced result with additional analysis
        result = {
            "mangrove_probability": float(prediction["coverage"]),
            "ndvi": satellite_data["ndvi"],
            "ndwi": satellite_data.get("ndwi", 0.0),
            "confidence": prediction["confidence"],
            "health_score": prediction.get("health_score", 0.0),
            "satellite_data": satellite_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Store prediction in database
        prediction_doc = {
            "latitude": request.latitude,
            "longitude": request.longitude,
            "prediction": result,
            "timestamp": datetime.utcnow(),
            "source": "gee_ml_analysis"
        }
        
        # Store in predictions collection if it exists
        if hasattr(db, 'predictions'):
            await db.predictions.insert_one(prediction_doc)
        else:
            await db.analytics.insert_one(prediction_doc)
        
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error predicting mangrove: {str(e)}")

# Mangrove extent endpoint
@app.get("/mangrove-extent")
async def get_mangrove_extent(
    latitude: float,
    longitude: float,
    radius_km: float = 10,
    current_user: User = Depends(get_current_user)
):
    """Get mangrove extent data from Global Mangrove Watch"""
    try:
        extent_data = await gee_service.get_mangrove_extent_data(latitude, longitude, radius_km)
        return extent_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting mangrove extent: {str(e)}")

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "mangrove-ai-backend",
        "version": "2.0.0",
        "timestamp": datetime.utcnow().isoformat()
    }

# GEE Visualization endpoints
@app.get("/gee/mangrove-visualization")
async def get_mangrove_visualization(
    center_lat: float = -2.0164,
    center_lng: float = -44.5626,
    zoom: int = 9
):
    """Get mangrove visualization data from Google Earth Engine"""
    try:
        visualization_data = await gee_service.get_mangrove_visualization_data(
            center_lat, center_lng, zoom
        )
        return visualization_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting visualization data: {str(e)}")

@app.get("/gee/mangrove-html")
async def get_mangrove_html(
    center_lat: float = -2.0164,
    center_lng: float = -44.5626,
    zoom: int = 9
):
    """Generate HTML page with embedded GEE mangrove visualization"""
    try:
        visualization_data = await gee_service.get_mangrove_visualization_data(
            center_lat, center_lng, zoom
        )
        
        # Generate HTML with embedded map using Leaflet and GEE tiles
        html_content = f'''
<!DOCTYPE html>
<html>
<head>
    <title>Mangrove Detection - Global Map</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />
    <style>
        body {{
            margin: 0;
            padding: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }}
        #map {{
            height: 100vh;
            width: 100%;
        }}
        .info-panel {{
            position: absolute;
            top: 10px;
            right: 10px;
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.3);
            z-index: 1000;
            min-width: 250px;
        }}
        .info-panel h3 {{
            margin: 0 0 10px 0;
            color: #2c5234;
        }}
        .stat-item {{
            margin: 5px 0;
            font-size: 14px;
        }}
        .stat-label {{
            font-weight: bold;
            color: #555;
        }}
        .mangrove-color {{
            color: #d40115;
            font-weight: bold;
        }}
        .legend {{
            position: absolute;
            bottom: 30px;
            left: 10px;
            background: white;
            padding: 10px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
            z-index: 1000;
        }}
        .legend-item {{
            display: flex;
            align-items: center;
            margin: 5px 0;
        }}
        .legend-color {{
            width: 20px;
            height: 20px;
            margin-right: 8px;
            border: 1px solid #ccc;
        }}
    </style>
</head>
<body>
    <div id="map"></div>
    
    <div class="info-panel">
        <h3>🌿 Mangrove Detection</h3>
        <div class="stat-item">
            <span class="stat-label">Dataset:</span> {visualization_data['layer_info']['name']}
        </div>
        <div class="stat-item">
            <span class="stat-label">Year:</span> {visualization_data['layer_info']['year']}
        </div>
        <div class="stat-item">
            <span class="stat-label">Resolution:</span> {visualization_data['layer_info']['resolution']}
        </div>
        <div class="stat-item">
            <span class="stat-label">Center:</span> {visualization_data['center']['latitude']:.4f}, {visualization_data['center']['longitude']:.4f}
        </div>
        <div class="stat-item">
            <span class="stat-label">Mangrove Coverage:</span> 
            <span class="mangrove-color">{visualization_data['statistics']['mangrove_pixel_count']:.0f} pixels</span>
        </div>
        <div class="stat-item">
            <span class="stat-label">Avg NDVI:</span> {visualization_data['statistics']['ndvi_mean']:.3f}
        </div>
    </div>
    
    <div class="legend">
        <h4 style="margin: 0 0 8px 0; font-size: 14px;">Legend</h4>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #d40115;"></div>
            <span>Mangrove Areas</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #4a90e2;"></div>
            <span>Water Bodies</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #7ed321;"></div>
            <span>Other Vegetation</span>
        </div>
    </div>

    <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"></script>
    <script>
        // Initialize the map
        var map = L.map('map').setView([{visualization_data['center']['latitude']}, {visualization_data['center']['longitude']}], {visualization_data['zoom']});

        // Add base layer (OpenStreetMap)
        L.tileLayer('https://{{s}}.tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png', {{
            attribution: '© OpenStreetMap contributors',
            maxZoom: 18
        }}).addTo(map);
        
        // Add satellite base layer option
        var satelliteLayer = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{{z}}/{{y}}/{{x}}', {{
            attribution: '© Esri, Maxar, GeoEye, Earthstar Geographics, CNES/Airbus DS, USDA, USGS, AeroGRID, IGN, and the GIS User Community'
        }});
        
        // Add GEE mangrove layer if available
        if ('{visualization_data['tile_url_template']}' && '{visualization_data['tile_url_template']}' !== 'https://tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png') {{
            var mangroveLayer = L.tileLayer('{visualization_data['tile_url_template']}', {{
                attribution: 'Global Mangrove Watch via Google Earth Engine',
                opacity: 0.7,
                maxZoom: 18
            }});
            mangroveLayer.addTo(map);
        }} else {{
            // Add mock mangrove areas for demonstration
            // These are approximate locations where mangroves commonly occur
            var mangroveAreas = [
                {{"lat": -2.0164, "lng": -44.5626, "name": "Amazon Delta, Brazil"}},
                {{"lat": 25.7617, "lng": -80.1918, "name": "Everglades, Florida"}},
                {{"lat": -17.8252, "lng": 25.8619, "name": "Okavango Delta, Botswana"}},
                {{"lat": 22.3193, "lng": 114.1694, "name": "Hong Kong Mangroves"}},
                {{"lat": -12.0464, "lng": 96.8297, "name": "Cocos Islands"}},
                {{"lat": 13.0827, "lng": 80.2707, "name": "Chennai, India"}}
            ];
            
            mangroveAreas.forEach(function(area) {{
                var circle = L.circle([area.lat, area.lng], {{
                    color: '#d40115',
                    fillColor: '#d40115',
                    fillOpacity: 0.6,
                    radius: 10000
                }}).addTo(map);
                
                circle.bindPopup('<b>Mangrove Area</b><br>' + area.name);
            }});
        }}
        
        // Layer control
        var baseLayers = {{
            "OpenStreetMap": map._layers[Object.keys(map._layers)[0]],
            "Satellite": satelliteLayer
        }};
        
        L.control.layers(baseLayers).addTo(map);
        
        // Add click handler to show coordinates
        map.on('click', function(e) {{
            console.log('Clicked at: ' + e.latlng);
        }});
        
        // Add scale control
        L.control.scale().addTo(map);
    </script>
</body>
</html>
        '''
        
        from fastapi.responses import HTMLResponse
        return HTMLResponse(content=html_content)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating HTML: {str(e)}")

# API info endpoint
@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "name": "Mangrove Watch AI Backend",
        "version": "2.0.0",
        "description": "AI-powered backend for mangrove monitoring and conservation",
        "endpoints": {
            "auth": "/auth/register, /auth/login",
            "analysis": "/analyze-image, /predict-mangrove",
            "incidents": "/incidents",
            "analytics": "/analytics/dashboard, /analytics/mangrove-trends",
            "gee": "/gee/mangrove-visualization, /gee/mangrove-html",
            "health": "/health"
        }
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
