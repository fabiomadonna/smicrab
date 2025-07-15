from datetime import datetime
from uuid import UUID

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
