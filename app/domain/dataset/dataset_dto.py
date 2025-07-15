from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class Raster(BaseModel):
    """Schema of Raster"""

    id: UUID = Field(..., description="Raster identifier")
    name: str = Field(..., description="Raster name")
    variable_name: str = Field(..., description="Raster variable name")
    from_date: datetime = Field(..., description="Start date in ISO format")
    to_date: datetime = Field(..., description="End date in ISO format")
    frequency: str = Field(..., description="Data frequency (monthly, daily, etc.)")
    file_path: str = Field(..., description="File path")
    csv_file_path: str = Field(..., description="CSV file path")

    class Config:
        json_encoders = {
            datetime: lambda dt: dt.isoformat(),
            UUID: lambda uuid: str(uuid),
        }
        from_attributes = True


class Covariate(Raster):
    x_leg: int = Field(..., description="")


class Variable(BaseModel):
    """Schema of variable"""

    id: str
    name: str
    description: Optional[str] = None
    data_type: str = "raster"
