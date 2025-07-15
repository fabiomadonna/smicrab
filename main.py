"""
SMICRAB Backend - FastAPI Application
Main entry point for the SMICRAB analytical platform backend.
"""

import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
import logging
from dotenv import load_dotenv

# Import routers
from app.api.api import api_router
from core.config import settings
from core.logging_config import setup_logging

# Load environment variables
load_dotenv()

# Setup logging
setup_logging()
logger = logging.getLogger(__name__)


# @asynccontextmanager
# async def lifespan(app: FastAPI):
#     """
#     Application lifespan events.
#     """
#     # Startup
#     logger.info("🚀 SMICRAB Backend starting up...")
#     logger.info(f"Environment: {settings.ENVIRONMENT}")
#     logger.info(f"API Version: {settings.API_V1_STR}")
#
#     # Check R installation
#     try:
#         import rpy2.robjects as ro
#
#         logger.info("✅ R environment detected and ready")
#         # Test R connection
#         ro.r('print("R connection successful")')
#     except Exception as e:
#         logger.error(f"❌ R environment setup failed: {e}")
#
#     yield
#
#     # Shutdown
#     logger.info("🛑 SMICRAB Backend shutting down...")


# Create FastAPI application
app = FastAPI(
    title="SMICRAB API",
    description="Backend API for SMICRAB - Spatio-temporal Modeling and Interactive Climate Risk Assessment for Business",
    version="1.0.0",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    # lifespan=lifespan,
)

from app.Models import base_model

print(base_model.Base.metadata.tables.keys())

# Add middleware
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router, prefix=settings.API_V1_STR)


# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "smicrab-backend", "version": "1.0.0"}


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "SMICRAB Backend API",
        "version": "1.0.0",
        "docs": f"{settings.API_V1_STR}/docs",
        "health": "/health",
    }


# Ensure the directory exists, or it will raise an error
TMP_ANALYSIS_DIR = "/tmp/analysis"
if not os.path.exists(TMP_ANALYSIS_DIR):
    os.makedirs(TMP_ANALYSIS_DIR, exist_ok=True)

DATASET_DIR = "/app/datasets"
if not os.path.exists(DATASET_DIR):
    os.makedirs(DATASET_DIR, exist_ok=True)

# Mount /tmp/analysis so its contents are served at /tmp/analysis
app.mount("/tmp/analysis", StaticFiles(directory=TMP_ANALYSIS_DIR), name="analysis")
app.mount("/datasets", StaticFiles(directory=DATASET_DIR), name="datasets")

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True, log_level="info")
