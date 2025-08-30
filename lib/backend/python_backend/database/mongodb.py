from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.errors import DuplicateKeyError
from typing import List, Optional
from datetime import datetime, timedelta
import os
from uuid import uuid4

from models.user import User, UserCreate, UserRole
from models.incident import IncidentReport, IncidentCreate, IncidentStatus

class Database:
    def __init__(self):
        self.client = None
        self.db = None
        self.users = None
        self.incidents = None
        self.analytics = None
        
    async def connect(self):
        """Connect to MongoDB"""
        mongodb_url = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
        self.client = AsyncIOMotorClient(mongodb_url)
        self.db = self.client.mangrove_watch
        
        # Collections
        self.users = self.db.users
        self.incidents = self.db.incidents
        self.analytics = self.db.analytics
        
        # Create indexes
        await self.create_indexes()
        
    async def disconnect(self):
        """Disconnect from MongoDB"""
        if self.client:
            self.client.close()
    
    async def create_indexes(self):
        """Create database indexes for optimal performance"""
        # User indexes
        await self.users.create_index("email", unique=True)
        await self.users.create_index("points")
        
        # Incident indexes
        await self.incidents.create_index([("latitude", 1), ("longitude", 1)])
        await self.incidents.create_index("status")
        await self.incidents.create_index("created_at")
        await self.incidents.create_index("user_id")
    
    # User operations
    async def create_user(self, user_data: UserCreate, hashed_password: str) -> User:
        """Create a new user"""
        user_id = str(uuid4())
        now = datetime.utcnow()
        
        user_doc = {
            "_id": user_id,
            "name": user_data.name,
            "email": user_data.email,
            "password": hashed_password,
            "role": user_data.role.value,
            "organization": user_data.organization,
            "phone": user_data.phone,
            "location": user_data.location,
            "points": 0,
            "badges": [],
            "is_verified": False,
            "is_admin": user_data.role == UserRole.ADMIN,
            "created_at": now,
            "updated_at": now
        }
        
        result = await self.users.insert_one(user_doc)
        return await self.get_user_by_id(user_id)
    
    async def get_user_by_email(self, email: str) -> Optional[User]:
        """Get user by email"""
        user_doc = await self.users.find_one({"email": email})
        if user_doc:
            return self._doc_to_user(user_doc)
        return None
    
    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """Get user by ID"""
        user_doc = await self.users.find_one({"_id": user_id})
        if user_doc:
            return self._doc_to_user(user_doc)
        return None
    
    def _doc_to_user(self, user_doc: dict) -> User:
        """Convert MongoDB document to User model"""
        return User(
            id=user_doc["_id"],
            name=user_doc["name"],
            email=user_doc["email"],
            role=UserRole(user_doc["role"]),
            organization=user_doc.get("organization"),
            phone=user_doc.get("phone"),
            location=user_doc.get("location"),
            points=user_doc.get("points", 0),
            badges=user_doc.get("badges", []),
            is_verified=user_doc.get("is_verified", False),
            is_admin=user_doc.get("is_admin", False),
            created_at=user_doc["created_at"],
            updated_at=user_doc["updated_at"]
        )
    
    async def update_user_points(self, user_id: str, points_to_add: int):
        """Add points to user's total"""
        await self.users.update_one(
            {"_id": user_id},
            {
                "$inc": {"points": points_to_add},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
    
    # Incident operations
    async def create_incident(self, incident_data: IncidentCreate, user_id: str) -> IncidentReport:
        """Create a new incident report"""
        incident_id = str(uuid4())
        now = datetime.utcnow()
        
        incident_doc = {
            "_id": incident_id,
            "user_id": user_id,
            "type": incident_data.type.value,
            "title": incident_data.title,
            "description": incident_data.description,
            "latitude": incident_data.latitude,
            "longitude": incident_data.longitude,
            "address": incident_data.address,
            "severity": incident_data.severity.value,
            "status": IncidentStatus.PENDING.value,
            "images": incident_data.images,
            "estimated_area": incident_data.estimated_area,
            "additional_notes": incident_data.additional_notes,
            "ai_analysis": None,
            "verification_notes": None,
            "verified_by": None,
            "points_awarded": 0,
            "created_at": now,
            "updated_at": now,
            "resolved_at": None
        }
        
        await self.incidents.insert_one(incident_doc)
        return await self.get_incident_by_id(incident_id)
    
    async def get_incidents(self, skip: int = 0, limit: int = 50, status_filter: Optional[str] = None) -> List[IncidentReport]:
        """Get incidents with pagination and filtering"""
        query = {}
        if status_filter:
            query["status"] = status_filter
        
        cursor = self.incidents.find(query).sort("created_at", -1).skip(skip).limit(limit)
        incidents = []
        async for doc in cursor:
            incidents.append(self._doc_to_incident(doc))
        
        return incidents
    
    async def get_incident_by_id(self, incident_id: str) -> Optional[IncidentReport]:
        """Get incident by ID"""
        incident_doc = await self.incidents.find_one({"_id": incident_id})
        if incident_doc:
            return self._doc_to_incident(incident_doc)
        return None
    
    def _doc_to_incident(self, incident_doc: dict) -> IncidentReport:
        """Convert MongoDB document to IncidentReport model"""
        return IncidentReport(
            id=incident_doc["_id"],
            user_id=incident_doc["user_id"],
            type=incident_doc["type"],
            title=incident_doc["title"],
            description=incident_doc["description"],
            latitude=incident_doc["latitude"],
            longitude=incident_doc["longitude"],
            address=incident_doc.get("address"),
            severity=incident_doc["severity"],
            status=incident_doc["status"],
            images=incident_doc.get("images", []),
            estimated_area=incident_doc.get("estimated_area"),
            additional_notes=incident_doc.get("additional_notes"),
            ai_analysis=incident_doc.get("ai_analysis"),
            verification_notes=incident_doc.get("verification_notes"),
            verified_by=incident_doc.get("verified_by"),
            points_awarded=incident_doc.get("points_awarded", 0),
            created_at=incident_doc["created_at"],
            updated_at=incident_doc["updated_at"],
            resolved_at=incident_doc.get("resolved_at")
        )
    
    async def verify_incident(self, incident_id: str, verification: dict, verifier_id: str):
        """Verify an incident report"""
        update_doc = {
            "verification_notes": verification.get("notes"),
            "verified_by": verifier_id,
            "updated_at": datetime.utcnow()
        }
        
        if verification.get("approved"):
            update_doc["status"] = IncidentStatus.VERIFIED.value
            update_doc["points_awarded"] = verification.get("points", 10)
        else:
            update_doc["status"] = IncidentStatus.REJECTED.value
        
        result = await self.incidents.update_one(
            {"_id": incident_id},
            {"$set": update_doc}
        )
        
        # Award points to user if incident is verified
        if verification.get("approved"):
            incident = await self.get_incident_by_id(incident_id)
            await self.update_user_points(incident.user_id, update_doc["points_awarded"])
        
        return {"success": result.modified_count > 0}
    
    # Analytics and leaderboard
    async def get_leaderboard(self, limit: int = 50):
        """Get user leaderboard by points"""
        cursor = self.users.find({}, {"password": 0}).sort("points", -1).limit(limit)
        leaderboard = []
        rank = 1
        async for doc in cursor:
            user_stats = await self.get_user_stats(doc["_id"])
            leaderboard.append({
                "rank": rank,
                "name": doc["name"],
                "points": doc["points"],
                "total_reports": user_stats.get("total_reports", 0),
                "verified_reports": user_stats.get("verified_reports", 0),
                "badges": doc.get("badges", []),
                "organization": doc.get("organization")
            })
            rank += 1
        
        return leaderboard
    
    async def get_user_stats(self, user_id: str):
        """Get user statistics"""
        total_reports = await self.incidents.count_documents({"user_id": user_id})
        verified_reports = await self.incidents.count_documents({
            "user_id": user_id,
            "status": IncidentStatus.VERIFIED.value
        })
        
        # Calculate badges
        badges = []
        if total_reports >= 1:
            badges.append("First Reporter")
        if total_reports >= 10:
            badges.append("Active Reporter")
        if total_reports >= 50:
            badges.append("Super Reporter")
        if verified_reports >= 5:
            badges.append("Verified Contributor")
        
        return {
            "total_reports": total_reports,
            "verified_reports": verified_reports,
            "badges": badges
        }
    
    async def get_dashboard_analytics(self):
        """Get analytics for dashboard"""
        total_incidents = await self.incidents.count_documents({})
        pending_incidents = await self.incidents.count_documents({"status": IncidentStatus.PENDING.value})
        verified_incidents = await self.incidents.count_documents({"status": IncidentStatus.VERIFIED.value})
        resolved_incidents = await self.incidents.count_documents({"status": IncidentStatus.RESOLVED.value})
        
        total_users = await self.users.count_documents({})
        active_users = await self.users.count_documents({
            "updated_at": {"$gte": datetime.utcnow() - timedelta(days=30)}
        })
        
        # Recent incidents by type
        pipeline = [
            {"$match": {"created_at": {"$gte": datetime.utcnow() - timedelta(days=30)}}},
            {"$group": {"_id": "$type", "count": {"$sum": 1}}},
            {"$sort": {"count": -1}}
        ]
        incidents_by_type = []
        async for doc in self.incidents.aggregate(pipeline):
            incidents_by_type.append({
                "type": doc["_id"],
                "count": doc["count"]
            })
        
        return {
            "total_incidents": total_incidents,
            "pending_incidents": pending_incidents,
            "verified_incidents": verified_incidents,
            "resolved_incidents": resolved_incidents,
            "total_users": total_users,
            "active_users": active_users,
            "incidents_by_type": incidents_by_type,
            "verification_rate": (verified_incidents / total_incidents * 100) if total_incidents > 0 else 0
        }
