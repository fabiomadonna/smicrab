from fastapi import APIRouter

from app.api.router import (
    user_router,
    analysis_router,
    describe_module_router,
    estimate_module_router,
    validate_module_router,
    risk_map_module_router,
    dataset_router,
)

api_router = APIRouter()

# Include Analysis session management router
api_router.include_router(
    analysis_router.router, prefix="/analysis", tags=["Analysis Sessions"]
)

# Include User management router
api_router.include_router(user_router.router, prefix="/user", tags=["User"])

# Include Dataset management router
api_router.include_router(dataset_router.router, prefix="/datasets", tags=["Datasets"])


# Include Describe module router
api_router.include_router(
    describe_module_router.router, prefix="/describe_module", tags=["DESCRIBE Module"]
)

# Include Estimate module router
api_router.include_router(
    estimate_module_router.router, prefix="/estimate_module", tags=["ESTIMATE Module"]
)

# Include Validate module router
api_router.include_router(
    validate_module_router.router, prefix="/validate_module", tags=["VALIDATE Module"]
)

# Include Risk Map module router
api_router.include_router(
    risk_map_module_router.router, prefix="/risk_map_module", tags=["RISK MAP Module"]
)


# Common endpoints
@api_router.get("/")
async def api_root():
    """API root endpoint."""
    return {
        "message": "SMICRAB API v1",
        "available_modules": [
            "ANALYSIS - /analysis/ (Session management)",
            "USER - /user/ (User management)",
            "DATASETS - /datasets/ (Dataset management)",
            "DESCRIBE - /describe_module/ (Data exploration and description)",
            "ESTIMATE - /estimate_module/ (Model estimation)",
            "VALIDATE - /validate_module/ (Model validation)",
            "RISK MAP - /risk_map_module/ (Risk mapping and visualization)",
        ],
        "documentation": "/docs",
    }
