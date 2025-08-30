import jwt
from datetime import datetime, timedelta
from passlib.context import CryptContext
from fastapi import HTTPException
import os
from typing import Optional

from models.user import User, UserCreate, UserLogin
from database.mongodb import Database

class AuthService:
    def __init__(self, db_instance=None):
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        # Use JWT configuration from environment variables
        self.secret_key = os.getenv("JWT_SECRET_KEY", os.getenv("JWT_SECRET", "your-secret-key-change-in-production"))
        self.algorithm = os.getenv("JWT_ALGORITHM", "HS256")
        # Use ACCESS_TOKEN_EXPIRE_MINUTES from env (default 1440 = 24 hours)
        self.access_token_expire_minutes = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))
        self.db = db_instance if db_instance else Database()
        
        # Log configuration for debugging
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"JWT configured with algorithm: {self.algorithm}, expiry: {self.access_token_expire_minutes} minutes")
    
    def hash_password(self, password: str) -> str:
        """Hash a password"""
        return self.pwd_context.hash(password)
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify a password against its hash"""
        return self.pwd_context.verify(plain_password, hashed_password)
    
    def create_access_token(self, data: dict) -> str:
        """Create JWT access token"""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(minutes=self.access_token_expire_minutes)
        to_encode.update({"exp": expire})
        
        encoded_jwt = jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)
        return encoded_jwt
    
    def decode_token(self, token: str) -> dict:
        """Decode JWT token"""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            return payload
        except jwt.PyJWTError:
            raise HTTPException(status_code=401, detail="Invalid token")
    
    async def register_user(self, user_data: UserCreate) -> User:
        """Register a new user"""
        # Check if user already exists
        existing_user = await self.db.get_user_by_email(user_data.email)
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # Hash password
        hashed_password = self.hash_password(user_data.password)
        
        # Create user
        user = await self.db.create_user(user_data, hashed_password)
        return user
    
    async def authenticate_user(self, credentials: UserLogin) -> str:
        """Authenticate user and return JWT token"""
        # Get user from database
        user_doc = await self.db.users.find_one({"email": credentials.email})
        if not user_doc:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        # Verify password
        if not self.verify_password(credentials.password, user_doc["password"]):
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        # Create access token
        access_token = self.create_access_token(
            data={"sub": user_doc["_id"], "email": user_doc["email"]}
        )
        
        return access_token
    
    async def get_current_user(self, token: str) -> User:
        """Get current user from JWT token"""
        payload = self.decode_token(token)
        user_id = payload.get("sub")
        
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        user = await self.db.get_user_by_id(user_id)
        if user is None:
            raise HTTPException(status_code=401, detail="User not found")
        
        return user
    
    async def add_user_points(self, user_id: str, points: int):
        """Add points to user's total"""
        await self.db.update_user_points(user_id, points)
    
    async def check_admin_permissions(self, user: User) -> bool:
        """Check if user has admin permissions"""
        return user.is_admin or user.role.value in ["admin", "government"]
