from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.response.response_dto import ResponseDTO
from app.utils.api_response import APIResponse
from app.utils.db import get_db
from app.utils.auth import get_current_active_user
from app.Models.user import User
from app.domain.validate.validate_dto import (
    GetValidateOutputsResponse,
)
from app.domain.validate.validate_service import ValidateModuleService
from app.utils.logger import Logger
from app.utils.utils import get_analysis_path
import os
from app.domain.analysis.analysis_service import AnalysisService
from app.infrastructure.repositories.analysis_repository import AnalysisRepository

router = APIRouter()


@router.get("/outputs", response_model=ResponseDTO[GetValidateOutputsResponse])
async def get_validate_outputs(
    analysis_id: str, 
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get validate module outputs for the given analysis and model type."""
    try:
        analysis_repo = AnalysisRepository(db)
        analysis_service = AnalysisService(analysis_repo)
        
        # Verify analysis ownership
        analysis = await analysis_service.verify_analysis_ownership(analysis_id, str(current_user.user_id))

        # Initialize service
        service = ValidateModuleService()
        
        # Call service method
        result = await service.get_validate_outputs(analysis)
        
        return APIResponse.send_response(
            result, 
            message="Validate module outputs retrieved successfully", 
            code=200
        )
    except Exception as e:
        return APIResponse.send_error(message=str(e))


@router.get("/download-file/{analysis_id}/{file_name}")
async def download_validate_file(
    analysis_id: str,
    file_name: str,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    """Download validate module result files."""
    try:
        # Verify analysis ownership
        analysis_repo = AnalysisRepository(db)
        analysis_service = AnalysisService(analysis_repo)
        await analysis_service.verify_analysis_ownership(analysis_id, str(current_user.user_id))
        
        # Construct file path
        file_path = get_analysis_path(analysis_id)
        
        if not os.path.exists(file_path):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"File {file_name} not found for analysis {analysis_id}",
            )
        
        return FileResponse(
            path=file_path,
            filename=file_name,
            media_type="application/octet-stream",
        )
    except HTTPException:
        raise
    except Exception as e:
        Logger.error(
            f"Failed to download validate file: {e}",
            context={
                "endpoint": "download_validate_file",
                "analysis_id": analysis_id,
                "file_name": file_name,
            },
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to download file: {str(e)}",
        )