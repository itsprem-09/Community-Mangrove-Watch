from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime
from enum import Enum

class UserRole(str, Enum):
    CITIZEN = "citizen"
    NGO = "ngo"
    GOVERNMENT = "government"
    RESEARCHER = "researcher"
    ADMIN = "admin"

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: UserRole = UserRole.CITIZEN
    organization: Optional[str] = None
    phone: Optional[str] = None
    location: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class User(BaseModel):
    id: str
    name: str
    email: EmailStr
    role: UserRole
    organization: Optional[str] = None
    phone: Optional[str] = None
    location: Optional[str] = None
    points: int = 0
    badges: List[str] = []
    is_verified: bool = False
    is_admin: bool = False
    created_at: datetime
    updated_at: datetime

class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    role: str
    organization: Optional[str] = None
    location: Optional[str] = None
    points: int
    badges: List[str] = []
    is_verified: bool
    rank: Optional[int] = None
    total_reports: Optional[int] = None
    verified_reports: Optional[int] = None
    joined_date: datetime

    @classmethod
    def from_user(cls, user: User, rank: Optional[int] = None):
        return cls(
            id=user.id,
            name=user.name,
            email=user.email,
            role=user.role.value,
            organization=user.organization,
            location=user.location,
            points=user.points,
            badges=user.badges,
            is_verified=user.is_verified,
            rank=rank,
            joined_date=user.created_at
        )
