from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from enum import Enum

class IncidentType(str, Enum):
    ILLEGAL_CUTTING = "illegal_cutting"
    LAND_RECLAMATION = "land_reclamation"
    POLLUTION = "pollution"
    DUMPING = "dumping"
    RESTORATION_OPPORTUNITY = "restoration_opportunity"
    HEALTHY_MANGROVES = "healthy_mangroves"
    OTHER = "other"

class IncidentStatus(str, Enum):
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"
    RESOLVED = "resolved"
    IN_PROGRESS = "in_progress"

class IncidentSeverity(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class IncidentCreate(BaseModel):
    type: IncidentType
    title: str
    description: str
    latitude: float
    longitude: float
    address: Optional[str] = None
    severity: IncidentSeverity = IncidentSeverity.MEDIUM
    images: List[str] = []  # Base64 encoded images or file paths
    estimated_area: Optional[float] = None  # Area affected in square meters
    additional_notes: Optional[str] = None

class IncidentReport(BaseModel):
    id: str
    user_id: str
    type: IncidentType
    title: str
    description: str
    latitude: float
    longitude: float
    address: Optional[str] = None
    severity: IncidentSeverity
    status: IncidentStatus = IncidentStatus.PENDING
    images: List[str] = []
    estimated_area: Optional[float] = None
    additional_notes: Optional[str] = None
    ai_analysis: Optional[dict] = None
    verification_notes: Optional[str] = None
    verified_by: Optional[str] = None
    points_awarded: int = 0
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime] = None

class IncidentResponse(BaseModel):
    id: str
    user_name: str
    user_id: str
    type: str
    title: str
    description: str
    latitude: float
    longitude: float
    address: Optional[str] = None
    severity: str
    status: str
    images: List[str] = []
    estimated_area: Optional[float] = None
    ai_analysis: Optional[dict] = None
    verification_notes: Optional[str] = None
    points_awarded: int
    created_at: datetime
    updated_at: datetime
    days_ago: Optional[int] = None

    @classmethod
    def from_incident(cls, incident: IncidentReport, user_name: str = "Unknown"):
        days_ago = (datetime.utcnow() - incident.created_at).days
        return cls(
            id=incident.id,
            user_name=user_name,
            user_id=incident.user_id,
            type=incident.type.value,
            title=incident.title,
            description=incident.description,
            latitude=incident.latitude,
            longitude=incident.longitude,
            address=incident.address,
            severity=incident.severity.value,
            status=incident.status.value,
            images=incident.images,
            estimated_area=incident.estimated_area,
            ai_analysis=incident.ai_analysis,
            verification_notes=incident.verification_notes,
            points_awarded=incident.points_awarded,
            created_at=incident.created_at,
            updated_at=incident.updated_at,
            days_ago=days_ago
        )
