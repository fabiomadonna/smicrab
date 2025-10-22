"""
User API Endpoints for SMICRAB
"""

from fastapi import APIRouter, Depends

from app.domain.response.response_dto import ResponseDTO
from app.domain.user.user_service import UserService
from app.infrastructure.repositories.user_repository import UserRepository
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.user.user_dto import (
    CreateUserRequest, 
    CreateUserResponse,
    LoginRequest,
    LoginResponse,
    RefreshTokenRequest,
    RefreshTokenResponse,
    UserProfileResponse
)
from app.utils.api_response import APIResponse
from app.utils.db import get_db
from app.utils.auth import get_current_active_user
from app.Models.user import User

router = APIRouter()


@router.post("/register", response_model=ResponseDTO[CreateUserResponse])
async def register_user(
    request: CreateUserRequest,
    db: AsyncSession = Depends(get_db),
):
    """Register a new user."""
    try:
        repo = UserRepository(db)
        service = UserService(repo)
        result = await service.create_user(request)
        return APIResponse.send_response(
            result, message="User registered successfully", code=201
        )
    except Exception as e:
        return APIResponse.send_error(message=str(e))


@router.post("/login", response_model=ResponseDTO[LoginResponse])
async def login_user(
    request: LoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """Login user and return JWT tokens."""
    try:
        repo = UserRepository(db)
        service = UserService(repo)
        result = await service.login_user(request)
        return APIResponse.send_response(
            result, message="Login successful", code=200
        )
    except Exception as e:
        return APIResponse.send_error(message=str(e), code=401)


@router.post("/refresh", response_model=ResponseDTO[RefreshTokenResponse])
async def refresh_token(
    request: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    """Refresh access token using refresh token."""
    try:
        repo = UserRepository(db)
        service = UserService(repo)
        result = await service.refresh_token(request)
        return APIResponse.send_response(
            result, message="Token refreshed successfully", code=200
        )
    except Exception as e:
        return APIResponse.send_error(message=str(e), code=401)


@router.get("/me", response_model=ResponseDTO[UserProfileResponse])
async def get_current_user_profile(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current user profile."""
    try:
        repo = UserRepository(db)
        service = UserService(repo)
        result = await service.get_user_profile(str(current_user.user_id))
        return APIResponse.send_response(
            result, message="User profile retrieved successfully", code=200
        )
    except Exception as e:
        return APIResponse.send_error(message=str(e), code=404)