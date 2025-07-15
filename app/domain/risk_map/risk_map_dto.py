from datetime import datetime
from uuid import UUID
from typing import List, Optional, Dict, Any
from sqlalchemy.dialects.postgresql import JSONB

from pydantic import BaseModel, Field

from app.utils.enums import ModelType


# DTOs for risk map module outputs

class RiskMapModuleFile(BaseModel):
    """File information for risk map module outputs."""
    name: str = Field(..., description="File name identifier")
    path_dynamic: Optional[str] = Field(None, description="Dynamic HTML file path")
    path_static: Optional[str] = Field(None, description="Static PNG file path")
    function: Optional[str] = Field(None, description="R function used to generate the file")
    description: Optional[str] = Field(None, description="File description")

    class Config:
        from_attributes = True


class RiskMapTestCategory(BaseModel):
    """Base category for risk map test outputs."""
    description: str = Field(..., description="Description of the test category")
    files: List[RiskMapModuleFile] = Field(..., description="List of files for this test category")

    class Config:
        from_attributes = True


class RiskMapModuleOutputs(BaseModel):
    """All risk map module outputs organized by test categories."""
    # Model 1 Simple - Trend Tests
    sens_slope_test: RiskMapTestCategory = Field(..., description="Sen's slope test results")
    cox_snell_test: RiskMapTestCategory = Field(..., description="Cox-Snell test results")
    mann_kendall_test: RiskMapTestCategory = Field(..., description="Mann-Kendall test results")
    seasonal_mann_kendall_test: RiskMapTestCategory = Field(..., description="Seasonal Mann-Kendall test results")
    prewhitened_mann_kendall_test: RiskMapTestCategory = Field(..., description="Pre-whitened Mann-Kendall test results")
    bias_corrected_prewhitened_test: RiskMapTestCategory = Field(..., description="Bias-corrected pre-whitened test results")
    robust_trend_newey_west: RiskMapTestCategory = Field(..., description="Robust trend test using Newey-West estimator")
    score_function_combination: RiskMapTestCategory = Field(..., description="Score function combination of trend tests")
    majority_voting_combination: RiskMapTestCategory = Field(..., description="Majority voting combination of trend tests")
    
    # Models 2 & 3 - MB-Trend Analysis
    temporal_analysis: RiskMapTestCategory = Field(..., description="Temporal analysis for MB-Trend models")
    spatial_analysis: RiskMapTestCategory = Field(..., description="Spatial analysis for MB-Trend models")
    
    # Models 4, 5 & 6 - H-SDPD Analysis
    spatiotemporal_trend_analysis: RiskMapTestCategory = Field(..., description="Spatiotemporal trend analysis for H-SDPD models")
    spatial_regression_trend_parameters: RiskMapTestCategory = Field(..., description="Spatial regression of trend parameters")
    spatiotemporal_fixed_effects_analysis: RiskMapTestCategory = Field(..., description="Spatiotemporal fixed effects analysis")
    spatial_regression_fixed_effect_parameters: RiskMapTestCategory = Field(..., description="Spatial regression of fixed effect parameters")

    class Config:
        from_attributes = True


class ModelSpecificAvailability(BaseModel):
    """Model specific availability for risk map features."""
    # Model 1 Simple - Trend Tests
    sens_slope_test: bool = Field(..., description="Whether Sen's slope test is available")
    cox_snell_test: bool = Field(..., description="Whether Cox-Snell test is available")
    mann_kendall_test: bool = Field(..., description="Whether Mann-Kendall test is available")
    seasonal_mann_kendall_test: bool = Field(..., description="Whether Seasonal Mann-Kendall test is available")
    prewhitened_mann_kendall_test: bool = Field(..., description="Whether Pre-whitened Mann-Kendall test is available")
    bias_corrected_prewhitened_test: bool = Field(..., description="Whether bias-corrected pre-whitened test is available")
    robust_trend_newey_west: bool = Field(..., description="Whether robust trend with Newey-West is available")
    score_function_combination: bool = Field(..., description="Whether score function combination is available")
    majority_voting_combination: bool = Field(..., description="Whether majority voting combination is available")
    
    # Models 2 & 3 - MB-Trend Analysis
    temporal_analysis: bool = Field(..., description="Whether temporal analysis is available")
    spatial_analysis: bool = Field(..., description="Whether spatial analysis is available")
    
    # Models 4, 5 & 6 - H-SDPD Analysis
    spatiotemporal_trend_analysis: bool = Field(..., description="Whether spatiotemporal trend analysis is available")
    spatial_regression_trend_parameters: bool = Field(..., description="Whether spatial regression trend parameters are available")
    spatiotemporal_fixed_effects_analysis: bool = Field(..., description="Whether spatiotemporal fixed effects analysis is available")
    spatial_regression_fixed_effect_parameters: bool = Field(..., description="Whether spatial regression fixed effect parameters are available")

    class Config:
        from_attributes = True


class GetRiskMapOutputsResponse(BaseModel):
    """Response schema for getting risk map module outputs."""
    riskmap_module_outputs: RiskMapModuleOutputs = Field(..., description="Complete risk map module outputs")
    model_specific_availability: Dict[str, ModelSpecificAvailability] = Field(..., description="Model-specific availability of risk map features")

    class Config:
        from_attributes = True