import os
from typing import List

from app.domain.dataset.dataset_dto import Raster
from app.domain.integration.integration_dto import (
    IntegrationResponse,
    RModelConfig,
    RBuildDataframe,
    RVariableSelection,
)
from app.domain.integration.integration_service import IntegrationService
from app.domain.load_module.load_module_dto import (
    ModelConfiguration,
    BuildDataframeOption,
)
from app.utils.enums import LoadStep, ModuleName
from app.utils.logger import Logger


class LoadModuleIntegrationService(IntegrationService):
    def __init__(self):
        super().__init__()
        self.module_name = str(ModuleName.load_module.value)

    def _get_model_config_path(self, analysis_id: str) -> str:
        """Returns the full path to model config JSON file"""
        analysis_dir = self.get_analysis_path(analysis_id, self.module_name)
        config_file = f"{LoadStep.model_config.value}.json"
        return os.path.join(analysis_dir, config_file)

    def _get_build_dataframe_path(self, analysis_id: str) -> str:
        """Returns the full path to model config JSON file"""
        analysis_dir = self.get_analysis_path(analysis_id, self.module_name)
        config_file = f"{LoadStep.build_dataframe.value}.json"
        return os.path.join(analysis_dir, config_file)

    def prepare_model_config(
        self, analysis_id: str, model_config: ModelConfiguration
    ) -> IntegrationResponse:
        """
        Prepares and returns mock model configuration paths for R processing.
        """
        try:

            # TODO: add R script and return real Configuration
            # This is currently returning mock data - implement actual R integration
            print("model_config:")
            print(model_config.model_dump_json())

            analysis_path = self.get_analysis_path(analysis_id, self.module_name)

            # Create mock response data
            config = RModelConfig(
                italy_shape_path=os.path.join(
                    analysis_path, "ProvCM01012025_g_WGS84.shp"
                ),
                projected_shape_path=os.path.join(analysis_path, "projected_shape.shp"),
                province_raster_path=os.path.join(analysis_path, "province_raster.tif"),
                label_province_mapping={
                    "001": "Province 1",
                    "002": "Province 2",
                    "003": "Province 3",
                },
            )

            # Save to JSON file
            config_path = self._get_model_config_path(analysis_id)
            self._save_result_to_file(config, config_path)

            response = IntegrationResponse(
                status=True,
                message="Mock model configuration prepared successfully",
                data_path=config_path,
                metadata={"source": "mock_data"},
            )

            return response

        except Exception as e:
            Logger.error(
                "Failed to prepare model config using R: {}".format(e),
                context={"task": "handle_prepare_r_model_config", "message": str(e)},
            )
            raise e

    # New integration methods for dataframe building and download functionality
    def build_dataframes(
        self, analysis_id: str, options: BuildDataframeOption
    ) -> IntegrationResponse:
        """
        Execute R script to build dataframes (df.data, global.series, df.gruppi).
        """
        try:
            # Get analysis path
            analysis_path = self.get_analysis_path(analysis_id, self.module_name)
            step_name = LoadStep.build_dataframe.value

            # Read Saved Model Configurations
            model_config_path = self._get_model_config_path(analysis_id)
            model_config = self._read_data_from_file(model_config_path, RModelConfig)

            print("saved model_config:\n", model_config)

            # TODO: Implement actual R script execution
            # This currently returns mock data - implement actual R integration later
            print("Build dataframe Options:")
            print(options.model_dump_json())

            # Create mock response data for the R dataframe building operation
            result_data = RBuildDataframe(
                df_data_path=os.path.join(analysis_path, "df_data.rds"),
                global_series_path=os.path.join(analysis_path, "global_series.rds"),
                df_gruppi_path=os.path.join(analysis_path, "df_gruppi.rds"),
                num_pixels=3182,  # Based on documentation example
                num_groups=5,  # Mock number of province groups
                time_period="2011-01-01 to 2023-12-01",  # Mock time period
            )

            output_path = self._get_build_dataframe_path(analysis_id)
            # Save to file
            self._save_result_to_file(result_data, output_path)

            # Return response with file paths in metadata
            response = IntegrationResponse(
                status=True,
                message=f"{step_name} completed successfully",
                data_path=output_path,
                metadata={
                    "source": "mock_data",
                    "df_data_path": result_data.df_data_path,
                    "global_series_path": result_data.global_series_path,
                    "df_gruppi_path": result_data.df_gruppi_path,
                    "num_pixels": result_data.num_pixels,
                    "num_groups": result_data.num_groups,
                    "time_period": result_data.time_period,
                },
            )

            return response

        except Exception as e:
            Logger.error(
                f"Failed to build dataframes: {e}",
                context={"task": "build_dataframes", "analysis_id": analysis_id},
            )
            raise e

    def select_variables(
        self, analysis_id: str, selected_variables: List[Raster]
    ) -> IntegrationResponse:
        """
        Execute R script to select variables and generate CSV files for download.
        Following R integration protocol: read from build_dataframe step.
        """
        try:
            # Get step output path using base class method
            step_name = LoadStep.download.value
            output_path = self._get_step_output_path(
                analysis_id, self.module_name, step_name
            )

            # Read previous step configuration from build_dataframe
            build_dataframe_path = self._get_previous_step_path(
                analysis_id, self.module_name, LoadStep.build_dataframe.value
            )

            build_dataframe_config = self._read_data_from_file(
                build_dataframe_path, RBuildDataframe
            )

            print(f"Read build dataframe config: {build_dataframe_config}")
            print(f"Variable selections: {selected_variables}")

            # TODO: Implement actual R script execution

            # Create proper R result DTO following the protocol
            downloads_path = os.path.join(
                self.get_analysis_path(analysis_id, self.module_name), "downloads"
            )
            os.makedirs(downloads_path, exist_ok=True)

            # Generate CSV file paths for selected variables
            csv_files = []

            for i, selected in enumerate(selected_variables):
                csv_file = os.path.join(downloads_path, f"{selected.variable_name}.csv")
                csv_files.append(csv_file)

                # Create mock CSV file (in actual implementation, R would generate these)
                with open(csv_file, "w") as f:
                    f.write("lat,lon,X2011.01.01,X2011.02.01,X2011.03.01\n")
                    f.write("40.8518,14.2681,285.5,287.2,289.1\n")
                    f.write("40.8519,14.2682,285.3,287.0,288.9\n")

            # Create proper R result DTO following the protocol
            result_data = RVariableSelection(
                csv_files=csv_files,
            )

            print("result_data in integration service: -----------------------")
            print(result_data)

            # Save R result DTO to file using base class method
            self._save_result_to_file(result_data, output_path)

            response = IntegrationResponse(
                status=True,
                message=f"{step_name} completed successfully",
                data_path=output_path,
                metadata={
                    "source": "mock_data",
                    "csv_files": csv_files,
                    "downloads_path": downloads_path,
                },
            )

            return response

        except Exception as e:
            Logger.error(
                f"Failed to select variables: {e}",
                context={"task": "select_variables", "analysis_id": analysis_id},
            )
            raise e
