"""
Async database session dependency for FastAPI.
"""

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from core.config import settings

DATABASE_URL = settings.DATABASE_URL

if not DATABASE_URL.startswith("postgresql+asyncpg://"):
    raise RuntimeError(
        "DATABASE_URL must start with 'postgresql+asyncpg://'. "
        "Current: {}".format(DATABASE_URL)
    )

engine = create_async_engine(DATABASE_URL, echo=False, future=True)
session_pool = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


async def get_db() -> AsyncSession:
    async with session_pool() as session:
        yield session
