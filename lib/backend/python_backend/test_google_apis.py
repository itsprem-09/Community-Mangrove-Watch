#!/usr/bin/env python
"""
Test script to verify Google API setup for Mangrove Watch Backend
Run this after setting up your .env file to verify everything works
"""

import os
import sys
import json
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
backend_root = Path(__file__).parent.parent
env_path = backend_root / '.env'
load_dotenv(env_path)

print("=" * 60)
print("Google APIs Test Script for Mangrove Watch")
print("=" * 60)

# Check if .env file exists
if not env_path.exists():
    print("\n❌ ERROR: .env file not found!")
    print(f"   Expected location: {env_path}")
    print("\n   Please create a .env file with your API keys.")
    print("   See GOOGLE_API_SETUP_GUIDE.md for instructions.")
    sys.exit(1)

print(f"\n✅ Found .env file at: {env_path}")

# Test 1: Check Environment Variables
print("\n" + "=" * 40)
print("1. Checking Environment Variables")
print("=" * 40)

required_vars = {
    'GEMINI_API_KEY': 'Google Gemini API Key',
    'GEE_PROJECT_ID': 'Google Earth Engine Project ID',
}

optional_vars = {
    'GEE_SERVICE_ACCOUNT_KEY': 'Earth Engine Service Account (JSON)',
    'GEE_SERVICE_ACCOUNT_PATH': 'Earth Engine Service Account (File Path)',
    'MONGODB_URL': 'MongoDB Connection URL',
    'JWT_SECRET_KEY': 'JWT Secret Key'
}

missing_required = []
for var, description in required_vars.items():
    value = os.getenv(var)
    if value:
        # Mask the value for security
        masked = value[:10] + "..." if len(value) > 10 else "***"
        print(f"✅ {var}: {masked}")
    else:
        print(f"❌ {var}: Not found")
        missing_required.append(var)

print("\nOptional variables:")
for var, description in optional_vars.items():
    value = os.getenv(var)
    if value:
        if var == 'GEE_SERVICE_ACCOUNT_KEY':
            # Just show if it's valid JSON
            try:
                json.loads(value)
                print(f"✅ {var}: Valid JSON detected")
            except:
                print(f"⚠️  {var}: Present but not valid JSON")
        else:
            masked = value[:20] + "..." if len(value) > 20 else "***"
            print(f"✅ {var}: {masked}")
    else:
        print(f"⚠️  {var}: Not set")

if missing_required:
    print(f"\n❌ Missing required variables: {', '.join(missing_required)}")
    print("   Please add these to your .env file")
    sys.exit(1)

# Test 2: Test Gemini API
print("\n" + "=" * 40)
print("2. Testing Google Gemini API")
print("=" * 40)

try:
    import google.generativeai as genai
    
    api_key = os.getenv('GEMINI_API_KEY')
    if not api_key:
        print("❌ Gemini API key not found")
    else:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-pro')
        
        # Simple test
        response = model.generate_content("Say 'API test successful' in 5 words or less")
        print(f"✅ Gemini API working!")
        print(f"   Response: {response.text.strip()}")
        
except ImportError:
    print("❌ google-generativeai package not installed")
    print("   Run: pip install google-generativeai")
except Exception as e:
    print(f"❌ Gemini API test failed: {str(e)}")
    print("\n   Possible issues:")
    print("   - Invalid API key")
    print("   - API key not activated")
    print("   - Network issues")

# Test 3: Test Google Earth Engine
print("\n" + "=" * 40)
print("3. Testing Google Earth Engine")
print("=" * 40)

try:
    import ee
    
    # Check which authentication method is available
    service_account_key = os.getenv('GEE_SERVICE_ACCOUNT_KEY')
    service_account_path = os.getenv('GEE_SERVICE_ACCOUNT_PATH')
    project_id = os.getenv('GEE_PROJECT_ID')
    
    if service_account_key:
        print("Using service account from JSON string...")
        try:
            key_dict = json.loads(service_account_key)
            credentials = ee.ServiceAccountCredentials(
                key_dict['client_email'], 
                key_data=key_dict
            )
            ee.Initialize(credentials, project=project_id)
            print("✅ Earth Engine initialized with service account!")
            
        except json.JSONDecodeError:
            print("❌ Service account key is not valid JSON")
            print("   Make sure to paste the entire JSON on one line")
        except Exception as e:
            print(f"❌ Failed to initialize with service account: {e}")
            
    elif service_account_path and os.path.exists(service_account_path):
        print(f"Using service account from file: {service_account_path}")
        try:
            with open(service_account_path, 'r') as f:
                key_dict = json.load(f)
            credentials = ee.ServiceAccountCredentials(
                key_dict['client_email'],
                key_data=key_dict
            )
            ee.Initialize(credentials, project=project_id)
            print("✅ Earth Engine initialized with service account file!")
            
        except Exception as e:
            print(f"❌ Failed to initialize with service account file: {e}")
    else:
        print("⚠️  No service account configured")
        print("   Trying default authentication...")
        try:
            ee.Initialize(project=project_id)
            print("✅ Earth Engine initialized with default auth!")
        except:
            print("❌ Earth Engine initialization failed")
            print("\n   You need to either:")
            print("   1. Set GEE_SERVICE_ACCOUNT_KEY in .env")
            print("   2. Set GEE_SERVICE_ACCOUNT_PATH in .env")
            print("   3. Run 'earthengine authenticate' in terminal")
    
    # Test Earth Engine functionality
    try:
        # Simple test: get an image
        image = ee.Image('LANDSAT/LC08/C02/T1/LC08_044034_20140318')
        info = image.getInfo()
        print(f"✅ Successfully accessed Earth Engine data!")
        print(f"   Test image ID: {info['id']}")
        
        # Test NDVI calculation
        point = ee.Geometry.Point([-122.4, 37.8])  # San Francisco
        image_clip = image.clip(point.buffer(1000))
        ndvi = image_clip.normalizedDifference(['B5', 'B4'])
        print("✅ NDVI calculation test successful!")
        
    except Exception as e:
        print(f"⚠️  Earth Engine is initialized but data access failed: {e}")
        print("   This might be due to:")
        print("   - Service account not registered with Earth Engine")
        print("   - Earth Engine API not enabled in Google Cloud")
        
except ImportError:
    print("❌ earthengine-api package not installed")
    print("   Run: pip install earthengine-api")
except Exception as e:
    print(f"❌ Earth Engine test failed: {str(e)}")

# Test 4: Test MongoDB Connection
print("\n" + "=" * 40)
print("4. Testing MongoDB Connection")
print("=" * 40)

try:
    import pymongo
    from motor.motor_asyncio import AsyncIOMotorClient
    import asyncio
    
    mongodb_url = os.getenv('MONGODB_URL', 'mongodb://localhost:27017')
    
    # Test synchronous connection first
    client = pymongo.MongoClient(mongodb_url, serverSelectionTimeoutMS=5000)
    client.server_info()
    print(f"✅ MongoDB connection successful!")
    print(f"   Connected to: {mongodb_url}")
    
    # List databases
    dbs = client.list_database_names()
    print(f"   Available databases: {', '.join(dbs[:5])}")
    
except ImportError:
    print("❌ pymongo/motor packages not installed")
    print("   Run: pip install pymongo motor")
except Exception as e:
    print(f"⚠️  MongoDB connection failed: {str(e)}")
    print("   Make sure MongoDB is running locally or update MONGODB_URL")

# Summary
print("\n" + "=" * 60)
print("Test Summary")
print("=" * 60)

print("\n📋 Checklist:")
checklist = {
    "Environment file (.env)": env_path.exists(),
    "Gemini API Key": bool(os.getenv('GEMINI_API_KEY')),
    "Earth Engine Project ID": bool(os.getenv('GEE_PROJECT_ID')),
    "Earth Engine Credentials": bool(os.getenv('GEE_SERVICE_ACCOUNT_KEY') or os.getenv('GEE_SERVICE_ACCOUNT_PATH')),
}

all_good = True
for item, status in checklist.items():
    symbol = "✅" if status else "❌"
    print(f"{symbol} {item}")
    if not status:
        all_good = False

if all_good:
    print("\n🎉 All tests passed! Your backend is ready to run.")
    print("\nStart the backend with:")
    print("   python main.py")
else:
    print("\n⚠️  Some configuration is missing.")
    print("Please check the GOOGLE_API_SETUP_GUIDE.md for detailed instructions.")

print("\n" + "=" * 60)
print("For detailed setup instructions, see:")
print("📖 GOOGLE_API_SETUP_GUIDE.md")
print("=" * 60)
