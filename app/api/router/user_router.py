"""
User API Endpoints for SMICRAB
"""

from fastapi import APIRouter, Depends

from app.domain.response.response_dto import ResponseDTO
from app.domain.user.user_service import UserService
from app.infrastructure.repositories.user_repository import UserRepository
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.user.user_dto import CreateUserRequest, CreateUserResponse
from app.utils.api_response import APIResponse
from app.utils.db import get_db

router = APIRouter()


@router.post("/create", response_model=ResponseDTO[CreateUserResponse])
async def create_user(
    request: CreateUserRequest,
    db: AsyncSession = Depends(get_db),
):
    try:
        print(f"request: {request}")
        repo = UserRepository(db)
        service = UserService(repo)
        result = await service.create_user(request)
        return APIResponse.send_response(
            result, message="User created successfully", code=201
        )

    except Exception as e:
        return APIResponse.send_error(message=str(e))
