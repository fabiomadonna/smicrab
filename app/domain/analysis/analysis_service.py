from app.Models.analysis import Analysis, AnalyzeStatus
from app.domain.analysis.analysis_dto import (
    CreateAnalysisRequest,
    UserAnalysesResponse,
    AnalysisSchema,
    SaveAnalysisParametersRequest,
    RunAnalysisRequest,
    RunAnalysisResponse,
    AnalysisWebhookRequest,
    AnalysisWebhookResponse,
    DeleteAnalysisRequest,
    DeleteAnalysisResponse,
)
from app.domain.integration.analysis_integration_service import (
    AnalysisIntegrationService,
)
from app.domain.analysis.container_service import ContainerService
from app.infrastructure.repositories.analysis_repository import AnalysisRepository
from app.utils import get_parameters_file, get_flag_file
from app.utils.constants import (
    MODEL_SCRIPTS,
    MODULE_SCRIPTS,
    MODULE_EXECUTION_ORDER,
    COMMON_SETUP_SCRIPT,
)
from app.utils.logger import Logger
from app.utils.enums import (
    ModelType,
    AnalysisVariable,
    SummaryStat,
    ModuleName,
    ModuleProgress,
)

from datetime import datetime, timezone
from typing import Dict, Any, List
import os
import json

from core.config import settings


class AnalysisService:
    def __init__(self, repository: AnalysisRepository):
        self.repository = repository
        self.integration_service = AnalysisIntegrationService()
        self.container_service = ContainerService()

    async def verify_analysis(self, analysis_id: str) -> Analysis:
        try:
            analysis = await self.repository.get_by_id(analysis_id)
            if analysis is None:
                raise ValueError(f'Analysis "{analysis_id}" does not exist')
            else:
                return analysis
        except Exception as e:
            Logger.error(
                "Failed to verify Analysis: {}".format(e),
                context={"task": "handle_verify_analysis", "message": str(e)},
            )
            raise Exception("Failed to verify Analysis")

    async def verify_analysis_ownership(self, analysis_id: str, user_id: str) -> Analysis:
        """Verify that the analysis exists and belongs to the specified user."""
        try:
            analysis = await self.repository.get_by_id(analysis_id)
            if analysis is None:
                raise ValueError(f'Analysis "{analysis_id}" does not exist')
            
            if str(analysis.user_id) != user_id:
                raise ValueError(f'Analysis "{analysis_id}" does not belong to user "{user_id}"')
            
            return analysis
        except Exception as e:
            Logger.error(
                "Failed to verify analysis ownership: {}".format(e),
                context={"task": "verify_analysis_ownership", "analysis_id": analysis_id, "user_id": user_id},
            )
            raise e

    async def create_analysis(self, request: CreateAnalysisRequest) -> AnalysisSchema:
        try:
            analysis = await self.repository.create_analysis(request.user_id)
            return AnalysisSchema(
                id=analysis.id,
                user_id=analysis.user_id,
                status=analysis.status,
                current_module=analysis.current_module,
                model_config_data=analysis.model_config,
                model_type=analysis.model_type,
                coordinates=analysis.coordinates,
                is_dynamic_output=analysis.is_dynamic_output,
                analysis_date=analysis.analysis_date,
                created_at=analysis.created_at,
                updated_at=analysis.updated_at,
                expires_at=analysis.expires_at,
            )

        except Exception as e:
            Logger.error(
                "Failed to create Analysis: {}".format(e),
                context={"task": "handle_create_analysis", "message": str(e)},
            )
            raise e

    async def start_new_module(self, analysis_id: str, module_name: ModuleName):
        try:
            await self.repository.update_current_module(
                analysis_id=analysis_id, module_name=module_name
            )
        except Exception as e:
            Logger.error(
                "Failed to complete module: {}".format(e),
                context={"task": "handle_start_new_module", "message": str(e)},
            )
            raise e

    async def get_analysis_status(self, analysis_id: str) -> AnalysisSchema:
        """Get the status of a specific analysis."""
        try:
            analysis = await self.repository.get_by_id(analysis_id)
            if analysis is None:
                raise ValueError(f'Analysis "{analysis_id}" does not exist')

            return AnalysisSchema(
                id=analysis.id,
                user_id=analysis.user_id,
                status=analysis.status,
                current_module=analysis.current_module,
                model_config_data=analysis.model_config,
                model_type=analysis.model_type,
                coordinates=analysis.coordinates,
                is_dynamic_output=analysis.is_dynamic_output,
                analysis_date=analysis.analysis_date,
                created_at=analysis.created_at,
                updated_at=analysis.updated_at,
                expires_at=analysis.expires_at,
            )

        except Exception as e:
            Logger.error(
                "Failed to get analysis status: {}".format(e),
                context={"task": "handle_get_analysis_status", "message": str(e)},
            )
            raise e

    async def update_analysis_status(self, analysis_id: str, status: AnalyzeStatus):
        """Update the status of an analysis."""
        try:
            analysis = await self.repository.update_status(
                analysis_id=analysis_id, status=status
            )
            return analysis
        except Exception as e:
            Logger.error(
                "Failed to update analysis status: {}".format(e),
                context={"task": "handle_update_analysis_status", "message": str(e)},
            )
            raise e

    async def get_user_analyses(self, user_id: str) -> UserAnalysesResponse:
        """Retrieve all analyses for a specific user."""
        try:
            analyses = await self.repository.get_user_analyses(user_id)

            analysis_statuses = [
                AnalysisSchema(
                    id=analysis.id,
                    user_id=analysis.user_id,
                    status=analysis.status,
                    current_module=analysis.current_module,
                    model_config_data=analysis.model_config,
                    model_type=analysis.model_type,
                    coordinates=analysis.coordinates,
                    is_dynamic_output=analysis.is_dynamic_output,
                    analysis_date=analysis.analysis_date,
                    created_at=analysis.created_at,
                    updated_at=analysis.updated_at,
                    expires_at=analysis.expires_at,
                )
                for analysis in analyses
            ]

            return UserAnalysesResponse(analyses=analysis_statuses)
        except Exception as e:
            Logger.error(
                "Failed to get user analyses: {}".format(e),
                context={"task": "handle_get_user_analyses", "message": str(e)},
            )
            raise e

    async def run_analysis(self, analysis: Analysis) -> RunAnalysisResponse:
        try:
            # Retrieve model_type from the existing analysis
            model_type = analysis.model_type

            if not model_type:
                raise ValueError("Model type is not configured for this analysis")

            if not analysis.model_config or not analysis.coordinates:
                raise ValueError("Analysis must be configured before running")

            if analysis.status not in [AnalyzeStatus.configured, AnalyzeStatus.error]:
                if analysis.status == AnalyzeStatus.in_progress:
                    raise ValueError(
                        "Analysis already in progress. Please wait until it completes"
                    )
                elif analysis.status == AnalyzeStatus.pending:
                    raise ValueError(
                        "Analysis must be configured with parameters before running"
                    )
                elif analysis.status == AnalyzeStatus.completed:
                    raise ValueError(
                        "Analysis is already completed. Create a new analysis to run again"
                    )

            # Check if we can start a new container (max 3 concurrent)
            if not self.container_service.can_start_new_container():
                running_count = self.container_service.get_running_container_count()
                raise ValueError(
                    f"Cannot start analysis: Maximum concurrent analyses ({self.container_service.max_concurrent_containers}) "
                    f"are already running. Currently running: {running_count}. Please wait for one to complete."
                )

            # Update status to in_progress
            analysis = await self.repository.update_status(
                analysis.id, AnalyzeStatus.in_progress
            )

            # Start analysis in Docker container
            container_started = self.container_service.start_analysis_container(
                str(analysis.id), 
                model_type.value
            )

            if not container_started:
                # Revert status if container failed to start
                await self.repository.update_status(analysis.id, AnalyzeStatus.error)
                await self.repository.add_error_message(
                    str(analysis.id), 
                    "Failed to start analysis container"
                )
                raise ValueError("Failed to start analysis container")

            Logger.info(
                f"Analysis container started for {analysis.id} with model {model_type.value}"
            )

            return RunAnalysisResponse(
                analysis_id=str(analysis.id),
                status=analysis.status,
                execution_started=True,
                message=f"Analysis execution started in container with {model_type.value}",
            )

        except Exception as e:
            await self.repository.add_error_message(str(analysis.id), str(e))
            Logger.error(
                f"Failed to run analysis: {e}",
                context={
                    "task": "handle_run_analysis",
                    "analysis_id": str(analysis.id),
                },
            )
            raise e

    # Thread-based execution methods removed - now using Docker containers

    # Old thread-based execution methods removed - execution now handled in Docker containers

    async def save_analysis_parameters(
        self, request: SaveAnalysisParametersRequest
    ) -> AnalysisSchema:
        """
        Save analysis parameters to database and parameter JSON file.

        Args:
            request (SaveAnalysisParametersRequest): Analysis parameters to save

        Returns:
            AnalysisSchema: Updated analysis object
        """
        try:
            # Verify analysis exists
            analysis = await self.verify_analysis(request.analysis_id)

            # Prepare parameters dictionary
            parameters = {
                "analysis_id": request.analysis_id,
                "model_type": request.model_type.value,
                "bool_update": request.bool_update,
                "bool_trend": request.bool_trend,
                "summary_stat": request.summary_stat.value,
                "user_longitude_choice": request.user_longitude_choice,
                "user_latitude_choice": request.user_latitude_choice,
                "user_coeff_choice": request.user_coeff_choice,
                "bool_dynamic": request.bool_dynamic,
                "endogenous_variable": request.endogenous_variable.value,
                "covariate_variables": [
                    var.value for var in request.covariate_variables
                ],
                "covariate_legs": request.covariate_legs,
                "user_date_choice": request.user_date_choice,
                "vec_options": (
                    request.vec_options.model_dump() if request.vec_options else {}
                ),
            }

            # Save parameters to JSON file using utils function
            parameters_file = get_parameters_file(request.analysis_id)
            os.makedirs(os.path.dirname(parameters_file), exist_ok=True)
            with open(parameters_file, "w") as f:
                json.dump(parameters, f, indent=2)

            # Update analysis with model config
            analysis = await self.repository.update_analysis_config(
                analysis_id=request.analysis_id,
                model_type=request.model_type,
                model_config=parameters,
                coordinates={
                    "longitude": request.user_longitude_choice,
                    "latitude": request.user_latitude_choice,
                },
                is_dynamic_output=request.bool_dynamic,
                analysis_date=(
                    datetime.now(timezone.utc)
                    if request.user_date_choice is None
                    else datetime.fromisoformat(request.user_date_choice)
                ),
            )

            # Update status to configured after parameters are saved
            analysis = await self.repository.update_status(
                request.analysis_id, AnalyzeStatus.configured
            )

            Logger.info(f"Analysis parameters saved for analysis {request.analysis_id}")

            Logger.info(
                f"Analysis {request.analysis_id} configured successfully with model {request.model_type}"
            )

            # Save parameters
            self.integration_service.save_analysis_parameters(
                request.analysis_id, parameters
            )

            return AnalysisSchema(
                id=analysis.id,
                user_id=analysis.user_id,
                status=analysis.status,
                current_module=analysis.current_module,
                model_config_data=analysis.model_config,
                model_type=analysis.model_type,
                coordinates=analysis.coordinates,
                is_dynamic_output=analysis.is_dynamic_output,
                analysis_date=analysis.analysis_date,
                created_at=analysis.created_at,
                updated_at=analysis.updated_at,
                expires_at=analysis.expires_at,
            )

        except Exception as e:
            Logger.error(
                f"Failed to save analysis parameters: {e}",
                context={"task": "save_analysis_parameters", "message": str(e)},
            )
            raise e

    async def handle_analysis_completion_webhook(
        self, request: AnalysisWebhookRequest
    ) -> AnalysisWebhookResponse:
        """
        Handle webhook notification for analysis completion and module updates

        Args:
            request: Webhook request with analysis completion status

        Returns:
            AnalysisWebhookResponse with processing status
        """
        try:
            # Verify analysis exists
            analysis = await self.verify_analysis(request.analysis_id)

            # Update analysis status based on webhook payload
            if request.status == "done":
                # Update status to completed and set current module to the last one
                analysis = await self.repository.update_current_module(
                    request.analysis_id,
                    ModuleName.risk_map_module,
                    AnalyzeStatus.completed,
                )
                message = f"Analysis {request.analysis_id} completed successfully"
                Logger.info(message)

            elif request.status == "module_completed":
                # Handle module completion update
                current_module = getattr(request, "current_module", None)
                next_module = getattr(request, "next_module", None)

                if current_module and next_module != "completed":
                    # Update to next module
                    try:
                        next_module_enum = ModuleName(next_module)
                        analysis = await self.repository.update_current_module(
                            request.analysis_id,
                            next_module_enum,
                            AnalyzeStatus.in_progress,
                        )
                        message = f"Analysis {request.analysis_id} progressed to module {next_module}"
                        Logger.info(message)
                    except ValueError:
                        Logger.error(
                            f"Invalid module name: {next_module}",
                            context={"task": "handle_analysis_completion_webhook"},
                        )
                        message = f"Module update processed for analysis {request.analysis_id}"
                else:
                    message = (
                        f"Module update processed for analysis {request.analysis_id}"
                    )

            elif request.status == "error":
                analysis = await self.repository.update_status(
                    request.analysis_id, AnalyzeStatus.error
                )
                message = f"Analysis {request.analysis_id} failed: {request.error_message or 'Unknown error'}"
                Logger.error(
                    message, context={"task": "handle_analysis_completion_webhook"}
                )

            elif request.status == "timeout":
                analysis = await self.repository.update_status(
                    request.analysis_id, AnalyzeStatus.error
                )
                message = f"Analysis {request.analysis_id} timed out"
                Logger.error(
                    message, context={"task": "handle_analysis_completion_webhook"}
                )

            else:
                raise ValueError(f"Invalid status received: {request.status}")

            return AnalysisWebhookResponse(
                success=True,
                message=message,
                analysis_id=request.analysis_id,
                updated_status=analysis.status,
            )

        except Exception as e:
            Logger.error(
                f"Failed to handle analysis completion webhook: {e}",
                context={
                    "task": "handle_analysis_completion_webhook",
                    "analysis_id": request.analysis_id,
                    "webhook_status": request.status,
                },
            )

            return AnalysisWebhookResponse(
                success=False,
                message=f"Failed to process webhook: {str(e)}",
                analysis_id=request.analysis_id,
                updated_status=AnalyzeStatus.error,
            )

    async def download_analysis_file(
        self, analysis_id: str, file_type: str, file_name: str
    ) -> str:
        """Get the file path for downloading analysis files."""
        try:
            # Verify analysis exists
            await self.verify_analysis(analysis_id)

            # Get analysis output directory
            output_base_dir = (
                "/tmp/analysis"
                if os.name != "nt"
                else os.path.join(os.getcwd(), "tmp", "analysis")
            )

            # Find the model directory (look for any model type directory)
            analysis_dir = os.path.join(output_base_dir, analysis_id)
            if not os.path.exists(analysis_dir):
                raise ValueError(f"Analysis directory not found: {analysis_dir}")

            # Find the model subdirectory
            model_dirs = [
                d
                for d in os.listdir(analysis_dir)
                if os.path.isdir(os.path.join(analysis_dir, d))
            ]
            if not model_dirs:
                raise ValueError(f"No model directories found in {analysis_dir}")

            # Use the first model directory found
            model_dir = model_dirs[0]

            # Construct file path based on file type
            if file_type == "plots":
                file_path = os.path.join(
                    analysis_dir, model_dir, "riskmap", "plots", file_name
                )
            elif file_type == "tables":
                file_path = os.path.join(
                    analysis_dir, model_dir, "riskmap", "plots", file_name
                )
            elif file_type == "maps":
                file_path = os.path.join(
                    analysis_dir, model_dir, "riskmap", "plots", file_name
                )
            elif file_type == "rdata":
                file_path = os.path.join(analysis_dir, model_dir, "Rdata", file_name)
            else:
                raise ValueError(f"Invalid file type: {file_type}")

            if not os.path.exists(file_path):
                raise ValueError(f"File not found: {file_path}")

            return file_path

        except Exception as e:
            Logger.error(
                f"Failed to get file path for download: {e}",
                context={
                    "task": "download_analysis_file",
                    "analysis_id": analysis_id,
                    "file_type": file_type,
                    "file_name": file_name,
                },
            )
            raise e

    async def delete_analysis(self, request: DeleteAnalysisRequest) -> DeleteAnalysisResponse:
        """
        Delete an analysis and clean up associated resources.
        
        Args:
            request (DeleteAnalysisRequest): Analysis deletion request
            
        Returns:
            DeleteAnalysisResponse: Deletion status and details
        """
        try:
            # Verify analysis exists
            analysis = await self.verify_analysis(request.analysis_id)
            
            container_stopped = False
            
            # Check if analysis is running and stop container if needed
            if analysis.status == AnalyzeStatus.in_progress:
                Logger.info(f"Stopping running container for analysis {request.analysis_id}")
                container_stopped = self.container_service.stop_analysis_container(request.analysis_id)
                if container_stopped:
                    Logger.info(f"Successfully stopped container for analysis {request.analysis_id}")
                else:
                    Logger.warn(f"Could not stop container for analysis {request.analysis_id}")
            
            # Delete analysis from database
            deleted = await self.repository.delete_analysis(request.analysis_id)
            
            if not deleted:
                raise ValueError(f"Failed to delete analysis {request.analysis_id} from database")
            
            # Clean up analysis files
            try:
                self._cleanup_analysis_files(request.analysis_id)
            except Exception as cleanup_error:
                Logger.warn(
                    f"Failed to cleanup analysis files for {request.analysis_id}: {cleanup_error}",
                    context={"task": "delete_analysis", "analysis_id": request.analysis_id}
                )
            
            Logger.info(f"Successfully deleted analysis {request.analysis_id}")
            
            return DeleteAnalysisResponse(
                analysis_id=request.analysis_id,
                deleted=True,
                container_stopped=container_stopped,
                message=f"Analysis {request.analysis_id} deleted successfully"
            )
            
        except Exception as e:
            Logger.error(
                f"Failed to delete analysis {request.analysis_id}: {e}",
                context={"task": "delete_analysis", "analysis_id": request.analysis_id}
            )
            raise e

    def _cleanup_analysis_files(self, analysis_id: str):
        """
        Clean up analysis files from the filesystem.
        
        Args:
            analysis_id (str): Analysis ID to cleanup
        """
        try:
            # Get analysis output directory
            output_base_dir = (
                "/tmp/analysis"
                if os.name != "nt"
                else os.path.join(os.getcwd(), "tmp", "analysis")
            )
            
            analysis_dir = os.path.join(output_base_dir, analysis_id)
            
            if os.path.exists(analysis_dir):
                import shutil
                shutil.rmtree(analysis_dir)
                Logger.info(f"Cleaned up analysis directory: {analysis_dir}")
            
            # Also cleanup parameters file
            parameters_file = get_parameters_file(analysis_id)
            if os.path.exists(parameters_file):
                os.remove(parameters_file)
                Logger.info(f"Cleaned up parameters file: {parameters_file}")
                
        except Exception as e:
            Logger.error(
                f"Error cleaning up analysis files for {analysis_id}: {e}",
                context={"task": "_cleanup_analysis_files", "analysis_id": analysis_id}
            )
            raise e
