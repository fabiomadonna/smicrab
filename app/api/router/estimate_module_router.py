from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.response.response_dto import ResponseDTO
from app.utils.api_response import APIResponse
from app.utils.db import get_db
from app.domain.estimate.estimate_dto import (
    GetEstimateOutputsResponse,
)
from app.domain.estimate.estimate_service import EstimateModuleService
from app.domain.analysis.analysis_service import AnalysisService
from app.infrastructure.repositories.analysis_repository import AnalysisRepository

router = APIRouter()


@router.get("/outputs", response_model=ResponseDTO[GetEstimateOutputsResponse])
async def get_estimate_outputs(analysis_id: str, db: AsyncSession = Depends(get_db)):
    """Get estimate module outputs for the given analysis and model type."""
    try:
        analysis_repo = AnalysisRepository(db)
        analysis_service = AnalysisService(analysis_repo)
        analysis = await analysis_service.verify_analysis(analysis_id)

        # Initialize service
        service = EstimateModuleService()

        # Call service method
        result = await service.get_estimate_outputs(analysis)

        return APIResponse.send_response(
            result, message="Estimate module outputs retrieved successfully", code=200
        )
    except Exception as e:
        return APIResponse.send_error(message=str(e))
