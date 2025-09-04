from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.response.response_dto import ResponseDTO
from app.utils.api_response import APIResponse
from app.utils.db import get_db
from app.utils.auth import get_current_active_user
from app.Models.user import User
from app.domain.describe.describe_dto import (
    GetDescribeModuleOutputsResponse,
)
from app.domain.describe.describe_service import DescribeModuleService
from app.domain.analysis.analysis_service import AnalysisService
from app.infrastructure.repositories.analysis_repository import AnalysisRepository

router = APIRouter()


@router.get("/outputs", response_model=ResponseDTO[GetDescribeModuleOutputsResponse])
async def get_describe_module_outputs(
    analysis_id: str, 
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get the describe module output file structure and paths."""
    try:
        analysis_repo = AnalysisRepository(db)
        analysis_service = AnalysisService(analysis_repo)
        
        # Verify analysis ownership
        analysis = await analysis_service.verify_analysis_ownership(analysis_id, str(current_user.user_id))

        # Initialize service
        service = DescribeModuleService()

        # Call service method
        result = await service.get_describe_module_outputs(analysis)

        return APIResponse.send_response(
            result, message="Describe module outputs retrieved successfully", code=200
        )
    except Exception as e:
        return APIResponse.send_error(message=str(e))
