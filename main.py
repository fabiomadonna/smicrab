"""
SMICRAB Backend - FastAPI Application
Main entry point for the SMICRAB analytical platform backend.
"""

import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from dotenv import load_dotenv

# Import routers and settings
from app.api.api import api_router
from core.config import settings
from core.logging_config import setup_logging
from app.domain.analysis.container_service import ContainerService
from app.middleware.auth_middleware import AuthMiddleware, RateLimitMiddleware

# Load environment variables from .env file
load_dotenv()

# Setup logging configuration
setup_logging()
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Manages application startup and shutdown events using the recommended
    lifespan context manager.
    """
    # --- Code to run on startup ---
    logger.info("🚀 SMICRAB Backend starting up...")
    logger.info(f"Environment: {settings.ENVIRONMENT}")
    logger.info(f"API Version: {settings.API_V1_STR}")

    # --- Build the analysis Docker image (for development convenience) ---
    # In a production environment, this image should be pre-built in a CI/CD pipeline
    # and this entire block should be removed.
    # logger.info("🐳 Initializing Container Service and building analysis Docker image...")
    # try:
    #     container_service = ContainerService()
    #     success = container_service.build_analysis_image()
    #     if success:
    #         logger.info("✅ Analysis Docker image built successfully.")
    #     else:
    #         logger.error("❌ Failed to build analysis Docker image during startup.")
    # except Exception as e:
    #     logger.error(f"❌ An exception occurred while building the analysis image: {e}")

    logger.info("✅ SMICRAB Backend startup sequence completed. Application is ready.")

    yield  # --- The application runs after this point ---

    # --- Code to run on shutdown ---
    logger.info("🛑 SMICRAB Backend shutting down...")


# Create FastAPI application instance
app = FastAPI(
    title="SMICRAB API",
    description="Backend API for SMICRAB - Spatio-temporal Modeling and Interactive Climate Risk Assessment for Business",
    version="1.0.0",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    lifespan=lifespan,  # Use the modern lifespan manager
)

# Add middleware
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Add authentication middleware
app.add_middleware(AuthMiddleware)

# Add rate limiting middleware
app.add_middleware(RateLimitMiddleware, requests_per_minute=60)

# Configure CORS (Cross-Origin Resource Sharing)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include the main API router
app.include_router(api_router, prefix=settings.API_V1_STR)


# --- Static file serving for analysis results and datasets ---

# Ensure the directories exist to prevent errors on startup
TMP_ANALYSIS_DIR = "/tmp/analysis"
DATASET_DIR = "/app/datasets" # This path is inside the container
DATASET_CSV_DIR = "/app/datasets_csv"
os.makedirs(TMP_ANALYSIS_DIR, exist_ok=True)
os.makedirs(DATASET_DIR, exist_ok=True)
os.makedirs(DATASET_CSV_DIR, exist_ok=True)

# Mount directories to serve their contents statically
app.mount("/tmp/analysis", StaticFiles(directory=TMP_ANALYSIS_DIR), name="analysis_results")
app.mount("/datasets", StaticFiles(directory=DATASET_DIR), name="datasets")
app.mount("/datasets_csv", StaticFiles(directory=DATASET_CSV_DIR), name="datasets_csv")


# --- Root and Health Check Endpoints ---

@app.get("/health", tags=["Utilities"])
async def health_check():
    """Provides a simple health check endpoint."""
    return {"status": "healthy", "service": "smicrab-backend", "version": "1.0.0"}


@app.get("/", tags=["Utilities"])
async def root():
    """Root endpoint with basic API information."""
    return {
        "message": "Welcome to the SMICRAB Backend API",
        "version": "1.0.0",
        "api_docs": app.docs_url,
        "health_check": "/health",
    }


# This block is for running the app directly with uvicorn for local development
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )