"""
Application configuration settings.
"""

import os
from typing import List, Union
from pydantic_settings import BaseSettings
from pydantic import field_validator


class Settings(BaseSettings):
    """Application settings that reads from .env file and environment variables."""

    # API Configuration
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "SMICRAB"
    ENVIRONMENT: str = "development"

    # CORS Configuration
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "https://localhost:3000",
        "http://15.188.26.222:8000/",
        "https://smicrab-ui.vercel.app/"
    ]

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> Union[List[str], str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)

    # File Storage Configuration
    SHAPEFILE_PATH: str = "./r_scripts/shapes/ProvCM01012025_g_WGS84.shp"

    # R Configuration - reads from environment or uses defaults
    R_HOME: str = "/usr/lib/R"
    R_USER_LIB_DIR: str = "/usr/local/lib/R/site-library"

    # PostgreSQL Configuration - reads strictly from .env
    POSTGRES_HOST: str
    POSTGRES_PORT: int
    POSTGRES_DB: str
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str

    # Database Configuration - constructed from PostgreSQL settings
    @property
    def DATABASE_URL(self) -> str:
        return f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

    # Validate that critical database configurations are set
    @field_validator(
        "POSTGRES_HOST", "POSTGRES_DB", "POSTGRES_USER", "POSTGRES_PASSWORD"
    )
    @classmethod
    def check_postgres_config(cls, v: str) -> str:
        if not v:
            raise ValueError("PostgreSQL configuration must be set in .env file")
        return v

    @field_validator("POSTGRES_PORT")
    @classmethod
    def check_postgres_port(cls, v: int) -> int:
        if v <= 0 or v > 65535:
            raise ValueError("Invalid PostgreSQL port number")
        return v

    # Logging Configuration
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "./logs/smicrab.log"
    
    # JWT Configuration
    JWT_SECRET_KEY: str = "your-jwt-secret-key-change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Redis Configuration
    REDIS_URL: str = "redis://localhost:6379/0"

    # Webhook Configuration
    WEBHOOK_URL: str

    model_config = {
        "env_file": ".env",
        "case_sensitive": True,
        "extra": "ignore",  # Allow extra environment variables
    }


# Create settings instance
settings = Settings()
