import os

from app.Models.analysis import Analysis
from app.domain.describe.describe_dto import (
    GetDescribeModuleOutputsResponse,
    DescribeModuleOutputs,
    DescribeModuleDataExports,
    DescribeModulePlotGroup,
    DescribeModuleFile,
    DescribeModuleStatistics,
    ModelSpecificAvailability,
)
from app.utils.utils import get_analysis_output_path
from app.utils.enums import AnalysisVariable


class DescribeModuleService:
    def __init__(self):
        pass

    async def get_describe_module_outputs(
        self, analysis: Analysis
    ) -> GetDescribeModuleOutputsResponse:
        """
        Retrieve describe module outputs for a given analysis and model type.

        :param analysis: Analysis object with all configuration
        :return: Describe module outputs response
        """

        # Get the output directory for this analysis and model type
        output_dir = get_analysis_output_path(analysis.id, analysis.model_type)

        # Get variables from analysis configuration
        variables = list(AnalysisVariable)
        endogenous_variable = analysis.model_config.get("endogenous_variable", "")
        summary_stat = analysis.model_config.get("summary_stat", "mean")

        # Create spatial distribution plots
        spatial_files = []
        for var in variables:
            spatial_files.append(
                DescribeModuleFile(
                    name=f"{var.value}_spatial",
                    variable=var,
                    path_dynamic=os.path.join(
                        output_dir, f"summary_stats/plots/{var.value}_spatial.html"
                    ),
                    path_static=os.path.join(
                        output_dir, f"summary_stats/plots/{var.value}_spatial.png"
                    ),
                    function=f"plotVarSpatial('{var.value}', user_date_choice, dataframes[['{var.value}']], pars_list[['{var.value}']], bool_dynamic, output_path)",
                    description=f"Spatial distribution plot for {var.value} at a fixed date"
                )
            )

        spatial_plots = DescribeModulePlotGroup(
            description="Plotting Spatial distribution of values at a fixed date",
            files=spatial_files,
        )

        # Create temporal distribution plots (STL decomposition)
        temporal_files = []
        for var in variables:
            temporal_files.append(
                DescribeModuleFile(
                    name=f"{var.value}_stl_decomposition",
                    variable=var,
                    path_dynamic=os.path.join(
                        output_dir,
                        f"summary_stats/plots/{var.value}_stl_decomposition.html",
                    ),
                    path_static=os.path.join(
                        output_dir, f"summary_stats/plots/{var.value}_stl_decomposition.png"
                    ),
                    function=f"PlotComponentsSTL_nonest_lonlat2(user_latitude_choice, user_longitude_choice, '{var.value}', dataframes[['{var.value}']], pars_list[['{var.value}']], bool_dynamic, output_path)",
                    description=f"STL decomposition plot for {var.value} at a fixed pixel"
                )
            )

        temporal_plots = DescribeModulePlotGroup(
            description="Plotting Temporal distribution of values for a fixed pixel (STL decomposition)",
            files=temporal_files,
        )

        # Create summary statistics plots
        summary_files = []
        for var in variables:
            summary_files.append(
                DescribeModuleFile(
                    name=f"{summary_stat}_{var.value}",
                    variable=var,
                    path_dynamic=os.path.join(
                        output_dir, f"summary_stats/plots/{summary_stat}_{var.value}.html"
                    ),
                    path_static=os.path.join(
                        output_dir, f"summary_stats/plots/{summary_stat}_{var.value}.png"
                    ),
                    function=f"fun.plot.stat.VARs(dataframes[['{var.value}']], funzione, paste('{summary_stat}', 'of', '{var.value}'), pars_list[['{var.value}']], output_path, bool_dynamic)",
                    description=f"Summary statistics plot ({summary_stat}) for {var.value}"
                )
            )

        summary_plots = DescribeModulePlotGroup(
            description="Plotting Summary Statistics (based on user-selected statistic)",
            files=summary_files,
        )

        # Create data exports
        data_exports = DescribeModuleDataExports(
            endogenous_variable_csv=os.path.join(
                output_dir, f"data/{endogenous_variable}.csv"
            ),
        )

        # Create statistics data exports
        statistics_data = DescribeModuleStatistics(
            variable_summary_statistics=os.path.join(
                output_dir, "summary_stats/stats", "variable_summary_statistics.json"
            ),
            pixel_time_series_data=os.path.join(
                output_dir, "summary_stats/stats", "pixel_time_series_data.json"
            ),
        )

        # Build the complete outputs structure
        outputs = DescribeModuleOutputs(
            data_exports=data_exports,
            spatial_distribution_plots=spatial_plots,
            temporal_distribution_plots=temporal_plots,
            summary_statistics_plots=summary_plots,
            statistics_data=statistics_data,
        )

        # Create model-specific availability
        model_availability = ModelSpecificAvailability()

        return GetDescribeModuleOutputsResponse(
            describe_module_outputs=outputs,
            model_specific_availability=model_availability,
        )
