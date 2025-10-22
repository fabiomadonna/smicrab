"""
Dataset API Endpoints for SMICRAB
"""

import os
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.domain.dataset.dataset_dto import (
    Raster
)
from app.domain.dataset.dataset_service import DatasetService
from app.domain.response.response_dto import ResponseDTO
from app.infrastructure.repositories.dataset_repository import DatasetRepository
from app.utils.api_response import APIResponse
from app.utils.db import get_db
from app.utils.enums import AnalysisVariable

router = APIRouter()

@router.get("/", response_model=ResponseDTO[List[Raster]])
async def get_all_datasets(
    db: AsyncSession = Depends(get_db),
):
    """Get list of all available datasets."""
    try:
        repo = DatasetRepository(db)
        service = DatasetService(repo)
        
        result = await service.get_all()
        
        return APIResponse.send_response(
            result, message="datasets retrieved successfully", code=200
        )
    except Exception as e:
        return APIResponse.send_error(message=str(e))


@router.get("/rasters", response_model=ResponseDTO[List[Raster]])
async def get_all_rasters(
    db: AsyncSession = Depends(get_db),
):
    """Get list of all available rasters that match AnalysisVariable enum."""
    try:
        repo = DatasetRepository(db)
        service = DatasetService(repo)
        
        result = await service.get_all()
        
        filtered_result = [
            raster for raster in result 
            if raster.variable_name in AnalysisVariable.get_all_variables()
        ]
        
        return APIResponse.send_response(
            filtered_result, message="rasters retrieved successfully", code=200
        )
    except Exception as e:
        return APIResponse.send_error(message=str(e))


@router.get("/{dataset_id}", response_model=ResponseDTO[Raster])
async def get_dataset_by_id(
    dataset_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Get dataset by ID."""
    try:
        repo = DatasetRepository(db)
        service = DatasetService(repo)
        
        result = await service.get_by_id(dataset_id)
        
        if not result:
            raise HTTPException(status_code=404, detail="Dataset not found")
            
        return APIResponse.send_response(
            result, message="dataset retrieved successfully", code=200
        )
    except Exception as e:
        return APIResponse.send_error(message=str(e)) 