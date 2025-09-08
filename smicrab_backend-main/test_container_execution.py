#!/usr/bin/env python3
"""
Test script to actually run a container for the test analysis
"""

import asyncio
import os
import sys
import json
import time
from pathlib import Path

# Add the app directory to Python path
sys.path.append('.')

from app.domain.analysis.container_service import ContainerService
from app.utils.logger import Logger

async def test_actual_container_execution():
    """Test actual container execution with the test analysis"""
    
    print("🚀 Testing SMICRAB Container Execution")
    print("=" * 50)
    
    # Test analysis ID (provided by user)
    test_analysis_id = "d0e99398-a538-471a-b551-8241e0c22825"
    
    try:
        # Initialize container service
        print("1. Initializing Container Service...")
        container_service = ContainerService()
        print(f"   ✅ Container service initialized")
        
        # Check if parameters file exists
        param_file = f"tmp/analysis/{test_analysis_id}/parameters.json"
        print(f"   📂 Parameters file in host: {param_file}")
        
        if not os.path.exists(param_file):
            print(f"   ❌ Parameters file not found: {param_file}")
            return False
            
        # Load parameters
        with open(param_file, 'r') as f:
            params = json.load(f)
        model_type = params.get('model_type', 'Unknown')
        print(f"   📋 Parameters loaded - Model type: {model_type}")
        
        # Check if we can start a container
        can_start = container_service.can_start_new_container()
        if not can_start:
            print(f"   ❌ Cannot start container - capacity reached")
            return False
            
        print(f"   🚦 Ready to start container")
        
        # Start the container
        print(f"\n2. Starting analysis container...")
        print(f"   📦 Container name: smicrab_analysis_{test_analysis_id}")
        print(f"   🏷️  Image: smicrab-analysis:latest")
        print(f"   🔧 Model type: {model_type}")
        
        success = container_service.start_analysis_container(test_analysis_id, model_type)
        
        if success:
            print(f"   ✅ Container started successfully!")
            
            # Get container status
            container_status = container_service.get_container_status(test_analysis_id)
            print(f"   📊 Container status: {container_status}")
            
            # Monitor container execution
            print(f"\n3. Monitoring container execution...")
            print(f"   ⏱️  Checking status every 30 seconds...")
            print(f"   💡 You can check logs with: docker logs smicrab_analysis_{test_analysis_id}")
            
            # Wait and check status periodically
            max_wait_time = 7200  # 2 hours for initial test
            check_interval = 30
            elapsed_time = 0
            
            while elapsed_time < max_wait_time:
                running_analyses = container_service.get_running_analyses()
                test_running = any(analysis['analysis_id'] == test_analysis_id for analysis in running_analyses)
                
                if test_running:
                    print(f"   🔄 Container still running... ({elapsed_time}s elapsed)")
                    
                    # Check container status periodically
                    if elapsed_time % 60 == 0:  # Every minute
                        status = container_service.get_container_status(test_analysis_id)
                        print(f"   📊 Container status: {status.get('status', 'unknown')}")
                else:
                    print(f"   ✅ Container has finished execution")
                    break
                    
                time.sleep(check_interval)
                elapsed_time += check_interval
            
            if elapsed_time >= max_wait_time:
                print(f"   ⏰ Monitoring timeout reached ({max_wait_time}s)")
                print(f"   📊 Container may still be running - check Docker logs")
            
            # Show final status
            final_running = container_service.get_running_analyses()
            test_still_running = any(analysis['analysis_id'] == test_analysis_id for analysis in final_running)
            
            print(f"\n4. Final Status:")
            print(f"   🏃‍♂️ Container still running: {test_still_running}")
            print(f"   📁 Output directory: tmp/analysis/{test_analysis_id}/")
            
            # Check for output files
            output_dir = f"tmp/analysis/{test_analysis_id}"
            if os.path.exists(output_dir):
                print(f"   📂 Output files:")
                for root, dirs, files in os.walk(output_dir):
                    for file in files[:10]:  # Show first 10 files
                        rel_path = os.path.relpath(os.path.join(root, file), output_dir)
                        print(f"      - {rel_path}")
                    if len(files) > 10:
                        print(f"      ... and {len(files) - 10} more files")
                    break  # Only show first level
            
        else:
            print(f"   ❌ Failed to start container")
            return False
            
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    print(f"\n🎉 Container execution test completed!")
    return True

async def test_stop_container():
    """Test stopping a container"""
    test_analysis_id = "d0e99398-a538-471a-b551-8241e0c22825"
    
    print(f"\n🛑 Testing container stop functionality")
    print("=" * 50)
    
    try:
        container_service = ContainerService()
        
        # Check if container is running
        running_analyses = container_service.get_running_analyses()
        test_running = any(analysis['analysis_id'] == test_analysis_id for analysis in running_analyses)
        
        if test_running:
            print(f"   🔄 Container found running for analysis {test_analysis_id}")
            
            # Stop the container
            stopped = container_service.stop_analysis_container(test_analysis_id)
            
            if stopped:
                print(f"   ✅ Container stopped successfully")
            else:
                print(f"   ❌ Failed to stop container")
                
        else:
            print(f"   ℹ️  No running container found for analysis {test_analysis_id}")
            
    except Exception as e:
        print(f"❌ Stop test failed: {e}")
        return False
    
    return True

async def test_error_handling():
    """Test error handling and container stopping mechanisms"""
    test_analysis_id = "test-error-handling-123"
    
    print(f"\n🧪 Testing error handling mechanisms")
    print("=" * 50)
    
    try:
        container_service = ContainerService()
        
        # Test container status for non-existent container
        print("1. Testing container status for non-existent container...")
        status = container_service.get_container_status(test_analysis_id)
        print(f"   📊 Status: {status}")
        
        # Test stopping non-existent container
        print("\n2. Testing stop for non-existent container...")
        stopped = container_service.stop_analysis_container(test_analysis_id)
        print(f"   🛑 Stop result: {stopped}")
        
        # Test error handling
        print("\n3. Testing error handling...")
        container_service.handle_container_error(test_analysis_id, "Test error message")
        print(f"   ✅ Error handling test completed")
        
    except Exception as e:
        print(f"❌ Error handling test failed: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("Select test to run:")
    print("1. Start container and monitor execution")
    print("2. Stop running container")
    print("3. Both (start then stop after delay)")
    print("4. Test error handling mechanisms")
    
    choice = input("\nEnter choice (1-4): ").strip()
    
    if choice == "1":
        asyncio.run(test_actual_container_execution())
    elif choice == "2":
        asyncio.run(test_stop_container())
    elif choice == "3":
        asyncio.run(test_actual_container_execution())
        print("\nWaiting 60 seconds before stopping...")
        time.sleep(60)
        asyncio.run(test_stop_container())
    elif choice == "4":
        asyncio.run(test_error_handling())
    else:
        print("Invalid choice") 