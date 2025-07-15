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
)
from app.domain.integration.analysis_integration_service import (
    AnalysisIntegrationService,
)
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

from datetime import datetime
from typing import Dict, Any, List
import threading
import subprocess
import os
import json
import asyncio
import time
import requests
import queue
import concurrent.futures

from core.config import settings


class AnalysisService:
    def __init__(self, repository: AnalysisRepository):
        self.repository = repository
        self.integration_service = AnalysisIntegrationService()

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

            analysis = await self.repository.update_status(
                analysis.id, AnalyzeStatus.in_progress
            )

            # Start step-by-step module execution in a background thread
            self._start_module_execution_thread(str(analysis.id), model_type, analysis)

            Logger.info(
                f"Analysis execution started for {analysis.id} with model {model_type.value}"
            )

            return RunAnalysisResponse(
                analysis_id=str(analysis.id),
                status=analysis.status,
                execution_started=True,
                message=f"Analysis execution started with {model_type.value}",
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

    def _start_module_execution_thread(
        self, analysis_id: str, model_type: ModelType, analysis
    ):
        """Start step-by-step module execution in a background thread."""

        def module_execution_task():
            try:
                param_path = get_parameters_file(analysis_id)
                flag_file = get_flag_file(analysis_id, model_type)

                if os.path.exists(flag_file):
                    os.remove(flag_file)

                Logger.info(
                    f"Starting step-by-step module execution for analysis {analysis_id}"
                )

                # Execute modules step by step
                for i, module_progress in enumerate(MODULE_EXECUTION_ORDER):
                    try:
                        Logger.info(
                            f"Starting module {module_progress.value} for analysis {analysis_id}"
                        )

                        # Execute the module (no database update here)
                        success = self._execute_module(
                            analysis_id, module_progress, param_path
                        )

                        if not success:
                            Logger.error(
                                f"Module {module_progress.value} failed for analysis {analysis_id}",
                                context={
                                    "task": "module_execution_task",
                                    "module": module_progress.value,
                                },
                            )
                            self._send_webhook(
                                analysis_id,
                                "error",
                                settings.WEBHOOK_URL,
                                f"Module {module_progress.value} execution failed",
                            )
                            return

                        Logger.info(
                            f"Module {module_progress.value} completed successfully for analysis {analysis_id}"
                        )

                        # Send webhook to update current module after successful completion
                        module_update_payload = {
                            "analysis_id": analysis_id,
                            "status": "module_completed",
                            "current_module": module_progress.value,
                            "next_module": (
                                MODULE_EXECUTION_ORDER[i + 1].value
                                if i + 1 < len(MODULE_EXECUTION_ORDER)
                                else "completed"
                            ),
                        }
                        self._send_module_update_webhook(
                            analysis_id, module_update_payload, settings.WEBHOOK_URL
                        )

                    except Exception as e:
                        Logger.error(
                            f"Error executing module {module_progress.value}: {e}",
                            context={
                                "task": "module_execution_task",
                                "module": module_progress.value,
                            },
                        )
                        self._send_webhook(
                            analysis_id, "error", settings.WEBHOOK_URL, str(e)
                        )
                        return

                # All modules completed successfully
                Logger.info(
                    f"All modules completed successfully for analysis {analysis_id}"
                )

                # Create final flag file
                with open(flag_file, "w") as f:
                    f.write("done")

                # Send webhook to update database
                self._send_webhook(analysis_id, "done", settings.WEBHOOK_URL)

            except Exception as e:
                Logger.error(
                    f"Module execution thread failed: {e}",
                    context={"task": "_start_module_execution_thread"},
                )
                self._send_webhook(analysis_id, "error", settings.WEBHOOK_URL, str(e))

        thread = threading.Thread(target=module_execution_task)
        thread.daemon = True
        thread.start()

    def _execute_module(
        self, analysis_id: str, module_progress: ModuleProgress, param_path: str
    ) -> bool:
        """Execute a single R module with enhanced monitoring."""
        try:
            module_script = MODULE_SCRIPTS.get(module_progress)
            if not module_script:
                raise ValueError(f"No R script found for module: {module_progress}")

            Logger.info(f"Executing module {module_progress.value}: {module_script}")

            # Create module-specific flag file for monitoring
            # module_flag_file = get_flag_file(analysis_id, module_name)
            # # Remove existing flag file
            # if os.path.exists(module_flag_file):
            #     os.remove(module_flag_file)

            # Execute the R script with timeout and monitoring
            start_time = time.time()
            process = subprocess.Popen(
                ["Rscript", module_script, param_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )

            # Monitor the process with timeout (30 minutes per module)
            timeout = 3600 * 2  # 2 hours
            check_interval = 5  # 5 seconds

            while True:
                # Check if process is still running
                return_code = process.poll()
                if return_code is not None:
                    # Process finished
                    stdout, stderr = process.communicate()
                    if return_code == 0:
                        Logger.info(
                            f"Module {module_progress.value} completed successfully"
                        )
                        Logger.debug(f"Module {module_progress.value} stdout: {stdout}")
                        return True
                    else:
                        Logger.error(
                            f"Module {module_progress.value} failed with return code {return_code}",
                            context={
                                "task": "_execute_module",
                                "module": module_progress.value,
                                "stdout": stdout,
                                "stderr": stderr,
                            },
                        )
                        return False

                # Check timeout
                elapsed_time = time.time() - start_time
                if elapsed_time > timeout:
                    Logger.error(
                        f"Module {module_progress.value} timed out after {timeout} seconds",
                        context={
                            "task": "_execute_module",
                            "module": module_progress.value,
                        },
                    )
                    process.terminate()
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        process.kill()
                    return False

                # Log progress every minute
                if int(elapsed_time) % 60 == 0:
                    Logger.info(
                        f"Analyze: {analysis_id} - Module {module_progress.value} still running... ({int(elapsed_time / 60)} min)"
                    )

                time.sleep(check_interval)

        except Exception as e:
            Logger.error(
                f"Error executing module {module_progress.value}: {e}",
                context={"task": "_execute_module", "module": module_progress.value},
            )
            return False

    def _monitor_r_execution(self, analysis_id: str, flag_path: str) -> str:
        """Monitor R execution by polling flag file and return its content."""
        print(f"Start monitoring R script execution - {analysis_id}")
        max_wait_time = 7200  # 2 hours
        check_interval = 3  # 3 seconds
        elapsed_time = 0

        Logger.debug(f"Checking flag file for {analysis_id} at {flag_path}")
        print(f"DEBUG: Looking for flag file at {flag_path}")

        while elapsed_time < max_wait_time:
            try:
                Logger.debug(f"Checking flag file for {analysis_id} at {flag_path}")
                if os.path.exists(flag_path):
                    with open(flag_path, "r") as f:
                        flag_content = f.read().strip()
                    Logger.info(f"Flag file found for {analysis_id}: {flag_content}")
                    return flag_content
                Logger.debug(f"Flag file not found for {analysis_id} at {flag_path}")
                time.sleep(check_interval)
                elapsed_time += check_interval
            except Exception as e:
                Logger.error(
                    f"Error monitoring execution for {analysis_id}: {e}",
                    context={"task": "_monitor_r_execution"},
                )
                return "error"

        Logger.error(
            f"Analysis {analysis_id} timed out after {max_wait_time} seconds",
            context={"task": "_monitor_r_execution"},
        )
        return "error"

    def _send_webhook(
        self,
        analysis_id: str,
        flag_content: str,
        webhook_url: str,
        error_message: str = None,
    ):
        """Send webhook notification to update database."""
        try:
            payload = {
                "analysis_id": analysis_id,
                "status": flag_content,
            }

            print("payload: ", payload)
            print("webhook_url: ", webhook_url)
            response = requests.post(
                webhook_url,
                json=payload,
                headers={"Content-Type": "application/json"},
            )
            response.raise_for_status()
            Logger.info(
                f"Webhook sent successfully for analysis {analysis_id}: {flag_content}"
            )
        except Exception as e:
            Logger.error(
                f"Failed to send webhook for analysis {analysis_id}: {e}",
                context={"task": "_send_webhook"},
            )

    def _send_module_update_webhook(
        self,
        analysis_id: str,
        payload: Dict[str, Any],
        webhook_url: str,
    ):
        """Send webhook notification for module completion updates."""
        try:
            print("module update payload: ", payload)
            print("webhook_url: ", webhook_url)
            response = requests.post(
                webhook_url,
                json=payload,
                headers={"Content-Type": "application/json"},
            )
            response.raise_for_status()
            Logger.info(
                f"Module update webhook sent successfully for analysis {analysis_id}: {payload['status']}"
            )
        except Exception as e:
            Logger.error(
                f"Failed to send module update webhook for analysis {analysis_id}: {e}",
                context={"task": "_send_module_update_webhook"},
            )

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

            # Create analysis directory if not exists
            analysis_dir = f"/tmp/analysis/{request.analysis_id}"
            os.makedirs(analysis_dir, exist_ok=True)

            # Save parameters to JSON file
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
                    datetime.now()
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
