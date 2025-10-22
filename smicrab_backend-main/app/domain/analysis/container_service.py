import docker
import os
import threading
import time
from typing import Dict, Optional, List
from datetime import datetime, timedelta, timezone
from app.utils.logger import Logger
from core.config import settings


class ContainerService:
    """Service to manage Docker containers for analysis execution"""
    
    def __init__(self):
        self.client = docker.from_env()
        self.running_containers: Dict[str, dict] = {}
        self.max_concurrent_containers = 3
        self.container_memory_limit = os.getenv("MEMORY_LIMIT_PER_ANALYSIS") 
        self.container_cpu_limit = os.getenv("CPU_LIMIT_PER_ANALYSIS") 
        self.lock = threading.Lock()
        self.network_name = "smicrab-net" 
        self.host_project_path = os.getenv("PROJECT_PATH")
        if not self.host_project_path:
            raise ValueError("CRITICAL: PROJECT_PATH environment variable is not set.")

        
    def get_running_container_count(self) -> int:
        """Get the number of currently running analysis containers"""
        with self.lock:
            # Clean up finished containers from tracking
            self._cleanup_finished_containers()
            return len(self.running_containers)
    
    def can_start_new_container(self) -> bool:
        """Check if we can start a new container (within limit)"""
        return self.get_running_container_count() < self.max_concurrent_containers
    
    def _cleanup_finished_containers(self):
        """Remove finished containers from tracking"""
        finished_ids = []
        for container_id, info in self.running_containers.items():
            try:
                container = self.client.containers.get(container_id)
                if container.status not in ['running', 'created']:
                    finished_ids.append(container_id)
            except docker.errors.NotFound:
                finished_ids.append(container_id)
        
        for container_id in finished_ids:
            del self.running_containers[container_id]
    

    def start_analysis_container(self, analysis_id: str, model_type: str) -> bool:
        if not self.can_start_new_container():
            Logger.error(
                f"Cannot start container for analysis {analysis_id}: Maximum concurrent containers ({self.max_concurrent_containers}) reached",
                context={"task": "start_analysis_container", "analysis_id": analysis_id}
            )
            return False

        container_name = f"smicrab_analysis_{analysis_id}"

        try:
            # Remove a pre-existing container with the same name, if any.
            try:
                existing_container = self.client.containers.get(container_name)
                Logger.info(f"Removing existing container with name {container_name}")
                existing_container.remove(force=True)
            except docker.errors.NotFound:
                pass  # This is fine, it means the container doesn't exist.
            
            volumes = {
                os.path.join(self.host_project_path, "tmp/analysis"): {"bind": "/tmp/analysis", "mode": "rw"},
            }
            
            environment = {
                "ANALYSIS_ID": analysis_id,
                "MODEL_TYPE": model_type,
                # Use the service name for communication inside the Docker network.
                # 'backend' is the name of the backend service in docker-compose.
                "WEBHOOK_URL": os.getenv("WEBHOOK_URL")
            }

            command = ["python", "/app/container_runner.py", analysis_id]
            
            # Convert CPU limit to nano_cpus
            nano_cpus = int(float(self.container_cpu_limit) * 1_000_000_000)

            # Run the container using the Docker API
            container = self.client.containers.run(
                image="smicrab-analysis:latest",
                name=container_name,  # A unique, dynamic name for each analysis
                command=command,
                volumes=volumes,
                environment=environment,
                mem_limit=self.container_memory_limit,
                nano_cpus=nano_cpus,
                detach=True,
                remove=False, # We handle removal manually after monitoring
                network=self.network_name, # Attach to the correct shared network
                labels={"smicrab.analysis_id": analysis_id, "smicrab.type": "analysis"}
            )

            
            # Track the container
            with self.lock:
                self.running_containers[container.id] = {
                    "analysis_id": analysis_id,
                    "model_type": model_type,
                    "container_name": container_name,
                    "started_at": datetime.now(timezone.utc),
                    "container": container
                }
            
            Logger.info(f"Started analysis container {container_name} for analysis {analysis_id}")
            
            # Start monitoring thread
            monitor_thread = threading.Thread(
                target=self._monitor_container,
                args=(container.id, analysis_id),
                daemon=True
            )
            monitor_thread.start()
            
            return True
            
        except Exception as e:
            Logger.error(
                f"Failed to start container for analysis {analysis_id}: {e}",
                context={"task": "start_analysis_container", "analysis_id": analysis_id}
            )
            return False
    
    def _monitor_container(self, container_id: str, analysis_id: str):
        """Monitor container execution and handle cleanup"""
        try:
            container = self.client.containers.get(container_id)
            
            # Wait for container to finish
            result = container.wait()
            
            # Get logs for debugging with error handling
            logs = ""
            try:
                logs = container.logs().decode('utf-8')
            except Exception as log_error:
                Logger.warn(f"Could not read container logs for {container_id}: {log_error}")
                logs = f"Log reading failed: {log_error}"
            
            # Check exit status
            exit_code = result['StatusCode']
            
            if exit_code == 0:
                Logger.info(f"Analysis container {container_id} completed successfully for analysis {analysis_id}")
                status = "done"
            else:
                Logger.error(
                    f"Analysis container {container_id} failed with exit code {exit_code} for analysis {analysis_id}",
                    context={"task": "_monitor_container", "container_id": container_id, "exit_code": exit_code}
                )
                Logger.error(
                    f"Container logs: {logs}",
                    context={"task": "_monitor_container", "container_id": container_id}
                )
                status = "error"
            
            # Send webhook notification
            self._send_completion_webhook(analysis_id, status, logs if exit_code != 0 else None)
            
        except Exception as e:
            Logger.error(
                f"Error monitoring container {container_id}: {e}",
                context={"task": "_monitor_container", "container_id": container_id}
            )
            self._send_completion_webhook(analysis_id, "error", str(e))
        
        finally:
            Logger.info(f"Container {container_id} finished")
            # Cleanup container
            self._cleanup_container(container_id)
    
    def _cleanup_container(self, container_id: str):
        """Remove container and clean up tracking"""
        try:
            container = self.client.containers.get(container_id)
            container.remove(force=True)
            Logger.info(f"Cleaned up container {container_id}")
        except docker.errors.NotFound:
            Logger.info(f"Container {container_id} already removed")
        except Exception as e:
            Logger.error(
                f"Error cleaning up container {container_id}: {e}",
                context={"task": "_cleanup_container", "container_id": container_id}
            )
        
        # Remove from tracking
        with self.lock:
            if container_id in self.running_containers:
                del self.running_containers[container_id]
    
    def _send_completion_webhook(self, analysis_id: str, status: str, error_message: Optional[str] = None):
        """Send webhook notification for analysis completion"""
        import requests
        
        try:
            payload = {
                "analysis_id": analysis_id,
                "status": status,
                "error_message": error_message
            }
            
            response = requests.post(
                settings.WEBHOOK_URL,
                json=payload,
                headers={"Content-Type": "application/json"}
            )
            response.raise_for_status()
            
            Logger.info(f"Webhook sent successfully for analysis {analysis_id}: {status}")
            
        except Exception as e:
            Logger.error(
                f"Failed to send webhook for analysis {analysis_id}: {e}",
                context={"task": "_send_completion_webhook", "analysis_id": analysis_id}
            )
    
    def stop_analysis_container(self, analysis_id: str) -> bool:
        """Stop and remove container for specific analysis"""
        with self.lock:
            for container_id, info in self.running_containers.items():
                if info["analysis_id"] == analysis_id:
                    try:
                        container = self.client.containers.get(container_id)
                        container.stop(timeout=30)
                        self._cleanup_container(container_id)
                        Logger.info(f"Stopped container for analysis {analysis_id}")
                        return True
                    except Exception as e:
                        Logger.error(
                            f"Error stopping container for analysis {analysis_id}: {e}",
                            context={"task": "stop_analysis_container", "analysis_id": analysis_id}
                        )
                        return False
            
            # Also check by container name in case it's not in our tracking
            try:
                container_name = f"smicrab_analysis_{analysis_id}"
                container = self.client.containers.get(container_name)
                container.stop(timeout=30)
                container.remove(force=True)
                Logger.info(f"Stopped container by name for analysis {analysis_id}")
                return True
            except docker.errors.NotFound:
                pass
            except Exception as e:
                Logger.error(
                    f"Error stopping container by name for analysis {analysis_id}: {e}",
                    context={"task": "stop_analysis_container", "analysis_id": analysis_id}
                )
            
            Logger.warn(f"No running container found for analysis {analysis_id}")
            return False
    
    def get_running_analyses(self) -> List[dict]:
        """Get list of currently running analyses"""
        with self.lock:
            self._cleanup_finished_containers()
            return [
                {
                    "analysis_id": info["analysis_id"],
                    "model_type": info["model_type"],
                    "started_at": info["started_at"].isoformat(),
                    "container_name": info["container_name"]
                }
                for info in self.running_containers.values()
            ]
    
    def build_analysis_image(self):
        """Build the Docker image for analysis execution"""
        try:
            Logger.info("Building analysis runner Docker image...")
            
            # Build image from current directory with specific Dockerfile
            image, build_logs = self.client.images.build(
                path=".",
                dockerfile="Dockerfile.analysis",
                tag="smicrab-analysis:latest",
                rm=True
            )
            
            Logger.info("Analysis runner Docker image built successfully")
            return True
            
        except Exception as e:
            Logger.error(
                f"Failed to build analysis runner image: {e}",
                context={"task": "build_analysis_image"}
            )
            return False
    
    def handle_container_error(self, analysis_id: str, error_message: str, container_id: str = None):
        """Handle container errors and update analysis status"""
        try:
            Logger.error(
                f"Container error for analysis {analysis_id}: {error_message}",
                context={"task": "handle_container_error", "analysis_id": analysis_id, "container_id": container_id}
            )
            
            # Stop the container if it's still running
            if container_id:
                try:
                    container = self.client.containers.get(container_id)
                    if container.status == 'running':
                        container.stop(timeout=10)
                        Logger.info(f"Stopped error container {container_id}")
                except Exception as e:
                    Logger.warn(f"Could not stop error container {container_id}: {e}")
            
            # Also try to stop by name
            try:
                container_name = f"smicrab_analysis_{analysis_id}"
                container = self.client.containers.get(container_name)
                if container.status == 'running':
                    container.stop(timeout=10)
                    container.remove(force=True)
                    Logger.info(f"Stopped error container by name {container_name}")
            except docker.errors.NotFound:
                pass
            except Exception as e:
                Logger.warn(f"Could not stop error container by name: {e}")
            
            # Send error webhook
            self._send_completion_webhook(analysis_id, "error", error_message)
            
        except Exception as e:
            Logger.error(
                f"Error in handle_container_error for analysis {analysis_id}: {e}",
                context={"task": "handle_container_error", "analysis_id": analysis_id}
            )
    
    def get_container_status(self, analysis_id: str) -> dict:
        """Get detailed status of a specific container"""
        try:
            container_name = f"smicrab_analysis_{analysis_id}"
            container = self.client.containers.get(container_name)
            
            return {
                "analysis_id": analysis_id,
                "container_id": container.id,
                "container_name": container_name,
                "status": container.status,
                "state": container.attrs.get('State', {}),
                "created": container.attrs.get('Created'),
                "started_at": container.attrs.get('State', {}).get('StartedAt')
            }
        except docker.errors.NotFound:
            return {"analysis_id": analysis_id, "status": "not_found"}
        except Exception as e:
            Logger.error(
                f"Error getting container status for analysis {analysis_id}: {e}",
                context={"task": "get_container_status", "analysis_id": analysis_id}
            )
            return {"analysis_id": analysis_id, "status": "error", "error": str(e)} 