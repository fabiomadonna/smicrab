#!/usr/bin/env python3
"""
Script to build the SMICRAB analysis Docker image
"""

import docker
import logging
import sys
import os

# Setup logging
logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(levelname)s %(message)s')
logger = logging.getLogger(__name__)

def build_analysis_image():
    """Build the Docker image for analysis execution"""
    try:
        client = docker.from_env()
        logger.info("Building analysis runner Docker image...")
        
        # Build image from current directory with specific Dockerfile
        image, build_logs = client.images.build(
            path=".",
            dockerfile="Dockerfile.analysis",
            tag="smicrab-analysis:latest",
            rm=True,
            forcerm=True
        )
        
        # Print build logs
        for log in build_logs:
            if 'stream' in log:
                print(log['stream'].strip())
        
        logger.info("✅ Analysis runner Docker image built successfully")
        logger.info(f"Image ID: {image.id}")
        logger.info(f"Image tags: {image.tags}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Failed to build analysis runner image: {e}")
        return False

if __name__ == "__main__":
    # Change to the directory containing this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    logger.info(f"Building from directory: {os.getcwd()}")
    
    success = build_analysis_image()
    sys.exit(0 if success else 1) 