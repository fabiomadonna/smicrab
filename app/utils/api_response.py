from fastapi import HTTPException
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder

from app.domain.response.response_dto import ResponseDTO


class APIResponse:

    @staticmethod
    def send_response(data, message: str = "", code: int = 200, headers: dict = None):
        response = ResponseDTO(
            success=True,
            message=message,
            data=data,
        )

        return JSONResponse(
            status_code=code,
            content=jsonable_encoder(response.model_dump()),
            headers=headers,
        )

        # return JSONResponse(status_code=code, content=response.model_dump())

    @staticmethod
    def send_error(message: str = "Something went wrong", code: int = 400, headers: dict = None):
        response = ResponseDTO(
            success=False,
            data=None,
            message=message,
        )
        return JSONResponse(
            status_code=code,
            content=jsonable_encoder(response.model_dump()),
            headers=headers,
        )

    @staticmethod
    def rollback(task: str, message: str = "Something went wrong"):
        # Placeholder for rollback logic (e.g., database transaction rollback)
        return APIResponse.throw(task, message)

    @staticmethod
    def throw(task: str, message: str = "Something went wrong"):
        content = {
            "status": "failed",
            "message": message,
            "task": task,
        }
        raise HTTPException(status_code=422, detail=content)
