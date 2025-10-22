#!/usr/bin/env python3
"""
Container Runner for SMICRAB Analysis
This script runs inside Docker containers to execute R analysis pipelines
"""

import os
import sys
import json
import subprocess
import time
import requests
from pathlib import Path
from enum import Enum


class ModuleProgress(Enum):
    """Enumeration for module progress tracking"""
    init_module = "init_module"
    load_module = "load_module"
    describe_module = "describe_module"
    estimate_module = "estimate_module"
    validate_module = "validate_module"
    risk_map_module = "risk_map_module"


# Module scripts for step-by-step execution
MODULE_SCRIPTS = {
    ModuleProgress.init_module: "/app/r_scripts/r_models/00_common_setup.R",
    ModuleProgress.load_module: "/app/r_scripts/r_models/01_data_module.R",
    ModuleProgress.describe_module: "/app/r_scripts/r_models/02_describe_module.R",
    ModuleProgress.estimate_module: "/app/r_scripts/r_models/03_estimate_module.R",
    ModuleProgress.validate_module: "/app/r_scripts/r_models/04_validate_module.R",
    ModuleProgress.risk_map_module: "/app/r_scripts/r_models/05_riskmap_module.R",
}

# Module execution order
MODULE_EXECUTION_ORDER = [
    ModuleProgress.init_module,
    ModuleProgress.load_module,
    ModuleProgress.describe_module,
    ModuleProgress.estimate_module,
    ModuleProgress.validate_module,
    ModuleProgress.risk_map_module,
]


def get_parameters_file(analysis_id: str) -> str:
    """Get the parameters file path for analysis"""
    base_path = "/tmp/analysis"
    analysis_dir = f"{base_path}/{analysis_id}"
    os.makedirs(analysis_dir, exist_ok=True)
    param_path = f"{analysis_dir}/parameters.json"
    return param_path


def log_info(message: str):
    """Simple logging function for info messages"""
    print(f"[INFO] {message}", flush=True)


def log_error(message: str):
    """Simple logging function for error messages"""
    print(f"[ERROR] {message}", flush=True, file=sys.stderr)


def execute_r_module(module_script: str, param_path: str) -> bool:
    """Execute a single R module with enhanced monitoring"""
    try:
        log_info(f"Starting execution of R module: {module_script}")
        
        # Execute the R script with timeout and monitoring
        start_time = time.time()
        process = subprocess.Popen(
            ["Rscript", module_script, param_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            cwd="/app"
        )
        
        # Monitor the process with timeout (2 hours per module)
        timeout = 7200  # 2 hours
        check_interval = 30  # 30 seconds
        
        while True:
            # Check if process is still running
            return_code = process.poll()
            if return_code is not None:
                # Process finished
                stdout, stderr = process.communicate()
                
                if return_code == 0:
                    log_info(f"Module {module_script} completed successfully")
                    if stdout:
                        log_info(f"Module stdout: {stdout}")
                    return True
                else:
                    log_error(f"Module {module_script} failed with return code {return_code}")
                    if stdout:
                        log_error(f"Module stdout: {stdout}")
                    if stderr:
                        log_error(f"Module stderr: {stderr}")
                    return False
            
            # Check timeout
            elapsed_time = time.time() - start_time
            if elapsed_time > timeout:
                log_error(f"Module {module_script} timed out after {timeout} seconds")
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                return False
            
            # Log progress every 5 minutes
            if int(elapsed_time) % 300 == 0:
                log_info(f"Module {module_script} still running... ({int(elapsed_time / 60)} min)")
            
            time.sleep(check_interval)
            
    except Exception as e:
        log_error(f"Error executing module {module_script}: {e}")
        return False


def send_module_update_webhook(analysis_id: str, current_module: str, next_module: str, webhook_url: str):
    """Send webhook notification for module completion updates"""
    try:
        payload = {
            "analysis_id": analysis_id,
            "status": "module_completed",
            "current_module": current_module,
            "next_module": next_module
        }
        
        log_info(f"Sending module update webhook: {payload}")
        
        response = requests.post(
            webhook_url,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        response.raise_for_status()
        
        log_info(f"Module update webhook sent successfully")
        
    except Exception as e:
        log_error(f"Failed to send module update webhook: {e}")


def send_error_webhook(analysis_id: str, error_message: str, webhook_url: str):
    """Send webhook notification for analysis errors"""
    try:
        payload = {
            "analysis_id": analysis_id,
            "status": "error",
            "error_message": error_message
        }
        
        log_error(f"Sending error webhook: {payload}")
        
        response = requests.post(
            webhook_url,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        response.raise_for_status()
        
        log_info(f"Error webhook sent successfully")
        
    except Exception as e:
        log_error(f"Failed to send error webhook: {e}")


def main():
    """Main execution function"""
    if len(sys.argv) != 2:
        print("Usage: container_runner.py <analysis_id>")
        sys.exit(1)
    
    analysis_id = sys.argv[1]
    
    # Get environment variables
    model_type = os.getenv("MODEL_TYPE")
    webhook_url = os.getenv("WEBHOOK_URL")
    if not webhook_url:
        log_error("CRITICAL: WEBHOOK_URL environment variable is not set.")
        sys.exit(1)  
          
    log_info(f"Starting analysis container execution")
    log_info(f"Analysis ID: {analysis_id}")
    log_info(f"Model Type: {model_type}")
    log_info(f"Webhook URL: {webhook_url}")
    
    try:
        # Verify parameters file exists
        param_path = get_parameters_file(analysis_id)
        log_info(f"Parameters file: {param_path}")
        
        if not os.path.exists(param_path):
            raise FileNotFoundError(f"Parameters file not found: {param_path}")
        
        # Check if the file is empty
        if os.path.getsize(param_path) == 0:
            raise FileNotFoundError(f"Parameters file is empty: {param_path}")
        
        log_info(f"Parameters file exists and is not empty")
        log_info(f"Using parameters file: {param_path}")
        
        # Execute modules step by step
        for i, module_progress in enumerate(MODULE_EXECUTION_ORDER):
            try:
                log_info(f"Starting module {module_progress.value} ({i+1}/{len(MODULE_EXECUTION_ORDER)})")
                
                # Get the module script path
                module_script = MODULE_SCRIPTS.get(module_progress)
                if not module_script:
                    error_msg = f"No R script found for module: {module_progress}"
                    log_error(error_msg)
                    send_error_webhook(analysis_id, error_msg, webhook_url)
                    sys.exit(1)
                
                # Execute the module
                success = execute_r_module(module_script, param_path)
                
                if not success:
                    error_msg = f"Module {module_progress.value} failed"
                    log_error(error_msg)
                    send_error_webhook(analysis_id, error_msg, webhook_url)
                    sys.exit(1)
                
                log_info(f"Module {module_progress.value} completed successfully")
                
                # Send webhook to update current module after successful completion
                next_module = (
                    MODULE_EXECUTION_ORDER[i + 1].value
                    if i + 1 < len(MODULE_EXECUTION_ORDER)
                    else "completed"
                )
                
                send_module_update_webhook(
                    analysis_id, 
                    module_progress.value, 
                    next_module, 
                    webhook_url, 
                )
                
            except Exception as e:
                error_msg = f"Error executing module {module_progress.value}: {e}"
                log_error(error_msg)
                send_error_webhook(analysis_id, error_msg, webhook_url)
                sys.exit(1)
        
        # All modules completed successfully
        log_info(f"All modules completed successfully for analysis {analysis_id}")
        
        # Create completion flag
        flag_file = f"/tmp/analysis/{analysis_id}/{analysis_id}.flag"
        os.makedirs(os.path.dirname(flag_file), exist_ok=True)
        with open(flag_file, "w") as f:
            f.write("done")
        
        log_info(f"Analysis pipeline completed successfully")
        sys.exit(0)
        
    except Exception as e:
        error_msg = f"Analysis pipeline failed: {e}"
        log_error(error_msg)
        send_error_webhook(analysis_id, error_msg, webhook_url)
        sys.exit(1)


if __name__ == "__main__":
    main() 