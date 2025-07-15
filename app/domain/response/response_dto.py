from typing import Generic, TypeVar, Optional
from pydantic import BaseModel

T = TypeVar("T")


class ResponseDTO(BaseModel, Generic[T]):
    success: bool = True
    data: Optional[T] = None
    message: str = ""
