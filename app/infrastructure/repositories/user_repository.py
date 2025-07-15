from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

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
