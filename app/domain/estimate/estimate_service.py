import os
from typing import List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.domain.estimate.estimate_dto import (
    GetEstimateOutputsResponse,
    EstimateModuleOutputs,
    CoefficientTables,
    CoefficientPlots,
    TimeSeriesPlots,
    CsvDownloads,
    EstimateModuleFile,
    ModelSpecificAvailability,
)
from app.Models.analysis import Analysis
from app.utils.enums import AnalysisVariable, ModelType
from app.utils.utils import get_analysis_output_path
from app.utils.logger import Logger


class EstimateModuleService:
    def __init__(self):
        pass

    async def get_estimate_outputs(
        self, analysis: Analysis
    ) -> GetEstimateOutputsResponse:
        """Get estimate module outputs for the given analysis and model type."""
        try:
            # Get output directory path
            output_dir = get_analysis_output_path(analysis.id, analysis.model_type)

            # Extract configuration from model_config
            model_config = analysis.model_config
            endogenous_variable = model_config.get("endogenous_variable", "")
            covariate_variables = model_config.get("covariate_variables", [])
            bool_trend = model_config.get("bool_trend", False)

            # Generate outputs based on configuration
            outputs = self._generate_estimate_outputs(
                output_dir,
                analysis.model_type,
                endogenous_variable,
                covariate_variables,
                bool_trend,
            )

            # Generate model-specific availability
            model_availability = ModelSpecificAvailability()

            return GetEstimateOutputsResponse(
                estimate_module_outputs=outputs,
                model_specific_availability=model_availability,
            )

        except Exception as e:
            Logger.error(
                f"Failed to get estimate outputs: {e}",
                context={
                    "task": "get_estimate_outputs",
                    "analysis_id": analysis.id,
                    "model_type": analysis.model_type.value,
                },
            )
            raise e

    def _generate_estimate_outputs(
        self,
        output_dir: str,
        model_type: ModelType,
        endogenous_variable: str,
        covariate_variables: List[str],
        bool_trend: bool,
    ) -> EstimateModuleOutputs:
        """Generate estimate module outputs based on configuration."""

        # Coefficient Tables
        coefficient_tables = CoefficientTables(
            description="Interactive tables with estimated parameters (lon, lat, district, coefficients)",
            files=[
                EstimateModuleFile(
                    name="coefficients_table",
                    path_dynamic=os.path.join(output_dir, f"model_fits/plots/coeff_{endogenous_variable}.html"),
                    path_static=os.path.join(output_dir, f"model_fits/plots/coeff_{endogenous_variable}.csv"),
                    function="datatable(dati, filter = 'top')",
                    description="Interactive table with longitude, latitude, district, and coefficient estimates",
                )
            ],
        )

        # Coefficient Plots
        trend_plots = []
        if bool_trend:
            trend_plots.append(
                EstimateModuleFile(
                    name="trend_coefficient",
                    path_dynamic=os.path.join(output_dir, f"estimate/plots/plot_trend_{endogenous_variable}.html"),
                    path_static=os.path.join(output_dir, f"estimate/plots/plot_trend_{endogenous_variable}.png"),
                    function="fun.plot.coeff.FITs(df.results.estimate, pars=pars_list)$trend",
                    description="Spatial plot of trend coefficient estimates",
                )
            )

        # Generate covariate plots for selected variables
        covariate_plots = []
        for var in covariate_variables:
            covariate_plots.append(
                EstimateModuleFile(
                    name=f"covariate_{var}",
                    path_dynamic=os.path.join(output_dir, f"estimate/plots/plot_{var}.html"),
                    path_static=os.path.join(output_dir, f"estimate/plots/plot_{var}.png"),
                    function=f"fun.plot.coeff.FITs(df.results.estimate, pars=pars_list)${var}",
                    description=f"Spatial plot of {var} coefficient estimates",
                )
            )

        # Spatial autocorrelation plots (for H-SDPD models)
        spatial_autocorrelation_plots = []
        if model_type in [ModelType.Model4_UHI, ModelType.Model5_RAB, ModelType.Model6_HSDPD_user]:
            spatial_autocorrelation_plots = [
                EstimateModuleFile(
                    name="lambda0_coefficient",
                    path_dynamic=os.path.join(output_dir, f"estimate/plots/plot_lambda0_{endogenous_variable}.html"),
                    path_static=os.path.join(output_dir, f"estimate/plots/plot_lambda0_{endogenous_variable}.png"),
                    function="fun.plot.coeff.FITs(df.results.estimate, pars=pars_list)$lambda0",
                    description="Spatial autocorrelation parameter lambda0 (spatial lag of dependent variable)",
                ),
                EstimateModuleFile(
                    name="lambda1_coefficient",
                    path_dynamic=os.path.join(output_dir, f"estimate/plots/plot_lambda1_{endogenous_variable}.html"),
                    path_static=os.path.join(output_dir, f"estimate/plots/plot_lambda1_{endogenous_variable}.png"),
                    function="fun.plot.coeff.FITs(df.results.estimate, pars=pars_list)$lambda1",
                    description="Spatial autocorrelation parameter lambda1 (spatial lag of independent variables)",
                ),
                EstimateModuleFile(
                    name="lambda2_coefficient",
                    path_dynamic=os.path.join(output_dir, f"estimate/plots/plot_lambda2_{endogenous_variable}.html"),
                    path_static=os.path.join(output_dir, f"estimate/plots/plot_lambda2_{endogenous_variable}.png"),
                    function="fun.plot.coeff.FITs(df.results.estimate, pars=pars_list)$lambda2",
                    description="Spatial autocorrelation parameter lambda2 (spatial lag of error term)",
                ),
            ]

        # Fixed effects plots (for H-SDPD models)
        fixed_effects_plots = []
        if model_type in [ModelType.Model4_UHI, ModelType.Model5_RAB, ModelType.Model6_HSDPD_user]:
            fixed_effects_plots = [
                EstimateModuleFile(
                    name="fixed_effects_coefficient",
                    path_dynamic=os.path.join(output_dir, f"estimate/plots/plot_fixed_effects_{endogenous_variable}.html"),
                    path_static=os.path.join(output_dir, f"estimate/plots/plot_fixed_effects_{endogenous_variable}.png"),
                    function="fun.plot.coeff.FITs(df.results.estimate, pars=pars_list)$fixed_effects",
                    description="Spatial fixed effects estimates",
                )
            ]

        coefficient_plots = CoefficientPlots(
            description="Spatial plots of estimated coefficients",
            trend_plots=trend_plots,
            covariate_plots=covariate_plots,
            spatial_autocorrelation_plots=spatial_autocorrelation_plots,
            fixed_effects_plots=fixed_effects_plots,
        )

        # Time Series Plots
        time_series_files = []
        if model_type != ModelType.Model1_Simple:
            # Different functions for different model types
            if model_type in [ModelType.Model2_Autoregressive, ModelType.Model3_MB_User]:
                function_name = "fun.plot.series.FITs2"
            else:  # H-SDPD models
                function_name = "fun.plot.series.FITs"

            time_series_files.append(
                EstimateModuleFile(
                    name="series_fits",
                    path_dynamic=os.path.join(output_dir, f"estimate/plots/series_{endogenous_variable}.html"),
                    path_static=os.path.join(output_dir, f"estimate/plots/series_{endogenous_variable}.png"),
                    function=f"{function_name}(df.results.estimate, latitude=user_latitude_choice, longitude=user_longitude_choice, pars=pars_list)",
                    description=f"Fitted and residual time series for {model_type.value} at selected location",
                )
            )

        time_series_plots = TimeSeriesPlots(
            description="Fitted and residual time series for selected locations",
            files=time_series_files,
        )

        # CSV Downloads
        csv_files = []
        if model_type != ModelType.Model1_Simple:
            csv_files = [
                EstimateModuleFile(
                    name="estimation_results_csv",
                    path_dynamic=os.path.join(output_dir, "estimate/stats/df_results_estimate.csv"),
                    path_static=os.path.join(output_dir, "estimate/stats/df_results_estimate.csv"),
                    function="fun.prepare.df.results(df.results=df.results.estimate, model=user_model_choice)",
                    description="CSV file with coordinates, districts, and estimated coefficients",
                )
            ]

        csv_downloads = CsvDownloads(
            description="Downloadable CSV files with estimation results",
            files=csv_files,
        )

        return EstimateModuleOutputs(
            coefficient_tables=coefficient_tables,
            coefficient_plots=coefficient_plots,
            time_series_plots=time_series_plots,
            csv_downloads=csv_downloads,
        )


