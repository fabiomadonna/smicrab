import os
from typing import List, Dict, Any

from app.Models.analysis import Analysis
from app.domain.risk_map.risk_map_dto import (
    GetRiskMapOutputsResponse,
    RiskMapModuleOutputs,
    RiskMapTestCategory,
    RiskMapModuleFile,
    ModelSpecificAvailability,
)
from app.utils.enums import ModelType
from app.utils.logger import Logger
from app.utils.utils import get_analysis_output_path


class RiskMapModuleService:
    def __init__(self):
        pass

    async def get_risk_map_outputs(
        self, analysis: Analysis
    ) -> GetRiskMapOutputsResponse:
        """Get risk map module outputs for the given analysis and model type."""
        try:
            # Get output directory path
            output_dir = get_analysis_output_path(analysis.id, analysis.model_type)

            # Generate outputs
            outputs = self._generate_risk_map_outputs(output_dir)

            # Generate model specific availability
            model_availability = self._generate_model_specific_availability()

            return GetRiskMapOutputsResponse(
                riskmap_module_outputs=outputs,
                model_specific_availability=model_availability,
            )

        except Exception as e:
            Logger.error(
                f"Failed to get risk map outputs: {e}",
                context={
                    "task": "get_risk_map_outputs",
                    "analysis_id": analysis.id,
                    "model_type": analysis.model_type.value,
                },
            )
            raise

    def _generate_risk_map_outputs(self, output_dir: str) -> RiskMapModuleOutputs:
        """Generate risk map module outputs based on R script analysis."""

        # MODEL 1 SIMPLE - TREND TESTS
        
        # Sen's slope test
        sens_slope_test = RiskMapTestCategory(
            description="Sen's slope test for trend analysis on deseasonalized time series",
            files=[
                RiskMapModuleFile(
                    name="sens_estimates",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/sens_estimates.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/sens_estimates.png"),
                    function="ggplot(TrendSens_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = estimate)) + geom_point()",
                    description="Spatial plot of Sen's slope estimates"
                ),
                RiskMapModuleFile(
                    name="sens_significant_pixels",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/sens_significant_pixels.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/sens_significant_pixels.png"),
                    function="ggplot(TrendSens_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab)) + geom_point()",
                    description="Spatial plot of significant pixels from Sen's slope test"
                ),
                RiskMapModuleFile(
                    name="sens_significant_pixels_BY",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/sens_significant_pixels_BY.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/sens_significant_pixels_BY.png"),
                    function="ggplot(TrendSens_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab_BY)) + geom_point()",
                    description="Spatial plot with Benjamini-Yekutieli adjusted p-values for Sen's slope test"
                ),
                RiskMapModuleFile(
                    name="sens_summary_table",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/sens_summary_table.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/sens_summary_table.html"),
                    function="datatable(dati, filter = 'top')",
                    description="Summary statistics table for Sen's slope test"
                ),
            ],
        )

        # Cox and Snell test
        cox_snell_test = RiskMapTestCategory(
            description="Cox and Snell test for trend on deseasonalized time series",
            files=[
                RiskMapModuleFile(
                    name="cs_estimates",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/cs_estimates.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/cs_estimates.png"),
                    function="ggplot(TrendCS_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = estimate)) + geom_point()",
                    description="Spatial plot of Cox-Snell estimates"
                ),
                RiskMapModuleFile(
                    name="cs_significant_pixels",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/cs_significant_pixels.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/cs_significant_pixels.png"),
                    function="ggplot(TrendCS_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab)) + geom_point()",
                    description="Spatial plot of significant pixels from Cox-Snell test"
                ),
                RiskMapModuleFile(
                    name="cs_significant_pixels_BY",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/cs_significant_pixels_BY.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/cs_significant_pixels_BY.png"),
                    function="ggplot(TrendCS_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab_BY)) + geom_point()",
                    description="Spatial plot with BY adjusted p-values for Cox-Snell test"
                ),
                RiskMapModuleFile(
                    name="cs_summary_table",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/cs_summary_table.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/cs_summary_table.html"),
                    function="datatable(dati, filter = 'top')",
                    description="Summary statistics table for Cox-Snell test"
                ),
            ],
        )

        # Mann-Kendall test
        mann_kendall_test = RiskMapTestCategory(
            description="Mann-Kendall trend test on deseasonalized time series",
            files=[
                RiskMapModuleFile(
                    name="mk_estimates",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/mk_estimates.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/mk_estimates.png"),
                    function="ggplot(TrendMK_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = estimate)) + geom_point()",
                    description="Spatial plot of Mann-Kendall estimates"
                ),
                RiskMapModuleFile(
                    name="mk_significant_pixels",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/mk_significant_pixels.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/mk_significant_pixels.png"),
                    function="ggplot(TrendMK_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab)) + geom_point()",
                    description="Spatial plot of significant pixels from Mann-Kendall test"
                ),
                RiskMapModuleFile(
                    name="mk_significant_pixels_BY",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/mk_significant_pixels_BY.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/mk_significant_pixels_BY.png"),
                    function="ggplot(TrendMK_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab_BY)) + geom_point()",
                    description="Spatial plot with BY adjusted p-values for Mann-Kendall test"
                ),
                RiskMapModuleFile(
                    name="mk_summary_table",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/mk_summary_table.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/mk_summary_table.html"),
                    function="datatable(dati, filter = 'top')",
                    description="Summary statistics table for Mann-Kendall test"
                ),
            ],
        )

        # Seasonal Mann-Kendall test
        seasonal_mann_kendall_test = RiskMapTestCategory(
            description="Seasonal Mann-Kendall trend test on original time series",
            files=[
                RiskMapModuleFile(
                    name="smk_estimates",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/smk_estimates.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/smk_estimates.png"),
                    function="ggplot(TrendSMK_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = estimate)) + geom_point()",
                    description="Spatial plot of Seasonal Mann-Kendall estimates"
                ),
                RiskMapModuleFile(
                    name="smk_significant_pixels",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/smk_significant_pixels.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/smk_significant_pixels.png"),
                    function="ggplot(TrendSMK_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab)) + geom_point()",
                    description="Spatial plot of significant pixels from Seasonal Mann-Kendall test"
                ),
                RiskMapModuleFile(
                    name="smk_significant_pixels_BY",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/smk_significant_pixels_BY.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/smk_significant_pixels_BY.png"),
                    function="ggplot(TrendSMK_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab_BY)) + geom_point()",
                    description="Spatial plot with BY adjusted p-values for Seasonal Mann-Kendall test"
                ),
                RiskMapModuleFile(
                    name="smk_summary_table",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/smk_summary_table.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/smk_summary_table.html"),
                    function="datatable(dati, filter = 'top')",
                    description="Summary statistics table for Seasonal Mann-Kendall test"
                ),
            ],
        )

        # Pre-whitened Mann-Kendall test
        prewhitened_mann_kendall_test = RiskMapTestCategory(
            description="Pre-whitened Mann-Kendall trend test on deseasonalized time series",
            files=[
                RiskMapModuleFile(
                    name="pwmk_estimates",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/pwmk_estimates.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/pwmk_estimates.png"),
                    function="ggplot(TrendPWMK_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = estimate)) + geom_point()",
                    description="Spatial plot of Pre-whitened Mann-Kendall estimates"
                ),
                RiskMapModuleFile(
                    name="pwmk_significant_pixels",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/pwmk_significant_pixels.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/pwmk_significant_pixels.png"),
                    function="ggplot(TrendPWMK_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab)) + geom_point()",
                    description="Spatial plot of significant pixels from Pre-whitened Mann-Kendall test"
                ),
                RiskMapModuleFile(
                    name="pwmk_significant_pixels_BY",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/pwmk_significant_pixels_BY.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/pwmk_significant_pixels_BY.png"),
                    function="ggplot(TrendPWMK_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab_BY)) + geom_point()",
                    description="Spatial plot with BY adjusted p-values for Pre-whitened Mann-Kendall test"
                ),
                RiskMapModuleFile(
                    name="pwmk_summary_table",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/pwmk_summary_table.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/pwmk_summary_table.html"),
                    function="datatable(dati, filter = 'top')",
                    description="Summary statistics table for Pre-whitened Mann-Kendall test"
                ),
            ],
        )

        # Bias-corrected pre-whitened test
        bias_corrected_prewhitened_test = RiskMapTestCategory(
            description="Bias-corrected pre-whitened trend test on deseasonalized time series",
            files=[
                RiskMapModuleFile(
                    name="bcpw_estimates",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/bcpw_estimates.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/bcpw_estimates.png"),
                    function="ggplot(TrendBCPW_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = estimate)) + geom_point()",
                    description="Spatial plot of Bias-corrected Pre-whitened estimates"
                ),
                RiskMapModuleFile(
                    name="bcpw_significant_pixels",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/bcpw_significant_pixels.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/bcpw_significant_pixels.png"),
                    function="ggplot(TrendBCPW_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab)) + geom_point()",
                    description="Spatial plot of significant pixels from Bias-corrected Pre-whitened test"
                ),
                RiskMapModuleFile(
                    name="bcpw_significant_pixels_BY",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/bcpw_significant_pixels_BY.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/bcpw_significant_pixels_BY.png"),
                    function="ggplot(TrendBCPW_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab_BY)) + geom_point()",
                    description="Spatial plot with BY adjusted p-values for Bias-corrected Pre-whitened test"
                ),
                RiskMapModuleFile(
                    name="bcpw_summary_table",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/bcpw_summary_table.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/bcpw_summary_table.html"),
                    function="datatable(dati, filter = 'top')",
                    description="Summary statistics table for Bias-corrected Pre-whitened test"
                ),
            ],
        )

        # Robust trend Newey-West
        robust_trend_newey_west = RiskMapTestCategory(
            description="Robust trend analysis using Newey-West estimator",
            files=[
                RiskMapModuleFile(
                    name="robust_estimates",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/robust_estimates.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/robust_estimates.png"),
                    function="ggplot(TrendRobust_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = estimate)) + geom_point()",
                    description="Spatial plot of Robust trend estimates"
                ),
                RiskMapModuleFile(
                    name="robust_estimates_error",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/robust_estimates_error.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/robust_estimates_error.png"),
                    function="ggplot(TrendRobust_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = std.error)) + geom_point()",
                    description="Spatial plot of Robust trend standard errors"
                ),
                RiskMapModuleFile(
                    name="robust_significant_pixels",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/robust_significant_pixels.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/robust_significant_pixels.png"),
                    function="ggplot(TrendRobust_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab)) + geom_point()",
                    description="Spatial plot of significant pixels from Robust trend test"
                ),
                RiskMapModuleFile(
                    name="robust_significant_pixels_BY",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/robust_significant_pixels_BY.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/robust_significant_pixels_BY.png"),
                    function="ggplot(TrendRobust_df[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab_BY)) + geom_point()",
                    description="Spatial plot with BY adjusted p-values for Robust trend test"
                ),
                RiskMapModuleFile(
                    name="robust_summary_table",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/robust_summary_table.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/robust_summary_table.html"),
                    function="datatable(dati, filter = 'top')",
                    description="Summary statistics table for Robust trend test"
                ),
            ],
        )

        # Score function combination
        score_function_combination = RiskMapTestCategory(
            description="Combination of trend tests using score functions",
            files=[
                RiskMapModuleFile(
                    name="score_estimates",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/score_estimates.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/score_estimates.png"),
                    function="ggplot(score_values, aes(x = Longitude, y = Latitude, col = score)) + geom_point()",
                    description="Spatial plot of score function combination estimates"
                ),
                RiskMapModuleFile(
                    name="score_BY_estimates",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/score_BY_estimates.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/score_BY_estimates.png"),
                    function="ggplot(score_values, aes(x = Longitude, y = Latitude, col = score_BY)) + geom_point()",
                    description="Spatial plot with BY adjusted score values"
                ),
            ],
        )

        # Majority voting combination
        majority_voting_combination = RiskMapTestCategory(
            description="Combination of trend tests using majority voting",
            files=[
                RiskMapModuleFile(
                    name="majority_vote",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/majority_vote.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/majority_vote.png"),
                    function="ggplot(mv$Vote, aes(x = Longitude, y = Latitude, col = Vote)) + geom_point()",
                    description="Spatial plot of majority voting estimates"
                ),
                RiskMapModuleFile(
                    name="majority_vote_BY",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/majority_vote_BY.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/majority_vote_BY.png"),
                    function="ggplot(mv$Vote_BY, aes(x = Longitude, y = Latitude, col = Vote)) + geom_point()",
                    description="Spatial plot with BY adjusted majority voting"
                ),
                RiskMapModuleFile(
                    name="majority_vote_summary_table",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/majority_vote_summary_table.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/majority_vote_summary_table.html"),
                    function="datatable(dati, filter = 'top')",
                    description="Summary statistics table for majority voting combination"
                ),
            ],
        )

        # MODELS 2 & 3 - MB-TREND ANALYSIS
        
        # Temporal analysis
        temporal_analysis = RiskMapTestCategory(
            description="Temporal analysis outputs for Models 2 and 3 (MB-Trend)",
            files=[
                RiskMapModuleFile(
                    name="mb_estimates",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/mb_estimates.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/mb_estimates.png"),
                    function="ggplot(modelStats_df$modStats[[name.endogenous]], aes(x = Longitude, y = Latitude, col = estimate)) + geom_point()",
                    description="MB trend analysis estimates"
                ),
                RiskMapModuleFile(
                    name="mb_std_errors",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/mb_std_errors.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/mb_std_errors.png"),
                    function="ggplot(modelStats_df$modStats[[name.endogenous]], aes(x = Longitude, y = Latitude, col = std.error)) + geom_point()",
                    description="MB trend analysis standard errors"
                ),
                RiskMapModuleFile(
                    name="mb_significant_pixels",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/mb_significant_pixels.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/mb_significant_pixels.png"),
                    function="ggplot(modelStats_df$modStats[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab)) + geom_point()",
                    description="MB trend analysis significant pixels"
                ),
                RiskMapModuleFile(
                    name="mb_significant_pixels_BY",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/mb_significant_pixels_BY.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/mb_significant_pixels_BY.png"),
                    function="ggplot(modelStats_df$modStats[[name.endogenous]], aes(x = Longitude, y = Latitude, col = trend_lab_BY)) + geom_point()",
                    description="MB trend analysis BY adjusted significant pixels"
                ),
                RiskMapModuleFile(
                    name="mb_summary_table",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/mb_summary_table.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/mb_summary_table.html"),
                    function="datatable(dati, filter = 'top')",
                    description="Summary statistics table for MB trend analysis"
                ),
            ],
        )

        # Spatial analysis
        spatial_analysis = RiskMapTestCategory(
            description="Spatial analysis outputs for Models 2 and 3 (MB-Trend)",
            files=[
                RiskMapModuleFile(
                    name="map_effect",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/map_effect.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/map_effect.html"),
                    function="EvaluateTest_map(spatialModels_df[[name.endogenous]]$GLS.int)",
                    description="Map effect analysis using GLS regression with constant"
                ),
                RiskMapModuleFile(
                    name="lc_effect",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/lc_effect.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/lc_effect.html"),
                    function="EvaluateTest_LC(spatialModels_df[[name.endogenous]]$GLS.lc)",
                    description="Land cover effect analysis using GLS regression"
                ),
                RiskMapModuleFile(
                    name="latitude_effect",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/latitude_effect.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/latitude_effect.html"),
                    function="EvaluateTest_latitude(spatialModels_df[[name.endogenous]]$GLS.lat)",
                    description="Latitude effect analysis using GLS regression"
                ),
                RiskMapModuleFile(
                    name="longitude_effect",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/longitude_effect.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/longitude_effect.html"),
                    function="EvaluateTest_longitude(spatialModels_df[[name.endogenous]]$GLS.lon)",
                    description="Longitude effect analysis using GLS regression"
                ),
                RiskMapModuleFile(
                    name="longitude_lc_interaction",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/longitude_lc_interaction.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/longitude_lc_interaction.html"),
                    function="EvaluateTest_lonxlc(spatialModels_df[[name.endogenous]]$GLS.lonxlc)",
                    description="Longitude and land cover interaction effect"
                ),
                RiskMapModuleFile(
                    name="latitude_lc_interaction",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/latitude_lc_interaction.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/latitude_lc_interaction.html"),
                    function="EvaluateTest_latxlc(spatialModels_df[[name.endogenous]]$GLS.latxlc)",
                    description="Latitude and land cover interaction effect"
                ),
                RiskMapModuleFile(
                    name="land_cover_map",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/land_cover_map.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/land_cover_map.png"),
                    function="ggplot(slc_df, aes(x = Longitude, y = Latitude, color = LC)) + geom_point()",
                    description="Land cover classification map"
                ),
            ],
        )

        # MODELS 4, 5 & 6 - H-SDPD ANALYSIS
        
        # Spatiotemporal trend analysis
        spatiotemporal_trend_analysis = RiskMapTestCategory(
            description="Spatio-temporal SDPD trend analysis for Models 4, 5 and 6",
            files=[
                RiskMapModuleFile(
                    name="trend_estimates_map",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/trend_estimates_map.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/trend_estimates_map.png"),
                    function="ggplot(results_data, aes(x = lon, y = lat, col = coeff.hat$trend)) + geom_point()",
                    description="SDPD model trend estimates map"
                ),
                RiskMapModuleFile(
                    name="trend_std_error_map",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/trend_std_error_map.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/trend_std_error_map.png"),
                    function="ggplot(df.results.test, aes(x = lon, y = lat, col = coeff.sd.boot$trend)) + geom_point()",
                    description="SDPD model trend standard errors map"
                ),
                RiskMapModuleFile(
                    name="significant_trend_pixels_map",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/significant_trend_pixels_map.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/significant_trend_pixels_map.png"),
                    function="ggplot(dati, aes(x = lon, y = lat, col = trend_sdpd_lab)) + geom_point()",
                    description="SDPD significant trend pixels map"
                ),
                RiskMapModuleFile(
                    name="by_adjusted_trend_map",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/by_adjusted_trend_map.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/by_adjusted_trend_map.png"),
                    function="ggplot(dati, aes(x = lon, y = lat, col = trend_sdpd_lab_BY)) + geom_point()",
                    description="SDPD BY adjusted significant trend pixels map"
                ),
                RiskMapModuleFile(
                    name="trend_analysis_summary_table",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/trend_analysis_summary_table.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/trend_analysis_summary_table.html"),
                    function="datatable(dati_summary, filter = 'top')",
                    description="Summary statistics table for SDPD trend analysis"
                ),
            ],
        )

        # Spatial regression trend parameters
        spatial_regression_trend_parameters = RiskMapTestCategory(
            description="Spatial regression of trend parameters for Models 4, 5 and 6",
            files=[
                RiskMapModuleFile(
                    name="land_cover_map_trend_regression",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/land_cover_map_trend_regression.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/land_cover_map_trend_regression.png"),
                    function="ggplot(slc_df, aes(x = Longitude, y = Latitude, color = LC)) + geom_point()",
                    description="Land cover map for trend regression analysis"
                ),
                RiskMapModuleFile(
                    name="trend_regression_model_1",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/trend_regression_model_1.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/trend_regression_model_1.html"),
                    function="summary(modelli_globali[[1]])",
                    description="Trend spatial regression model 1 with diagnostic plots"
                ),
                RiskMapModuleFile(
                    name="trend_regression_model_2",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/trend_regression_model_2.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/trend_regression_model_2.html"),
                    function="summary(modelli_globali[[2]])",
                    description="Trend spatial regression model 2 with diagnostic plots"
                ),
                RiskMapModuleFile(
                    name="trend_regression_model_3",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/trend_regression_model_3.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/trend_regression_model_3.html"),
                    function="summary(modelli_globali[[3]])",
                    description="Trend spatial regression model 3 with diagnostic plots"
                ),
                RiskMapModuleFile(
                    name="trend_regression_model_4",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/trend_regression_model_4.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/trend_regression_model_4.html"),
                    function="summary(modelli_globali[[4]])",
                    description="Trend spatial regression model 4 with diagnostic plots"
                ),
                RiskMapModuleFile(
                    name="trend_regression_model_5",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/trend_regression_model_5.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/trend_regression_model_5.html"),
                    function="summary(modelli_globali[[5]])",
                    description="Trend spatial regression model 5 with diagnostic plots"
                ),
                RiskMapModuleFile(
                    name="trend_regression_model_6",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/trend_regression_model_6.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/trend_regression_model_6.html"),
                    function="summary(modelli_globali[[6]])",
                    description="Trend spatial regression model 6 with diagnostic plots"
                ),
            ],
        )

        # Spatiotemporal fixed effects analysis
        spatiotemporal_fixed_effects_analysis = RiskMapTestCategory(
            description="Spatio-temporal fixed effects analysis for Models 4, 5 and 6",
            files=[
                RiskMapModuleFile(
                    name="fixed_effects_estimates_map",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/fixed_effects_estimates_map.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/fixed_effects_estimates_map.png"),
                    function="ggplot(results_data, aes(x = lon, y = lat, col = coeff.hat$fixed_effects)) + geom_point()",
                    description="Fixed effects estimates map"
                ),
                RiskMapModuleFile(
                    name="fixed_effects_std_error_map",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/fixed_effects_std_error_map.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/fixed_effects_std_error_map.png"),
                    function="ggplot(df.results.test, aes(x = lon, y = lat, col = coeff.sd.boot$fixed_effects)) + geom_point()",
                    description="Fixed effects standard errors map"
                ),
                RiskMapModuleFile(
                    name="significant_fixed_effects_map",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/significant_fixed_effects_map.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/significant_fixed_effects_map.png"),
                    function="ggplot(dati_fe, aes(x = lon, y = lat, col = trend_sdpd_lab)) + geom_point()",
                    description="Fixed effects significant pixels map"
                ),
                RiskMapModuleFile(
                    name="by_adjusted_fixed_effects_map",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/by_adjusted_fixed_effects_map.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/by_adjusted_fixed_effects_map.png"),
                    function="ggplot(dati_fe, aes(x = lon, y = lat, col = trend_sdpd_lab_BY)) + geom_point()",
                    description="Fixed effects BY adjusted significant pixels map"
                ),
                RiskMapModuleFile(
                    name="fixed_effects_summary_table",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/fixed_effects_summary_table.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/fixed_effects_summary_table.html"),
                    function="datatable(dati_summary_fe, filter = 'top')",
                    description="Summary statistics table for fixed effects analysis"
                ),
            ],
        )

        # Spatial regression fixed effect parameters
        spatial_regression_fixed_effect_parameters = RiskMapTestCategory(
            description="Spatial regression of fixed effect parameters for Models 4, 5 and 6",
            files=[
                RiskMapModuleFile(
                    name="land_cover_map_fixed_effects_regression",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/land_cover_map_fixed_effects_regression.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/land_cover_map_fixed_effects_regression.png"),
                    function="ggplot(slc_df, aes(x = Longitude, y = Latitude, color = LC)) + geom_point()",
                    description="Land cover map for fixed effects regression analysis"
                ),
                RiskMapModuleFile(
                    name="fixed_effects_regression_model_1",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_1.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_1.html"),
                    function="summary(modelli_globali_FE[[1]])",
                    description="Fixed effects spatial regression model 1 with diagnostic plots"
                ),
                RiskMapModuleFile(
                    name="fixed_effects_regression_model_2",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_2.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_2.html"),
                    function="summary(modelli_globali_FE[[2]])",
                    description="Fixed effects spatial regression model 2 with diagnostic plots"
                ),
                RiskMapModuleFile(
                    name="fixed_effects_regression_model_3",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_3.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_3.html"),
                    function="summary(modelli_globali_FE[[3]])",
                    description="Fixed effects spatial regression model 3 with diagnostic plots"
                ),
                RiskMapModuleFile(
                    name="fixed_effects_regression_model_4",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_4.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_4.html"),
                    function="summary(modelli_globali_FE[[4]])",
                    description="Fixed effects spatial regression model 4 with diagnostic plots"
                ),
                RiskMapModuleFile(
                    name="fixed_effects_regression_model_5",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_5.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_5.html"),
                    function="summary(modelli_globali_FE[[5]])",
                    description="Fixed effects spatial regression model 5 with diagnostic plots"
                ),
                RiskMapModuleFile(
                    name="fixed_effects_regression_model_6",
                    path_dynamic=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_6.html"),
                    path_static=os.path.join(output_dir, "riskmap/plots/fixed_effects_regression_model_6.html"),
                    function="summary(modelli_globali_FE[[6]])",
                    description="Fixed effects spatial regression model 6 with diagnostic plots"
                ),
            ],
        )

        return RiskMapModuleOutputs(
            sens_slope_test=sens_slope_test,
            cox_snell_test=cox_snell_test,
            mann_kendall_test=mann_kendall_test,
            seasonal_mann_kendall_test=seasonal_mann_kendall_test,
            prewhitened_mann_kendall_test=prewhitened_mann_kendall_test,
            bias_corrected_prewhitened_test=bias_corrected_prewhitened_test,
            robust_trend_newey_west=robust_trend_newey_west,
            score_function_combination=score_function_combination,
            majority_voting_combination=majority_voting_combination,
            temporal_analysis=temporal_analysis,
            spatial_analysis=spatial_analysis,
            spatiotemporal_trend_analysis=spatiotemporal_trend_analysis,
            spatial_regression_trend_parameters=spatial_regression_trend_parameters,
            spatiotemporal_fixed_effects_analysis=spatiotemporal_fixed_effects_analysis,
            spatial_regression_fixed_effect_parameters=spatial_regression_fixed_effect_parameters,
        )

    def _generate_model_specific_availability(self) -> Dict[str, ModelSpecificAvailability]:
        """Generate model specific availability for risk map features based on R script analysis."""
        return {
            ModelType.Model1_Simple.value: ModelSpecificAvailability(
                # Model 1 Simple - All trend tests available
                sens_slope_test=True,
                cox_snell_test=True,
                mann_kendall_test=True,
                seasonal_mann_kendall_test=True,
                prewhitened_mann_kendall_test=True,
                bias_corrected_prewhitened_test=True,
                robust_trend_newey_west=True,
                score_function_combination=True,
                majority_voting_combination=True,
                # MB-Trend analysis not available
                temporal_analysis=False,
                spatial_analysis=False,
                # H-SDPD analysis not available
                spatiotemporal_trend_analysis=False,
                spatial_regression_trend_parameters=False,
                spatiotemporal_fixed_effects_analysis=False,
                spatial_regression_fixed_effect_parameters=False,
            ),
            ModelType.Model2_Autoregressive.value: ModelSpecificAvailability(
                # Model 1 Simple trend tests not available
                sens_slope_test=False,
                cox_snell_test=False,
                mann_kendall_test=False,
                seasonal_mann_kendall_test=False,
                prewhitened_mann_kendall_test=False,
                bias_corrected_prewhitened_test=False,
                robust_trend_newey_west=False,
                score_function_combination=False,
                majority_voting_combination=False,
                # MB-Trend analysis available
                temporal_analysis=True,
                spatial_analysis=True,
                # H-SDPD analysis not available
                spatiotemporal_trend_analysis=False,
                spatial_regression_trend_parameters=False,
                spatiotemporal_fixed_effects_analysis=False,
                spatial_regression_fixed_effect_parameters=False,
            ),
            ModelType.Model3_MB_User.value: ModelSpecificAvailability(
                # Model 1 Simple trend tests not available
                sens_slope_test=False,
                cox_snell_test=False,
                mann_kendall_test=False,
                seasonal_mann_kendall_test=False,
                prewhitened_mann_kendall_test=False,
                bias_corrected_prewhitened_test=False,
                robust_trend_newey_west=False,
                score_function_combination=False,
                majority_voting_combination=False,
                # MB-Trend analysis available
                temporal_analysis=True,
                spatial_analysis=True,
                # H-SDPD analysis not available
                spatiotemporal_trend_analysis=False,
                spatial_regression_trend_parameters=False,
                spatiotemporal_fixed_effects_analysis=False,
                spatial_regression_fixed_effect_parameters=False,
            ),
            ModelType.Model4_UHI.value: ModelSpecificAvailability(
                # Model 1 Simple trend tests not available
                sens_slope_test=False,
                cox_snell_test=False,
                mann_kendall_test=False,
                seasonal_mann_kendall_test=False,
                prewhitened_mann_kendall_test=False,
                bias_corrected_prewhitened_test=False,
                robust_trend_newey_west=False,
                score_function_combination=False,
                majority_voting_combination=False,
                # MB-Trend analysis not available
                temporal_analysis=False,
                spatial_analysis=False,
                # H-SDPD analysis available
                spatiotemporal_trend_analysis=True,
                spatial_regression_trend_parameters=True,
                spatiotemporal_fixed_effects_analysis=True,
                spatial_regression_fixed_effect_parameters=True,
            ),
            ModelType.Model5_RAB.value: ModelSpecificAvailability(
                # Model 1 Simple trend tests not available
                sens_slope_test=False,
                cox_snell_test=False,
                mann_kendall_test=False,
                seasonal_mann_kendall_test=False,
                prewhitened_mann_kendall_test=False,
                bias_corrected_prewhitened_test=False,
                robust_trend_newey_west=False,
                score_function_combination=False,
                majority_voting_combination=False,
                # MB-Trend analysis not available
                temporal_analysis=False,
                spatial_analysis=False,
                # H-SDPD analysis available
                spatiotemporal_trend_analysis=True,
                spatial_regression_trend_parameters=True,
                spatiotemporal_fixed_effects_analysis=True,
                spatial_regression_fixed_effect_parameters=True,
            ),
            ModelType.Model6_HSDPD_user.value: ModelSpecificAvailability(
                # Model 1 Simple trend tests not available
                sens_slope_test=False,
                cox_snell_test=False,
                mann_kendall_test=False,
                seasonal_mann_kendall_test=False,
                prewhitened_mann_kendall_test=False,
                bias_corrected_prewhitened_test=False,
                robust_trend_newey_west=False,
                score_function_combination=False,
                majority_voting_combination=False,
                # MB-Trend analysis not available
                temporal_analysis=False,
                spatial_analysis=False,
                # H-SDPD analysis available
                spatiotemporal_trend_analysis=True,
                spatial_regression_trend_parameters=True,
                spatiotemporal_fixed_effects_analysis=True,
                spatial_regression_fixed_effect_parameters=True,
            ),
        }
