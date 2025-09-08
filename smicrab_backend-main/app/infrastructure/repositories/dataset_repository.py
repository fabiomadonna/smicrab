from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.Models.dataset import Dataset


class DatasetRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_all(self) -> List[Dataset]:
        stmt = select(Dataset)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, dataset_id: str) -> Dataset:
        stmt = select(Dataset).where(Dataset.id == dataset_id)
        result = await self.db.execute(stmt)
        return result.scalar()

    async def get_by_variable_name(self, variable_name: str) -> Dataset:
        stmt = select(Dataset).where(Dataset.variable_name == variable_name)
        result = await self.db.execute(stmt)
        return result.scalar()
