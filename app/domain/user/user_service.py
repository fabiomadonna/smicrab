import bcrypt

from app.domain.user.user_dto import CreateUserRequest, CreateUserResponse
from app.infrastructure.repositories.user_repository import UserRepository
from app.utils.logger import Logger


class UserService:
    def __init__(self, repository: UserRepository):
        self.repository = repository

    async def create_user(self, request: CreateUserRequest) -> CreateUserResponse:
        try:
            hashed_password = bcrypt.hashpw(
                request.password.encode("utf-8"), bcrypt.gensalt()
            ).decode("utf-8")

            user = await self.repository.create_user(request.email, hashed_password)
            return CreateUserResponse(
                user_id=user.user_id, email=user.email, created_at=user.created_at
            )

        except Exception as e:
            Logger.error(
                "Failed to create user: {}".format(e),
                context={"task": "handle_create_user", "message": str(e)},
            )
            raise e
