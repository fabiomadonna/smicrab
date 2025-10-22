from app.domain.user.user_dto import (
    CreateUserRequest, 
    CreateUserResponse, 
    LoginRequest, 
    LoginResponse,
    RefreshTokenRequest,
    RefreshTokenResponse,
    UserProfileResponse
)
from app.infrastructure.repositories.user_repository import UserRepository
from app.utils.logger import Logger
from app.utils.auth import AuthUtils
from fastapi import HTTPException, status


class UserService:
    def __init__(self, repository: UserRepository):
        self.repository = repository

    async def create_user(self, request: CreateUserRequest) -> CreateUserResponse:
        """Create a new user with validation."""
        try:
            # Validate email format
            if not AuthUtils.validate_email(request.email):
                raise ValueError("Invalid email format")
            
            # Validate password strength
            if not AuthUtils.validate_password(request.password):
                # raise ValueError("Password must be at least 8 characters long and contain uppercase, lowercase, and digit")
                raise ValueError("Password must be at least 8 characters long")
            
            # Check if user already exists
            if await self.repository.user_exists(request.email):
                raise ValueError("User with this email already exists")
            
            # Hash password
            hashed_password = AuthUtils.hash_password(request.password)
            
            # Create user
            user = await self.repository.create_user(request.email, hashed_password)
            
            return CreateUserResponse(
                user_id=user.user_id, 
                email=user.email, 
                created_at=user.created_at
            )

        except Exception as e:
            Logger.error(
                "Failed to create user: {}".format(e),
                context={"task": "create_user", "email": request.email},
            )
            raise e

    async def login_user(self, request: LoginRequest) -> LoginResponse:
        """Authenticate user and return JWT tokens."""
        try:
            # Get user by email
            user = await self.repository.get_user_by_email(request.email)
            if not user:
                raise ValueError("Incorrect email or password")
            
            # Verify password
            if not AuthUtils.verify_password(request.password, user.password):
                raise ValueError("Incorrect email or password")
            
            # Create tokens
            token_data = {"sub": str(user.user_id), "email": user.email}
            access_token = AuthUtils.create_access_token(token_data)
            refresh_token = AuthUtils.create_refresh_token(token_data)
            
            return LoginResponse(
                access_token=access_token,
                refresh_token=refresh_token,
                token_type="bearer",
                user_id=user.user_id,
                email=user.email
            )
            
        except Exception as e:
            Logger.error(
                "Failed to login user: {}".format(e),
                context={"task": "login_user", "email": request.email},
            )
            raise e

    async def refresh_token(self, request: RefreshTokenRequest) -> RefreshTokenResponse:
        """Refresh access token using refresh token."""
        try:
            # Verify refresh token
            payload = AuthUtils.verify_token(request.refresh_token)
            
            # Check if it's a refresh token
            if payload.get("type") != "refresh":
                raise ValueError("Invalid token type")
            
            # Get user
            user_id = payload.get("sub")
            user = await self.repository.get_user_by_id(user_id)
            if not user:
                raise ValueError("User not found")
            
            # Create new access token
            token_data = {"sub": str(user.user_id), "email": user.email}
            access_token = AuthUtils.create_access_token(token_data)
            
            return RefreshTokenResponse(
                access_token=access_token,
                token_type="bearer"
            )
            
        except HTTPException:
            raise
        except Exception as e:
            Logger.error(
                "Failed to refresh token: {}".format(e),
                context={"task": "refresh_token"},
            )
            raise e

    async def get_user_profile(self, user_id: str) -> UserProfileResponse:
        """Get user profile by ID."""
        try:
            user = await self.repository.get_user_by_id(user_id)
            if not user:
                raise ValueError("User not found")
            
            return UserProfileResponse(
                user_id=user.user_id,
                email=user.email,
                created_at=user.created_at
            )
            
        except Exception as e:
            Logger.error(
                "Failed to get user profile: {}".format(e),
                context={"task": "get_user_profile", "user_id": user_id},
            )
            raise e
