from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional
from uuid import UUID

from app.Models.user import User


class UserRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_user(self, email: str, hashed_password: str) -> User:
        user = User(email=email, password=hashed_password)
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user
    
    async def get_first_user(self) -> User:
        stmt = select(User).limit(1)
        result = await self.db.execute(stmt)
        return result.scalar()
    
    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """Get user by ID."""
        stmt = select(User).where(User.user_id == UUID(user_id))
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_user_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        stmt = select(User).where(User.email == email)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def user_exists(self, email: str) -> bool:
        """Check if user exists by email."""
        stmt = select(User).where(User.email == email)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none() is not None
