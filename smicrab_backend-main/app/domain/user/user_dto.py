from datetime import datetime
from uuid import UUID
from typing import Optional

from pydantic import BaseModel, Field


class CreateUserRequest(BaseModel):
    """Request model for creating a user."""

    email: str = Field(..., description="User email address")
    password: str = Field(..., description="User password")


class CreateUserResponse(BaseModel):
    user_id: UUID
    email: str
    created_at: datetime

    class Config:
        json_encoders = {
            datetime: lambda dt: dt.isoformat(),
            UUID: lambda uuid: str(uuid),
        }
        from_attributes = True


class LoginRequest(BaseModel):
    """Request model for user login."""

    email: str = Field(..., description="User email address")
    password: str = Field(..., description="User password")


class LoginResponse(BaseModel):
    """Response model for user login."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: UUID
    email: str

    class Config:
        json_encoders = {
            UUID: lambda uuid: str(uuid),
        }
        from_attributes = True


class RefreshTokenRequest(BaseModel):
    """Request model for refreshing access token."""

    refresh_token: str = Field(..., description="Refresh token")


class RefreshTokenResponse(BaseModel):
    """Response model for refreshing access token."""

    access_token: str
    token_type: str = "bearer"

    class Config:
        from_attributes = True


class UserProfileResponse(BaseModel):
    """Response model for user profile."""

    user_id: UUID
    email: str
    created_at: datetime

    class Config:
        json_encoders = {
            datetime: lambda dt: dt.isoformat(),
            UUID: lambda uuid: str(uuid),
        }
        from_attributes = True
