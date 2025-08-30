from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class PredictionRequest(BaseModel):
    latitude: float
    longitude: float
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    radius_meters: Optional[int] = 1000

class PredictionResponse(BaseModel):
    latitude: float
    longitude: float
    predicted_coverage: float  # Percentage of mangrove coverage
    confidence: float  # Prediction confidence (0-1)
    ndvi_value: float  # Normalized Difference Vegetation Index
    prediction_date: datetime
    satellite_data_date: Optional[datetime] = None
    analysis_metadata: Optional[dict] = None

class MangroveHealthMetrics(BaseModel):
    area_hectares: float
    health_score: float  # 0-100 scale
    biomass_estimate: float
    carbon_storage: float
    biodiversity_index: float
    threat_level: str  # low, medium, high, critical

class SatelliteAnalysis(BaseModel):
    ndvi_mean: float
    ndvi_std: float
    water_body_percentage: float
    vegetation_percentage: float
    bare_soil_percentage: float
    cloud_coverage: float
    data_quality_score: float
