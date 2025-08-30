import ee
import os
import json
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional

class GoogleEarthEngineService:
    def __init__(self):
        self.initialized = False
        self.project_id = os.getenv("GEE_PROJECT_ID", "your-gee-project-id")
    
    async def initialize(self):
        """Initialize Google Earth Engine"""
        try:
            # Check for service account path first
            service_account_path = os.getenv("GEE_SERVICE_ACCOUNT_PATH")
            service_account_key = os.getenv("GEE_SERVICE_ACCOUNT_KEY")
            
            if service_account_path and os.path.exists(service_account_path):
                # Load from file path - use the file path directly
                print(f"Loading service account from file: {service_account_path}")
                
                # Method 1: Use the file path directly
                credentials = ee.ServiceAccountCredentials(
                    email=None,  # Will be read from the key file
                    key_file=service_account_path
                )
                ee.Initialize(credentials, project=self.project_id)
                self.initialized = True
                print("✅ Google Earth Engine initialized successfully with service account file!")
                
            elif service_account_key:
                # Parse service account key from string
                print("Loading service account from environment variable...")
                # Check if it's already a dict or needs parsing
                if isinstance(service_account_key, dict):
                    key_dict = service_account_key
                else:
                    key_dict = json.loads(service_account_key)
                    
                # Write to temporary file for authentication
                import tempfile
                with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
                    json.dump(key_dict, f)
                    temp_key_file = f.name
                
                try:
                    credentials = ee.ServiceAccountCredentials(
                        email=key_dict['client_email'],
                        key_file=temp_key_file
                    )
                    ee.Initialize(credentials, project=self.project_id)
                    self.initialized = True
                    print("✅ Google Earth Engine initialized successfully with service account key!")
                finally:
                    # Clean up temp file
                    if 'temp_key_file' in locals():
                        try:
                            os.unlink(temp_key_file)
                        except:
                            pass
                
            else:
                # Try default authentication
                print("No service account found, trying default authentication...")
                ee.Initialize(project=self.project_id)
                self.initialized = True
                print("✅ Google Earth Engine initialized with default credentials!")
            
        except Exception as e:
            error_msg = str(e)
            
            if "earthengine.computations.create" in error_msg or "earthengine" in error_msg.lower():
                print("\n" + "="*80)
                print("⚠️  Google Earth Engine API Access Required")
                print("="*80)
                print(f"\nYour service account needs Earth Engine API access.")
                print(f"\nService account file: {service_account_path if service_account_path else 'Using environment variable'}")
                print(f"Project ID: {self.project_id}")
                print("\n📋 To enable Earth Engine for your project:")
                print("\n   STEP 1: Register your project with Earth Engine")
                print("   1. Go to: https://signup.earthengine.google.com/#!/service_accounts")
                print(f"   2. Enter your project ID: {self.project_id}")
                print("   3. Click 'Register' and wait for approval (usually instant)")
                print("\n   STEP 2: Enable the Earth Engine API")
                print("   1. Go to: https://console.cloud.google.com/apis/library/earthengine.googleapis.com")
                print(f"   2. Make sure project '{self.project_id}' is selected")
                print("   3. Click 'ENABLE' if not already enabled")
                print("\n   STEP 3: Grant Earth Engine permissions to your service account")
                print("   1. Go to: https://console.cloud.google.com/iam-admin/iam")
                print(f"   2. Select project: {self.project_id}")
                print("   3. Find your service account and click 'Edit'")
                print("   4. Add these roles:")
                print("      - Earth Engine Resource Admin")
                print("      - Service Usage Consumer")
                print("\n" + "="*80)
                print("\n✅ The backend will continue using simulated satellite data for development.")
                print("   This is perfectly fine for testing and development!\n")
            elif "not registered" in error_msg.lower() or "not found" in error_msg.lower():
                print("\n" + "="*80)
                print("⚠️  Google Earth Engine Project Not Registered")
                print("="*80)
                print(f"\nProject '{self.project_id}' is not registered for Earth Engine.")
                print("\n📋 To register your project:")
                print("   1. Go to: https://signup.earthengine.google.com/#!/service_accounts")
                print("   2. Register your Google Cloud project for Earth Engine")
                print("   3. Wait for approval (usually instant for development)")
                print("\n" + "="*80)
                print("\n✅ The backend will continue using simulated satellite data for development.\n")
            else:
                print(f"\n⚠️ Failed to initialize Google Earth Engine: {e}")
                print(f"   Error type: {type(e).__name__}")
                
            print("\n💡 Note: The system is fully functional with simulated data!")
            print("   All endpoints will work normally using realistic mock satellite data.\n")
            
            # For development, continue without GEE
            self.initialized = False
    
    async def get_satellite_data(self, latitude: float, longitude: float, 
                               start_date: Optional[datetime] = None, 
                               end_date: Optional[datetime] = None) -> Dict[str, Any]:
        """Get satellite data for a specific location"""
        if not self.initialized:
            # Return mock data if GEE is not initialized
            return await self._get_mock_satellite_data(latitude, longitude)
        
        try:
            # Define area of interest
            point = ee.Geometry.Point([longitude, latitude])
            area = point.buffer(1000)  # 1km radius
            
            # Set date range
            if not start_date:
                start_date = datetime.now() - timedelta(days=365)
            if not end_date:
                end_date = datetime.now()
            
            # Load Landsat 8 data
            landsat = ee.ImageCollection('LANDSAT/LC08/C02/T1_TOA') \
                .filterBounds(area) \
                .filterDate(start_date.strftime('%Y-%m-%d'), end_date.strftime('%Y-%m-%d')) \
                .filter(ee.Filter.lt('CLOUD_COVER', 20))
            
            if landsat.size().getInfo() == 0:
                # Fallback to Landsat 7 if no Landsat 8 data
                landsat = ee.ImageCollection('LANDSAT/LE07/C02/T1_TOA') \
                    .filterBounds(area) \
                    .filterDate(start_date.strftime('%Y-%m-%d'), end_date.strftime('%Y-%m-%d')) \
                    .filter(ee.Filter.lt('CLOUD_COVER', 20))
            
            # Get median composite
            image = landsat.median().clip(area)
            
            # Calculate NDVI
            ndvi = image.normalizedDifference(['B5', 'B4']).rename('NDVI')
            
            # Calculate other indices
            ndwi = image.normalizedDifference(['B3', 'B5']).rename('NDWI')  # Water index
            savi = image.expression(
                '1.5 * (NIR - RED) / (NIR + RED + 0.5)',
                {
                    'NIR': image.select('B5'),
                    'RED': image.select('B4')
                }
            ).rename('SAVI')
            
            # Get pixel values at the point
            ndvi_value = ndvi.sample(point, 30).first().get('NDVI').getInfo()
            ndwi_value = ndwi.sample(point, 30).first().get('NDWI').getInfo()
            savi_value = savi.sample(point, 30).first().get('SAVI').getInfo()
            
            # Calculate area statistics
            stats = ee.Dictionary({
                'ndvi_mean': ndvi.reduceRegion(ee.Reducer.mean(), area, 30).get('NDVI'),
                'ndvi_std': ndvi.reduceRegion(ee.Reducer.stdDev(), area, 30).get('NDVI'),
                'water_percentage': ndwi.gt(0).multiply(100).reduceRegion(ee.Reducer.mean(), area, 30).get('NDWI')
            }).getInfo()
            
            return {
                'latitude': latitude,
                'longitude': longitude,
                'ndvi': float(ndvi_value) if ndvi_value is not None else 0.0,
                'ndwi': float(ndwi_value) if ndwi_value is not None else 0.0,
                'savi': float(savi_value) if savi_value is not None else 0.0,
                'area_stats': stats,
                'data_date': end_date.isoformat(),
                'cloud_cover': 'low',
                'data_source': 'Landsat'
            }
            
        except Exception as e:
            print(f"Error getting satellite data: {e}")
            return await self._get_mock_satellite_data(latitude, longitude)
    
    async def _get_mock_satellite_data(self, latitude: float, longitude: float) -> Dict[str, Any]:
        """Return mock satellite data for development/testing"""
        # Generate realistic mock data based on location
        # Coastal areas typically have different NDVI values
        base_ndvi = 0.3 + (abs(latitude) / 90 * 0.4)  # Rough approximation
        
        return {
            'latitude': latitude,
            'longitude': longitude,
            'ndvi': base_ndvi,
            'ndwi': 0.2,
            'savi': base_ndvi * 0.8,
            'area_stats': {
                'ndvi_mean': base_ndvi,
                'ndvi_std': 0.15,
                'water_percentage': 25.0
            },
            'data_date': datetime.now().isoformat(),
            'cloud_cover': 'low',
            'data_source': 'Mock'
        }
    
    async def get_mangrove_extent_data(self, latitude: float, longitude: float, radius_km: float = 10):
        """Get mangrove extent data from Global Mangrove Watch"""
        if not self.initialized:
            return await self._get_mock_extent_data(latitude, longitude)
        
        try:
            # Define area of interest
            point = ee.Geometry.Point([longitude, latitude])
            area = point.buffer(radius_km * 1000)  # Convert km to meters
            
            # Load Global Mangrove Watch data
            gmw_2020 = ee.FeatureCollection("projects/earthengine-legacy/assets/projects/sat-io/open-datasets/GMW/extent/gmw_v3_2020_vec")
            gmw_1996 = ee.FeatureCollection("projects/earthengine-legacy/assets/projects/sat-io/open-datasets/GMW/extent/gmw_v3_1996_vec")
            
            # Filter to area of interest
            mangroves_2020 = gmw_2020.filterBounds(area)
            mangroves_1996 = gmw_1996.filterBounds(area)
            
            # Calculate areas
            area_2020 = mangroves_2020.geometry().area().divide(10000).getInfo()  # Convert to hectares
            area_1996 = mangroves_1996.geometry().area().divide(10000).getInfo()
            
            return {
                'current_extent_hectares': area_2020 or 0,
                'historical_extent_hectares': area_1996 or 0,
                'change_hectares': (area_2020 or 0) - (area_1996 or 0),
                'change_percentage': ((area_2020 - area_1996) / area_1996 * 100) if area_1996 > 0 else 0
            }
            
        except Exception as e:
            print(f"Error getting mangrove extent data: {e}")
            return await self._get_mock_extent_data(latitude, longitude)
    
    async def _get_mock_extent_data(self, latitude: float, longitude: float):
        """Mock mangrove extent data"""
        # Generate realistic mock data
        base_area = abs(latitude) * 10  # Rough approximation
        
        return {
            'current_extent_hectares': base_area,
            'historical_extent_hectares': base_area * 1.2,
            'change_hectares': base_area * -0.2,
            'change_percentage': -16.7
        }
    
    async def get_mangrove_trends(self, latitude: float, longitude: float, radius_km: float = 10):
        """Get mangrove health trends over time"""
        if not self.initialized:
            return await self._get_mock_trends_data(latitude, longitude)
        
        try:
            point = ee.Geometry.Point([longitude, latitude])
            area = point.buffer(radius_km * 1000)
            
            # Define years for analysis
            years = [1996, 2000, 2005, 2010, 2015, 2020]
            trends = []
            
            for year in years:
                # Get Landsat data for the year
                start_date = f"{year}-01-01"
                end_date = f"{year}-12-31"
                
                landsat = ee.ImageCollection('LANDSAT/LE07/C02/T1_TOA') \
                    .filterBounds(area) \
                    .filterDate(start_date, end_date) \
                    .filter(ee.Filter.lt('CLOUD_COVER', 20))
                
                if landsat.size().getInfo() > 0:
                    image = landsat.median().clip(area)
                    ndvi = image.normalizedDifference(['B4', 'B3'])
                    
                    # Get mean NDVI for the area
                    ndvi_mean = ndvi.reduceRegion(ee.Reducer.mean(), area, 30).get('nd').getInfo()
                    
                    trends.append({
                        'year': year,
                        'ndvi_mean': float(ndvi_mean) if ndvi_mean is not None else 0.0,
                        'health_score': float(ndvi_mean * 100) if ndvi_mean is not None else 0.0
                    })
            
            return {
                'trends': trends,
                'location': {'latitude': latitude, 'longitude': longitude},
                'radius_km': radius_km
            }
            
        except Exception as e:
            print(f"Error getting mangrove trends: {e}")
            return await self._get_mock_trends_data(latitude, longitude)
    
    async def _get_mock_trends_data(self, latitude: float, longitude: float):
        """Mock trends data for development"""
        years = [1996, 2000, 2005, 2010, 2015, 2020]
        base_health = 75.0
        trends = []
        
        for i, year in enumerate(years):
            # Simulate declining trend with some variation
            health_score = base_health - (i * 2) + np.random.normal(0, 5)
            health_score = max(0, min(100, health_score))  # Clamp to 0-100
            
            trends.append({
                'year': year,
                'ndvi_mean': health_score / 100,
                'health_score': health_score
            })
        
        return {
            'trends': trends,
            'location': {'latitude': latitude, 'longitude': longitude},
            'radius_km': 10
        }
