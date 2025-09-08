from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from app.Models.analysis import Analysis, AnalyzeStatus
from app.utils.enums import ModuleName, ModelType
from typing import List, Dict, Any
from datetime import datetime


class AnalysisRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, analysis_id: str) -> Analysis:
        stmt = select(Analysis).where(Analysis.id == analysis_id)
        result = await self.db.execute(stmt)
        analysis = result.scalar()
        if analysis:
            await self.db.refresh(analysis)
        return analysis

    async def create_analysis(self, user_id: str) -> Analysis:
        analysis = Analysis(user_id=user_id)
        self.db.add(analysis)
        await self.db.commit()
        await self.db.refresh(analysis)
        return analysis

    async def delete_analysis(self, analysis_id: str) -> bool:
        """Delete an analysis from the database."""
        try:
            stmt = delete(Analysis).where(Analysis.id == analysis_id)
            result = await self.db.execute(stmt)
            await self.db.commit()
            return result.rowcount > 0
        except Exception as e:
            await self.db.rollback()
            raise e

    async def update_current_module(
        self,
        analysis_id: str,
        module_name: ModuleName,
        status: AnalyzeStatus = AnalyzeStatus.in_progress,
    ) -> Analysis:
        """Update the current_module of an analysis."""
        await self.db.execute(
            update(Analysis)
            .where(Analysis.id == analysis_id)
            .values(current_module=module_name, status=status)
        )
        await self.db.commit()
        return await self.get_by_id(analysis_id)

    async def update_analysis_config(
        self,
        analysis_id: str,
        model_type: ModelType,
        model_config: Dict[str, Any],
        coordinates: Dict[str, Any],
        is_dynamic_output: bool,
        analysis_date: datetime,
    ) -> Analysis:
        """Update the analysis configuration with all user inputs."""
        await self.db.execute(
            update(Analysis)
            .where(Analysis.id == analysis_id)
            .values(
                model_type=model_type.value,
                model_config=model_config,
                coordinates=coordinates,
                is_dynamic_output=is_dynamic_output,
                analysis_date=analysis_date,
            )
        )
        await self.db.commit()
        return await self.get_by_id(analysis_id)

    async def update_status(
        self,
        analysis_id: str,
        status: AnalyzeStatus,
    ) -> Analysis:
        """Update the status of an analysis."""
        await self.db.execute(
            update(Analysis).where(Analysis.id == analysis_id).values(status=status)
        )
        await self.db.commit()
        return await self.get_by_id(analysis_id)

    async def get_user_analyses(self, user_id: str) -> List[Analysis]:
        """Retrieve all analyses for a specific user."""
        stmt = select(Analysis).where(Analysis.user_id == user_id)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def add_error_message(self, analysis_id: str, error_message: str):
        """Add an error message to an analysis."""
        await self.db.execute(
            update(Analysis).where(Analysis.id == analysis_id).values(error_message=error_message)
        )
        await self.db.commit()
        return await self.get_by_id(analysis_id)